require 'helper'
require 'oci8'

describe Aquarium::Executors::RegisterChange do
  before do
    @change_collection = Aquarium::ChangeCollection.new('file_name')
    @change1 = Aquarium::Change.new('test:1','test_file.sql','description')
    @change1.current_sql_collection << 'create table test1'
    @change_collection.add_change(@change1)
    @change2 = Aquarium::Change.new('test:2','test_file.sql','description')
    @change2.current_sql_collection << 'create table test2'
    @change_collection.add_change(@change2)
    @parser = instance_double('Aquarium::Parser')
  end
  describe '#help' do
    it 'returns help string' do
      expect(Aquarium::Executors::RegisterChange.help).to be_instance_of String
    end
  end
  describe '#new' do
    context 'when parameters are nil' do
      it 'raises an exception' do
        database = nil
        parameters = nil
        options = {}
        expect(@parser).to receive(:parse) {@change_collection}
        expect {Aquarium::Executors::RegisterChange.new(database, @parser,parameters,options)}.to raise_error
      end
    end
    context 'when non existing change is passed' do
      it 'raises an exception' do
        database = nil
        parameters = ["test:3"]
        options = {}
        expect(@parser).to receive(:parse) {@change_collection}
        expect {Aquarium::Executors::RegisterChange.new(database, @parser,parameters,options)}.to raise_error
      end
    end
    context 'with correct parameters' do
      it 'creates new object instance' do
        database = nil
        parameters = ["test:1"]
        options = {}
        expect(@parser).to receive(:parse) {@change_collection}
        expect(Aquarium::Executors::RegisterChange.new(database, @parser,parameters,options)).to be_instance_of(Aquarium::Executors::RegisterChange)
      end
    end
  end
  describe '#execute' do
    context 'when change is already registered in the database' do
      it 'raises an error' do
        options = {:interactive => false}
        parameters = ['test:1']
        database = instance_double('Aquarium::MySQLDatabase')
        expect(database).to receive(:change_registered?).with(@change1) {true}
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::RegisterChange.new(database, @parser,parameters,options)
        expect {executor.execute}.to raise_error
      end
    end
    context 'when change is not registered in the database' do
      it 'registers the change' do
        options = {:interactive => false}
        parameters = ['test:1']
        database = instance_double('Aquarium::MySQLDatabase')
        expect(database).to receive(:control_table_missing?) {false}
        expect(database).to receive(:change_registered?).with(@change1) {false}
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::RegisterChange.new(database, @parser,parameters,options)
        expect(database).to receive(:register_change).with(@change1)
        executor.execute
      end
    end
    context 'when user_update option is set' do
      it 'registers the change and control table is correctly updated' do
        options = {:interactive => false,:user_update=>'test'}
        parameters = ['test:1']
        database = instance_double('Aquarium::MySQLDatabase')
        expect(database).to receive(:control_table_missing?) {false}
        expect(database).to receive(:change_registered?).with(@change1) {false}
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::RegisterChange.new(database, @parser,parameters,options)
        expect(database).to receive(:register_change) do |change|
          expect(change.user_update).to eq('test')
        end
        executor.execute
      end
    end
  end
  describe '#print' do
    it 'prints DDL that would be executed' do
      options = {:interactive => false}
      parameters = ['test:1']
      expect(OCI8).to receive(:new)
      database = Aquarium::OracleDatabase.new(options)
      expect(database).to receive(:control_table_missing?) {true}
      expect(database).to receive(:change_registered?).with(@change1) {false}
      expect(@parser).to receive(:parse) {@change_collection}
      executor = Aquarium::Executors::RegisterChange.new(database, @parser,parameters,options)
      expect {executor.print}.to output.to_stdout
    end
  end
end
