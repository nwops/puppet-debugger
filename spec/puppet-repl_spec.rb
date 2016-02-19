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
      repl_output = "Puppet Version: 4.3.2\nPuppet Repl Version: 0.0.1\nCreated by: NWOps <corey@nwops.io>\nType \"exit\", \"functions\", \"types\", \"reset\", \"help\" for more information.\n\n"
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

  describe 'each block' do
    let(:input) do
      "['/tmp/test3', '/tmp/test4'].each |String $path| { file{$path: ensure => present} }"
    end
    it 'can process a each block' do
      repl_output = " => [\"/tmp/test3\", \"/tmp/test4\"]\n"
      expect{repl.handle_input(input)}.to output(repl_output).to_stdout
    end
  end
end
