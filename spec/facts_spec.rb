require 'spec_helper'

describe 'facts' do
  let(:debugger) do
    PuppetDebugger::Cli.new(:out_buffer => output)
  end

  let(:puppet_version) do
    '4.5.3'
  end

  let(:facter_version) do
    debugger.default_facter_version
  end

  before(:each) do
    allow(Puppet).to receive(:version).and_return(puppet_version)
  end

  describe '2.4' do
    before(:each) do
      ENV['REPL_FACTERDB_FILTER'] = nil
    end
    let(:puppet_version) do
      '4.2.0'
    end
    it 'returns 2.4' do
      expect(facter_version).to eq('/^2\.4/')
    end
    it 'return default filter' do
      expect(debugger.dynamic_facterdb_filter).to eq("operatingsystem=Fedora and operatingsystemrelease=23 and architecture=x86_64 and facterversion=/^2\\.4/")
    end
    it 'get node_facts' do
      expect(debugger.node_facts).to be_instance_of(Hash)
    end
    it 'has fqdn' do
      expect(debugger.node_facts[:fqdn]).to eq('foo.example.com')
    end
  end

  describe '3.1' do
    before(:each) do
      ENV['REPL_FACTERDB_FILTER'] = nil
    end
    let(:puppet_version) do
      '4.5.3'
    end
    it 'get node_facts' do
      expect(debugger.node_facts).to be_instance_of(Hash)
    end
    it 'has networking fqdn' do
      expect(debugger.node_facts[:networking]['fqdn']).to eq('foo.example.com')
    end
    it 'has fqdn' do
      expect(debugger.node_facts[:fqdn]).to eq('foo.example.com')
    end
    it 'returns 3.1' do
      expect(facter_version).to eq('/^3\.1/')
    end
    it 'return default filter' do
      expect(debugger.dynamic_facterdb_filter).to eq("operatingsystem=Fedora and operatingsystemrelease=23 and architecture=x86_64 and facterversion=/^3\\.1/")
    end
  end

  describe 'default facts' do
    describe 'bad filter' do
      before(:each) do
        ENV['REPL_FACTERDB_FILTER'] = 'facterversion=/^6\.5/'
      end
      it 'return filter' do
        expect(debugger.dynamic_facterdb_filter).to eq("facterversion=/^6\\.5/")
      end
      it 'throws error' do
        expect{debugger.default_facts}.to raise_error(PuppetDebugger::Exception::BadFilter)
      end
    end
    describe 'good filter' do
      before(:each) do
        ENV['REPL_FACTERDB_FILTER'] = 'facterversion=/^3\.1/'
      end
      it 'return filter' do
        expect(debugger.dynamic_facterdb_filter).to eq("facterversion=/^3\\.1/")
      end
    end
  end
end
