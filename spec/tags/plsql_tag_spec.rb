require 'helper'
require 'stringio'

describe Aquarium::Tags::Plsql do
  before do
    @change_collection = Aquarium::ChangeCollection.new('test_file.sql')
    @change = Aquarium::Change.new('test:1','test_file.sql','description')

  end
  describe '#new' do
      it 'creates tag object' do
        @change_collection.add_change(@change)
        expect(Aquarium::Tags::Plsql.new('','file_name',@change_collection)).to be_an_instance_of(Aquarium::Tags::Plsql)

      end
  end
  describe '#parse' do
    context 'when #plsql tag is terminated by #endplsql tag' do
      it 'extracts SQL for PL/SQL as it is' do
        plsql_code = <<EOF
begin
 for rec in (select * from table) loop
  var = rec.something;
 end;
end
EOF
        file = StringIO.new("#{plsql_code}--#endplsql")
        @change_collection.add_change(@change)
        Aquarium::Tags::Plsql.new('','file_name',@change_collection).parse(file)
        expect(@change_collection.current_change.apply_sql_collection.sql_collection[0]).to eq(plsql_code)
      end
    end
    context 'when #plsql tag is not terminated properly' do
      it 'raises an error' do
        file = StringIO.new("some code\n--#blah")
        @change_collection.add_change(@change)
        expect {Aquarium::Tags::Plsql.new('','file_name',@change_collection).parse(file)}.to raise_error
      end
    end
  end
end