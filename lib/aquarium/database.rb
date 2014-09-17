require 'dbi'


module Aquarium
  # Abstract database class, with subclasses Oracle or Mysql implementing
  # actual specifics of accessing database
  class Database
    attr :dbh

    @@registered_databases= []

    # Return all registered databases
    def self.registered_databases
      @@registered_databases
    end

    # Find database that can handle particular URL
    def self.database_for(options)
      url = options[:url]      

      @@registered_databases.each do |database|
        return database.new(options) if database.service(url)
      end
      
      raise "Unknow database driver for URl #{url}"
      
    end

    # Called by subclass to register itself
    def self.register_database
      @@registered_databases << self
    end

    # disconnect
    def disconnect
      @dbh.disconnect
    end

    # Execute specified SQL
    def execute(sql)      
        @dbh.do(sql)
    end

    # Register change
    def register_change(change)
      @dbh.do(register_change_sql(change))
      @dbh.commit
    end

    # Unregister change (rollback)
    def unregister_change(change)
      return unless change_registered?(change)
      @dbh.do(unregister_change_sql(change))
      @dbh.commit
      
    end

    # Return all changes in the database ordered by change_id
    def changes_in_database
      return [] if control_table_missing?
      
      # Cache all changes on first call
      if @changes_in_database.nil?
        @changes_in_database = []
        @dbh.select_all('select code,file_name,description,change_id,cmr_number,user_update from aqu_change order by change_id asc') do | row |
            @changes_in_database << Aquarium::Change.new(row[0],row[1],row[2],row[3],row[4],row[5])
        end
      end
      @changes_in_database
    end

    # Return whether particular change is registered in this database
    def change_registered?(change)               
      database_change = changes_in_database.detect{|c| c.code == change.code && c.file_name == change.file_name}
      return nil if database_change.nil?

      # Also fill in ID attribute which is in database table only
      change.id = database_change.id
      return database_change
    end

    # Return whether control table is missing in the database
    def control_table_missing?
      return @control_table_missing unless @control_table_missing.nil?
      row = @dbh.select_one(control_table_missing_sql)
      @control_table_missing = (row[0].to_i == 0)
      return @control_table_missing
    end

    # Create control table
    def create_control_table(options)
      puts "---- Creating control table" if options[:interactive]
      control_table_sqls.each do |sql|
        execute(sql)
      end
    end

  end
end

# Load all files in tags directory
Dir[File.dirname(__FILE__) + '/databases/*.rb'].each {|file| require file }