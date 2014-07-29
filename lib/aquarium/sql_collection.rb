module Aquarium
  # Class to store collection of SQL statements
  class SqlCollection

    DELIMITER = /[;\/]/

    attr :sql_collection

    # Create empty collection
    def initialize
      @sql_collection = []
    end

    # Parse list of SQL statements working from current pointer in the specified file
    def parse(file)

      blob = ''
      while (line = file.gets)

        # Terminate on finding next tag
        if line =~ /^--#/
          file.seek(0-line.size,IO::SEEK_CUR)
          break
        end

        # Ignore comments
        next if line =~ /^--/

        blob << line
      end

      @sql_collection  = @sql_collection + blob.split(DELIMITER).delete_if{|e| e =~ /\A\s+\Z/}
    end

    # Add object to this SQL collection.
    # Object can be string or another SQL collection
    def << (object)
      @sql_collection << object
    end

    # Return SQL collection as an array
    def to_a(database)
      sql_array = []
      @sql_collection.each do |item|
        if item.kind_of? Aquarium::SqlCollection
          sql_array  = sql_array + item.to_a(database)
        else
          sql_array << item
        end
      end
      return sql_array
    end

    # Return SQL collection as one big string
    def to_string(database)
      to_a(database).join(";\n") << ";"
    end
    
  end
end
