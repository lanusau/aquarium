require 'aquarium/change'

module Aquarium

  module Tags
    # Change tag describes the database change
    class Change < Aquarium::Tag
      register_tag :change
      attr :change

      # Create new tag
      def initialize(parameters,file_name,change_collection)

        # Parse change code out of string following #change tag
        tokens = parameters.split
        code = tokens.shift
        raise "Change code not found" if code.nil?
        if tokens.size > 0
          description = tokens.join(' ')
        else
          description = ''
        end

        @change = Aquarium::Change.new(code,File.basename(file_name),description)
        @change.current_sql_collection = :apply

        # {change} tag terminates current change
        change_collection.add_change(@change)
      end

      # Parse tag information from current position in the specified file
      def parse(file)

        @change.apply_sql_collection.parse(file)

      end

    end

  end

end