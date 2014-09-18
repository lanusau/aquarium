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
        database = instance_double('Aquarium::MySQLDatabase')
        expect(database).to receive(:condition_met?) {true}

        expect(@conditional_sql_collection.to_a(database)).to include(@sql)
      end
    end
    context 'when condition is not met' do
      it 'returns empty list' do

        # Fake database call to execute condition SQL
        database = instance_double('Aquarium::MySQLDatabase')
        expect(database).to receive(:condition_met?) {false}

        expect(@conditional_sql_collection.to_a(database)).not_to include(@sql)
      end
    end
    context 'when invalid condition SQL is passed' do
      it 'raises error' do
        # Fake database call to execute condition SQL
        database = instance_double('Aquarium::MySQLDatabase')
        expect(database).to receive(:condition_met?) {raise "Database error"}
        expect {@conditional_sql_collection.to_a(database)}.to raise_error
      end
    end
  end
end
end