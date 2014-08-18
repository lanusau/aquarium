require 'aquarium/executor'

module Aquarium
  module Executors
    # Rollback specified number of changes
    class RollbackCount < Executor

      register_executor :rollback_count

      def self.help #:nodoc:
        '   rollback_count - rollback N number of changes in the reverse order that they were applied. N should be specified as a parameter'
      end

      # Create new executor
      def initialize(database, parser,parameters,logger=STDOUT)
        super
        raise "Rollback requires parameter - number of changes to rollback" if parameters.nil?
        @count = parameters.shift.to_i
        raise "Invalid number of changes to rollback" if @count == 0        
      end

      # Actually execute SQLs
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
          rollback_change(change)
          @database.unregister_change(change)
        end
      end

      # Only print SQLs
      def print
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
          change.print_banner('ROLLBACK',STDOUT)

          change.rollback_sql_collection.to_a(@database).each do |sql|
            puts sql
            puts ';'
          end
          puts @database.unregister_change_sql(change)
          puts ";"
        end
      end
    end
  end
end
