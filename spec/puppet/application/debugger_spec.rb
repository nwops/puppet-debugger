#! /usr/bin/env ruby
require 'spec_helper'

require 'puppet/application/debugger'

describe Puppet::Application::Debugger do
  let(:debugger) do
    Puppet::Application[:debugger]
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

  it "declare a main command" do
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

  # use --stdin
  #  use facterdb
  # not use facterdb
  # use execute
  # play
  # runonce
  # test


  # it 'create a node' do
  #   require 'pry'; binding.pry
  #   expect(node).to be_a(Puppet::Node::Environment)
  # end
  #
  # it 'create a scope' do
  #   expect(scope).to be_a(Puppet::Node::Environment)
  # end

end
