require 'dbi'
require 'aquarium/database'
require 'aquarium/change'

module Aquarium
  # Oracle database
  class OracleDatabase < Aquarium::Database    
    register_database

    def self.service(url) #:nodoc:
      url =~ /^dbi:OCI8/ ? true : false
    end

    # Create new object
    def initialize(options)
      @dbh = DBI.connect(options[:url], options[:username], options[:password])
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
  tag varchar2(100) null,
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
   create_sysdate,update_sysdate,user_update)
values
  (aqu_primary_key_s.nextval,
   '#{change.code}','#{change.file_name}','#{change.description}',
   sysdate, '#{change.cmr_number}',
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

  end
end