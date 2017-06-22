require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :resources do
  include_examples 'plugin_tests'
  let(:args) { ["resources"] }

  it 'should be able to print resources' do
    debugger_output = /main/
    expect(plugin.run(args)).to match(debugger_output)
  end
end
