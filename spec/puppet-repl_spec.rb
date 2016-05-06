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
      expected_repl_output = /Type \"exit\", \"functions\", \"vars\", \"krt\", \"facts\", \"resources\", \"classes\",\n     \"play\",\"reset\", or \"help\" for more information.\n\n/
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
      repl_output = " => \n"
      repl.handle_input(input)
      expect(output.string).to eq(repl_output)
    end
    describe 'space' do
      let(:input) do
        " "
      end
      it 'can run' do
        repl_output = " => \n"
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
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'play' do
    let(:fixtures_file) do
      File.join(fixtures_dir, 'sample_manifest.pp')
    end

    let(:file_url) do
      'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0/raw'
    end
    it 'file' do
      expect{repl.handle_input("play #{fixtures_file}")}.to output(/Puppet::Type::File/).to_stdout
    end
    it 'url' do
      expect{repl.handle_input("play #{file_url}")}.to output(/Puppet::Type::File/).to_stdout
    end

  end

  describe 'variables' do
    let(:input) do
      "$file_path = '/tmp/test2.txt'"
    end
    it 'can process a variable' do
      repl_output = " => \e[0;33m\"/tmp/test2.txt\"\e[0m\n"
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'resource' do
    let(:input) do
      "file{'/tmp/test2.txt': ensure => present, mode => '0755'}"
    end
    it 'can process a resource' do
      repl_output = /Puppet::Type::File/
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'bad input' do
    let(:input) do
      "Service{"
    end
    it 'can process' do
      repl_output = " => \e[31mSyntax error at end of file\e[0m\n"
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'bad resources' do
    let(:input) do
      "file{'/tmp/test': ensure => present, mode => 755}"
    end
    xit 'can process' do  #this fails with puppet 3.8 and passes with others
      repl_output = /must be a string/
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'reset' do
    let(:input) do
      "file{'/tmp/reset': ensure => present}"
    end

    it 'can process a file' do
      repl_output = /Puppet::Type::File/
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
      repl.handle_input('reset')
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end

    describe 'loglevel' do
      it 'has not changed' do
        repl.handle_input(":set loglevel debug")
        expect(Puppet::Util::Log.level).to eq(:debug)
        expect(Puppet::Util::Log.destinations[:console].name).to eq(:console)
        repl.handle_input('reset')
        expect(Puppet::Util::Log.level).to eq(:debug)
        expect(Puppet::Util::Log.destinations[:console].name).to eq(:console)
      end
    end
  end

  describe 'map block' do
    let(:input) do
      "['/tmp/test3', '/tmp/test4'].map |String $path| { file{$path: ensure => present} }"
    end
    it 'can process a each block' do
      repl_output = /Puppet::Type::File/
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'each block' do
    let(:input) do
      "['/tmp/test3', '/tmp/test4'].each |String $path| { file{$path: ensure => present} }"
    end
    let(:repl_output) do
      " => [\n    \e[1;37m[0] \e[0m\e[0;33m\"/tmp/test3\"\e[0m,\n    \e[1;37m[1] \e[0m\e[0;33m\"/tmp/test4\"\e[0m\n]\n"
    end
    it 'can process a each block' do
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'facts' do
    let(:input) do
      "$::fqdn"
    end
    it 'should be able to resolve fqdn' do
      repl_output = " => \e[0;33m\"foo.example.com\"\e[0m\n"
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'print facts' do
    let(:input) do
      "facts"
    end
    it 'should be able to print facts' do
      expect{repl.handle_input(input)}.to output(/kernel/).to_stdout
    end
  end

  describe 'print resources' do
    let(:input) do
      'resources'
    end
    it 'should be able to print resources' do
      expect{repl.handle_input(input)}.to output(/main/).to_stdout
    end
  end

  describe 'print classes' do
    let(:input) do
      'resources'
    end
    it 'should be able to print classes' do
      expect{repl.handle_input(input)}.to output(/Settings/).to_stdout
    end
  end

  describe 'set' do
    let(:input) do
      ":set loglevel debug"
    end
    it 'should set the loglevel' do
      output = /loglevel debug is set/
      expect{repl.handle_input(input)}.to output(output).to_stdout
      expect(Puppet::Util::Log.level).to eq(:debug)
      expect(Puppet::Util::Log.destinations[:console].name).to eq(:console)
    end
  end

  describe 'vars' do
    let(:input) do
      "vars"
    end
    it 'display facts variable' do
      output = /facts/
      expect{repl.handle_input(input)}.to output(output).to_stdout
    end
    it 'display local variable' do
      expect{repl.handle_input("$var1 = 'value1'")}.to output(/value1/).to_stdout
      expect{repl.handle_input("$var1")}.to output(/value1/).to_stdout

    end
    it 'display productname variable' do
      expect{repl.handle_input("$productname")}.to output(/VirtualBox/).to_stdout
    end
  end

  describe 'execute functions' do
    let(:input) do
      "md5('hello')"
    end
    it 'execute md5' do
      sum = " => \e[0;33m\"5d41402abc4b2a76b9719d911017c592\"\e[0m\n"
      expect{repl.handle_input(input)}.to output(sum).to_stdout
    end
    it 'execute swapcase' do
      output = /HELLO/
      expect{repl.handle_input("swapcase('hello')")}.to output(output).to_stdout
    end

  end
end
