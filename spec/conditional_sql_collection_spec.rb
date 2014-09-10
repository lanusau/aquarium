require 'helper'

describe Aquarium::ConditionalSqlCollection do
  before do
    @conditional_sql_collection = Aquarium::ConditionalSqlCollection.new('condition',true)
    @sql = 'select 1 from 1'
    @conditional_sql_collection << @sql
  end

describe '#new' do
  it 'creates new conditional sql collection' do    
    expect(@conditional_sql_collection).to be_an_instance_of(Aquarium::ConditionalSqlCollection)
  end
end

describe '#to_a' do
  context 'when nil database object is passed' do
    it 'returns if/ifnot tag with list of SQLs' do
      expect(@conditional_sql_collection.to_a(nil)).to include("--#if condition\n")
      expect(@conditional_sql_collection.to_a(nil)).to include(@sql)
    end
  end
  context 'when not nil database object is passed' do
    context 'when condition is met' do
      it 'returns list of SQLs' do

        # Fake database call to execute condition SQL
        database = instance_double('Aquarium::Database')
        dbh = instance_double('DBI::DatabaseHandle')
        allow(dbh).to receive(:select_one) {[1]}
        allow(database).to receive(:dbh) {dbh}

        expect(@conditional_sql_collection.to_a(database)).to include(@sql)
      end
    end
    context 'when condition is not met' do
      it 'returns empty list' do

        # Fake database call to execute condition SQL
        database = instance_double('Aquarium::Database')
        dbh = instance_double('DBI::DatabaseHandle')
        allow(dbh).to receive(:select_one) {[0]}
        allow(database).to receive(:dbh) {dbh}

        expect(@conditional_sql_collection.to_a(database)).not_to include(@sql)
      end
    end
    context 'when invalid condition SQL is passed' do
      it 'raises error' do
        # Fake database call to execute condition SQL
        database = instance_double('Aquarium::Database')
        dbh = instance_double('DBI::DatabaseHandle')
        allow(dbh).to receive(:select_one) {raise "Database error"}
        allow(database).to receive(:dbh) {dbh}
        expect {@conditional_sql_collection.to_a(database)}.to raise_error
      end
    end
  end
end
end