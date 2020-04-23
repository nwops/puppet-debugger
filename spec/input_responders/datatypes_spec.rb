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
    if Gem::Version.new(Puppet.version) >= Gem::Version.new('6.0.0')
      expect(plugin.all_data_types.count).to be >= 19 if supports_datatypes?
    else
      expect(plugin.all_data_types.count).to be >= 30 if supports_datatypes?
    end

  end

  it 'returns environment datatypes' do
    expect(plugin.environment_data_types.count).to be >= 0
  end

  it 'search datatypes' do
    output = plugin.run(['integer'])
    expect(output.split("Integer").count).to be >= 2
  end
end
