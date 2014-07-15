module Aquarium
  module Executors
    class PrintUpdate

      def initialize(database, change_collection)
        @database = database
        @change_collection = change_collection
      end

      def execute
        if @database.control_table_missing?
          puts "-- SQL for control table"
          puts "--"
          @database.control_table_sqls.each do |sql|
            puts(sql)
            puts(';')
          end
        end

        @change_collection.pending_changes(@database).each do |change|
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
        end
      end
    end
  end
end
