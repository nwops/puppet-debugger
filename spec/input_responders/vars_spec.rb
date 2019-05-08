require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'
require 'pluginator'

describe :vars do
  include_examples 'plugin_tests'
  let(:args) { [] }

  it 'display facts variable' do
    debugger_output = /facts/
    output = plugin.run(args)
    expect(output).to match(debugger_output)
  end
  it 'display server facts variable' do
    debugger_output = /server_facts/
    expect(plugin.run(args)).to match(debugger_output) if Puppet.version.to_f >= 4.1
  end
  it 'display serverversion variable' do
    debugger_output = /serverversion/
    expect(plugin.run(args)).to match(debugger_output) if Puppet.version.to_f >= 4.1
  end
  it 'display local variable' do
    debugger.handle_input("$var1 = 'value1'")
    expect(plugin.run(args)).to match(/value1/)
  end

  describe 'resource' do
    let(:input) do
      "$service_require = Package['httpd']"
    end
    it 'can process a resource' do
      debugger_output = /Facts/
      debugger.handle_input(input)
      expect(plugin.run(args)).to match(debugger_output)
    end
  end

  describe 'list variables' do
    let(:input) do
      <<-EOF
      class test( $param1 = "files", $param2 = $param1 ) {}
      include test
      EOF
    end
    it 'ls test' do
      debugger.handle_input(input)
      out = plugin.run(['test'])
      expect(out).to include('"param1"')
      expect(out).to include('"param2"')
    end
   

  end
end
