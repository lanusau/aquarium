module Aquarium
  module Executors
    class PrintUpdate

      def initialize(database, change_collection)
        @database = database
        @change_collection = change_collection
      end

      def execute
        @pending_changes = []
        if @database.control_table_missing?
          puts "-- SQL for control table"
          puts "--"
          @database.control_table_sqls.each do |sql|
            puts(sql)
            puts(';')
          end

          # With no control table we assume nothing was implemented yet
          @pending_changes =  @change_collection.dup
        else
          @change_collection.each do |change|
            @pending_changes << change if !@database.change_registered?(change)
          end
        end

        @pending_changes.each do |change|
          begin
            puts "---------------------------------------------"
            puts "-- Change #{change.code}"
            puts "-- #{change.description}" unless change.description.empty?
            puts "---------------------------------------------"
            change.apply_sql_collection.to_a(@database).each do |sql|
              puts(sql)
              puts(';')
            end
            puts @database.register_change_sql(change)
            puts(';')
          rescue Exception => e
            puts e.to_s
            puts e.backtrace.first
            return false
          end
        end
      end
    end
  end
end
