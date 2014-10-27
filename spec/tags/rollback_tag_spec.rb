require 'helper'
require 'stringio'

describe Aquarium::Tags::Rollback do
  before do    
    @change_collection = Aquarium::ChangeCollection.new('test_file.sql')
    @change = Aquarium::Change.new('test:1','test_file.sql','description')
    @change_collection.add_change(@change)
  end
  describe '#new' do
    context 'when no parameters are passed' do
      it 'creates new tag object, with rollback attribute set to :none' do
        expect(Aquarium::Tags::Rollback.new('','file_name',@change_collection)).to be_instance_of(Aquarium::Tags::Rollback)
        expect(@change.rollback_attribute).to eq(:none)
      end
    end
    context 'when parameter *long* is passed' do
      it 'creates new tag object, with rollback attribute set to :long' do
        expect(Aquarium::Tags::Rollback.new('long','file_name',@change_collection)).to be_instance_of(Aquarium::Tags::Rollback)
        expect(@change.rollback_attribute).to eq(:long)
      end
    end
    context 'when parameter *impossible* is passed' do
      it 'creates new tag object, with rollback attribute set to :impossible' do
        expect(Aquarium::Tags::Rollback.new('impossible','file_name',@change_collection)).to be_instance_of(Aquarium::Tags::Rollback)
        expect(@change.rollback_attribute).to eq(:impossible)
      end
    end
    context 'when unknown attribute is passed as a parameter' do
      it 'raises error' do
        expect {Aquarium::Tags::Rollback.new('unknown_attribute','file_name',@change_collection)}.to raise_error
      end
    end
    
  end
  describe '#parse' do
    it 'extracts rollback SQLs for a change from a file' do
      file = StringIO.new("drop table1\n;\ndrop table2\n;\n--#change blah:1")
      Aquarium::Tags::Rollback.new('','file_name',@change_collection).parse(file)
      expect(@change_collection.current_change.rollback_sql_collection.sql_collection.size).to eql(2)
    end
  end
end