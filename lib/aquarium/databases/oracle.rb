require 'oci8'
require 'aquarium/database'
require 'aquarium/change'

module Aquarium
  # Oracle database
  class OracleDatabase < Aquarium::Database
    attr :client

    register_database

    def self.service(adapter) #:nodoc:
      adapter.downcase == 'oracle'
    end

    # Create new object
    def initialize(options)
      @client = OCI8.new(options[:username], options[:password], "//#{options[:host]}:#{options[:port]}/#{options[:database]}")
    end

    # SQL list to create control table
    def control_table_sqls
      sql_list = []

      sql_list << <<-END
create table aqu_change (
  change_id number(38) not null,
  code varchar2(100) not null,
  file_name varchar2(200) not null,
  description varchar2(1000) ,
  execution_date date not null,
  rollback_digest varchar2(100) null,
  cmr_number varchar2(10) null,
  create_sysdate date not null,
  update_sysdate date not null,
  user_update varchar2(100) null,
  comments varchar2(1000) null
  )
END
      sql_list << <<-END
create unique index aqu_change_u1 on aqu_change(change_id)
END
      sql_list << <<-END
create unique index aqu_change_u2 on aqu_change(code,file_name)
END
      sql_list << <<-END
create sequence aqu_primary_key_s
END
      return sql_list
    end

    # Register particular change in database
    def register_change_sql(change)
      return <<-END
insert into aqu_change
  (change_id,
   code,file_name,description,
   execution_date,cmr_number,
   rollback_digest,
   create_sysdate,update_sysdate,user_update)
values
  (aqu_primary_key_s.nextval,
   '#{change.code}','#{change.file_name}','#{change.description}',
   sysdate, '#{change.cmr_number}',
   '#{change.rollback_digest}',
   sysdate,sysdate,'#{change.user_update}')
END
    end

    # Unregister particular change from database
    def unregister_change_sql(change)
      return <<-END
delete from aqu_change
where change_id = #{change.id}
END
    end

    # Return whether control table is missing from the dataatabase
    def control_table_missing_sql
      sql = <<-END
       select count(*) from all_tables
       where owner = USER
       and table_name = 'AQU_CHANGE'
      END
      return sql
    end

    # Disconnect
    def disconnect
      @client.logoff
    end

    # Execute specified SQL
    def execute(sql)
      @client.exec(sql)
    end

    # Commit
    def commit
      @client.commit
    end

    # Return list of changes in database
    def get_changes_in_database
      @changes_in_database = []
      cursor = @client.exec('select code,file_name,description,change_id,cmr_number,user_update,rollback_digest
        from aqu_change order by change_id asc')
      while row = cursor.fetch_hash
        @changes_in_database << Aquarium::Change.new(
              row["CODE"],row["FILE_NAME"],row["DESCRIPTION"],row["CHANGE_ID"],
              row["CMR_NUMBER"],row["USER_UPDATE"],row["ROLLBACK_DIGEST"])
      end
      cursor.close
      @changes_in_database
    end

    # Return whether control table is missing in the database
    def control_table_missing?
      return @control_table_missing unless @control_table_missing.nil?
      cursor = @client.exec(control_table_missing_sql)
      row = cursor.fetch
      @control_table_missing = (row[0] == 0)
      cursor.close
      return @control_table_missing
    end

    # Check if particular SQL condition is met
    def condition_met?(condition, expected_result)
      begin
        row = @client.exec(condition)
      rescue Exception => e
        raise "Error executing conditional SQL -> #{condition}\n#{e.to_s}"
      end
      result = (!row[0].nil? && row[0] > 0)
      return result  == expected_result
    end

  end
end