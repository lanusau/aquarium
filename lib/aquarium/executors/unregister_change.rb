require 'aquarium/executor'

module Aquarium
  module Executors
    # Rollback particular change
    class UnregisterChange < Executor

      register_executor :unregister_change

      def self.help #:nodoc:
        '   unregister_change - unregister change as (if manually rolled back), code is passed as a parameter'
      end

      # Create new executor
      def initialize(database, parser,parameters,options)
        super
        raise 'Please specify change code to apply' if parameters.nil?
        @change_code_to_unregister = parameters.shift
        @change = @change_collection.find(@change_code_to_unregister)
        raise "Change #{@change_code_to_unregister} not found" if @change.nil?
      end

      # Print warning
      # :nocov:
      def warning(message)
        puts ("** #{message}") if @options[:interactive]
      end
      # :nocov:

      # Actually execute SQLs
      def execute
        database_change = @database.change_registered?(@change)
        raise "Change #{@change.code} is not registered in the database" unless database_change
        @database.unregister_change(@change)
      end

      # Only print SQLs
      def print
        database_change = @database.change_registered?(@change)
        raise "Change #{@change.code} is not registered in the database" unless database_change

        puts @database.unregister_change_sql(@change)
        puts ";"
      end
    end
  end
end
