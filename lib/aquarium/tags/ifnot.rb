require 'aquarium/conditional_sql_collection'

module Aquarium
  module Tags
    # IFNOT tag specifies to execute list of SQL if condition is not true
    class IfNot < Aquarium::Tag
      register_tag :ifnot

      # Create new tag
      def initialize(parameters,file_name,change_collection)
        @conditional_sql_collection = Aquarium::ConditionalSqlCollection.new(parameters,false)
        @change_collection = change_collection
      end

      # Parse tag information from current position in the specified file
      def parse(file)
        @conditional_sql_collection.parse(file)

        # This should be terminated with --#endif tag
        line = file.gets
        if line =~ /^--#endif/
          @change_collection.current_change.current_sql_collection << @conditional_sql_collection
        else
          raise "Did not find #endif tag where expected:\n #{line}"
        end
      end

    end

  end

end