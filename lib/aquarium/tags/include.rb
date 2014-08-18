require 'aquarium/parser'

module Aquarium

  module Tags
    # Include tag includes another file into change list
    class Include < Aquarium::Tag
      register_tag :include

      # Create new tag
      def initialize(parameters,file,change_collection)
        @include_file_name = File.dirname(file) +'/'+ parameters

        @change_collection = change_collection
      end

      # Parse tag information from current position in the specified file
      def parse(file)
        include_change_collection = Aquarium::Parser.new(@include_file_name).parse
        @change_collection.merge(include_change_collection)
      end

    end

  end

end