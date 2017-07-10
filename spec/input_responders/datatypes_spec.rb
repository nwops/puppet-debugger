require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :datatypes do
  include_examples 'plugin_tests'
  let(:args) { [] }

  it 'handle datatypes' do
    output = plugin.run(args)
    if Gem::Version.new(Puppet.version) < Gem::Version.new('4.5.0')
      expect(output).to eq("[]")
    else
      expect(output).to match(/.*Array.*/)
    end
  end

  it 'returns core datatypes' do
    expect(plugin.all_data_types.count).to be >= 30 if supports_datatypes?
  end

  it 'returns environment datatypes' do
    expect(plugin.environment_data_types.count).to be >= 0
  end
end
