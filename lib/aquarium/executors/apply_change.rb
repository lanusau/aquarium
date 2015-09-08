require 'aquarium/executor'

module Aquarium
  module Executors
    # Apply particular change
    class ApplyChange < Executor

      register_executor :apply_change

      def self.help #:nodoc:
        '   apply_change - apply single change with code that is passed as a parameter'
      end

      # Create new executor
      def initialize(database, parser,parameters,options)
        super        
        raise 'Please specify change code to apply' if parameters.nil?
        @change_code_to_apply = parameters.shift
        @change = @change_collection.find(@change_code_to_apply)
        raise "Change #{@change_code_to_apply} not found" if @change.nil?
        @change.user_update = options[:user_update] if options[:user_update]
      end

      # Actually execute SQL
      def execute
        raise 'Change already registered in the database' if @database.change_registered?(@change)
        
        @database.create_control_table(@options) if @database.control_table_missing?
        apply_change(@change)
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

        @change.print_banner('APPLY',@options)
        @change.apply_sql_collection.to_a(@database).each do |sql|
          puts sql
          puts ';'
        end
        puts  @database.register_change_sql(@change)
        puts ';'
        


      end


    end
  end
end
