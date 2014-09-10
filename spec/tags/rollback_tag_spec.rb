require 'helper'
require 'stringio'

describe Aquarium::Tags::Rollback do
  before do    
    @change_collection = Aquarium::ChangeCollection.new('test_file.sql')
    @change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
  end
  describe '#new' do
    it 'creates new tag object' do
      expect(Aquarium::Tags::Rollback.new('parameters','file_name',@change_collection)).to be_instance_of(Aquarium::Tags::Rollback)
    end
  end
  describe '#parse' do
    it 'extracts rollback SQLs for a change from a file' do
      file = StringIO.new("drop table1\n;\ndrop table2\n;\n--#change blah:1")
      Aquarium::Tags::Rollback.new('lanusau:1 testing123','file_name',@change_collection).parse(file)
      expect(@change_collection.current_change.rollback_sql_collection.sql_collection.size).to eql(2)
    end
  end
end