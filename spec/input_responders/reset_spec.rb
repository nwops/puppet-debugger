require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :reset do
  include_examples 'plugin_tests'
  let(:args) { [] }

  it 'can process a file' do
    debugger_output = /Puppet::Type::File/
    debugger.handle_input("file{'/tmp/reset': ensure => present}")
    expect(output.string).to match(debugger_output)
    debugger.handle_input('reset')
    expect(output.string).to match(debugger_output)
  end

  describe 'loglevel' do
    it 'has not changed' do
      debugger.handle_input(':set loglevel debug')
      expect(Puppet::Util::Log.level).to eq(:debug)
      expect(Puppet::Util::Log.destinations[:buffer].name).to eq(:buffer)
      plugin.run('reset')
      expect(Puppet::Util::Log.level).to eq(:debug)
      expect(Puppet::Util::Log.destinations[:buffer].name).to eq(:buffer)
    end
  end
end
