require 'optparse'
require 'yaml'
require 'mysql2'
require 'encryptor'
require 'base64'
require 'colored'
require 'aquarium/database'
require 'aquarium/parser'
require 'aquarium/executor'
require 'byebug'

module Aquarium

  # This is a wrapper class to be used from command line
  class CommandLine
    attr :options, true
    attr :command, true
    attr :parameters, true

    # Create new command line object
    # :nocov:
    def initialize(args)
      # Below is needed to shut up Oracle DBI driver
      ENV['NLS_LANG']='AMERICAN_AMERICA.US7ASCII'
      process_options(args)
      query_repository
    rescue Exception => e
      puts e.to_s.red
      exit!
    end
    # :nocov:

    # Query repository for the database instance data
    def query_repository
      raise "Can not open onfig file #{@options[:config]}" unless File.exists?(@options[:config]) and File.readable?(@options[:config])
      config = {}
      File.open(@options[:config]) do |f|
        config = YAML::load(f)
      end
      assert_not_null(config,'username')
      assert_not_null(config,'password')
      assert_not_null(config,'database')
      assert_not_null(config,'host')
      assert_not_null(config,'secret')      
      client = Mysql2::Client.new(
        :host => config[:host],
        :username => config[:username],
        :password => config[:password],
        :port => config[:port] || 3306,
        :database => config[:database])

      row = client.query("select adapter,host,port,database,username,salt,password from aqu_instance where name = '#{@options[:instance_name]}'",
          :symbolize_keys => true).first
      raise "Did not find database instance \"#{@options[:instance_name]}\" in repository" if row.nil?
      @options[:adapter] = row[:adapter]
      @options[:host] = row[:host]
      @options[:port] = row[:port]
      @options[:database] = row[:database]
      @options[:username] = row[:username]
      @options[:password] = decrypt(row[:salt],row[:password],config['secret'])
      
    end

    # Decrypt password using salt and secret
    def decrypt(salt,password,secret)
      secret_key = Digest::MD5.digest(secret)
      iv = Digest::MD5.digest(salt)
      Encryptor.default_options.merge!(:algorithm => 'aes-128-cbc')
      Encryptor.decrypt(Base64.decode64(password), :key => secret_key,:iv=>iv)
    rescue Exception => e
      raise 'Decryption failed. Please check if "secret" parameter is set correctly in configuration file'
    end

    # Assert particular key (parameter) in the has is not null
    # :nocov:
    def assert_not_null(config, key)
      raise "Please set parameter \"#{key}\" in config file" if config[key].nil?
    end
    # :nocov:

    # Run specified command
    def run      
      @options[:interactive] = true
      parser = Aquarium::Parser.new(@options[:file])      
      database = Aquarium::Database.database_for(@options)
      executor = Aquarium::Executor.executor_for(@command).new(database,parser,@parameters,@options)
      
      if @options[:execute]
        executor.execute
      else        
        executor.print
      end
      
    rescue Exception => e      
      puts e.to_s.red
    ensure
      executor.finish if executor
    end

    # Process options
    def process_options(args)
      @options = {}
      @options[:config] = 'repo.yml'
      @options[:execute] = false
      optparse = OptionParser.new do |opts|
        opts.banner = "Usage: aq [OPTIONS] COMMAND [PARAMETERS]"
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
        opts.on("-v", "--verbose", "Verbose. Print every SQL executed") do |config|
          @options[:callback] = self
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

    # Executor callback methods
    # :nocov:
    def start_sql(sql)
      puts(sql)
    end
    def end_sql(status)
      if status == :success
        puts "OK".green
      end
    end
    # :nocov:

  end
end