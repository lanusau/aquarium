require 'aquarium/sql_collection'
require 'digest'
require 'base64'

module Aquarium
  # Change class holds information about single change in the change log file
  class Change
    attr :id, true
    attr :code
    attr :file_name, true
    attr :description
    attr :apply_sql_collection
    attr :rollback_sql_collection
    attr :saved_rollback_sql_collection
    attr :cmr_number, true
    attr :user_update, true
    attr :rollback_digest
    attr :rollback_attribute, true # :none, :long or :impossible

    # Create new change with specified code, file name and description
    def initialize(code,file_name,description,id=nil,
        cmr_number=nil,user_update=nil,rollback_digest=nil,
        saved_rollback_text=nil)
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
      @rollback_attribute = :none
      if saved_rollback_text && saved_rollback_text != ''
        @saved_rollback_sql_collection = Marshal::load(Base64.decode64(saved_rollback_text))
      end

    end

    # Set current SQL collection to either :apply or :rollback
    def current_sql_collection=(name)
      @current_sql_collection = name
    end

    # Return digest of rollback SQLs
    def rollback_digest      
      @rollback_digest ||= Digest::MD5.hexdigest @rollback_sql_collection.to_string(nil)
    end

    # Return rollback SQL collection, or warning if rollback is not possible
    def rollback_sql_collection
      if @rollback_attribute == :impossible
        sql_collection = Aquarium::SqlCollection.new
        sql_collection << "--ROLLBACK NOT POSSIBLE"
        return sql_collection
      end
      @rollback_sql_collection
    end

    # Return rollback SQL encoded to text suitable for saving into db
    def encoded_rollback_text
      Base64.encode64(Marshal::dump(@rollback_sql_collection))
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
