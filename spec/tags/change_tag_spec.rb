require 'helper'
require 'stringio'

describe Aquarium::Tags::Change do
  before do    
    @change_collection = Aquarium::ChangeCollection.new('test_file.sql')    
  end
  describe '#new' do
    context 'when parameters are missing change code' do
      it 'raises an exception' do
        expect {Aquarium::Tags::Change.new('','file_name',@change_collection)}.to raise_error
      end
    end
    context 'when parameters are missing description' do
      it 'creates change object with empty description' do        
        Aquarium::Tags::Change.new('lanusau:1','file_name',@change_collection)
        expect(@change_collection.current_change.code).to eql('lanusau:1')
        expect(@change_collection.current_change.description).to eql('')
      end
    end
    context 'with full parameters' do
      it 'creates change object' do
        Aquarium::Tags::Change.new('lanusau:1 testing123','file_name',@change_collection)
        expect(@change_collection.current_change.code).to eql('lanusau:1')
        expect(@change_collection.current_change.description).to eql('testing123')
      end
    end
  end
  describe '#parse' do
    it 'extracts SQLs for a change from a file' do
      file = StringIO.new("select * from table1\n;\nselect * from table2\n;\n--#change blah:1")
      Aquarium::Tags::Change.new('lanusau:1 testing123','file_name',@change_collection).parse(file)
      expect(@change_collection.current_change.apply_sql_collection.sql_collection.size).to eql(2)
    end
  end
end