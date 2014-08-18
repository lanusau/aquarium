require 'aquarium/tag'
require 'aquarium/change_collection'

module Aquarium
  # Parser class parses change file
  class Parser

    # Create Parser instance
    def initialize(file_name)
      @file_name = file_name
    end

    # Parse file and return change collection
    def parse

      change_collection = Aquarium::ChangeCollection.new(@file_name)
      File.open(@file_name, "r") do |f|

        while line = f.gets
          if tag = Aquarium::Tag.match(line,@file_name,change_collection)
            tag.parse(f)
          else
            if !change_collection.current_change.nil?
              f.seek(0-line.size,IO::SEEK_CUR)
              change_collection.current_change.current_sql_collection.parse(f)
            else
              # Ignore anything before first change set
              next
            end
          end
        end                  
      end

      return change_collection

    end
    
  end

end