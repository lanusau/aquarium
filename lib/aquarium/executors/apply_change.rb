require 'aquarium/executor'

module Aquarium
  module Executors
    class ApplyChange < Executor

      register_executor :apply_change

      def self.help
        '   apply_change - apply single change with code that is passed as a parameter'
      end

      def initialize(database, change_collection,parameters,logger=STDOUT)
        @database = database
        raise 'Please specify change code to apply' if parameters.nil?
        @change_code_to_apply = parameters.shift
        @change = change_collection.find_by_code(@change_code_to_apply)        
        raise "Change #{@change_code_to_apply} not found" if @change.nil?
        @logger = logger
      end

      def execute
        raise 'Change already registered in the database' if @database.change_registered?(@change)
        
        @database.create_control_table(@logger) if @database.control_table_missing?

        @change.print_banner('APPLY',@logger)
        
        @change.apply_sql_collection.to_a(@database).each do |sql|
          @database.execute(sql)
        end
        @database.register_change(@change)
      end

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

        @change.print_banner('APPLY',STDOUT)
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
