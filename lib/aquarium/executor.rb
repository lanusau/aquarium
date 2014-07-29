module Aquarium
  # Abstract class for executors
  class Executor
    @@registered_executors = { }

    # Find executor for particular command
    def self.executor_for(command)

      klass = @@registered_executors[command]
      raise "Unknown command #{command}" if klass.nil?
      klass

    end

    # Subclasses will call this to register  that they can handle particular command
    def self.register_executor(command)
      @@registered_executors[command] = self
    end

    # Return all registered executors
    def self.registered_executors
      @@registered_executors.values
    end

  end

end

# Load all files in tags directory
Dir[File.dirname(__FILE__) + '/executors/*.rb'].each {|file| require file }