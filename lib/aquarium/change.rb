require 'aquarium/sql_collection'
require 'digest'

module Aquarium
  # Change class holds information about single change in the change log file
  class Change
    attr :id, true
    attr :code
    attr :file_name, true
    attr :description
    attr :apply_sql_collection
    attr :rollback_sql_collection
    attr :cmr_number, true
    attr :user_update, true
    attr :rollback_digest

    # Create new change with specified code, file name and description
    def initialize(code,file_name,description,id=nil,cmr_number=nil,user_update=nil,rollback_digest=nil)
      @code = code
      @file_name = file_name
      @description = description
      @id = id
      @apply_sql_collection = Aquarium::SqlCollection.new
      @rollback_sql_collection = Aquarium::SqlCollection.new
      @current_sql_collection = :apply
      @cmr_number = cmr_number || ''
      @user_update = user_update || ENV['LOGNAME']
      @rollback_digest = rollback_digest
    end

    # Set current SQL collection to either :apply or :rollback
    def current_sql_collection=(name)
      @current_sql_collection = name
    end

    # Return digest of rollback SQLs
    def rollback_digest      
      @rollback_digest ||= Digest::MD5.hexdigest @rollback_sql_collection.to_string(nil)
    end

    # Return current SQL collection (either apply or rollback)
    def current_sql_collection
      case @current_sql_collection
      when :apply
        @apply_sql_collection
      when :rollback
        @rollback_sql_collection
      else
        raise "Unknow sql collection #{@current_sql_collection}"
      end
    end

    # Print banner text for this change
    def print_banner(operation,options)
      return unless options[:interactive]
      puts "---------------------------------------------"
      puts "-- #{operation}"
      puts "-- CHANGE: #{@code}"
      puts "-- DESCRIPTION: #{@description}" unless @description.empty?
      puts "---------------------------------------------"
    end
   
  end
end
