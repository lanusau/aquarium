require 'aquarium/execution_exception'

module Aquarium
  # Abstract class for executors
  class Executor
    @@registered_executors = { }

    attr :callback, true

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
    def initialize(database, parser,parameters,options)
      @parser = parser
      @database = database
      @change_collection = @parser.parse
      @options = options
      @parameters = parameters
      if options[:callback] &&
          options[:callback].respond_to?(:start_sql) &&
          options[:callback].respond_to?(:end_sql)
        @callback = options[:callback]
      end
    end

    # Close database connection
    def finish
      @database.disconnect if @database
    end

    # Apply change
    def apply_change(change)
      do_change_with_retry(:apply,change)
    end

    # Rollback change
    def rollback_change(change)
      if change.rollback_attribute == :impossible
        raise 'Can not rollback change because rollback is marked as impossible'
      end
      do_change_with_retry(:rollback,change)   
    end    

    # Apply/rollback particular change, with re-try logic
    def do_change_with_retry(operation,change)
      banner = (operation == :apply ? 'APPLY' : 'ROLLBACK')
      change.print_banner(banner,@options)

      sql_collection =  case operation
        when :apply    then change.apply_sql_collection.to_a(@database)
        when :rollback then change.rollback_sql_collection.to_a(@database)
      end
      start_with = 0
      begin
        execute_collection(sql_collection,start_with)
      rescue Aquarium::ExecutionException => e        
        if @options[:interactive]
          puts "Error: #{e.message}".red
          puts "When executing:".red
          puts "-----------------------------".red
          puts e.sql.red
          puts "-----------------------------".red
          begin
            response = get_response("[R]etry,[A]bort,[S]kip or [P]arse file and retry ?")
            case response
            when 'R'
              puts('Retrying ...')
              start_with = e.index
              retry
            when 'S'
              puts('Skipping last SQL')
              start_with = e.index + 1
              retry
            when 'A'
              raise 'Aborted'
            when 'P'
              puts('Reparsing file ...')
              # Re-parse file and retry again at the same index
              @change_collection = @parser.parse
              change = @change_collection.find!(change.code)
              sql_collection =  case operation
                when :apply    then change.apply_sql_collection.to_a(@database)
                when :rollback then change.rollback_sql_collection.to_a(@database)
              end
              start_with = e.index
              puts('Retrying ...')
              retry
            end
          end
        else
          raise
        end
      end
      puts "#{banner} operation successful".green if @options[:interactive]
    end
    
    # Execute particular SQL collection
    def execute_collection(sql_collection,start_with)
      sql_collection.each_with_index do |sql,index|
        next if index < start_with
        begin
          @callback.start_sql(sql) if @callback
          @database.execute(sql)
          @callback.end_sql(:success) if @callback
        rescue Exception => e
          @callback.end_sql(:error) if @callback
          raise Aquarium::ExecutionException.new(sql,index), e.message
        end

      end
    end
    
    # Update Poseidon repository if requested (by command line client)
    def update_repository(operation,change)
      return if !@options[:update_repository]
      client = @options[:client]
      instance_id = @options[:instance_id]
      case operation
      when :register then 
        client.query("insert ignore into aqu_instance_change (instance_id,change_code,create_sysdate,update_sysdate) 
          values (#{instance_id},'#{change.code}',now(),now())")
      when :unregister then
        client.query("delete from aqu_instance_change where instance_id = #{instance_id} and change_code = '#{change.code}'")
      end
      client.query("COMMIT")
    rescue Exception => e
      raise "Updating Poseidon repository failed: " + e.to_s 
    end    

    # Get response, retrying until its valid
    # :nocov:
    def get_response(message)
      response = ''
      loop do
        puts(message)
        response = gets.chop.upcase
        break if response =~ /^[RAPS]{1}/
      end
      return response
    end
    # :nocov:

  end

end

# Load all files in tags directory
Dir[File.dirname(__FILE__) + '/executors/*.rb'].each {|file| require file }