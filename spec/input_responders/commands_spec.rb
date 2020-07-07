# frozen_string_literal: true

require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :commands do
  include_examples 'plugin_tests'
  let(:args) { [] }

  it do
    expect(plugin.run(args)).to match(/environment/)
  end

  it 'run a plugin command' do
    debugger.handle_input('help')
    expect(output.string).to match(/Type "commands" for a list of debugger commands/)
  end

  it 'show error when command does not exist' do
    debugger.handle_input('helpp')
    expect(output.string).to match(/invalid command helpp/)
  end
end
