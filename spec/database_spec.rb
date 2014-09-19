require 'helper'
require 'mysql2'

describe Aquarium::Database do
  describe '#register_database' do
    it 'registers children class that handles some database' do
      class TestDatabase < Aquarium::Database
        register_database
      end
      expect(Aquarium::Database.registered_databases).to include(TestDatabase)
    end
  end
  describe '#database_for' do
    context 'when valid adapter is passed' do
      it 'returns class that handles database specified by the adapter' do
        class TestDatabase < Aquarium::Database
          register_database
          def self.service(adapter)
            adapter.downcase == 'test'
          end
          def initialize(options)
          end
        end
        options = {:adapter => 'test'}
        expect(Aquarium::Database.database_for(options)).to be_instance_of(TestDatabase)
      end
    end
    context 'when invalid adapter is passed' do
      it 'raises an error' do
        options = {:adapter => 'not_existing'}
        expect {Aquarium::Database.database_for(options) }.to raise_error
      end
    end
  end

  describe '#register_change' do
    it 'registers change into the database' do
      client = double()
      expect(Mysql2::Client).to receive(:new) {client}
      options = {:adapter => 'mysql'}
      database = Aquarium::Database.database_for(options)
      change = Aquarium::Change.new('test:1','test_file.sql','description')
      expect(client).to receive(:query).with(database.register_change_sql(change))
      expect(client).to receive(:query).with('commit')
      database.register_change(change)
    end
  end
  describe '#unregister_change' do
    context 'when change is registered in database' do
      it 'executes SQL to delete registrations from the database' do
        client = double()
        expect(Mysql2::Client).to receive(:new) {client}
        options = {:adapter => 'mysql'}
        database = Aquarium::Database.database_for(options)
        change = Aquarium::Change.new('test:1','test_file.sql','description')
        expect(client).to receive(:query).with(database.unregister_change_sql(change))
        expect(client).to receive(:query).with('commit')
        allow(database).to receive(:change_registered?).with(change) {true}
        database.unregister_change(change)
      end
    end
    context 'when change is not registered in database' do
      it 'does nothing' do
        client = double()
        expect(Mysql2::Client).to receive(:new) {client}
        options = {:adapter => 'mysql'}
        database = Aquarium::Database.database_for(options)
        change = Aquarium::Change.new('test:1','test_file.sql','description')
        allow(database).to receive(:change_registered?).with(change) {false}
        expect(client).not_to receive(:query)
        database.unregister_change(change)
      end
    end
  end
  describe '#changes_in_database' do
    context 'when control table is present' do
      it 'returns list of changes in the dabatase' do
        client = double()
        expect(Mysql2::Client).to receive(:new) {client}
        options = {:adapter => 'mysql'}
        database = Aquarium::Database.database_for(options)
        allow(database).to receive(:control_table_missing?) {false}
        row = {
          :code=>'test:1',:file_name=>'test_file.sql',
          :description=>'description',:change_id=>1,:cmr_number=>'123',
          :user_update=>'user_update'}
        result = double()      
        expect(client).to receive(:query) {result}
        expect(result).to receive(:each).and_yield(row)
        @changes = database.changes_in_database
        expect(@changes.size).to eql(1)
        expect(@changes[0]).to be_instance_of(Aquarium::Change)
        expect(@changes[0].code).to eql('test:1')
      end
    end
    context 'when control table is not present' do
      it 'returns empty list' do
        client = double()
        expect(Mysql2::Client).to receive(:new) {client}
        options = {:adapter => 'mysql'}
        database = Aquarium::Database.database_for(options)
        allow(database).to receive(:control_table_missing?) {true}
        @changes = database.changes_in_database
        expect(@changes.size).to eql(0)
      end
    end
  end
  describe '#change_registered?' do
    context 'when change is registered in database' do
      it 'returns full information for the change' do
        client = double()
        expect(Mysql2::Client).to receive(:new) {client}
        options = {:adapter => 'mysql'}
        database = Aquarium::Database.database_for(options)
        complete_change = Aquarium::Change.new('test:1','test_file.sql','description',1,'123','user_update')
        incomplete_change = Aquarium::Change.new('test:1','test_file.sql','description')
        allow(database).to receive(:changes_in_database) {[complete_change]}
        expect(database.change_registered?(incomplete_change)).to be_instance_of Aquarium::Change
        expect(database.change_registered?(incomplete_change).id).to eql(1)
        expect(database.change_registered?(incomplete_change).cmr_number).to eql('123')
        expect(database.change_registered?(incomplete_change).user_update).to eql('user_update')
      end
    end
    context 'when change is not registered in database' do
      it 'returns nil' do
        client = double()
        expect(Mysql2::Client).to receive(:new) {client}
        options = {:adapter => 'mysql'}
        database = Aquarium::Database.database_for(options)
        complete_change = Aquarium::Change.new('test:1','test_file.sql','description',1,'123','user_update')
        new_change = Aquarium::Change.new('test:2','test_file.sql','description')
        allow(database).to receive(:changes_in_database) {[complete_change]}
        expect(database.change_registered?(new_change)).to be_nil
      end
    end
  end

  describe '#create_control_table' do
    context 'when interactive option is not specified' do
      it 'creates control table in the database' do
        client = double()
        expect(Mysql2::Client).to receive(:new) {client}
        options = {:adapter => 'mysql'}
        database = Aquarium::Database.database_for(options)
        database.control_table_sqls.each do |sql|
          expect(database).to receive(:execute).with(sql)
        end
        database.create_control_table({})
      end
    end
    context 'when interactive option is specified' do
      it 'creates control table and prints to the STDOUT' do
        client = double()
        expect(Mysql2::Client).to receive(:new) {client}
        options = {:adapter => 'mysql',:interactive => true}
        database = Aquarium::Database.database_for(options)
        database.control_table_sqls.each do |sql|
          expect(database).to receive(:execute).with(sql)
        end        
        expect { database.create_control_table({:interactive => true}) }.to output.to_stdout
      end
    end
  end
end