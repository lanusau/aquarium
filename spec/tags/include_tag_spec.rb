require 'helper'
require 'stringio'

describe Aquarium::Tags::Include do
  before do
    @change_collection = Aquarium::ChangeCollection.new('test_file.sql')
    @change_collection.add_change(Aquarium::Change.new('test:1','test_file.sql','description'))
  end
  describe '#new' do
    it 'creates new tag object' do      
      allow(File).to receive(:dirname) {''}
      expect(Aquarium::Tags::Include.new('include_file','original_file',@change_collection)).to be_instance_of(Aquarium::Tags::Include)
    end
  end
  describe '#parse' do
    it 'extracts chages from the included file' do
      file = StringIO.new("--#change test:2\ncreate table test2\n;\n--#rollback\ndrop table test2\n;")      
      allow(File).to receive(:dirname) {''}
      allow(File).to receive(:open).and_yield(file)
      Aquarium::Tags::Include.new('include_file','original_file',@change_collection).parse(nil)
      expect(@change_collection.find('test:2')).to be_instance_of(Aquarium::Change)
    end
  end
end