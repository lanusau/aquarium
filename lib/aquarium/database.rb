require 'dbi'


module Aquarium
  class Database
    attr :dbh

    @@registered_databases= []

    def self.database_for(options)
      url = options[:url]      

      @@registered_databases.each do |database|
        return database.new(options) if database.service(url)
      end
      
      raise "Unknow database driver for URl #{url}"
      
    end

    def self.register_database
      @@registered_databases << self
    end

    def execute(sql)
      @dbh.do(sql)
    rescue DBI::DatabaseError => e
      raise "Got: #{e.message}\nWhen executing:\n#{sql}"
    end

    def register_change(change)
      @dbh.do(register_change_sql(change))
      @dbh.commit
    end

    def unregister_change(change)
      @dbh.do(unregister_change_sql(change))
      @dbh.commit
    end

    def changes_in_database
      # Cache all changes on first call
      if @changes_in_database.nil?
        @changes_in_database = []
        @dbh.select_all('select code,file_name,description,change_id from aqu_change order by change_id asc') do | row |
            @changes_in_database << Aquarium::Change.new(row[0],row[1],row[2],row[3])
        end
      end
      @changes_in_database
    end

    def change_registered?(change)               
      changes_in_database.detect{|c| c.code == change.code && c.file_name == change.file_name}
    end

    def control_table_missing?
      return @control_table_missing unless @control_table_missing.nil?
      row = @dbh.select_one(control_table_missing_sql)
      @control_table_missing = (row[0].to_i == 0)
      return @control_table_missing
    end

  end
end

# Load all files in tags directory
Dir[File.dirname(__FILE__) + '/databases/*.rb'].each {|file| require file }