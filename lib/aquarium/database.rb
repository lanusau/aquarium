module Aquarium
  # Abstract database class, with subclasses Oracle or Mysql implementing
  # actual specifics of accessing database
  class Database

    @@registered_databases= []

    # Return all registered databases
    def self.registered_databases
      @@registered_databases
    end

    # Find database that can handle particular URL
    def self.database_for(options)
      raise "Null adapter passed" if options[:adapter].nil?
      adapter = options[:adapter]

      @@registered_databases.each do |database|
        return database.new(options) if database.service(adapter)
      end
      
      raise "Unknow database adapter: #{adapter}"
      
    end

    # Called by subclass to register itself
    def self.register_database
      @@registered_databases << self
    end

    # Register change
    def register_change(change)
      execute(register_change_sql(change))
      commit
    end

    # Unregister change (rollback)
    def unregister_change(change)
      return unless change_registered?(change)
      execute(unregister_change_sql(change))
      commit
      
    end

    # Return all changes in the database ordered by change_id
    def changes_in_database
      return [] if control_table_missing?
      
      # Cache all changes on first call
      @changes_in_database ||= get_changes_in_database

    end

    # Return whether particular change is registered in this database
    def change_registered?(change)               
      database_change = changes_in_database.detect{|c| c.code == change.code && c.file_name == change.file_name}
      return nil if database_change.nil?

      # Also fill in ID attribute which is in database table only
      change.id = database_change.id
      return database_change
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