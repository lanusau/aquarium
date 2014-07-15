require 'dbi'
require 'aquarium/database'

module Aquarium
  class MySQLDatabase < Aquarium::Database
    
    register_database

    def self.service(url)
      url =~ /^dbi:Mysql/ ? true : false
    end

    def initialize(options)     
      @dbh = DBI.connect(options[:url], options[:user], options[:password])
    end

    def control_table_sqls
      sql_list = []

      sql_list << <<-END
create table aqu_change (
  change_id int not null autoincrement,
  code varchar(100) not null,        
  file_name varchar(200) not null,
  description varchar(1000) ,
  execution_date datetime not null,
  tag varchar(100) null,
  PRIMARY KEY (change_id),
  UNIQUE_KEY (code, file_name)
  ) engine=InnoDB;
END
      return sql_list
    end
    
    def register_change_sql(change)
      return <<-END
insert into aqu_change
  (code,file_name,description,execution_date)
values
('#{change.code}','#{change.file_name}','#{change.description}',now())
END
    end

    def unregister_change_sql(change)
      return <<-END
delete from aqu_change
where change_id = #{change.id}
END
    end

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