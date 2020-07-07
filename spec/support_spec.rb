# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

describe 'support' do
  let(:output) do
    StringIO.new
  end

  let(:debugger) do
    PuppetDebugger::Cli.new(out_buffer: output)
  end

  let(:scope) do
    debugger.scope
  end

  let(:puppet_version) do
    debugger.puppet_lib_dir.scan(debugger.mod_finder).flatten.last
  end

  let(:manifest_file) do
    File.open('/tmp/debugger_puppet_manifest.pp', 'w') do |f|
      f.write(manifest_code)
    end
    '/tmp/debugger_puppet_manifest.pp'
  end

  let(:manifest_code) do
    <<-OUT
    file{'/tmp/test.txt': ensure => absent } \n
    notify{'hello_there':} \n
    service{'httpd': ensure => running}\n

    OUT
  end

  after(:each) do
    # manifest_file.close
  end

  it 'should return a puppet version' do
    expect(puppet_version).to match(/puppet-\d\.\d+.\d/)
  end

  it 'should return lib dirs' do
    expect(debugger.lib_dirs.count).to be >= 1
  end

  it 'should return module dirs' do
    expect(debugger.modules_paths.count).to be >= 1
  end

  it 'should return a list of default facts' do
    expect(debugger.default_facts.values).to be_instance_of(Hash)
    expect(debugger.default_facts.values['fqdn']).to eq('foo.example.com')
  end

  it 'should return a list of facts' do
    expect(debugger.node.facts.values).to be_instance_of(Hash)
    expect(debugger.node.facts.values['fqdn']).to eq('foo.example.com')
  end
end
