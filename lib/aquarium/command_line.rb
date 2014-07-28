require 'optparse'
require 'yaml'
require 'dbi'
require 'encryptor'
require 'base64'
require 'aquarium/database'
require 'aquarium/parser'
require 'aquarium/executor'

module Aquarium

  class CommandLine
    attr :options

    def initialize(args)
      process_options(args)
      query_repository
    end

    # Load configuration
    def query_repository
      config = YAML::load(File.open(@options[:config]))
      assert_not_null(config,'username')
      assert_not_null(config,'password')
      assert_not_null(config,'database')
      assert_not_null(config,'host')
      assert_not_null(config,'secret')
      url = "dbi:Mysql:database=#{config['database']};host=#{config['host']};port=3306"      
      DBI.connect(url, config['username'], config['password']) do |dbh|
        row = dbh.select_one("select url,username,salt,password from aqu_instance where name = '#{@options[:instance_name]}'")
        raise "Did not find database instance \"#{@options[:instance_name]}\" in repository" if row.nil?
        @options[:url] = row[0]
        @options[:username] = row[1]
        @options[:password] = decrypt(row[2],row[3],config['secret'])
      end
    end

    def decrypt(salt,password,secret)
      secret_key = Digest::MD5.digest(secret)
      iv = Digest::MD5.digest(salt)
      Encryptor.default_options.merge!(:algorithm => 'aes-128-cbc')
      Encryptor.decrypt(Base64.decode64(password), :key => secret_key,:iv=>iv)
    end

    def assert_not_null(config, key)
      raise "Please set parameter \"#{key}\" in config file" if config[key].nil?
    end

    def run
      change_collection= Aquarium::Parser.parse(@options[:file])
      database = Aquarium::Database.database_for(@options)
      executor = Aquarium::Executor.executor_for(@command).new(database,change_collection,@parameters,STDOUT)
      if @options[:execute]
        executor.execute
      else        
        executor.print
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