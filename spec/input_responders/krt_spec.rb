require 'spec_helper'
require 'puppet-debugger/plugin_test_helper'

describe :krt do
  include_examples "plugin_tests"
  let(:args) { [] }

  it 'works' do
    expect(plugin.run(args)).to match(/hostclasses/)
  end

end