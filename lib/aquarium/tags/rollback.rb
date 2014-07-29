module Aquarium

  module Tags

    # Rollback tag specifies list of SQL to perform rollback
    class Rollback < Aquarium::Tag
      register_tag :rollback

      def initialize(parameters,file_name,change_collection)
        @change_collection = change_collection
        @change_collection.current_change.current_sql_collection = :rollback
      end

      # Parse tag information from current position in the specified file
      def parse(file)

        @change_collection.current_change.rollback_sql_collection.parse(file)

      end

    end

  end

end