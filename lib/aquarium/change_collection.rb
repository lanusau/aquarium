module Aquarium
  # Class to store a collection of Changes
  class ChangeCollection

    # Create new change collection
    def initialize(file_name)
      @file_name=File.basename(file_name)
      @change_collection = []
      @current_change = -1
    end

    # Advance pointer and set it to change
    def add_change(change)
      raise "Duplicate change #{change.code} found" if find(change.code)
      @current_change += 1
      @change_collection[@current_change] = change
    end

    # Return current change
    def current_change
      @change_collection[@current_change]
    end

    # Merge current change collection with parameter collection
    def merge(collection)
      collection.each do |change|
        change.file_name = @file_name
        add_change(change)
      end
    end

    # Iterate each change
    def each(&block)
      @change_collection.each &block
    end
    
    # Return whether change exists
    def exists(change)
      @change_collection.detect{|c| (c.code == change.code) && (c.file_name == change.file_name)}
    end

    # Find particular change by code
    def find(change_code)
      @change_collection.detect{|c| c.code == change_code}
    end

    # Return list of changes that have not been applied yet
    def pending_changes(database)      
      return @pending_change_collection unless @pending_change_collection.nil?

      @pending_change_collection = []
      if database.control_table_missing?
        # With no control table we assume nothing was implemented yet
        @pending_change_collection =  @change_collection.dup
      else
        @change_collection.each do |change|          
          @pending_change_collection << change if !database.change_registered?(change)
        end
      end
      return @pending_change_collection
    end

  end
end