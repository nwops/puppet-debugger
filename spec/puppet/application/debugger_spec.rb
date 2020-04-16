# frozen_string_literal: true

require 'spec_helper'
require 'puppet/application/debugger'

describe Puppet::Application::Debugger do
  let(:debugger) do
    Puppet::Application::Debugger.new(command_line)
  end

  # ideally, we should only be providing args in stead of mocking the options
  # however during a text, the options in the puppet application are not merged from 
  # the command line opts so the args never get passed through to options
  let(:args) do
    []
  end

  let(:command_line) do
    Puppet::Util::CommandLine.new('puppet', ['debugger', args].flatten)
  end

  let(:environment) do
    debugger.create_environment(nil)
  end

  let(:node) do
    debugger.create_node(environment)
  end

  let(:scope) do
    debugger.create_node(node)
  end

  before :each do
    debugger.initialize_app_defaults
  end

  it 'declare a main command' do
    expect(debugger).to respond_to(:main)
  end

  it 'start the debugger' do
    expect(PuppetDebugger::Cli).to receive(:start_without_stdin)
    debugger.run_command
  end

  it 'start the debugger' do
    expect(PuppetDebugger::Cli).to receive(:start_without_stdin)
    debugger.run_command
  end

  it 'create an environment' do
    expect(environment).to be_a(Puppet::Node::Environment)
  end

  it 'shows describtion' do
    expect(debugger.help).to match(/^puppet-debugger\([^\)]+\) -- (.*)$/)
  end

  describe 'with facterdb' do
    before(:each) do
    end
    it 'run md5 function' do
      allow(debugger).to receive(:options).and_return(code: "md5('sdafsd')", quiet: true, run_once: true, use_facterdb: true)
      expect { debugger.run_command }.to output(/569ebc3d91672e7d3dce25de1684d0c9/).to_stdout
    end

    it 'assign variable' do
      allow(debugger).to receive(:options).and_return(code: "$var1 = 'blah'", quiet: true, run_once: true, use_facterdb: true)
      expect { debugger.run_command }.to output(/"blah"/).to_stdout
    end

    describe 'can reset correctly' do
      let(:input) do
        <<-EOF
$var1 = 'dsfasd'
$var1
reset
$var1 = '111111'
$var1
        EOF
      end

      it 'assign variable' do
        allow(debugger).to receive(:options).and_return(code: input, quiet: true, run_once: true, use_facterdb: true)
        expect { debugger.run_command }.to output(/\"111111\"/).to_stdout
      end
    end
  end

  describe 'without facterdb' do
    
    it 'run md5 function' do
      allow(debugger).to receive(:options).and_return(code: "md5('sdafsd')", quiet: true, run_once: true, use_facterdb: false)
      expect { debugger.run_command }.to output(/569ebc3d91672e7d3dce25de1684d0c9/).to_stdout
    end

    it 'assign variable' do
      allow(debugger).to receive(:options).and_return(code: "$var1 = 'blah'", quiet: true, run_once: true, use_facterdb: false)
      expect { debugger.run_command }.to output(/"blah"/).to_stdout
    end

    describe 'import a catalog' do
      let(:args) do
        [
          '--quiet', '--run_once', "--code='resources'",
          "--catalog=#{File.expand_path(File.join(fixtures_dir, 'pe-xl-core-0.puppet.vm.json'))}"
        ]
      end
      it 'list resources in catalog' do
        allow(debugger).to receive(:options).and_return(code: "resources",
          quiet: true, run_once: true, use_facterdb: true, 
          catalog: File.expand_path(File.join(fixtures_dir, 'pe-xl-core-0.puppet.vm.json')))
        expect { debugger.run_command }.to output(/Puppet_enterprise/).to_stdout
      end
    end

    describe 'can reset correctly' do
      let(:input) do
        <<-EOF
$var1 = 'dsfasd'
$var1
reset
$var1 = '111111'
$var1
        EOF
      end

      it 'assign variable' do
        allow(debugger).to receive(:options).and_return(code: input, quiet: true, run_once: true, use_facterdb: false)
        expect { debugger.run_command }.to output(/\"111111\"/).to_stdout
      end
    end
  end
end
