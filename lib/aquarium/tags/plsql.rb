module Aquarium

  module Tags
    # IF table
    class Plsql < Aquarium::Tag
      register_tag :plsql

      def initialize(parameters,file_name,change_collection)
        @change_collection = change_collection
      end

      # Parse tag information from current position in the specified file
      def parse(file)

        plsql_blob = ''

        while (line = file.gets)

          # PLSQL tag should terminate with --#endplsql
          if line =~ /^--#/

          if line =~ /^--#endplsql/
            @change_collection.current_change.current_sql_collection << plsql_blob
            break
          else
            raise "Did not find #endplsql tag where expected:\n #{line}"
          end

          end

          plsql_blob << line
          
        end
      end

    end

  end

end