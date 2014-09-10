require 'helper'

describe Aquarium::Tag do
  describe '#register_tag' do
    it 'registers children class that handles some tag' do
      class TestTag < Aquarium::Tag
        register_tag :test
      end
      expect(Aquarium::Tag.registered_tags).to include(:test => TestTag)
      expect(TestTag.new.tag_type).to eql(:test)
    end
  end
  describe '#find_tag' do
    context 'when existing tag name is passed' do
      it 'returns instance of tag class' do
        class TestTag < Aquarium::Tag
          register_tag :test
          def initialize(parameters,file_name,change_collection)  
          end
        end
        expect(Aquarium::Tag.find_tag(:test, '', '', '')).to be_an_instance_of(TestTag)
      end
    end
    context 'when non existing tag name is passed' do
      it 'raises an error' do
        expect {Aquarium::Tag.find_tag(:non_existing, '', '', '')}.to raise_error
      end
    end
  end
  describe '#match' do
    context 'when line with tag syntax is passed' do
      it 'returns instance of tag class' do
        class TestTag < Aquarium::Tag
          register_tag :test
          def initialize(parameters,file_name,change_collection)
          end
        end
        expect(Aquarium::Tag.match('--#test something','','')).to be_an_instance_of(TestTag)
      end
    end
    context 'when line without tag syntax is passed' do
      it 'returns nil' do
        expect(Aquarium::Tag.match('something','','')).to be_nil
      end
    end
  end
end