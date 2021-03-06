require 'aquarium/executor'

module Aquarium
  module Executors
    # Rollback particular change
    class RollbackChange < Executor

      register_executor :rollback_change

      def self.help #:nodoc:
        '   rollback_change - apply single change with code that is passed as a parameter'
      end

      # Create new executor
      def initialize(database, parser,parameters,options)
        super

        raise 'Please specify change code to rollback' if parameters.nil?
        @change_code_to_rollback = parameters.shift
        @change = @change_collection.find(@change_code_to_rollback)
        raise "Change #{@change_code_to_rollback} not found" if @change.nil?

        @database_change = @database.change_registered?(@change)
        raise "Change #{@change.code} is not registered in the database" unless @database_change
        
        if options[:use_saved_rollback]
          @change.rollback_sql_collection = @database_change.saved_rollback_sql_collection
        end
      end

      # Print warning
      # :nocov:
      def warning(message)
        puts ("** #{message}") if @options[:interactive]
      end
      # :nocov:

      # Actually execute SQLs
      def execute        
        if @database_change.rollback_digest != @change.rollback_digest
          warning "Warning ! Rollback SQLs in the file changed since the change was applied to the database"
          warning "This may cause rollback to fail"
          warning "You can use -s option to use rollback SQLs that were stored in database when change was applied"
        end
        rollback_change(@change)
        @database.unregister_change(@change)
        update_repository(:unregister,@change)
      end

      # Only print SQLs
      def print
        if @database_change.rollback_digest != @change.rollback_digest
          warning "Warning ! Rollback SQLs in the file changed since the change was applied to the database"
          warning "This may cause rollback to fail"
          warning "You can use -s option to use rollback SQLs that were stored in database when change was applied"
        end
        
        @change.print_banner('ROLLBACK',@options)

        @change.rollback_sql_collection.to_a(@database).each do |sql|
          puts sql
          puts ';'
        end
        puts @database.unregister_change_sql(@change)
        puts ";"
      end
    end
  end
end
