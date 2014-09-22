require 'helper'
require 'digest'

describe Aquarium::Change do

  before do
    @change = Aquarium::Change.new('test:1','test_file.sql','description')
  end

  describe '#new' do
    context 'without an id' do
      it 'creates and instance of Change' do
        code = 'test:1'
        file_name = 'test_file.sql'
        description = 'test description'
        change = Aquarium::Change.new(code,file_name,description)
        expect(change.code).to eql(code)
        expect(change.file_name).to eql(file_name)
        expect(change.description).to eql(description)
        expect(change.id).to be_nil
      end
    end
    context 'with an id' do
      it 'creates and instance of Change' do
        code = 'test:1'
        file_name = 'test_file.sql'
        description = 'test description'
        id = 123
        change = Aquarium::Change.new(code,file_name,description,id)
        expect(change.code).to eql(code)
        expect(change.file_name).to eql(file_name)
        expect(change.description).to eql(description)
        expect(change.id).to eql(id)
      end
    end
    context 'with rollback_digest' do
      it 'creates and instance of Change with rollback digest set' do
        code = 'test:1'
        file_name = 'test_file.sql'
        description = 'test description'
        id = 123
        cmr_number = '123'
        user_update = 'lanusau'
        rollback_digest = '123ABCDEFG'
        change = Aquarium::Change.new(code,file_name,description,id,cmr_number, user_update,rollback_digest)
        expect(change.code).to eql(code)
        expect(change.file_name).to eql(file_name)
        expect(change.description).to eql(description)
        expect(change.id).to eql(id)
        expect(change.rollback_digest).to eql(rollback_digest)
      end
    end
  end

  describe '#rollback_digest' do
    it 'calculates MD5 digest based on strings in rollback SQL collection' do
      code = 'test:1'
      file_name = 'test_file.sql'
      description = 'test description'
      change = Aquarium::Change.new(code,file_name,description)
      change.rollback_sql_collection << 'SQL1'
      change.rollback_sql_collection << 'SQL2'
      expect(change.rollback_digest).to eq(Digest::MD5.hexdigest("SQL1;\nSQL2;"))
    end
  end
  
  describe '#current_sql_collection' do
    context 'when valid collection name is passed' do
      it 'sets current SQL collection to either :apply or :rollback' do
        @change.current_sql_collection = :apply
        expect(@change.current_sql_collection).to eq(@change.apply_sql_collection)
        @change.current_sql_collection = :rollback
        expect(@change.current_sql_collection).to eq(@change.rollback_sql_collection)
      end
    end
    context 'when invalid collection name is passed' do
      it 'raises an exception' do
        @change.current_sql_collection = :invalid
        expect {@change.current_sql_collection}.to raise_error
      end
    end
  end

  describe '#print_banner' do
    context 'when option :interactive is set' do
      it 'outputs to stdout' do
        expect { @change.print_banner('rollback',{:interactive => true}) }.to output.to_stdout
      end
    end
    context 'when option :interactive is not set' do
      it 'does not output to stdout' do
        expect { @change.print_banner('rollback',{}) }.to_not output.to_stdout
      end
    end
  end
end
