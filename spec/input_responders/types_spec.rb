# frozen_string_literal: true

require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :types do
  include_examples 'plugin_tests'
  let(:args) { [] }

  it 'runs' do
    expect(plugin.run(args)).to match(/service/)
  end

  describe 'types' do
    let(:input) do
      'types'
    end
    it 'runs' do
      debugger.handle_input(input)
      expect(output.string).to match(/service/)
    end
  end
end
