#! /usr/bin/env ruby
# frozen_string_literal: true
require 'spec_helper'

require 'puppet/application/debugger'

describe Puppet::Application::Debugger do
  let(:debugger) do
    Puppet::Application::Debugger.new(command_line)
  end

  let(:args) do
    []
  end

  let(:command_line) do
    Puppet::Util::CommandLine.new('debugger', args)
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
  end

  describe 'without facterdb' do
    before(:each) do
    end
    it 'run md5 function' do
      allow(debugger).to receive(:options).and_return(code: "md5('sdafsd')", quiet: true, run_once: true, use_facterdb: false)
      expect { debugger.run_command }.to output(/569ebc3d91672e7d3dce25de1684d0c9/).to_stdout
    end
    it 'assign variable' do
      allow(debugger).to receive(:options).and_return(code: "$var1 = 'blah'", quiet: true, run_once: true, use_facterdb: false)
      expect { debugger.run_command }.to output(/"blah"/).to_stdout
    end
  end
end
