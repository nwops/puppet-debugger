require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :classification do
  include_examples 'plugin_tests'
  let(:args) { [] }

  it 'can process a file' do
    expect(plugin.run(args)).to eq("[]")
  end

  it 'can process a file from handle input' do
    debugger.handle_input('classification')
    expect(output.string).to eq(" => []\n")
  end
end
