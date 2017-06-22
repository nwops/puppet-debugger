require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :facts do
  include_examples 'plugin_tests'
  let(:args) { ['$::fqdn', 'facts'] }

  it 'should be able to resolve fqdn' do
    debugger_output = /foo\.example\.com/
    output = plugin.run(args[0])
    expect(output).to match(debugger_output)
  end

  it 'should be able to print facts' do
    debugger_output = /kernel/
    plugin.run(args[1])
    expect(plugin.run(args[1])).to match(debugger_output)
  end
end
