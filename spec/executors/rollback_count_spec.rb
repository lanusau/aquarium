require 'helper'
require 'oci8'

describe Aquarium::Executors::RollbackCount do
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
      expect(Aquarium::Executors::RollbackCount.help).to be_instance_of String
    end
  end
  describe '#new' do
    context 'when parameters are nil' do
      it 'raises an exception' do
        database = nil
        parameters = nil
        options = {}
        expect(@parser).to receive(:parse) {@change_collection}
        expect {Aquarium::Executors::RollbackCount.new(database, @parser,parameters,options)}.to raise_error
      end
    end
    context 'when invalid number is passed as a parameter' do
      it 'raises an exception' do
        database = nil
        parameters = ['abc']
        options = {}
        expect(@parser).to receive(:parse) {@change_collection}
        expect {Aquarium::Executors::RollbackCount.new(database, @parser,parameters,options)}.to raise_error
      end
    end
    context 'with correct parameters' do
      it 'creates new object instance' do
        database = nil
        parameters = [1]
        options = {}
        expect(@parser).to receive(:parse) {@change_collection}
        expect(Aquarium::Executors::RollbackCount.new(database, @parser,parameters,options)).to be_instance_of(Aquarium::Executors::RollbackCount)
      end
    end
  end
  describe '#execute' do
    context 'when control table does not exists' do
      it 'does nothing' do
        options = {:interactive => false}
        parameters = [1]
        database = instance_double('Aquarium::MySQLDatabase')
        expect(database).to receive(:control_table_missing?) {true}
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::RollbackCount.new(database, @parser,parameters,options)
        expect(executor).not_to receive(:rollback_change)
        executor.execute
      end
    end
    context 'when there is a change in the database that does not exist in file' do
      it 'raises error' do
        options = {:interactive => false}
        parameters = [1]
        database = instance_double('Aquarium::MySQLDatabase')
        expect(database).to receive(:control_table_missing?) {false}
        expect(database).to receive(:changes_in_database) { [Aquarium::Change.new('test:3','test_file.sql','description')] }
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::RollbackCount.new(database, @parser,parameters,options)
        expect {executor.execute}.to raise_error
      end
    end
    context 'when changes in database exist in the file ' do
      it 'rolls back changes' do
        options = {:interactive => false}
        parameters = [2]
        database = instance_double('Aquarium::MySQLDatabase')
        expect(database).to receive(:control_table_missing?) {false}
        db_change1 = @change1.dup
        db_change1.id = 1
        db_change2 = @change2.dup
        db_change2.id = 2
        expect(database).to receive(:changes_in_database) { [db_change1, db_change2] }
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::RollbackCount.new(database, @parser,parameters,options)
        expect(executor).to receive(:rollback_change).with(@change1)
        expect(database).to receive(:unregister_change).with(@change1)
        expect(executor).to receive(:rollback_change).with(@change2)
        expect(database).to receive(:unregister_change).with(@change2)
        executor.execute
        # Primary keys should be populated from database record
        expect(@change1.id).to eq(1)
        expect(@change2.id).to eq(2)
      end
    end
  end
  describe '#print' do
    context 'when control table does not exists' do
      it 'does nothing' do
        options = {:interactive => true}
        parameters = [1]
        database = instance_double('Aquarium::MySQLDatabase')
        expect(database).to receive(:control_table_missing?) {true}
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::RollbackCount.new(database, @parser,parameters,options)
        expect {executor.print}.not_to output.to_stdout
      end
    end
    context 'when there is a change in the database that does not exist in file' do
      it 'raises error' do
        options = {:interactive => false}
        parameters = [1]
        database = instance_double('Aquarium::MySQLDatabase')
        expect(database).to receive(:control_table_missing?) {false}
        expect(database).to receive(:changes_in_database) { [Aquarium::Change.new('test:3','test_file.sql','description')] }
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::RollbackCount.new(database, @parser,parameters,options)
        expect {executor.print}.to raise_error
      end
    end
    context 'when changes in database exist in the file ' do
      it 'prints roll back DDL' do
        options = {:interactive => false}
        parameters = [2]
        expect(OCI8).to receive(:new)
        database = Aquarium::OracleDatabase.new(options)
        expect(database).to receive(:control_table_missing?) {false}
        db_change1 = @change1.dup
        db_change1.id = 1
        db_change2 = @change2.dup
        db_change2.id = 2
        expect(database).to receive(:changes_in_database) { [db_change1, db_change2] }
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::RollbackCount.new(database, @parser,parameters,options)
        expect {executor.print}.to output.to_stdout
        # Primary keys should be populated from database record
        expect(@change1.id).to eq(1)
        expect(@change2.id).to eq(2)
      end
    end
  end
end