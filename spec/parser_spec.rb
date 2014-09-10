require 'helper'
require 'stringio'

describe Aquarium::Parser do
  describe '#new' do
    it 'creates new parser object' do
      expect(Aquarium::Parser.new('file_name')).to be_instance_of(Aquarium::Parser)
    end
  end
  describe '#parse' do
    it 'extracts chages from change file' do
      file = StringIO.new <<EOF
-- Some empty text before first change
--#change test:1 Test change number 1
create table test1(
n1 int, c1 varchar(100))
;
--#rollback
drop table test1
;
--#change test:2 Test change number 2
--#ifnot select count(*) from dba_tablespaces where tablespace_name = 'TEST2'
create tablespace TEST2
;
--#endif
create table test2 (
n1 number, c1 varchar2(100))
tablespace TEST2
;
--#rollback
drop table test2
EOF
      allow(File).to receive(:dirname) {''}
      allow(File).to receive(:open).and_yield(file)
      @change_collection = Aquarium::Parser.new('file').parse
      expect(@change_collection.find('test:1')).to be_instance_of(Aquarium::Change)
      expect(@change_collection.find('test:2')).to be_instance_of(Aquarium::Change)
      @change = @change_collection.find('test:2')
      expect(@change.apply_sql_collection.sql_collection.size).to eql(2)
      expect(@change.apply_sql_collection.sql_collection[0]).to be_instance_of(Aquarium::ConditionalSqlCollection)
      expect(@change.apply_sql_collection.sql_collection[1]).to be_instance_of(String)
      expect(@change.rollback_sql_collection.sql_collection[0]).to be_instance_of(String)
    end
  end
end