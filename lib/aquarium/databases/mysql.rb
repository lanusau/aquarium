require 'mysql2'
require 'aquarium/database'

module Aquarium
  # MySQL database
  class MySQLDatabase < Aquarium::Database

    attr :client
    
    register_database

    def self.service(adapter) #:nodoc:
      adapter.downcase == 'mysql'
    end

    # Create new object
    def initialize(options)
      @client = Mysql2::Client.new(
        :host => options[:host],
        :username => options[:username],
        :password => options[:password],
        :port => options[:port] || 3306,
        :database => options[:database])
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
       select count(*) cnt from information_schema.tables
       where table_schema = database()
       and table_name = 'aqu_change'
      END
      return sql
    end

    # Disconnect
    def disconnect
      @client.close
    end

    # Execute specified SQL
    def execute(sql)
      @client.query(sql)
    end

    # Commit
    def commit
      @client.query('commit')
    end

    # Return list of changes in database
    def get_changes_in_database
      @changes_in_database = []
      @client.query('select code,file_name,description,change_id,cmr_number,user_update from aqu_change order by change_id asc',
        :symbolize_keys => true).each do | row |
            @changes_in_database << Aquarium::Change.new(
              row[:code],row[:file_name],row[:description],row[:change_id],row[:cmr_number],row[:user_update])
      end
      @changes_in_database
    end

    # Return whether control table is missing in the database
    def control_table_missing?
      return @control_table_missing unless @control_table_missing.nil?
      row = @client.query(control_table_missing_sql,:symbolize_keys => true).first
      @control_table_missing = (row[:cnt] == 0)
      return @control_table_missing
    end

    # Check if particular SQL condition is met
    def condition_met?(condition, expected_result)
      begin
        row = @client.query(condition,:as => :array).first
      rescue Exception => e
        raise "Error executing conditional SQL -> #{condition}\n#{e.to_s}"
      end
      result = (!row[0].nil? && row[0] > 0)
      return result  == expected_result
    end

  end
end