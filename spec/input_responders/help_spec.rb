require 'spec_helper'
require 'puppet-debugger/plugin_test_helper'

describe :help do
  include_examples "plugin_tests"
  let(:args) { [] }

  it 'can show the help screen' do
    output = plugin.run(args)
    expected_debugger_output = /Type \"commands\" for a list of debugger commands\nor \"help\" to show the help screen.\n\n/
    expect(output).to match(/Ruby Version: #{RUBY_VERSION}\n/)
    expect(output).to match(/Puppet Version: \d.\d\d?.\d\n/)
    expect(output).to match(/Puppet Debugger Version: \d.\d.\d\n/)
    expect(output).to match(/Created by: NWOps <corey@nwops.io>\n/)
    expect(output).to match(expected_debugger_output)
  end
end