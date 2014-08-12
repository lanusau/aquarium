require 'helper'

describe Aquarium::ChangeCollection do

  before do
    @change = Aquarium::Change.new('test:1','test_file.sql','description')
    @change_colllection = Aquarium::ChangeCollection.new('test_file.sql')
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
      @change_colllection.add_change(@change)
      expect(@change_colllection.current_change).to eq(@change)
    end
  end

  describe '#current_change' do
    context 'when collection is empty' do
      it 'returns nil'  do
        expect(@change_colllection.current_change).to be_nil
      end
    end
    context 'when collection is not empty' do
      it 'returns current change in the collection' do
        @change_colllection.add_change(@change)
        expect(@change_colllection.current_change).to eq(@change)
      end
    end
  end

  describe '#merge' do
    context 'when merging with collection that has duplicate changes' do
      it 'raises an error' do
        @change_colllection.add_change(@change)
        additional_change_collection = Aquarium::ChangeCollection.new('test_file1.sql')
        additional_change_collection.add_change(@change)
        expect {@change_colllection.merge(additional_change_collection)}.to raise_error
      end
    end
    context 'when merging with collection with no duplicate changes' do
      it 'produces merged collection' do
        @change_colllection.add_change(@change)
        additional_change = Aquarium::Change.new('test:2','test_file.sql','description')
        additional_change_collection = Aquarium::ChangeCollection.new('test_file1.sql')
        additional_change_collection.add_change(additional_change)
        @change_colllection.merge(additional_change_collection)
        expect(@change_colllection.find(@change.code)).to eq(@change)
        expect(@change_colllection.find(additional_change.code)).to eq(additional_change)
      end
    end
  end

  describe '#exists' do
    it 'checks if change exists in collection' do
      @change_colllection.add_change(@change)
      expect(@change_colllection.exists(@change)).to eq(@change)
    end
  end

  describe '#find' do
    it 'finds change by code' do
      @change_colllection.add_change(@change)
      expect(@change_colllection.find(@change.code)).to eq(@change)
    end
  end

  describe '#pending_changes' do
    it 'returns changes not applied to the database' do
      database = instance_double('Aquarium::Database')
      allow(database).to receive(:control_table_missing?) {false}
      allow(database).to receive(:change_registered?) do |change|
        change.code == 'test:1' ? true : false
      end
      @change_colllection.add_change(@change)
      unregistered_change = Aquarium::Change.new('test:2','test_file.sql','description')
      @change_colllection.add_change(unregistered_change)
      pending_changes = @change_colllection.pending_changes(database)
      expect(pending_changes.size).to eql(1)
      expect(pending_changes).to include(unregistered_change)
    end
  end

  describe '#reverse' do
    it 'returns changes in reversed order' do
      @change_colllection.add_change(@change)
      second_change = Aquarium::Change.new('test:2','test_file.sql','description')
      @change_colllection.add_change(second_change)
      reversed_collection = @change_colllection.reverse
      expect(reversed_collection.first).to eql(second_change)
      expect(reversed_collection.last).to eql(@change)
    end
  end
end