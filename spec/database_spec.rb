require 'helper'
require 'dbi'

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
    context 'when valid URL is passed' do
      it 'returns class that handles database specified by the URL' do
        class TestDatabase < Aquarium::Database
          register_database
          def self.service(url)
            url =~ /^test:/ ? true : false
          end
          def initialize(options)
          end
        end
        options = {:url => 'test:something'}
        expect(Aquarium::Database.database_for(options)).to be_instance_of(TestDatabase)
      end
    end
    context 'when invalid URL is passed' do
      it 'raises an error' do
        options = {:url => 'not:existing'}
        expect {Aquarium::Database.database_for(options) }.to raise_error
      end
    end
  end
  describe '#disconnect' do
    it 'disconnects database handle' do
      dbh = double()
      expect(dbh).to receive(:disconnect)
      allow(DBI).to receive(:connect) {dbh}
      options = {:url => 'dbi:Mysql:blah'}
      database = Aquarium::Database.database_for(options)
      database.disconnect
    end
  end
  describe '#execute' do
    it 'executes specified SQL' do
      sql = "select * from table"
      dbh = double()
      expect(dbh).to receive(:do).with(sql)
      allow(DBI).to receive(:connect) {dbh}
      options = {:url => 'dbi:Mysql:blah'}
      database = Aquarium::Database.database_for(options)
      database.execute(sql)
    end
  end
  describe '#register_change' do
    it 'registers change into the database' do
      dbh = double()
      allow(DBI).to receive(:connect) {dbh}
      options = {:url => 'dbi:Mysql:blah'}
      database = Aquarium::Database.database_for(options)
      change = Aquarium::Change.new('test:1','test_file.sql','description')
      expect(dbh).to receive(:do).with(database.register_change_sql(change))
      expect(dbh).to receive(:commit)
      database.register_change(change)
    end
  end
  describe '#unregister_change' do
    context 'when change is registered in database' do
      it 'executes SQL to delete registrations from the database' do
        dbh = double()
        allow(DBI).to receive(:connect) {dbh}
        options = {:url => 'dbi:Mysql:blah'}
        database = Aquarium::Database.database_for(options)
        change = Aquarium::Change.new('test:1','test_file.sql','description')
        expect(dbh).to receive(:do).with(database.unregister_change_sql(change))
        expect(dbh).to receive(:commit)
        allow(database).to receive(:change_registered?).with(change) {true}
        database.unregister_change(change)
      end
    end
    context 'when change is not registered in database' do
      it 'does nothing' do
        dbh = double()
        allow(DBI).to receive(:connect) {dbh}
        options = {:url => 'dbi:Mysql:blah'}
        database = Aquarium::Database.database_for(options)
        change = Aquarium::Change.new('test:1','test_file.sql','description')
        allow(database).to receive(:change_registered?).with(change) {false}
        expect(dbh).not_to receive(:do)
        expect(dbh).not_to receive(:commit)
        database.unregister_change(change)
      end
    end
  end
  describe '#changes_in_database' do
    context 'when control table is present' do
      it 'returns list of changes in the dabatase' do
        dbh = double()
        allow(DBI).to receive(:connect) {dbh}
        options = {:url => 'dbi:Mysql:blah'}
        database = Aquarium::Database.database_for(options)
        allow(database).to receive(:control_table_missing?) {false}
        row = ['test:1','test_file.sql','description',1,'123','user_update']
        allow(dbh).to receive(:select_all).and_yield(row)
        @changes = database.changes_in_database
        expect(@changes.size).to eql(1)
        expect(@changes[0]).to be_instance_of(Aquarium::Change)
        expect(@changes[0].code).to eql('test:1')
      end
    end
    context 'when control table is not present' do
      it 'returns empty list' do
        dbh = double()
        allow(DBI).to receive(:connect) {dbh}
        options = {:url => 'dbi:Mysql:blah'}
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
        dbh = double()
        allow(DBI).to receive(:connect) {dbh}
        options = {:url => 'dbi:Mysql:blah'}
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
        dbh = double()
        allow(DBI).to receive(:connect) {dbh}
        options = {:url => 'dbi:Mysql:blah'}
        database = Aquarium::Database.database_for(options)
        complete_change = Aquarium::Change.new('test:1','test_file.sql','description',1,'123','user_update')
        new_change = Aquarium::Change.new('test:2','test_file.sql','description')
        allow(database).to receive(:changes_in_database) {[complete_change]}
        expect(database.change_registered?(new_change)).to be_nil
      end
    end
  end
  describe '#control_table_missing?' do
    it 'returns whether control table is missing in the database' do
      dbh = double()
      allow(DBI).to receive(:connect) {dbh}
      options = {:url => 'dbi:Mysql:blah'}
      database = Aquarium::Database.database_for(options)
      expect(dbh).to receive(:select_one).with(database.control_table_missing_sql) {[0]}
      expect(database.control_table_missing?).to eql(true)
    end
  end
  describe '#create_control_table' do
    context 'when interactive option is not specified' do
      it 'creates control table in the database' do
        dbh = double()
        allow(DBI).to receive(:connect) {dbh}
        options = {:url => 'dbi:Mysql:blah'}
        database = Aquarium::Database.database_for(options)
        database.control_table_sqls.each do |sql|
          expect(dbh).to receive(:do).with(sql)
        end
        database.create_control_table({})
      end
    end
    context 'when interactive option is specified' do
      it 'creates control table and prints to the STDOUT' do
        dbh = double()
        allow(DBI).to receive(:connect) {dbh}
        options = {:url => 'dbi:Mysql:blah'}
        database = Aquarium::Database.database_for(options)
        database.control_table_sqls.each do |sql|
          expect(dbh).to receive(:do).with(sql)
        end        
        expect { database.create_control_table({:interactive => true}) }.to output.to_stdout
      end
    end
  end
end