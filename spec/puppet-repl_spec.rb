require 'spec_helper'

describe "PuppetRepl" do
  let(:resource) do
    "service{'httpd': ensure => running}"
  end

  let(:repl) do
    PuppetRepl::Cli.new
  end

  describe 'help' do
    let(:input) do
      'help'
    end
    it 'can show the help screen' do
      repl_output = "Ruby Version: #{RUBY_VERSION}\nPuppet Version: 4.3.2\nPuppet Repl Version: 0.0.2\nCreated by: NWOps <corey@nwops.io>\nType \"exit\", \"functions\", \"types\", \"reset\", \"help\" for more information.\n\n"
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'variables' do
    let(:input) do
      "$file_path = '/tmp/test2.txt'"
    end
    it 'can process a variable' do
      repl_output = " => /tmp/test2.txt\n"
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'resource' do
    let(:input) do
      "file{'/tmp/test2.txt': ensure => present, mode => '0755'}"
    end
    it 'can process a resource' do
      repl_output = " => File['/tmp/test2.txt']\n"
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'bad input' do
    let(:input) do
      "Service{"
    end
    it 'can process' do
      repl_output = " => Syntax error at end of file\n"
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'reset' do
    before(:each) do
      repl.handle_input(input)
    end
    let(:input) do
      "file{'/tmp/reset': ensure => present}"
    end

    it 'can process a each block' do
      repl.handle_input('reset')
      repl_output = " => File['/tmp/reset']\n"
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'each block' do
    let(:input) do
      "['/tmp/test3', '/tmp/test4'].each |String $path| { file{$path: ensure => present} }"
    end
    it 'can process a each block' do
      repl_output = " => [\"/tmp/test3\", \"/tmp/test4\"]\n"
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'facts' do
    let(:input) do
      "$::fqdn"
    end
    it 'should be able to resolve fqdn' do
      repl_output = " => foo.example.com\n"
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end

  describe 'print facts' do
    let(:input) do
      "facts"
    end
    it 'should be able to print facts' do
      expect{repl.handle_input(input)}.to output(/"kernel": "Linux"/).to_stdout
    end
  end
end
