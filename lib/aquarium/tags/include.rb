require 'aquarium/parser'

module Aquarium

  module Tags

    class Include < Aquarium::Tag
      register_tag :include

      def initialize(parameters,file_name,change_collection)
        @include_file_name = parameters
        @change_collection = change_collection
      end

      def parse(file)
        include_change_collection = Aquarium::Parser.parse(@include_file_name)
        @change_collection.merge(include_change_collection)
      end

    end

  end

end