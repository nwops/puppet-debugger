require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :environment do
  include_examples 'plugin_tests'
  let(:args) { [''] }

  it 'can display itself' do
    output = plugin.run(args)
    expect(output).to eq("Puppet Environment: #{debugger.puppet_env_name}")
  end
end
