require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe 'set' do
  include_examples 'plugin_tests'
  let(:input) do
    ':set loglevel debug'
  end

  it 'should set the loglevel' do
    debugger_output = /loglevel debug is set/
    debugger.handle_input(input)
    expect(output.string).to match(debugger_output)
    expect(Puppet::Util::Log.level).to eq(:debug)
    expect(Puppet::Util::Log.destinations[:buffer].name).to eq(:buffer)
  end
end
