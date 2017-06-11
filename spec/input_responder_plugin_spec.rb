require 'spec_helper'
require 'puppet-debugger/input_responder_plugin'

describe :input_responder_plugin do
  let(:output) do
    StringIO.new
  end

  before(:each) do
    allow(plugin).to receive(:run).and_return([])
  end

  let(:debugger) do
    PuppetDebugger::Cli.new({ out_buffer: output }.merge(options))
  end

  let(:options) do
    {}
  end

  let(:plugin) do
    instance = PuppetDebugger::InputResponderPlugin.instance
    instance.debugger = debugger
    instance
  end

  it 'works' do
    expect(plugin.run([])).to eq([])
  end

  {scope: Puppet::Parser::Scope, node: Puppet::Node, facts: Puppet::Node::Facts,
   environment: Puppet::Node::Environment, function_map: Hash,
  compiler: Puppet::Parser::Compiler, catalog: Puppet::Resource::Catalog}.each do |name, klass|
    it "can access #{name}" do
      expect(plugin.send(name).class).to be klass
    end
  end

  [:add_hook, :handle_input, :delete_hook, :handle_input].each do |name|
    it "responds to method #{name}" do
      expect(plugin.respond_to?(name)).to eq(true)
    end
  end

end