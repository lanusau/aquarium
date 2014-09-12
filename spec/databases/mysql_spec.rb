require 'helper'
require 'dbi'

describe Aquarium::MySQLDatabase do
  before do
    @options = {:url => 'dbi:Mysql',:username => 'username',:password => '***'}
  end
  describe '#service' do
    it 'registers that it can handle url starting with dbi:Mysql' do      
      expect(DBI).to receive(:connect).with(@options[:url], @options[:username], @options[:password])
      expect(Aquarium::Database.database_for(@options)).to be_instance_of(Aquarium::MySQLDatabase)
    end
  end
  describe '#new' do
    it 'creates new instance of MySQLDatabase' do      
      expect(DBI).to receive(:connect).with(@options[:url], @options[:username], @options[:password])
      expect(Aquarium::MySQLDatabase.new(@options)).to be_instance_of(Aquarium::MySQLDatabase)
    end
  end
  describe '#control_table_sqls' do
    it 'returns list of SQL needed to create control table' do
      allow(DBI).to receive(:connect).with(@options[:url], @options[:username], @options[:password])
      expect(Aquarium::MySQLDatabase.new(@options).control_table_sqls.size).to be > 0
    end
  end
  describe '#register_change_sql' do
    it 'returns SQL needed to register change' do
      allow(DBI).to receive(:connect).with(@options[:url], @options[:username], @options[:password])
      change = Aquarium::Change.new('test:1','test_file.sql','description')
      expect(Aquarium::MySQLDatabase.new(@options).register_change_sql(change)).to be_instance_of(String)
    end
  end
  describe '#unregister_change_sql' do
    it 'returns SQL needed to unregister change' do
      allow(DBI).to receive(:connect).with(@options[:url], @options[:username], @options[:password])
      change = Aquarium::Change.new('test:1','test_file.sql','description')
      expect(Aquarium::MySQLDatabase.new(@options).unregister_change_sql(change)).to be_instance_of(String)
    end
  end
  describe '#control_table_missing_sql' do
    it 'returns SQL needed to check if control table is missing' do
      allow(DBI).to receive(:connect).with(@options[:url], @options[:username], @options[:password])
      expect(Aquarium::MySQLDatabase.new(@options).control_table_missing_sql).to be_instance_of(String)
    end
  end
end