require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :functions do
  include_examples 'plugin_tests'
  let(:input) do
    "md5('hello')"
  end
  it 'execute md5' do
    debugger_output = /5d41402abc4b2a76b9719d911017c592/
    debugger.handle_input(input)
    expect(output.string).to match(debugger_output)
  end
  it 'execute swapcase' do
    debugger_output = /HELLO/
    debugger.handle_input("swapcase('hello')")
    expect(output.string).to match(debugger_output)
  end
end
