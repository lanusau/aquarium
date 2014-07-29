require 'aquarium/tag'
require 'aquarium/change_collection'

module Aquarium
  # Parser class parses change file
  class Parser

    # Class method to parse particular file
    def self.parse(file)

      change_collection = Aquarium::ChangeCollection.new
      File.open(file, "r") do |f|       

        while line = f.gets
          if tag = Aquarium::Tag.match(line,file,change_collection)
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