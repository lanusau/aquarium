require 'aquarium/executor'

module Aquarium
  module Executors
    class ApplyAll < Executor

      register_executor :apply_all

      def self.help
        '   apply_all - apply all pending changes for this database instance'
      end

      def initialize(database, change_collection,parameters,logger=STDOUT)
        @database = database
        @change_collection = change_collection
        @logger = logger
        @parameters = parameters
      end

      # Actually execute SQLs
      def execute

        @database.create_control_table(@logger) if @database.control_table_missing?

        @change_collection.pending_changes(@database).each do |change|

         change.print_banner('APPLY',@logger)
          
          change.apply_sql_collection.to_a(@database).each do |sql|
            @database.execute(sql)
          end
          @database.register_change(change)
        end
      end

      # Only print SQLs
      def print
        if @database.control_table_missing?
          puts "-- SQL for control table"
          puts "--"
          @database.control_table_sqls.each do |sql|
            puts sql
            puts ';' 
          end
        end

        @change_collection.pending_changes(@database).each do |change|
          change.print_banner('APPLY',STDOUT)
          change.apply_sql_collection.to_a(@database).each do |sql|
            puts sql
            puts ';'
          end
          puts  @database.register_change_sql(change)
          puts ';'
        end
      end
    end
  end
end
