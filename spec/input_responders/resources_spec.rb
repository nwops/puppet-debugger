require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :resources do
  include_examples 'plugin_tests'
  let(:args) { }

  it 'should be able to print resources' do
    debugger_output = /main/
    expect(plugin.run(args)).to match(debugger_output)
  end

  it 'filter resources' do
    expect(plugin.run(['settings'])).to match(/Settings/)
  end
end
