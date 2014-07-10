module Aquarium
  module Executors
    class Rollback

      def initialize(database, change_collection,parameters)
        @database = database
        @change_collection = change_collection
        raise "Rollback requires parameter - number of changes to rollback" if parameters.nil?
        @count = parameters.shift.to_i
        raise "Invalid number of changes to rollback" if @count == 0
      end

      def execute
        # Nothing to do if control table is missing
        return if @database.control_table_missing?

        changes_to_rollback = []
        index = 1
        @database.changes_in_database.reverse.each do | database_change |
          if file_change = @change_collection.exists(database_change)
            # Database change will have primary key
            file_change.id = database_change.id
            changes_to_rollback << file_change
          else
            raise "Change #{database_change.code} exists in control table, but not in file"
          end
          index += 1
          break if index > @count
        end

        changes_to_rollback.each do |change|
          puts "---------------------------------------------"
          puts "-- Rollback change #{change.code}"          
          puts "---------------------------------------------"

          change.rollback_sql_collection.to_a(@database).each do |sql|
            @database.execute(sql)
          end
          @database.unregister_change(change)
        end
      end
    end
  end
end
