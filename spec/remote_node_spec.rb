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

  describe 'remote node' do
    let(:node_obj) do
      YAML.load_file(File.join(fixtures_dir, 'node_obj.yaml'))
    end
    let(:node_name) do
      'puppetdev.localdomain'
    end
    before :each do
      allow(repl).to receive(:get_remote_node).with(node_name).and_return(node_obj)
      repl.handle_input(":set node #{node_name}")
    end

    describe 'set' do
      it 'sends message about resetting' do
        expect(output.string).to eq("\n => Resetting to use node puppetdev.localdomain\n")
      end

      it "return node name" do
        output.reopen # removes previous message
        repl.handle_input('$::hostname')
        expect(output.string).to match(/puppetdev.localdomain/)
      end

      it "return classification" do
        output.reopen # removes previous message
        repl.handle_input('classification')
        expect(output.string).to match(/stdlib/)
      end
    end

    describe 'facts' do
      let(:input) do
        "$::facts['os']['family'].downcase == 'debian'"
      end
      it 'fact evaulation should return false' do
        repl_output = /false/
        repl.handle_input(input)
        expect(output.string).to match(repl_output)
      end

    end
    describe 'use defaults when invalid' do
      let(:node_obj) do
        YAML.load_file(File.join(fixtures_dir, 'invalid_node_obj.yaml'))
      end
      let(:node_name) do
        'invalid.localdomain'
      end
      it 'name' do
        expect{repl.node.name}.to raise_error(PuppetRepl::Exception::UndefinedNode)
      end
    end

    it 'set node name' do
      expect(repl.remote_node_name = 'puppetdev.localdomain').to eq("puppetdev.localdomain")
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
      it 'display server facts variable' do
        repl_output = /server_facts/
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
        expect(output.string).to match(/VMware Virtual Platform/)
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
    end

    describe 'classification' do
      let(:input) do
        "classification"
      end

      it 'shows certificate_authority_host' do
        repl.handle_input(input)
        expect(output.string).to match(/stdlib/)
      end
    end
  end
end
