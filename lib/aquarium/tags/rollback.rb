module Aquarium

  module Tags

    # Rollback tag specifies list of SQL to perform rollback
    class Rollback < Aquarium::Tag
      register_tag :rollback

      def initialize(parameters,file_name,change_collection)
        @change_collection = change_collection
        @change_collection.current_change.current_sql_collection = :rollback

        # Check for optional rollback attribute
        tokens = parameters.split
        attribute = tokens.shift || 'none'
        case attribute.downcase
        when 'long'
          @change_collection.current_change.rollback_attribute = :long
        when 'impossible'
          @change_collection.current_change.rollback_attribute = :impossible
        when 'none'

        else raise "Unrecognized attribute [#{attribute}] in the rollback tag"
        end
      end

      # Parse tag information from current position in the specified file
      def parse(file)

        @change_collection.current_change.rollback_sql_collection.parse(file)

      end

    end

  end

end