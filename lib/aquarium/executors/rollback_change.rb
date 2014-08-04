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
      def initialize(database, change_collection,parameters,logger=STDOUT)
        @database = database
        raise 'Please specify change code to apply' if parameters.nil?
        @change_code_to_apply = parameters.shift
        @change = change_collection.find(@change_code_to_apply)
        raise "Change #{@change_code_to_apply} not found" if @change.nil?
        @logger = logger
      end

      # Actually execute SQLs
      def execute
        raise "Change #{@change.code} is not registered in the database" unless @database.change_registered?(@change)

        @change.print_banner('ROLLBACK',@logger)
        @change.rollback_sql_collection.to_a(@database).each do |sql|
          @database.execute(sql)
        end
        @database.unregister_change(@change)
      end

      # Only print SQLs
      def print
        raise "Change #{@change.code} is not registered in the database" unless @database.change_registered?(@change)
        
        @change.print_banner('ROLLBACK',STDOUT)

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