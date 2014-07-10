module Aquarium
  module Executors
    class Update

      def initialize(database, change_collection)
        @database = database
        @change_collection = change_collection
      end

      def execute
        pending_changes = []
        if @database.control_table_missing?
          puts "---- Creating control table"
          @database.control_table_sqls.each do |sql|
            @database.execute(sql)
          end

          # With no control table we assume nothing was implemented yet
          pending_changes =  @change_collection.dup
        else
          @change_collection.each do |change|
            pending_changes << change if !@database.change_registered?(change)
          end
        end

        pending_changes.each do |change|
          puts "---------------------------------------------"
          puts "-- Change #{change.code}"
          puts "-- #{change.description}" unless change.description.empty?
          puts "---------------------------------------------"
          
          change.apply_sql_collection.to_a(@database).each do |sql|
            @database.execute(sql)
          end
          @database.register_change(change)
        end
      end
    end
  end
end
