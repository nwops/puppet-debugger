require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :classes do
  include_examples 'plugin_tests'
  let(:input) do
    'classes'
  end

  it 'should be able to print classes' do
    expect(plugin.run([])).to match(/settings/)
  end

  it 'should be able to print classes with handle input' do
    debugger_output = /settings/
    expect(plugin.run(['settings'])).to match(debugger_output)
  end
end
