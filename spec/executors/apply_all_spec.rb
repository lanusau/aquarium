require 'helper'
require 'dbi'

describe Aquarium::Executors::ApplyAll do
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
      expect(Aquarium::Executors::ApplyAll.help).to be_instance_of String
    end
  end
  describe '#execute' do
    context 'when there is no control table in the database' do
      it 'creates control table and executes all changes' do
        options = {:interactive => false}
        parameters = nil
        database = instance_double('Aquarium::Database')
        expect(database).to receive(:control_table_missing?).twice {true}
        expect(database).to receive(:create_control_table).with(options)
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::ApplyAll.new(database, @parser,parameters,options)
        expect(executor).to receive(:apply_change).with(@change1)
        expect(database).to receive(:register_change).with(@change1)
        expect(executor).to receive(:apply_change).with(@change2)
        expect(database).to receive(:register_change).with(@change2)
        executor.execute
      end
    end
    context 'when there is control table in the database' do
      it 'executes only missing changes' do
        options = {:interactive => false}
        parameters = nil
        database = instance_double('Aquarium::Database')
        expect(database).to receive(:control_table_missing?).twice {false}     
        expect(database).to receive(:change_registered?).with(@change1) {true}
        expect(database).to receive(:change_registered?).with(@change2) {false}
        expect(@parser).to receive(:parse) {@change_collection}
        executor = Aquarium::Executors::ApplyAll.new(database, @parser,parameters,options)
        expect(executor).not_to receive(:apply_change).with(@change1)
        expect(database).not_to receive(:register_change).with(@change1)
        expect(executor).to receive(:apply_change).with(@change2)
        expect(database).to receive(:register_change).with(@change2)
        executor.execute
      end
    end
  end
  describe '#print' do
    it 'prints DDL that would be executed' do
      options = {:interactive => true}
      parameters = nil
      expect(DBI).to receive(:connect)
      database = Aquarium::OracleDatabase.new(options)
      expect(database).to receive(:control_table_missing?).twice {true}
      expect(@parser).to receive(:parse) {@change_collection}
      executor = Aquarium::Executors::ApplyAll.new(database, @parser,parameters,options)
      expect {executor.print}.to output.to_stdout
    end
  end
end