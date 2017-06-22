require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :commands do
  include_examples 'plugin_tests'
  let(:args) { [] }

  it do
    expect(plugin.run(args)).to match(/environment/)
  end
end
