require 'spec_helper'


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
    expect(repl.module_dirs.count).to be >= 1
  end

  it 'should return a list of facts' do
    expect(repl.facts).to be_instance_of(Hash)
    expect(repl.facts[:fqdn]).to eq('foo.example.com')
  end



end
