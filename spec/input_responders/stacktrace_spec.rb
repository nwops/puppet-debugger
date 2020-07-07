# frozen_string_literal: true

require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :stacktrace do
  include_examples 'plugin_tests'
  let(:args) {}

  it 'should be able to print stacktrace' do
    debugger_output = /stacktrace\snot\savailable/
    expect(plugin.run(args)).to match(debugger_output)
  end
end
