require 'aquarium/sql_collection'

module Aquarium
  class Change
    attr :id, true
    attr :code
    attr :file_name
    attr :description
    attr :apply_sql_collection
    attr :rollback_sql_collection
    attr :cmr_number, true
    attr :user_update, true

    def initialize(code,file_name,description,id=nil)
      @code = code
      @file_name = file_name
      @description = description
      @id = id
      @apply_sql_collection = Aquarium::SqlCollection.new
      @rollback_sql_collection = Aquarium::SqlCollection.new
      @current_sql_collection = :apply
      @cmr_number = ''
      @user_update = ''
    end

    def current_sql_collection=(name)
      @current_sql_collection = name
    end

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

    def print_banner(logger)
      return if logger.nil?
      logger << "---------------------------------------------"
      logger << "-- Change #{@code}"
      logger << "-- #{@description}" unless @description.empty?
      logger << "---------------------------------------------"
    end
   
  end
end
