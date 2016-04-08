require 'spec_helper'
require 'tempfile'

describe 'support' do

  let(:repl) do
    PuppetRepl::Cli.new
  end

  let(:scope) do
    repl.scope
  end

  let(:puppet_version) do
    repl.mod_finder.match(repl.puppet_lib_dir)[1]
  end

  let(:manifest_file) do
    file = File.open('/tmp/repl_puppet_manifest.pp', 'w') do |f|
      f.write(manifest_code)
    end
    '/tmp/repl_puppet_manifest.pp'
  end

  let(:manifest_code) do
    <<-EOF
    file{'/tmp/test.txt': ensure => absent } \n
    notify{'hello_there':} \n
    service{'httpd': ensure => running}\n

    EOF

  end

  after(:each) do
    #manifest_file.close
  end

  context '#function_map' do

    it 'should list functions' do
      func = repl.function_map["#{puppet_version}::hiera"]
      expect(repl.function_map).to be_instance_of(Hash)
      expect(func).to eq({:name => 'hiera', :parent => puppet_version})
    end

  end

  it 'should return a puppet version' do
    expect(puppet_version).to match(/puppet-\d\.\d.\d/)
  end

  it 'should return lib dirs' do
    expect(repl.lib_dirs.count).to be >= 1
  end

  it 'should return module dirs' do
    expect(repl.modules_paths.count).to be >= 1
  end

  it 'should return a list of default facts' do
    expect(repl.default_facts.values).to be_instance_of(Hash)
    expect(repl.default_facts.values['fqdn']).to eq('foo.example.com')
  end

  it 'should return a list of facts' do
    expect(repl.node.facts.values).to be_instance_of(Hash)
    expect(repl.node.facts.values['fqdn']).to eq('foo.example.com')
  end

end
