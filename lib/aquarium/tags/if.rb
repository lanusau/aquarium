require 'aquarium/conditional_sql_collection'

module Aquarium

  module Tags

    class If < Aquarium::Tag
      register_tag :if

      def initialize(parameters,file_name,change_collection)
        @conditional_sql_collection = Aquarium::ConditionalSqlCollection.new(parameters,true)
        @change_collection = change_collection
      end

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