require 'helper'
require 'mysql2'
require 'colored'

describe Aquarium::CommandLine do
  describe '#process_options' do
    context 'when valid options are passed' do
      it 'populates options has' do
        args = [
          '-f','file',
          '-d','database',
          '-c','config',
          '-x',
          '-v',
          '-s',
          'apply_change','test:1'
        ]
        Aquarium::CommandLine.class_eval {def initialize ; end}
        cmd = Aquarium::CommandLine.new
        cmd.process_options(args)
        expect(cmd.options[:file]).to eq 'file'
        expect(cmd.options[:instance_name]).to eq 'database'
        expect(cmd.options[:config]).to eq 'config'
        expect(cmd.options[:execute]).to eq true
        expect(cmd.options[:use_saved_rollback]).to eq true
        expect(cmd.options[:callback]).to eq cmd
        expect(cmd.command).to eq :apply_change
        expect(cmd.parameters[0]).to eq 'test:1'
      end
    end
    context 'when help is requested' do
      it 'prints help and exists' do
        args = ['-h']
        Aquarium::CommandLine.class_eval {def initialize ; end}
        cmd = Aquarium::CommandLine.new
        begin
          expect {cmd.process_options(args)}.to output.to_stdout
        rescue SystemExit
        end
      end
    end
    context 'when wrong option is specified' do
      it 'prints help and exists' do
        args = ['-blah']
        Aquarium::CommandLine.class_eval {def initialize ; end}
        cmd = Aquarium::CommandLine.new
        begin
          expect {cmd.process_options(args)}.to output.to_stdout
        rescue SystemExit
        end
      end
    end
  end
  describe '#decrypt' do
    context 'when incorrect data is passed' do
      it 'raises an exception' do
        Aquarium::CommandLine.class_eval {def initialize ; end}
        cmd = Aquarium::CommandLine.new
        expect {cmd.decrypt('123', '123123', 'abc')}.to raise_error
      end
    end
    context 'when correct data is passed' do
      it 'returns decrypted password' do
        Aquarium::CommandLine.class_eval {def initialize ; end}
        cmd = Aquarium::CommandLine.new
        expect(cmd.decrypt('1025784991619346', 'Y9rEnBmdSsiC6XHAUz9csg==', 'm0nitr$this')).to eq('dev2')
      end
    end
  end
  describe '#query_repository' do
    context 'when configuration file does not exists' do
      it 'raises exception' do
        Aquarium::CommandLine.class_eval {def initialize ; end}
        cmd = Aquarium::CommandLine.new
        cmd.options= {:config=>'config'}
        expect(File).to receive(:exists?) {false}
        expect {cmd.query_repository}.to raise_error
      end
    end
    context 'with present config file' do
      it 'connects to repository and gets target instance information' do
        Aquarium::CommandLine.class_eval {def initialize ; end}
        cmd = Aquarium::CommandLine.new
        cmd.options= {:config=>'config'}
        expect(File).to receive(:exists?) {true}
        expect(File).to receive(:readable?) {true}
        config_file = StringIO.new <<EOF
database: poseidon
username: root
password: password
host: host
secret: m0nitr$this
EOF
        expect(File).to receive(:open).and_yield(config_file)
        client = double()
        expect(client).to receive(:query) {
          [{:adapter => 'mysql',
           :host => 'test.host.com',
           :port => 3306,
           :database => 'test',
           :username => 'username',
           :salt => '1025784991619346',
           :password => 'Y9rEnBmdSsiC6XHAUz9csg==',
           :instance_id => 1
          }]
        }
        expect(Mysql2::Client).to receive(:new) {client}        
        cmd.query_repository
        expect(cmd.options[:adapter]).to eq 'mysql'
        expect(cmd.options[:host]).to eq 'test.host.com'
        expect(cmd.options[:port]).to eq 3306
        expect(cmd.options[:database]).to eq 'test'
        expect(cmd.options[:username]).to eq 'username'
        expect(cmd.options[:password]).to eq 'dev2'
        expect(cmd.options[:update_repository]).to eq true
        expect(cmd.options[:instance_id]).to eq 1
        expect(cmd.options[:client]).to eq client     
      end
    end
    context 'with present config file, when instance is not found in repository' do
      it 'connects to repository and gets target instance information' do
        Aquarium::CommandLine.class_eval {def initialize ; end}
        cmd = Aquarium::CommandLine.new
        cmd.options= {:config=>'config',:instance_name =>'test'}
        expect(File).to receive(:exists?) {true}
        expect(File).to receive(:readable?) {true}
        config_file = StringIO.new <<EOF
database: poseidon
username: root
password: password
host: host
secret: m0nitr$this
EOF
        expect(File).to receive(:open).and_yield(config_file)
        client = double()
        expect(client).to receive(:query) { {}}
        expect(Mysql2::Client).to receive(:new) {client}
        expect {cmd.query_repository}.to raise_error
      end
    end
  end
  describe '#run' do
    context 'when -x options is not specified' do
      it 'runs #print method on executor' do
        Aquarium::CommandLine.class_eval {def initialize ; end}
        cmd = Aquarium::CommandLine.new
        cmd.options = {:file=>'file',:adapter=>'mysql'}
        cmd.command = :apply_change
        cmd.parameters = ['test:1']
        file = StringIO.new "--#change test:1 Test change number 1\ncreate table test1\n;"
        allow(File).to receive(:dirname) {''}
        allow(File).to receive(:open).and_yield(file)
        client = double()
        expect(Mysql2::Client).to receive(:new) {client}
        class TestExecutor < Aquarium::Executor
          def initialize(database, parser,parameters,options)
          end
          def print
            @@printed = true
          end
          def self.printed
            @@printed
          end
        end
        expect(Aquarium::Executor).to receive(:executor_for).with(cmd.command) {TestExecutor}        
        cmd.run
        expect(TestExecutor.printed).to be true
      end
    end
    context 'when -x options is specified' do
      it 'runs #execute method on executor' do
        Aquarium::CommandLine.class_eval {def initialize ; end}
        cmd = Aquarium::CommandLine.new
        cmd.options = {:file=>'file',:adapter=>'mysql',:execute=>true,:callback => cmd}
        cmd.command = :apply_change
        cmd.parameters = ['test:1']
        file = StringIO.new "--#change test:1 Test change number 1\ncreate table test1\n;"
        allow(File).to receive(:dirname) {''}
        allow(File).to receive(:open).and_yield(file)
        client = double()
        expect(Mysql2::Client).to receive(:new) {client}
        class TestExecutor < Aquarium::Executor
          def initialize(database, parser,parameters,options)
          end
          def execute
            @@executed = true
          end
          def self.executed
            @@executed
          end
        end
        expect(Aquarium::Executor).to receive(:executor_for).with(cmd.command) {TestExecutor}        
        cmd.run
        expect(TestExecutor.executed).to be true
      end
      context 'when verbose option is used'
    end
    context 'when exception is raised inside executor' do
      it 'print error to the stdout' do
        Aquarium::CommandLine.class_eval {def initialize ; end}
        cmd = Aquarium::CommandLine.new
        cmd.options = {:file=>'file',:adapter=>'mysql',:execute=>true}
        cmd.command = :apply_change
        cmd.parameters = ['test:1']
        file = StringIO.new "--#change test:1 Test change number 1\ncreate table test1\n;"
        allow(File).to receive(:dirname) {''}
        allow(File).to receive(:open).and_yield(file)
        client = double()
        expect(Mysql2::Client).to receive(:new) {client}
        class TestExecutor < Aquarium::Executor
          def initialize(database, parser,parameters,options)
          end
          def execute
            raise 'error'
          end
        end
        expect(Aquarium::Executor).to receive(:executor_for).with(cmd.command) {TestExecutor}
        expect{cmd.run}.to output('error'.red+"\n").to_stdout
      end
    end
  end
end