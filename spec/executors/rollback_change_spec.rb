require 'helper'
require 'dbi'

describe Aquarium::Executors::RollbackChange do
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
      expect(Aquarium::Executors::RollbackChange.help).to be_instance_of String
    end
  end
  describe '#new' do
    context 'when parameters are nil' do
      it 'raises an exception' do
        database = nil
        parameters = nil
        options = nil
        expect(@parser).to receive(:parse) {@change_collection}
        expect {Aquarium::Executors::RollbackChange.new(database, @parser,parameters,options)}.to raise_error
      end
    end
    context 'when non existing change is passed' do
      it 'raises an exception' do
        database = nil
        parameters = ["test:3"]
        options = nil
        expect(@parser).to receive(:parse) {@change_collection}
        expect {Aquarium::Executors::RollbackChange.new(database, @parser,parameters,options)}.to raise_error
      end
    end
    context 'with correct parameters' do
      it 'creates new object instance' do
        database = nil
        parameters = ["test:1"]
        options = nil
        expect(@parser).to receive(:parse) {@change_collection}
        expect(Aquarium::Executors::RollbackChange.new(database, @parser,parameters,options)).to be_instance_of(Aquarium::Executors::RollbackChange)
      end
    end
  end
  describe '#execute' do
    context 'when change is not registered in the database' do
      it 'raises an error' do
        options = {:interactive => false}
        parameters = ['test:1']
        database = instance_double('Aquarium::Database')
        expect(database).to receive(:change_registered?).with(@change1) {false}
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::RollbackChange.new(database, @parser,parameters,options)
        expect {executor.execute}.to raise_error
      end
    end
    context 'when change is registered in the database' do
      it 'executes the change' do
        options = {:interactive => false}
        parameters = ['test:1']
        database = instance_double('Aquarium::Database')
        expect(database).to receive(:change_registered?).with(@change1) {true}
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::RollbackChange.new(database, @parser,parameters,options)
        expect(executor).to receive(:rollback_change).with(@change1)
        expect(database).to receive(:unregister_change).with(@change1)
        executor.execute
      end
    end
  end
  describe '#print' do
    it 'prints DDL that would be executed' do
      options = {:interactive => false}
      parameters = ['test:1']
      expect(DBI).to receive(:connect)
      database = Aquarium::OracleDatabase.new(options)
      expect(database).to receive(:change_registered?).with(@change1) {true}
      expect(@parser).to receive(:parse) {@change_collection}
      executor = Aquarium::Executors::RollbackChange.new(database, @parser,parameters,options)
      expect {executor.print}.to output.to_stdout
    end
  end
end