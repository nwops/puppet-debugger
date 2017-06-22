require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :classes do
  include_examples 'plugin_tests'
  let(:args) { [] }

    let(:input) do
      'classes'
    end

    it 'should be able to print classes' do
      expect(plugin.run(args)).to match(/settings/)
    end

    it 'should be able to print classes with handle input' do
      debugger_output = /settings/
      debugger.handle_input(input)
      expect(output.string).to match(debugger_output)
    end
end
