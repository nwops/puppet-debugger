# frozen_string_literal: true

require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :facterdb_filter do
  include_examples 'plugin_tests'
  let(:args) { [] }

  it 'outputs filter' do
    expect(plugin.run(args)).to match(/facterversion/)
  end
end
