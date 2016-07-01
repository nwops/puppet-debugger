require 'spec_helper'
require 'stringio'
describe "PuppetRepl" do

  let(:resource) do
    "service{'httpd': ensure => running}"
  end

  before(:each) do
    repl.handle_input('reset')
  end

  let(:output) do
    StringIO.new('', 'w')
  end

  let(:repl) do
    PuppetRepl::Cli.new(:out_buffer => output)
  end

  let(:input) do
    "file{'/tmp/test2.txt': ensure => present, mode => '0755'}"
  end

  let(:resource_types) do
    repl.parser.evaluate_string(repl.scope, input)
  end

  describe 'native classes' do
    describe 'create' do
      let(:input) do
        'class testfoo {}'
      end
      let(:repl_output) do
        "\n => Puppet::Type::Component {\n  loglevel\e[0;37m => \e[0m\e[0;36mnotice\e[0m,\n      name\e[0;37m => \e[0m\e[0;33m\"Testfoo\"\e[0m,\n     title\e[0;37m => \e[0m\e[0;33m\"Class[Testfoo]\"\e[0m\n}\n"
      end
      it do
        repl.handle_input(input)
        expect(output.string).to eq("\n")
        expect(repl.scope.known_resource_types.hostclasses).to include('testfoo')
      end
      it do
        repl.handle_input(input)
        repl.handle_input("class{'testfoo':}")
        expect(repl.scope.compiler.catalog.classes).to include('testfoo')
        expect(output.string).to eq(repl_output)
      end
      it do
        repl.handle_input(input)
        repl.handle_input("include testfoo")
        expect(repl.scope.compiler.catalog.classes).to include('testfoo')
      end
    end
  end

  describe 'native definitions' do
    describe 'create' do
      let(:input) do
        'define testfoo {}'
      end
      let(:repl_output) do
        "\n => Puppet::Type::Component {\n  loglevel\e[0;37m => \e[0m\e[0;36mnotice\e[0m,\n      name\e[0;37m => \e[0m\e[0;33m\"some_name\"\e[0m,\n     title\e[0;37m => \e[0m\e[0;33m\"Testfoo[some_name]\"\e[0m\n}\n"
      end
      it do
        repl.handle_input(input)
        expect(repl.scope.known_resource_types.definitions.keys).to include('testfoo')
        expect(output.string).to eq("\n")
      end
      it do
        repl.handle_input(input)
        repl.handle_input("testfoo{'some_name':}")
        expect(repl.scope.compiler.resources.collect(&:name)).to include('some_name')
        expect(repl.scope.compiler.resources.collect(&:type)).to include('Testfoo')
        expect(output.string).to eq(repl_output)
      end
    end
  end

  describe 'native functions', :native_functions => true do
    let(:func) do
      <<-EOF
      function repl::bool2http($arg) {
        case $arg {
          false, undef, /(?i:false)/ : { 'Off' }
          true, /(?i:true)/          : { 'On' }
          default               : { "$arg" }
        }
      }
      EOF
    end
    before(:each) do
      repl.handle_input(func)
    end
    describe 'create' do
      it 'shows function' do
        expect(output.string).to eq("\n")
      end
    end
    describe 'run' do
      let(:input) do
        <<-EOF
        repl::bool2http(false)
        EOF
      end
      it do
        repl.handle_input(input)
        expect(output.string).to include('Off')
      end
    end
  end

  describe 'types' do

    describe 'string' do
      let(:input) do
        "String"
      end
      it 'shows type' do
        repl.handle_input(input)
        expect(output.string).to eq("\n => String\n")
      end
    end
    describe 'Array' do
      let(:input) do
        "type_of([1,2,3,4])"
      end
      it 'shows type' do
        repl.handle_input(input)
        expect(output.string).to eq("\n => Tuple[Integer[1, 1], Integer[2, 2], Integer[3, 3], Integer[4, 4]]\n")
      end
    end

  end

  describe 'multiple lines of input' do
    describe '3 lines' do
      let(:input) do
        "$var1 = 'test'\nfile{\"/tmp/${var1}.txt\": ensure => present, mode => '0755'}\nvars"
      end
      it do
        repl.play_back_string(input)
        expect(output.string).to match(/server_facts/) if Puppet.version.to_f >= 4.1
        expect(output.string).to match(/test/)
        expect(output.string).to match(/Puppet::Type::File/)
      end
    end
    describe '2 lines' do
      let(:input) do
        "$var1 = 'test'\n $var2 = 'test2'"
      end
      it do
        repl.play_back_string(input)
        expect(output.string).to eq("\n>> $var1 = 'test'\n => \e[0;33m\"test\"\e[0m\n>>  $var2 = 'test2'\n => \e[0;33m\"test2\"\e[0m\n")
      end
    end
    describe '1 lines' do
      let(:input) do
        "$var1 = 'test'"
      end
      it do
        repl.play_back_string(input)
        expect(output.string).to include("\n>> $var1 = 'test'")
        expect(output.string).to include("\n => \e[0;33m\"test\"")
      end
    end

  end

  describe 'returns a array of resource_types' do
    it 'returns resource type' do
      expect(resource_types.first.class.to_s).to eq('Puppet::Pops::Types::PResourceType')
    end
  end

  describe 'help' do
    let(:input) do
      'help'
    end
    it 'can show the help screen' do
      expected_repl_output = /Type \"exit\", \"functions\", \"vars\", \"krt\", \"facts\", \"resources\", \"classes\",\n     \"play\", \"classification\", \"reset\", or \"help\" for more information.\n\n/
      repl.handle_input(input)
      expect(output.string).to match(/Ruby Version: #{RUBY_VERSION}\n/)
      expect(output.string).to match(/Puppet Version: \d.\d.\d\n/)
      expect(output.string).to match(/Puppet Repl Version: \d.\d.\d\n/)
      expect(output.string).to match(/Created by: NWOps <corey@nwops.io>\n/)
      expect(output.string).to match(expected_repl_output)
    end
  end

  describe 'empty' do
    let(:input) do
      ""
    end
    it 'can run' do
      repl_output = "\n"
      repl.handle_input(input)
      expect(output.string).to eq(repl_output)
    end
    describe 'space' do
      let(:input) do
        " "
      end
      it 'can run' do
        repl_output = "\n"
        repl.handle_input(input)
        expect(output.string).to eq(repl_output)
      end
    end
  end

  describe 'krt' do
    let(:input) do
      "krt"
    end
    it 'can run' do
      repl_output = /hostclasses/
      repl.handle_input(input)
      expect(output.string).to match(repl_output)
    end
  end

  describe 'play' do
    let(:fixtures_file) do
      File.join(fixtures_dir, 'sample_manifest.pp')
    end

    before(:each) do
      allow(repl).to receive(:fetch_url_data).with(file_url + '.txt').and_return(File.read(fixtures_file))
    end

    let(:file_url) do
      'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0'
    end
    it 'file' do
      repl.handle_input("play #{fixtures_file}")
      expect(output.string).to match(/Puppet::Type::File/)
    end
    it 'url' do
      repl.handle_input("play #{file_url}")
      expect(output.string).to match(/Puppet::Type::File/)
    end
  end

  describe 'variables' do
    let(:input) do
      "$file_path = '/tmp/test2.txt'"
    end
    it 'can process a variable' do
      repl.handle_input(input)
      expect(output.string).to match(/\/tmp\/test2.txt/)
    end
  end

  describe 'resource' do
    let(:input) do
      "file{'/tmp/test2.txt': ensure => present, mode => '0755'}"
    end
    it 'can process a resource' do
      repl_output = /Puppet::Type::File/
      repl.handle_input(input)
      expect(output.string).to match(repl_output)
    end
  end

  describe 'bad input' do
    let(:input) do
      "Service{"
    end
    it 'can process' do
      repl_output = "\n => \e[31mSyntax error at end of file\e[0m\n"
      repl.handle_input(input)
      expect(output.string).to eq(repl_output)
    end
  end

  describe 'classification' do
    let(:input) do
      "classification"
    end

    it 'can process a file' do
      repl.handle_input(input)
      expect(output.string).to eq("\n[]\n")
    end
  end

  describe 'reset' do
    let(:input) do
      "file{'/tmp/reset': ensure => present}"
    end

    it 'can process a file' do
      repl_output = /Puppet::Type::File/
      repl.handle_input(input)
      expect(output.string).to match(repl_output)
      repl.handle_input('reset')
      repl.handle_input(input)
      expect(output.string).to match(repl_output)
    end

    describe 'loglevel' do
      it 'has not changed' do
        repl.handle_input(":set loglevel debug")
        expect(Puppet::Util::Log.level).to eq(:debug)
        expect(Puppet::Util::Log.destinations[:buffer].name).to eq(:buffer)
        repl.handle_input('reset')
        expect(Puppet::Util::Log.level).to eq(:debug)
        expect(Puppet::Util::Log.destinations[:buffer].name).to eq(:buffer)
      end
    end
  end

  describe 'map block' do
    let(:input) do
      "['/tmp/test3', '/tmp/test4'].map |String $path| { file{$path: ensure => present} }"
    end
    it 'can process a each block' do
      repl_output = /Puppet::Type::File/
      repl.handle_input(input)
      expect(output.string).to match(repl_output)
    end
  end

  describe 'each block' do
    let(:input) do
      "['/tmp/test3', '/tmp/test4'].each |String $path| { file{$path: ensure => present} }"
    end
    it 'can process a each block' do
      repl.handle_input(input)
      expect(output.string).to match(/\/tmp\/test3/)
      expect(output.string).to match(/\/tmp\/test4/)
    end
  end

  describe 'facts' do
    let(:input) do
      "$::fqdn"
    end
    it 'should be able to resolve fqdn' do
      repl_output = /foo\.example\.com/
      repl.handle_input(input)
      expect(output.string).to match(repl_output)
    end
  end

  describe 'print facts' do
    let(:input) do
      "facts"
    end
    it 'should be able to print facts' do
      repl_output = /kernel/
      repl.handle_input(input)
      expect(output.string).to match(repl_output)
    end
  end

  describe 'print resources' do
    let(:input) do
      'resources'
    end
    it 'should be able to print resources' do
      repl_output = /main/
      repl.handle_input(input)
      expect(output.string).to match(repl_output)
    end
  end

  describe 'print class' do
    let(:input) do
      "Class['settings']"
    end
    it 'should be able to print classes' do
      repl_output = /Settings/
      repl.handle_input(input)
      expect(output.string).to match(repl_output)
    end
  end

  describe 'print classes' do
    let(:input) do
      'resources'
    end
    it 'should be able to print classes' do
      repl_output = /Settings/
      repl.handle_input(input)
      expect(output.string).to match(repl_output)
    end
  end

  describe 'set' do
    let(:input) do
      ":set loglevel debug"
    end
    it 'should set the loglevel' do
      repl_output = /loglevel debug is set/
      repl.handle_input(input)
      expect(output.string).to match(repl_output)
      expect(Puppet::Util::Log.level).to eq(:debug)
      expect(Puppet::Util::Log.destinations[:buffer].name).to eq(:buffer)
    end
  end

  describe 'vars' do
    let(:input) do
      "vars"
    end
    it 'display facts variable' do
      repl_output = /facts/
      repl.handle_input(input)
      expect(output.string).to match(repl_output)
    end
    it 'display server facts variable' do
      repl_output = /server_facts/
      repl.handle_input(input)
      expect(output.string).to match(repl_output) if Puppet.version.to_f >= 4.1
    end
    it 'display serverversion variable' do
      repl_output = /serverversion/
      repl.handle_input(input)
      expect(output.string).to match(repl_output) if Puppet.version.to_f >= 4.1
    end
    it 'display local variable' do
      repl.handle_input("$var1 = 'value1'")
      expect(output.string).to match(/value1/)
      repl.handle_input("$var1")
      expect(output.string).to match(/value1/)
    end
    it 'display productname variable' do
      repl.handle_input("$productname")
      expect(output.string).to match(/VirtualBox/)
    end
  end

  describe 'execute functions' do
    let(:input) do
      "md5('hello')"
    end
    it 'execute md5' do
      repl_output =  /5d41402abc4b2a76b9719d911017c592/
      repl.handle_input(input)
      expect(output.string).to match(repl_output)
    end
    it 'execute swapcase' do
      repl_output =  /HELLO/
      repl.handle_input("swapcase('hello')")
      expect(output.string).to match(repl_output)
    end
  end

  # this code no longer works in puppet 4.5+
  # describe 'unidentified object' do
  #   let(:repl_output) { "\n" }
  #   describe "Node['foot']" do
  #     let(:input) { subject }
  #     it 'returns string' do
  #       repl.handle_input(input)
  #       expect(output.string).to eq(repl_output)
  #     end
  #   end
  #   describe "Puppet::Pops::Types::PStringType" do
  #     let(:input) { subject }
  #     it 'returns string' do
  #       repl.handle_input(input)
  #       expect(output.string).to eq(repl_output)
  #     end
  #   end
  #   describe 'Facts' do
  #     let(:input) { subject }
  #     it 'returns string' do
  #       repl.handle_input(input)
  #       expect(output.string).to eq(repl_output)
  #     end
  #   end
  # end

end
