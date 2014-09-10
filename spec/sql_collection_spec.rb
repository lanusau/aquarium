require 'helper'

describe Aquarium::SqlCollection do
  describe '#new' do
    it 'creates new sql collection' do
      sql_collection = Aquarium::SqlCollection.new
      expect(sql_collection).to be_an_instance_of(Aquarium::SqlCollection)
    end
  end
  describe '#parse' do
    it 'extracts SQL list out of file' do
      file = instance_double('File')
      lines = ["select * from table1\n",";\n","select * from table2\n",";\n","--#change blah:1"]
      call_count = -1
      allow(file).to receive(:gets) do
        call_count += 1
        call_count >= lines.size ? nil : lines[call_count]
      end
      allow(file).to receive(:seek)
      sc = Aquarium::SqlCollection.new
      sc.parse(file)
      expect(sc.sql_collection.size).to eql(2)
    end
  end
  describe '#to_a' do
    it 'returns array of SQLs' do
      sc = Aquarium::SqlCollection.new
      csc = Aquarium::ConditionalSqlCollection.new('condition',true)
      sc << 'SQL1'
      sc << 'SQL2'
      csc << "SQL3"
      sc << csc

      # Fake database call to execute condition SQL
      database = instance_double('Aquarium::Database')
      dbh = instance_double('DBI::DatabaseHandle')
      allow(dbh).to receive(:select_one) {[1]}
      allow(database).to receive(:dbh) {dbh}
      expect(sc.to_a(database).size).to eql(3)
    end
  end
  describe '#to_string' do
    it 'returns list of SQLs as one string' do
      sc = Aquarium::SqlCollection.new
      sc << 'SQL1'
      sc << 'SQL2'
      expect(sc.to_string(nil)).to eql("SQL1;\nSQL2;")
    end
  end
end