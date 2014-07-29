require 'dbi'
require 'aquarium/database'

module Aquarium
  # MySQL database
  class MySQLDatabase < Aquarium::Database
    
    register_database

    def self.service(url) #:nodoc:
      url =~ /^dbi:Mysql/ ? true : false
    end

    # Create new object
    def initialize(options)     
      @dbh = DBI.connect(options[:url], options[:username], options[:password])
    end

    # Return SQL needed to create new control table
    def control_table_sqls
      sql_list = []

      sql_list << <<-END
create table aqu_change (
  change_id int not null auto_increment,
  code varchar(100) not null,        
  file_name varchar(200) not null,
  description varchar(1000) ,
  execution_date datetime not null,
  tag varchar(100) null,
  cmr_number varchar(10) null,
  create_sysdate datetime not null,
  update_sysdate datetime not null,
  user_update varchar(100) null,
  comments varchar(1000) null,
  PRIMARY KEY (change_id),
  UNIQUE KEY (code, file_name)
  ) engine=InnoDB;
END
      return sql_list
    end

    # Register change in the database
    def register_change_sql(change)
      return <<-END
insert into aqu_change
  (code,file_name,description,
   execution_date,cmr_number,
   create_sysdate,update_sysdate,user_update)
values
  ('#{change.code}','#{change.file_name}','#{change.description}',
   now(),'#{change.cmr_number}',
   now(),now(),'#{change.user_update}')
END
    end

    # Unregister change from the database
    def unregister_change_sql(change)
      return <<-END
delete from aqu_change
where change_id = #{change.id}
END
    end

    # Return whether control table is missing
    def control_table_missing_sql
      sql = <<-END
       select count(*) from information_schema.tables
       where table_schema = database()
       and table_name = 'aqu_change'
      END
      return sql
    end


  end
end