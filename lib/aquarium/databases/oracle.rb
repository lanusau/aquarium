require 'dbi'
require 'aquarium/database'
require 'aquarium/change'

module Aquarium
  class OracleDatabase < Aquarium::Database    
    register_database

    def self.service(url)
      url =~ /^dbi:OCI8/ ? true : false
    end

    def initialize(options)
      @dbh = DBI.connect(options[:url], options[:user], options[:password])
    end

    def control_table_sqls
      sql_list = []

      sql_list << <<-END
create table aqu_change (
  change_id number(38) not null,
  code varchar2(100) not null,
  file_name varchar2(200) not null,
  description varchar2(1000) ,
  execution_date date not null,
  tag varchar2(100) null
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

    def register_change_sql(change)
      return <<-END
insert into aqu_change
  (change_id,code,file_name,description,execution_date)
values
(aqu_primary_key_s.nextval,'#{change.code}','#{change.file_name}','#{change.description}',sysdate)
END
    end

    def unregister_change_sql(change)
      return <<-END
delete from aqu_change
where change_id = #{change.id}
END
    end

    def control_table_missing?
      sql = <<-END
       select count(*) from all_tables
       where owner = USER
       and table_name = 'AQU_CHANGE'
      END
      row = @dbh.select_one(sql)
      return row[0].to_i == 0
    end

  end
end