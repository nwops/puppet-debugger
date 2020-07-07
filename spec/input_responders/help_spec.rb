# frozen_string_literal: true

require 'spec_helper'
require 'puppet-debugger/plugin_test_helper'

describe :help do
  include_examples 'plugin_tests'
  let(:args) { [] }

  let(:help_output) do
    plugin.run(args)
  end

  it 'can show the help screen' do
    expected_debugger_output = /Type \"commands\" for a list of debugger commands\nor \"help\" to show the help screen.\n\n/
    expect(help_output).to match(expected_debugger_output)
  end

  it 'show puppet version' do
    expect(help_output).to match(/Puppet Version: \d.\d\d?.\d+\n/)
  end

  it 'show ruby version' do
    expect(help_output).to match(/Ruby Version: #{RUBY_VERSION}\n/)
  end

  it 'show debugger version' do
    expect(help_output).to match(/Puppet Debugger Version: \d.\d\d?.\d.*+\n/)
  end

  it 'show created by' do
    expect(help_output).to match(/Created by: NWOps <corey@nwops.io>\n/)
  end
end
