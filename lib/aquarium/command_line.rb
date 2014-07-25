require 'optparse'
require 'yaml'
require 'active_record'
require 'aquarium/database'
require 'aquarium/parser'
require 'aquarium/executor'
require 'aquarium/models/aqu_database'
require 'aquarium/models/aqu_instance'

module Aquarium

  class CommandLine
    attr :options

    def initialize(args)
      process_options(args)
      query_repository
    end

    # Load configuration
    def query_repository
      ActiveRecord::Base.establish_connection(YAML::load(File.open('database.yml')))
      instance = AquInstance.find_by_name(@options[:instance_name])
      @options[:url] = instance.url
      @options[:username] = instance.username
      @options[:password] = instance.password
    end

    def run
      change_collection= Aquarium::Parser.parse(@options[:file])
      database = Aquarium::Database.database_for(@options)
      if @options[:execute]
        Aquarium::Executor.executor_for(@command).new(database,change_collection,@parameters).execute
      else
        Aquarium::Executor.executor_for(@command).new(database,change_collection,@parameters).print
      end
    rescue Exception => e      
      puts e.to_s
      e.backtrace.each{|line| puts line}
    end

    def process_options(args)
      @options = {}
      @options[:config] = 'repo.yml'
      @options[:execute] = false
      optparse = OptionParser.new do |opts|
        opts.banner = "Usage: aq [OPTIONS] COMMAND"
        opts.separator ""
        opts.separator "Options:"        
        opts.on("-f", "--file CHANGEFILE", "File with changes") do |config|
          @options[:file] = config
        end
        opts.on("-d", "--database DATABASE", "Name of database instance") do |config|
          @options[:instance_name] = config
        end
        opts.on("-c", "--confile [FILE]", "Alternate configuration file. Default is repo.yml in current directory") do |config|
          @options[:config] = config
        end
        opts.on("-x", "--execute", "Execute SQL. Default is to just print SQL") do |config|
          @options[:execute] = true
        end
        opts.on("-h", "--help", "Show this message") do
          puts opts
          exit
        end
        opts.separator ""
        opts.separator "Commands:"
        Aquarium::Executor.registered_executors.each do |executor|
            opts.separator executor.help
        end
        
      end

      optparse.parse!(args)
      
      @command = args.shift
      raise OptionParser::InvalidOption.new('Please specify command') if @command.nil?
      @command = @command.to_sym      

      @parameters = args
            
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument
      puts $!.to_s
      puts optparse
      exit
    end

  end
end