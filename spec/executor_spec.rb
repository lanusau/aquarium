require 'helper'
require 'colored'

describe Aquarium::Executor do
  describe '#register_executor' do
    it 'registers class that can handle command' do
      class TestExecutor < Aquarium::Executor
          register_executor :test
      end      
      expect(Aquarium::Executor.registered_executors).to include TestExecutor
    end
  end
  describe '#executor_for' do
    context 'when registered command is passed' do
      it 'returns executor class that handles that command' do
        class TestExecutor < Aquarium::Executor
          register_executor :test
        end
        expect(Aquarium::Executor.executor_for(:test)).to eql TestExecutor
      end
    end
  end
  describe '#new' do
    it 'creates new instance of executor' do
      file = StringIO.new "--#change test:1 Test change number 1\ncreate table test1\n;"
      allow(File).to receive(:dirname) {''}
      allow(File).to receive(:open).and_yield(file)
      parser  = Aquarium::Parser.new('file')
      expect(Aquarium::Executor.new(nil, parser,[],{})).to be_instance_of Aquarium::Executor
    end
  end
  describe '#apply_change' do
    context 'when interactive is set in options' do
      options = {:interactive => true}
      context 'when no errors are raised during execution' do
        it 'executes SQLs for particular change' do
          parser  = Aquarium::Parser.new('file_name')
          change_collection = Aquarium::ChangeCollection.new('file_name')
          change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
          change_collection.add_change(Aquarium::Change.new('test:2','test_file.sql','description'))
          expect(parser).to receive(:parse) {change_collection}
          change = change_collection.find('test:1')
          database = nil
          parameters = nil
          executor = Aquarium::Executor.new(database,parser,parameters,options)
          expect(executor).to receive(:execute_collection).with(change.apply_sql_collection.to_a(database),0)
          expect {executor.apply_change(change)}.to output.to_stdout
        end
      end
      context 'when errors are raised during execution' do
        context 'when user requests retry' do
          it 'retries execution' do
            parser  = Aquarium::Parser.new('file_name')
            change_collection = Aquarium::ChangeCollection.new('file_name')
            change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
            change_collection.add_change(Aquarium::Change.new('test:2','test_file.sql','description'))
            expect(parser).to receive(:parse) {change_collection}
            change = change_collection.find('test:1')
            database = nil
            parameters = nil
            executor = Aquarium::Executor.new(database,parser,parameters,options)
            expect(executor).to receive(:execute_collection).
              with(change.apply_sql_collection.to_a(database),0) {raise Aquarium::ExecutionException.new('sql',1), 'error'}
            expect(executor).to receive(:execute_collection).with(change.apply_sql_collection.to_a(database),1)
            expect(executor).to receive(:get_response) {'R'}
            silence_stream(STDOUT) do
              expect {executor.apply_change(change)}.not_to raise_error
            end
          end
        end
        context 'when user requests to skip' do
          it 'skips to next SQL' do
            parser  = Aquarium::Parser.new('file_name')
            change_collection = Aquarium::ChangeCollection.new('file_name')
            change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
            change_collection.add_change(Aquarium::Change.new('test:2','test_file.sql','description'))
            expect(parser).to receive(:parse) {change_collection}
            change = change_collection.find('test:1')
            database = nil
            parameters = nil
            executor = Aquarium::Executor.new(database,parser,parameters,options)
            expect(executor).to receive(:execute_collection).
              with(change.apply_sql_collection.to_a(database),0) {raise Aquarium::ExecutionException.new('sql',1), 'error'}
            expect(executor).to receive(:execute_collection).with(change.apply_sql_collection.to_a(database),2)
            expect(executor).to receive(:get_response) {'S'}
            silence_stream(STDOUT) do
              expect {executor.apply_change(change)}.not_to raise_error
            end
          end
        end
        context "when user requests aborting execution" do
          it 'raises error' do
            parser  = Aquarium::Parser.new('file_name')
            change_collection = Aquarium::ChangeCollection.new('file_name')
            change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
            change_collection.add_change(Aquarium::Change.new('test:2','test_file.sql','description'))
            expect(parser).to receive(:parse) {change_collection}
            change = change_collection.find('test:1')
            database = nil
            parameters = nil
            executor = Aquarium::Executor.new(database,parser,parameters,options)
            expect(executor).to receive(:execute_collection).
              with(change.apply_sql_collection.to_a(database),0) {raise Aquarium::ExecutionException.new('sql',0), 'error'}
            expect(executor).to receive(:get_response) {'A'}
            silence_stream(STDOUT) do
              expect {executor.apply_change(change)}.to raise_error
            end
          end
        end
        context 'when user request reparsing' do
          it 'reparses the file and executes again' do
            parser  = Aquarium::Parser.new('file_name')
            change_collection = Aquarium::ChangeCollection.new('file_name')
            change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
            change_collection.add_change(Aquarium::Change.new('test:2','test_file.sql','description'))
            expect(parser).to receive(:parse).twice {change_collection}
            change = change_collection.find('test:1')
            database = nil
            parameters = nil
            executor = Aquarium::Executor.new(database,parser,parameters,options)
            expect(executor).to receive(:execute_collection).
              with(change.apply_sql_collection.to_a(database),0) {raise Aquarium::ExecutionException.new('sql',1), 'error'}
            expect(executor).to receive(:execute_collection).with(change.apply_sql_collection.to_a(database),1)
            expect(executor).to receive(:get_response) {'P'}
            silence_stream(STDOUT) do
              expect {executor.apply_change(change)}.not_to raise_error
            end
          end
        end
      end
    end
    context 'when interactive is not set in options' do
      options = {:interactive => false}
      context 'when no errors are raised during execution' do
        it 'executes SQLs for particular change' do
          parser  = Aquarium::Parser.new('file_name')
          change_collection = Aquarium::ChangeCollection.new('file_name')
          change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
          change_collection.add_change(Aquarium::Change.new('test:2','test_file.sql','description'))
          expect(parser).to receive(:parse) {change_collection}
          change = change_collection.find('test:1')
          database = nil
          parameters = nil
          executor = Aquarium::Executor.new(database,parser,parameters,options)
          expect(executor).to receive(:execute_collection).with(change.apply_sql_collection.to_a(database),0)
          expect {executor.apply_change(change)}.not_to output.to_stdout
        end
      end
      context 'when there are errors raised during execution' do
        it 'raises error' do
          parser  = Aquarium::Parser.new('file_name')
          change_collection = Aquarium::ChangeCollection.new('file_name')
          change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
          change_collection.add_change(Aquarium::Change.new('test:2','test_file.sql','description'))
          expect(parser).to receive(:parse) {change_collection}
          change = change_collection.find('test:1')
          database = nil
          parameters = nil
          executor = Aquarium::Executor.new(database,parser,parameters,options)
          expect(executor).to receive(:execute_collection).
            with(change.apply_sql_collection.to_a(database),0) {raise Aquarium::ExecutionException.new('sql',1), 'error'}
          expect {executor.apply_change(change)}.to raise_error
        end
      end
    end
  end
  describe '#rollback_change' do
    context 'when change has rollback tag marged as impossible to rollback' do
      it 'raises error' do
        parser  = Aquarium::Parser.new('file_name')
        change_collection = Aquarium::ChangeCollection.new('file_name')
        change = Aquarium::Change.new('test:1','test_file.sql','description')
        change.rollback_attribute = :impossible
        change_collection.add_change(change)
        expect(parser).to receive(:parse) {change_collection}
        database = nil
        parameters = nil
        executor = Aquarium::Executor.new(database,parser,parameters,{})
        expect {executor.rollback_change(change)}.to raise_error
      end
    end
    context 'when interactive is set in options' do
      options = {:interactive => true}
      context 'when no errors are raised during execution' do
        it 'executes SQLs for particular change' do
          parser  = Aquarium::Parser.new('file_name')
          change_collection = Aquarium::ChangeCollection.new('file_name')
          change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
          change_collection.add_change(Aquarium::Change.new('test:2','test_file.sql','description'))
          expect(parser).to receive(:parse) {change_collection}
          change = change_collection.find('test:1')
          database = nil
          parameters = nil
          executor = Aquarium::Executor.new(database,parser,parameters,options)
          expect(executor).to receive(:execute_collection).with(change.rollback_sql_collection.to_a(database),0)
          expect {executor.rollback_change(change)}.to output.to_stdout
        end
      end
      context 'when errors are raised during execution' do
        context 'when user requests retry' do
          it 'retries execution' do
            parser  = Aquarium::Parser.new('file_name')
            change_collection = Aquarium::ChangeCollection.new('file_name')
            change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
            change_collection.add_change(Aquarium::Change.new('test:2','test_file.sql','description'))
            expect(parser).to receive(:parse) {change_collection}
            change = change_collection.find('test:1')
            database = nil
            parameters = nil
            executor = Aquarium::Executor.new(database,parser,parameters,options)
            expect(executor).to receive(:execute_collection).
              with(change.rollback_sql_collection.to_a(database),0) {raise Aquarium::ExecutionException.new('sql',1), 'error'}
            expect(executor).to receive(:execute_collection).with(change.rollback_sql_collection.to_a(database),1)
            expect(executor).to receive(:get_response) {'R'}
            silence_stream(STDOUT) do
              expect {executor.rollback_change(change)}.not_to raise_error
            end
          end
        end
        context "when user requests aborting execution" do
          it 'raises error' do
            parser  = Aquarium::Parser.new('file_name')
            change_collection = Aquarium::ChangeCollection.new('file_name')
            change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
            change_collection.add_change(Aquarium::Change.new('test:2','test_file.sql','description'))
            expect(parser).to receive(:parse) {change_collection}
            change = change_collection.find('test:1')
            database = nil
            parameters = nil
            executor = Aquarium::Executor.new(database,parser,parameters,options)
            expect(executor).to receive(:execute_collection).
              with(change.rollback_sql_collection.to_a(database),0) {raise Aquarium::ExecutionException.new('sql',0), 'error'}
            expect(executor).to receive(:get_response) {'A'}
            silence_stream(STDOUT) do
              expect {executor.rollback_change(change)}.to raise_error
            end
          end
        end
        context 'when user request reparsing' do
          it 'reparses the file and executes again' do
            parser  = Aquarium::Parser.new('file_name')
            change_collection = Aquarium::ChangeCollection.new('file_name')
            change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
            change_collection.add_change(Aquarium::Change.new('test:2','test_file.sql','description'))
            expect(parser).to receive(:parse).twice {change_collection}
            change = change_collection.find('test:1')
            database = nil
            parameters = nil
            executor = Aquarium::Executor.new(database,parser,parameters,options)
            expect(executor).to receive(:execute_collection).
              with(change.rollback_sql_collection.to_a(database),0) {raise Aquarium::ExecutionException.new('sql',1), 'error'}
            expect(executor).to receive(:execute_collection).with(change.rollback_sql_collection.to_a(database),1)
            expect(executor).to receive(:get_response) {'P'}
            silence_stream(STDOUT) do
              expect {executor.rollback_change(change)}.not_to raise_error
            end
          end
        end
      end
    end
    context 'when interactive is not set in options' do
      options = {:interactive => false}
      context 'when no errors are raised during execution' do
        it 'executes SQLs for particular change' do
          parser  = Aquarium::Parser.new('file_name')
          change_collection = Aquarium::ChangeCollection.new('file_name')
          change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
          change_collection.add_change(Aquarium::Change.new('test:2','test_file.sql','description'))
          expect(parser).to receive(:parse) {change_collection}
          change = change_collection.find('test:1')
          database = nil
          parameters = nil
          executor = Aquarium::Executor.new(database,parser,parameters,options)
          expect(executor).to receive(:execute_collection).with(change.rollback_sql_collection.to_a(database),0)
          expect {executor.rollback_change(change)}.not_to output.to_stdout
        end
      end
      context 'when there are errors raised during execution' do
        it 'raises error' do
          parser  = Aquarium::Parser.new('file_name')
          change_collection = Aquarium::ChangeCollection.new('file_name')
          change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
          change_collection.add_change(Aquarium::Change.new('test:2','test_file.sql','description'))
          expect(parser).to receive(:parse) {change_collection}
          change = change_collection.find('test:1')
          database = nil
          parameters = nil
          executor = Aquarium::Executor.new(database,parser,parameters,options)
          expect(executor).to receive(:execute_collection).
            with(change.rollback_sql_collection.to_a(database),0) {raise Aquarium::ExecutionException.new('sql',1), 'error'}
          expect {executor.rollback_change(change)}.to raise_error
        end
      end
    end
  end
  describe '#execute_collection' do
    it 'executes collection of SQLs' do
      sqls = ["sql1","sql2","sql3"]
      parser  = Aquarium::Parser.new('file_name')
      change_collection = Aquarium::ChangeCollection.new('file_name')
      expect(parser).to receive(:parse) {change_collection}
      database = double()
      expect(database).to receive(:execute).twice
      executor = Aquarium::Executor.new(database,parser,[],{})
      executor.execute_collection(sqls,1)
    end
    it 'raises an error if databases raises error for any of the SQLs' do
      sqls = ["sql1","sql2","sql3"]
      parser  = Aquarium::Parser.new('file_name')
      change_collection = Aquarium::ChangeCollection.new('file_name')
      expect(parser).to receive(:parse) {change_collection}
      database = double()
      expect(database).to receive(:execute) {raise Exception.new 'error'}
      executor = Aquarium::Executor.new(database,parser,[],{})
      expect {executor.execute_collection(sqls,1)}.to raise_error
    end
    context 'when callback object is set in options' do
      it 'calls callback object during execution' do
        sqls = ["sql1","sql2"]
        parser  = Aquarium::Parser.new('file_name')
        change_collection = Aquarium::ChangeCollection.new('file_name')
        expect(parser).to receive(:parse) {change_collection}
        database = double()
        expect(database).to receive(:execute).twice
        callback = double()
        expect(callback).to receive(:start_sql).twice
        expect(callback).to receive(:end_sql).twice
        options = {:callback => callback}
        executor = Aquarium::Executor.new(database,parser,[],options)
        executor.execute_collection(sqls,0)
      end
    end
  end
  describe '#update_repository' do
    context 'when :register parameter is passed' do
      it 'registers change in repository' do
        client = double()
        options = Hash.new
        options[:update_repository] = true
        options[:client] = client
        options[:instance_id] = 1
        expect(client).to receive(:query).twice
        database = double()
        parser  = Aquarium::Parser.new('file_name')
        change_collection = Aquarium::ChangeCollection.new('file_name')
        expect(parser).to receive(:parse) {change_collection}
        executor = Aquarium::Executor.new(database,parser,[],options)
        change = Aquarium::Change.new('test:1','test_file.sql','description')
        executor.update_repository(:register,change)
      end
    end
    context 'when :unregister parameter is passed' do
      it 'unregisters change in repository' do
        client = double()
        options = Hash.new
        options[:update_repository] = true
        options[:client] = client
        options[:instance_id] = 1
        expect(client).to receive(:query).twice
        database = double()
        parser  = Aquarium::Parser.new('file_name')
        change_collection = Aquarium::ChangeCollection.new('file_name')
        expect(parser).to receive(:parse) {change_collection}
        executor = Aquarium::Executor.new(database,parser,[],options)
        change = Aquarium::Change.new('test:1','test_file.sql','description')
        executor.update_repository(:unregister,change)
      end
    end    
    context 'when client exception is raised' do
      it 'it re-raises exception' do
        client = double()
        options = Hash.new
        options[:update_repository] = true
        options[:client] = client
        options[:instance_id] = 1
        expect(client).to receive(:query)  {raise "Client error"}
        database = double()
        parser  = Aquarium::Parser.new('file_name')
        change_collection = Aquarium::ChangeCollection.new('file_name')
        expect(parser).to receive(:parse) {change_collection}
        executor = Aquarium::Executor.new(database,parser,[],options)
        change = Aquarium::Change.new('test:1','test_file.sql','description')      
        expect {executor.update_repository(:register,change)}.to raise_error
      end
    end
  end
end