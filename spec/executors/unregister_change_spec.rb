require 'helper'
require 'oci8'

describe Aquarium::Executors::UnregisterChange do
  before do
    @change_collection = Aquarium::ChangeCollection.new('file_name')
    @change1 = Aquarium::Change.new('test:1','test_file.sql','description')
    @change1.rollback_sql_collection << 'drop table test1'
    @change_collection.add_change(@change1)
    @change2 = Aquarium::Change.new('test:2','test_file.sql','description')
    @change2.rollback_sql_collection << 'drop table test2'
    @change_collection.add_change(@change2)
    @parser = instance_double('Aquarium::Parser')
  end
  describe '#help' do
    it 'returns help string' do
      expect(Aquarium::Executors::UnregisterChange.help).to be_instance_of String
    end
  end
  describe '#new' do
    context 'when parameters are nil' do
      it 'raises an exception' do
        database = nil
        parameters = nil
        options = {}
        expect(@parser).to receive(:parse) {@change_collection}
        expect {Aquarium::Executors::UnregisterChange.new(database, @parser,parameters,options)}.to raise_error
      end
    end
    context 'when non existing change is passed' do
      it 'raises an exception' do
        database = nil
        parameters = ["test:3"]
        options = {}
        expect(@parser).to receive(:parse) {@change_collection}
        expect {Aquarium::Executors::UnregisterChange.new(database, @parser,parameters,options)}.to raise_error
      end
    end
    context 'with correct parameters' do
      it 'creates new object instance' do
        database = nil
        parameters = ["test:1"]
        options = {}
        expect(@parser).to receive(:parse) {@change_collection}
        expect(Aquarium::Executors::UnregisterChange.new(database, @parser,parameters,options)).to be_instance_of(Aquarium::Executors::UnregisterChange)
      end
    end
  end
  describe '#execute' do
    context 'when change is not registered in the database' do
      it 'raises an error' do
        options = {:interactive => false}
        parameters = ['test:1']
        database = instance_double('Aquarium::MySQLDatabase')
        expect(database).to receive(:change_registered?).with(@change1) {nil}
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::UnregisterChange.new(database, @parser,parameters,options)
        expect {executor.execute}.to raise_error
      end
    end
    context 'when change is registered' do
      it 'unregisters the change' do
        options = {:interactive => false}
        parameters = ['test:1']
        database = instance_double('Aquarium::MySQLDatabase')
        database_change = Aquarium::Change.new('test:1','test_file.sql','description',1,'123','lanusau',@change1.rollback_digest)
        expect(database).to receive(:change_registered?).with(@change1) {database_change}
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::UnregisterChange.new(database, @parser,parameters,options)        
        expect(database).to receive(:unregister_change).with(@change1)
        expect(executor).not_to receive(:warning)
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
      database_change = Aquarium::Change.new('test:1','test_file.sql','description',1,'123','lanusau',@change1.rollback_digest)
      expect(database).to receive(:change_registered?).with(@change1) {database_change}
      expect(@parser).to receive(:parse) {@change_collection}
      executor = Aquarium::Executors::UnregisterChange.new(database, @parser,parameters,options)
      expect {executor.print}.to output.to_stdout
    end
  end
end
