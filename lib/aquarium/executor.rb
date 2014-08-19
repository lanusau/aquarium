require 'aquarium/execution_exception'

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

    # Create new executor
    def initialize(database, parser,parameters,logger=STDOUT)
      @parser = parser
      @database = database
      @change_collection = @parser.parse
      @logger = logger
      @parameters = parameters
    end

    # Apply particular change, with re-try logic
    def apply_change(change)
      change.print_banner('APPLY',@logger)

      sql_collection = change.apply_sql_collection.to_a(@database)
      start_with = 0
      begin
        execute_collection(sql_collection,start_with)
      rescue Aquarium::ExecutionException => e
        # If logger is nil, that means we are not in interactive mode
        if @logger.nil?
          raise
        else
          puts "Error: #{e.message}".red
          puts "When executing:".red
          puts "-----------------------------".red
          puts e.sql.red
          puts "-----------------------------".red
          begin
            response = get_response("[R]etry,[A]bort or [P]arse file and retry ?")
            case response
            when 'R'
              puts('Retrying ...')
              start_with = e.index
              retry
            when 'A'
              raise 'Aborted'
            when 'P'
              puts('Reparsing file ...')
              # Re-parse file and retry again at the same index
              @change_collection = @parser.parse
              change = @change_collection.find!(change.code)
              sql_collection = change.apply_sql_collection.to_a(@database)
              start_with = e.index
              puts('Retrying ...')
              retry
            end
          end
        end
      end
      puts 'Applied successfully'.green
    end

    # Rollback particular change, with re-try logic
    def rollback_change(change)
      change.print_banner('ROLLBACK',@logger)

      sql_collection = change.rollback_sql_collection.to_a(@database)
      start_with = 0
      begin
        execute_collection(sql_collection,start_with)
      rescue Aquarium::ExecutionException => e
        # If logger is nil, that means we are not in interactive mode
        if @logger.nil?
          raise
        else
          puts "Error: #{e.message}".red
          puts "When executing:".red
          puts "-----------------------------".red
          puts e.sql.red
          puts "-----------------------------".red
          begin
            response = get_response("[R]etry,[A]bort or [P]arse file again and retry ?")
            case response
            when 'R'
              puts('Retrying ...')
              start_with = e.index
              retry
            when 'A'
              raise 'Aborted'
            when 'P'
              puts('Reparsing file ...')
              # Re-parse file and retry again at the same index
              @change_collection = @parser.parse
              change = @change_collection.find!(change.code)
              sql_collection = change.rollback_sql_collection.to_a(@database)
              start_with = e.index
              puts('Retrying ...')
              retry
            end
          end
        end
      end
      puts 'Rolled back successfully'.green
    end

    # Execute particular SQL collection
    def execute_collection(sql_collection,start_with)
      sql_collection.each_with_index do |sql,index|
        next if index < start_with
        begin
          @database.execute(sql)
        rescue DBI::DatabaseError => e
          raise Aquarium::ExecutionException.new(sql,index), e.message
        end

      end
    end

    # Get response, retrying until its valid
    def get_response(message)
      response = ''
      loop do
        puts(message)
        response = gets.chop.upcase
        break if response =~ /^[RAP]{1}/
      end
      return response
    end

  end

end

# Load all files in tags directory
Dir[File.dirname(__FILE__) + '/executors/*.rb'].each {|file| require file }