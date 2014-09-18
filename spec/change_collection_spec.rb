require 'helper'

describe Aquarium::ChangeCollection do

  before do
    @change = Aquarium::Change.new('test:1','test_file.sql','description')
    @change_collection = Aquarium::ChangeCollection.new('test_file.sql')
  end

  describe '#new' do
    it 'creates new change collection' do
      file_name = 'some/dir/test_file.sql'
      change_collection = Aquarium::ChangeCollection.new(file_name)
      expect(change_collection).to be_an_instance_of(Aquarium::ChangeCollection)
    end
  end

  describe '#add_change' do
    it 'adds new change to the list' do
      @change_collection.add_change(@change)
      expect(@change_collection.current_change).to eq(@change)
    end
  end

  describe '#current_change' do
    context 'when collection is empty' do
      it 'returns nil'  do
        expect(@change_collection.current_change).to be_nil
      end
    end
    context 'when collection is not empty' do
      it 'returns current change in the collection' do
        @change_collection.add_change(@change)
        expect(@change_collection.current_change).to eq(@change)
      end
    end
  end

  describe '#merge' do
    context 'when merging with collection that has duplicate changes' do
      it 'raises an error' do
        @change_collection.add_change(@change)
        additional_change_collection = Aquarium::ChangeCollection.new('test_file1.sql')
        additional_change_collection.add_change(@change)
        expect {@change_collection.merge(additional_change_collection)}.to raise_error
      end
    end
    context 'when merging with collection with no duplicate changes' do
      it 'produces merged collection' do
        @change_collection.add_change(@change)
        additional_change = Aquarium::Change.new('test:2','test_file.sql','description')
        additional_change_collection = Aquarium::ChangeCollection.new('test_file1.sql')
        additional_change_collection.add_change(additional_change)
        @change_collection.merge(additional_change_collection)
        expect(@change_collection.find(@change.code)).to eq(@change)
        expect(@change_collection.find(additional_change.code)).to eq(additional_change)
      end
    end
  end

  describe '#exists' do
    it 'checks if change exists in collection' do
      @change_collection.add_change(@change)
      expect(@change_collection.exists(@change)).to eq(@change)
    end
  end

  describe '#find' do
    it 'finds change by code' do
      @change_collection.add_change(@change)
      expect(@change_collection.find(@change.code)).to eq(@change)
    end
  end

  describe '#find!' do
    context 'when existing change code is passed' do
      it 'finds change by code' do
        @change_collection.add_change(@change)
        expect(@change_collection.find!(@change.code)).to eq(@change)
      end
    end
    context 'when non existing change code is passwd' do
      it 'raises an exeption' do
        expect {@change_collection.find!('no_existing_change')}.to raise_error
      end
    end
  end

  describe '#pending_changes' do
    context 'when control table does not exist in database' do
      it 'returns all changes' do
        database = instance_double('Aquarium::MySQLDatabase')
        allow(database).to receive(:control_table_missing?) {true}
        @change_collection.add_change(@change)
        pending_changes = @change_collection.pending_changes(database)
        expect(pending_changes.size).to eql(1)
        expect(pending_changes).to include(@change)
      end
    end
    context 'when control table exists and has some changes registered' do
      it 'returns changes not applied to the database' do
        database = instance_double('Aquarium::MySQLDatabase')
        allow(database).to receive(:control_table_missing?) {false}
        allow(database).to receive(:change_registered?) do |change|
          change.code == 'test:1' ? true : false
        end
        @change_collection.add_change(@change)
        unregistered_change = Aquarium::Change.new('test:2','test_file.sql','description')
        @change_collection.add_change(unregistered_change)
        pending_changes = @change_collection.pending_changes(database)
        expect(pending_changes.size).to eql(1)
        expect(pending_changes).to include(unregistered_change)
      end
    end
  end

  describe '#reverse' do
    it 'returns changes in reversed order' do
      @change_collection.add_change(@change)
      second_change = Aquarium::Change.new('test:2','test_file.sql','description')
      @change_collection.add_change(second_change)
      reversed_collection = @change_collection.reverse
      expect(reversed_collection.first).to eql(second_change)
      expect(reversed_collection.last).to eql(@change)
    end
  end
end