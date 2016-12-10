# frozen_string_literal: true
require 'spec_helper'
require 'stringio'
describe 'PuppetDebugger' do
  let(:resource) do
    "service{'httpd': ensure => running}"
  end

  before(:each) do
    debugger.handle_input('reset')
  end

  let(:output) do
    StringIO.new('', 'w')
  end

  let(:debugger) do
    PuppetDebugger::Cli.new(out_buffer: output)
  end

  let(:input) do
    "file{'/tmp/test2.txt': ensure => present, mode => '0755'}"
  end

  let(:resource_types) do
    debugger.parser.evaluate_string(debugger.scope, input)
  end

  describe 'remote node' do
    let(:node_obj) do
      YAML.load_file(File.join(fixtures_dir, 'node_obj.yaml'))
    end
    let(:node_name) do
      'puppetdev.localdomain'
    end
    before :each do
      allow(debugger).to receive(:get_remote_node).with(node_name).and_return(node_obj)
      debugger.handle_input(":set node #{node_name}")
    end

    describe 'set' do
      it 'sends message about resetting' do
        expect(output.string).to eq("\n => Resetting to use node puppetdev.localdomain\n")
      end

      it 'return node name' do
        output.reopen # removes previous message
        debugger.handle_input('$::hostname')
        expect(output.string).to match(/puppetdev.localdomain/)
      end

      it 'return classification' do
        output.reopen # removes previous message
        debugger.handle_input('classification')
        expect(output.string).to match(/stdlib/)
      end
    end

    describe 'facts' do
      let(:input) do
        "$::facts['os']['family'].downcase == 'debian'"
      end
      it 'fact evaulation should return false' do
        debugger_output = /false/
        debugger.handle_input(input)
        expect(output.string).to match(debugger_output)
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
        expect { debugger.node.name }.to raise_error(PuppetDebugger::Exception::UndefinedNode)
      end
    end

    it 'set node name' do
      expect(debugger.remote_node_name = 'puppetdev.localdomain').to eq('puppetdev.localdomain')
    end

    describe 'print classes' do
      let(:input) do
        'resources'
      end
      it 'should be able to print classes' do
        debugger_output = /Settings/
        debugger.handle_input(input)
        expect(output.string).to match(debugger_output)
      end
    end

    describe 'vars' do
      let(:input) do
        'vars'
      end
      it 'display facts variable' do
        debugger_output = /facts/
        debugger.handle_input(input)
        expect(output.string).to match(debugger_output)
      end
      it 'display server facts variable' do
        debugger_output = /server_facts/
        debugger.handle_input(input)
        expect(output.string).to match(debugger_output) if Puppet.version.to_f >= 4.1
      end
      it 'display server facts variable' do
        debugger_output = /server_facts/
        debugger.handle_input(input)
        expect(output.string).to match(debugger_output) if Puppet.version.to_f >= 4.1
      end
      it 'display local variable' do
        debugger.handle_input("$var1 = 'value1'")
        expect(output.string).to match(/value1/)
        debugger.handle_input('$var1')
        expect(output.string).to match(/value1/)
      end
      it 'display productname variable' do
        debugger.handle_input('$productname')
        expect(output.string).to match(/VMware Virtual Platform/)
      end
    end

    describe 'execute functions' do
      let(:input) do
        "md5('hello')"
      end
      it 'execute md5' do
        debugger_output = /5d41402abc4b2a76b9719d911017c592/
        debugger.handle_input(input)
        expect(output.string).to match(debugger_output)
      end
      it 'execute swapcase' do
        debugger_output = /HELLO/
        debugger.handle_input("swapcase('hello')")
        expect(output.string).to match(debugger_output)
      end
    end

    describe 'reset' do
      let(:input) do
        "file{'/tmp/reset': ensure => present}"
      end

      it 'can process a file' do
        debugger_output = /Puppet::Type::File/
        debugger.handle_input(input)
        expect(output.string).to match(debugger_output)
        debugger.handle_input('reset')
        debugger.handle_input(input)
        expect(output.string).to match(debugger_output)
      end
    end

    describe 'classification' do
      let(:input) do
        'classification'
      end

      it 'shows certificate_authority_host' do
        debugger.handle_input(input)
        expect(output.string).to match(/stdlib/)
      end
    end
  end
end
