require 'helper'
require 'oci8'

describe Aquarium::OracleDatabase do
  before do
    @options = {
      :adapter => 'oracle',
      :host => 'some.host',
      :port => 1521,
      :database => 'test',
      :username => 'username',
      :password => '***'}
  end
  describe '#service' do
    it 'registers that it can handle oracle adapter' do
      expect(OCI8).to receive(:new)
      expect(Aquarium::Database.database_for(@options)).to be_instance_of(Aquarium::OracleDatabase)
    end
  end
  describe '#new' do
    it 'creates new instance of OracleDatabase' do
      expect(OCI8).to receive(:new)
      expect(Aquarium::OracleDatabase.new(@options)).to be_instance_of(Aquarium::OracleDatabase)
    end
  end
  describe '#control_table_sqls' do
    it 'returns list of SQL needed to create control table' do
      expect(OCI8).to receive(:new)
      expect(Aquarium::OracleDatabase.new(@options).control_table_sqls.size).to be > 0
    end
  end
  describe '#register_change_sql' do
    it 'returns SQL needed to register change' do
      expect(OCI8).to receive(:new)
      change = Aquarium::Change.new('test:1','test_file.sql','description')
      expect(Aquarium::OracleDatabase.new(@options).register_change_sql(change)).to be_instance_of(String)
    end
  end
  describe '#unregister_change_sql' do
    it 'returns SQL needed to unregister change' do
      expect(OCI8).to receive(:new)
      change = Aquarium::Change.new('test:1','test_file.sql','description')
      expect(Aquarium::OracleDatabase.new(@options).unregister_change_sql(change)).to be_instance_of(String)
    end
  end
  describe '#control_table_missing_sql' do
    it 'returns SQL needed to check if control table is missing' do
      expect(OCI8).to receive(:new)
      expect(Aquarium::OracleDatabase.new(@options).control_table_missing_sql).to be_instance_of(String)
    end
  end
  describe '#disconnect' do
    it 'disconnects database handle' do
      client = double()
      expect(client).to receive(:logoff)
      expect(OCI8).to receive(:new) {client}
      options = {:adapter => 'oracle'}
      database = Aquarium::Database.database_for(options)
      database.disconnect
    end
  end
  describe '#execute' do
    it 'executes specified SQL' do
      sql = "select * from table"
      client = double()
      expect(client).to receive(:exec).with(sql)
      expect(OCI8).to receive(:new) {client}
      options = {:adapter => 'oracle'}
      database = Aquarium::Database.database_for(options)
      database.execute(sql)
    end
  end
  describe '#control_table_missing?' do
    it 'returns whether control table is missing in the database' do
      client = double()
      expect(OCI8).to receive(:new) {client}
      options = {:adapter => 'oracle'}
      database = Aquarium::Database.database_for(options)
      cursor = double()
      expect(client).to receive(:exec).with(database.control_table_missing_sql) { cursor }
      expect(cursor).to receive(:fetch) {[0]}
      expect(cursor).to receive(:close)
      expect(database.control_table_missing?).to eql(true)
    end
  end
  describe '#condition_met?' do
    context 'when valid SQL is passed' do
      it 'returns whether SQL condition is met' do
        client = double()
        expect(OCI8).to receive(:new) {client}
        options = {:adapter => 'oracle'}
        database = Aquarium::Database.database_for(options)
        expect(client).to receive(:exec) {[1]}
        expect(database.condition_met?("condition", true)).to eq(true)
      end
    end
    context 'when invalid SQL is passed' do
      it 'raises error' do
        client = double()
        expect(OCI8).to receive(:new) {client}
        options = {:adapter => 'oracle'}
        database = Aquarium::Database.database_for(options)
        expect(client).to receive(:exec) {raise "Database Error"}
        expect { database.condition_met?("condition", true) }.to raise_error
      end
    end
  end
  describe '#get_changes_in_database' do
    it 'gets changes in the database' do
      client = double()
      expect(OCI8).to receive(:new) {client}
      options = {:adapter => 'oracle'}
      database = Aquarium::Database.database_for(options)
      row = {
          "CODE"=>'test:1',"FILE_NAME"=>'test_file.sql',
          "DESCRIPTION"=>'description',"CHANGE_ID"=>1,"CMR_NUMBER"=>'123',
          "USER_UPDATE"=>'user_update',"ROLLBACK_DIGEST"=>'123ABCD'}
      cursor = double()
      expect(client).to receive(:exec) {cursor}
      expect(cursor).to receive(:fetch_hash) {row }
      expect(cursor).to receive(:fetch_hash) {nil}
      expect(cursor).to receive(:close)
      changes = database.get_changes_in_database
      expect(changes.size).to eql(1)
      expect(changes[0]).to be_instance_of(Aquarium::Change)
      expect(changes[0].code).to eql('test:1')
      expect(changes[0].rollback_digest).to eql('123ABCD')
    end
  end
  describe '#commit' do
    it "commits database transaction" do
      client = double()
      expect(OCI8).to receive(:new) {client}
      expect(client).to receive(:commit)
      options = {:adapter => 'oracle'}
      database = Aquarium::Database.database_for(options)
      database.commit
    end
  end
end