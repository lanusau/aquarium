require 'helper'
require 'mysql2'

describe Aquarium::MySQLDatabase do
  before do
    @options = {
      :adapter => 'mysql',
      :host => 'some.host',
      :port => 3306,
      :database => 'test',
      :username => 'username',
      :password => '***'}
  end
  describe '#service' do
    it 'registers that it can handle mysql adapter' do
      expect(Mysql2::Client).to receive(:new)
      expect(Aquarium::Database.database_for(@options)).to be_instance_of(Aquarium::MySQLDatabase)
    end
  end
  describe '#new' do
    it 'creates new instance of MySQLDatabase' do
      expect(Mysql2::Client).to receive(:new)
      expect(Aquarium::MySQLDatabase.new(@options)).to be_instance_of(Aquarium::MySQLDatabase)
    end
  end
  describe '#control_table_sqls' do
    it 'returns list of SQL needed to create control table' do
      expect(Mysql2::Client).to receive(:new)
      expect(Aquarium::MySQLDatabase.new(@options).control_table_sqls.size).to be > 0
    end
  end
  describe '#register_change_sql' do
    it 'returns SQL needed to register change' do
      expect(Mysql2::Client).to receive(:new)
      change = Aquarium::Change.new('test:1','test_file.sql','description')
      expect(Aquarium::MySQLDatabase.new(@options).register_change_sql(change)).to be_instance_of(String)
    end
  end
  describe '#unregister_change_sql' do
    it 'returns SQL needed to unregister change' do
      expect(Mysql2::Client).to receive(:new)
      change = Aquarium::Change.new('test:1','test_file.sql','description')
      expect(Aquarium::MySQLDatabase.new(@options).unregister_change_sql(change)).to be_instance_of(String)
    end
  end
  describe '#control_table_missing_sql' do
    it 'returns SQL needed to check if control table is missing' do
      expect(Mysql2::Client).to receive(:new)
      expect(Aquarium::MySQLDatabase.new(@options).control_table_missing_sql).to be_instance_of(String)
    end
  end
  describe '#disconnect' do
    it 'disconnects database handle' do
      client = double()
      expect(client).to receive(:close)
      expect(Mysql2::Client).to receive(:new) {client}
      options = {:adapter => 'mysql'}
      database = Aquarium::Database.database_for(options)
      database.disconnect
    end
  end
  describe '#execute' do
    it 'executes specified SQL' do
      sql = "select * from table"
      client = double()
      expect(client).to receive(:query).with(sql)
      expect(Mysql2::Client).to receive(:new) {client}
      options = {:adapter => 'mysql'}
      database = Aquarium::Database.database_for(options)
      database.execute(sql)
    end
  end
  describe '#control_table_missing?' do
    it 'returns whether control table is missing in the database' do
      client = double()
      expect(Mysql2::Client).to receive(:new) {client}
      options = {:adapter => 'mysql'}
      database = Aquarium::Database.database_for(options)
      expect(client).to receive(:query).with(database.control_table_missing_sql,:symbolize_keys => true) { [{:cnt => 0}]}
      expect(database.control_table_missing?).to eql(true)
    end
  end
  describe '#condition_met?' do
    context 'when valid SQL is passed' do
      it 'returns whether SQL condition is met' do
        client = double()
        expect(Mysql2::Client).to receive(:new) {client}
        options = {:adapter => 'mysql'}
        database = Aquarium::Database.database_for(options)
        expect(client).to receive(:query) {[1]}
        expect(database.condition_met?("condition", true)).to eq(true)
      end
    end
    context 'when invalid SQL is passed' do
      it 'raises error' do
        client = double()
        expect(Mysql2::Client).to receive(:new) {client}
        options = {:adapter => 'mysql'}
        database = Aquarium::Database.database_for(options)
        expect(client).to receive(:query) {raise "Database Error"}
        expect { database.condition_met?("condition", true) }.to raise_error
      end
    end
  end
  describe '#get_changes_in_database' do
    it 'gets changes in the database' do
      client = double()
      expect(Mysql2::Client).to receive(:new) {client}
      options = {:adapter => 'mysql'}
      database = Aquarium::Database.database_for(options)
      row = {
          :code=>'test:1',:file_name=>'test_file.sql',
          :description=>'description',:change_id=>1,:cmr_number=>'123',
          :user_update=>'user_update'}
      allow(client).to receive(:query).and_yield(row)
      changes = database.get_changes_in_database
      expect(changes.size).to eql(1)
      expect(changes[0]).to be_instance_of(Aquarium::Change)
      expect(changes[0].code).to eql('test:1')
    end   
  end
end