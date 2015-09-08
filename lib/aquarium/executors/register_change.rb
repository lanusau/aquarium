require 'aquarium/executor'

module Aquarium
  module Executors
    # Register particular change as manually applied
    class RegisterChange < Executor

      register_executor :register_change

      def self.help #:nodoc:
        '   register_change - register change (if manually applied), change code is passed as a parameter'
      end

      # Create new executor
      def initialize(database, parser,parameters,options)
        super
        raise 'Please specify change code to apply' if parameters.nil?
        @change_code_to_register = parameters.shift
        @change = @change_collection.find(@change_code_to_register)
        raise "Change #{@change_code_to_register} not found" if @change.nil?
        @change.user_update = options[:user_update] if options[:user_update]
      end

      # Actually execute SQL
      def execute
        raise 'Change already registered in the database' if @database.change_registered?(@change)

        @database.create_control_table(@options) if @database.control_table_missing?
        @database.register_change(@change)
        update_repository(:register,@change)
      end

      # Only print SQLs
      def print
        raise 'Change already registered in the database' if @database.change_registered?(@change)

        if @database.control_table_missing?
          puts "-- SQL for control table"
          puts  "--"
          @database.control_table_sqls.each do |sql|
            puts  sql
            puts  ';'
          end
        end

        puts  @database.register_change_sql(@change)
        puts ';'

      end

    end
  end
end
