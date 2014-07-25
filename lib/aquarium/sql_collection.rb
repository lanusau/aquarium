module Aquarium

  class SqlCollection

    DELIMITER = /[;\/]/

    attr :sql_collection

    def initialize
      @sql_collection = []
    end

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

    def << (object)
      @sql_collection << object
    end

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

    def to_string(database)
      to_a(database).join(";\n") << ";"
    end
    
  end
end
