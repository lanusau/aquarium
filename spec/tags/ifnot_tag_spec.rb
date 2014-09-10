require 'helper'
require 'stringio'

describe Aquarium::Tags::IfNot do
  before do    
    @change_collection = Aquarium::ChangeCollection.new('test_file.sql')
    @change = Aquarium::Change.new('test:1','test_file.sql','description')

  end
  describe '#new' do
      it 'creates tag object' do
        @change_collection.add_change(@change)
        expect(Aquarium::Tags::IfNot.new('select count(*) from dba_tablespaces','file_name',@change_collection)).to be_an_instance_of(Aquarium::Tags::IfNot)
        
      end
  end
  describe '#parse' do
    context 'when #if tag is terminated by #endif tag' do
      it 'extracts SQLs for conditional SQL collection' do
        file = StringIO.new("select * from table1\n;\nselect * from table2\n;\n--#endif")
        @change_collection.add_change(@change)
        Aquarium::Tags::IfNot.new('select count(*) from dba_tablespaces','file_name',@change_collection).parse(file)
        expect(@change_collection.current_change.apply_sql_collection.sql_collection[0]).to be_an_instance_of Aquarium::ConditionalSqlCollection
      end
    end
    context 'when #if tag is not terminated properly' do
      it 'raises an error' do
        file = StringIO.new("select * from table1\n;\nselect * from table2\n;\n--#blah")
        @change_collection.add_change(@change)
        expect {Aquarium::Tags::IfNot.new('select count(*) from dba_tablespaces','file_name',@change_collection).parse(file)}.to raise_error
      end
    end
  end
end