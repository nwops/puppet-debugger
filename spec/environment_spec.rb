# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
describe 'environment' do
  let(:output) do
    StringIO.new('', 'w')
  end

  let(:debugger) do
    PuppetDebugger::Cli.new(out_buffer: output)
  end

  it 'environment returns object with properties' do
    expect(debugger.puppet_environment).to_not eq nil
    expect(debugger.default_site_manifest).to eq(File.join(Puppet[:environmentpath],
                                                           Puppet[:environment], 'manifests', 'site.pp'))
  end

  it 'full module path' do
    expect(debugger.modules_paths.count).to be >= 2
  end
end
