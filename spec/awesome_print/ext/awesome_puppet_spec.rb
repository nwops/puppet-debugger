require 'spec_helper'
require 'awesome_print'
require "awesome_print/ext/awesome_puppet"

RSpec.describe do
  let(:output) do
    StringIO.new
  end

  let(:debugger) do
    PuppetDebugger::Cli.new(options)
  end

  let(:options) do
    {
      out_buffer: output
    }
  end

  let(:input) do
    "notify{'ff:gg': }"
  end

  let(:resource_type) do
    debugger.parser.evaluate_string(debugger.scope, input).first
  end

  let(:ral_type) do
    debugger.scope.catalog.resource(resource_type.type_name, resource_type.title).to_ral
  end

  it 'outputs awesomely' do
    expect(ral_type.ai).to include('ff:gg')
  end
end
