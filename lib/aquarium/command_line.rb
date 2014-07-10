require 'optparse'
require 'aquarium/database'
require 'aquarium/parser'
require 'aquarium/executors/update'
require 'aquarium/executors/print_update'
require 'aquarium/executors/rollback'
require 'aquarium/executors/print_rollback'

module Aquarium

  class CommandLine
    attr :options

    COMMANDS = [:update,:print_update,:rollback,:print_rollback]
    
    def initialize(args)
      handle_options(args)
    end

    def process
      change_collection= Aquarium::Parser.parse(@file)
      database = Aquarium::Database.database_for(options)
      case @command
      when :update        
        Aquarium::Executors::Update.new(database,change_collection).execute
      when :print_update
        Aquarium::Executors::PrintUpdate.new(database,change_collection).execute
      when :rollback
        Aquarium::Executors::Rollback.new(database,change_collection,@parameters).execute
      when :print_rollback
        Aquarium::Executors::PrintRollback.new(database,change_collection,@parameters).execute
      end
    rescue Exception => e      
      puts e.to_s
      e.backtrace.each{|line| puts line}
    end

    def handle_options(args)
      @options = {}
      optparse = OptionParser.new do |opts|
        opts.banner = "Usage: aq FILE COMMAND [PARAMETERS] [OPTIONS]"
        opts.separator ""
        opts.separator "Options:"
        opts.on("-d", "--database URL", "Database connection URL") do |url|
          @options[:url] = url
        end
        opts.on("-u", "--user USER", "Username") do |username|
          @options[:user] = username
        end
        opts.on("-p", "--password PASSWORD", "Password") do |password|
          @options[:password] = password
        end
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end

      optparse.parse!(args)

      mandatory = [:url, :user,:password]
      missing = mandatory.select{ |param| @options[param].nil? }      
      raise OptionParser::InvalidOption.new("Missing options: #{missing.join(', ')}") unless missing.empty?
      
      @file = args.shift
      raise OptionParser::InvalidOption.new('Please specify file') if @file.nil?

      @command = args.shift
      raise OptionParser::InvalidOption.new('Please specify command') if @command.nil?
      @command = @command.to_sym
      raise OptionParser::InvalidOption.new("Unknown command [#{@command}]") unless COMMANDS.detect { |c| c == @command }

      @parameters = args
            
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument
      puts $!.to_s
      puts optparse
      exit
    end

  end
end