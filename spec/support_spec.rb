# frozen_string_literal: true
require 'spec_helper'
require 'tempfile'

describe 'support' do
  let(:output) do
    StringIO.new('', 'w')
  end

  let(:debugger) do
    PuppetDebugger::Cli.new(out_buffer: output)
  end

  let(:scope) do
    debugger.scope
  end

  describe 'play' do
    before(:each) do
      allow(debugger).to receive(:fetch_url_data).with(file_url + '.txt').and_return(File.read(fixtures_file))
    end

    let(:fixtures_file) do
      File.join(fixtures_dir, 'sample_manifest.pp')
    end

    let(:file_url) do
      'https://gist.github.com/logicminds/f9b1ac65a3a440d562b0'
    end
    let(:input) do
      "play #{file_url}"
    end

    it do
      debugger.handle_input(input)
      expect(output.string).to match(/test/)
      expect(output.string).to match(/Puppet::Type::File/)
    end
  end

  let(:puppet_version) do
    debugger.puppet_lib_dir.scan(debugger.mod_finder).flatten.last
  end

  let(:manifest_file) do
    file = File.open('/tmp/debugger_puppet_manifest.pp', 'w') do |f|
      f.write(manifest_code)
    end
    '/tmp/debugger_puppet_manifest.pp'
  end

  let(:manifest_code) do
    <<-EOF
    file{'/tmp/test.txt': ensure => absent } \n
    notify{'hello_there':} \n
    service{'httpd': ensure => running}\n

    EOF
  end

  after(:each) do
    # manifest_file.close
  end

  context '#function_map' do
    it 'should list functions' do
      func = debugger.function_map["#{puppet_version}::hiera"]
      expect(debugger.function_map).to be_instance_of(Hash)
      expect(func).to eq(name: 'hiera', parent: puppet_version)
    end
  end

  it 'should return a puppet version' do
    expect(puppet_version).to match(/puppet-\d\.\d.\d/)
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

  describe 'convert  url' do
    describe 'unsupported' do
      let(:url) { 'https://bitbuck.com/master/lib/log_helper.rb' }
      let(:converted) { 'https://bitbuck.com/master/lib/log_helper.rb' }
      it do
        expect(debugger.convert_to_text(url)).to eq(converted)
      end
    end
    describe 'gitlab' do
      describe 'blob' do
        let(:url) { 'https://gitlab.com/nwops/pdebugger-web/blob/master/lib/log_helper.rb' }
        let(:converted) { 'https://gitlab.com/nwops/pdebugger-web/raw/master/lib/log_helper.rb' }
        it do
          expect(debugger.convert_to_text(url)).to eq(converted)
        end
      end

      describe 'raw' do
        let(:url) { 'https://gitlab.com/nwops/pdebugger-web/raw/master/lib/log_helper.rb' }
        let(:converted) { 'https://gitlab.com/nwops/pdebugger-web/raw/master/lib/log_helper.rb' }
        it do
          expect(debugger.convert_to_text(url)).to eq(converted)
        end
      end

      describe 'snippet' do
        describe 'not raw' do
          let(:url) { 'https://gitlab.com/snippets/19471' }
          let(:converted) { 'https://gitlab.com/snippets/19471/raw' }
          it do
            expect(debugger.convert_to_text(url)).to eq(converted)
          end
        end

        describe 'raw' do
          let(:url) { 'https://gitlab.com/snippets/19471/raw' }
          let(:converted) { 'https://gitlab.com/snippets/19471/raw' }
          it do
            expect(debugger.convert_to_text(url)).to eq(converted)
          end
        end
      end
    end
    describe 'github' do
      describe 'raw' do
        let(:url) { 'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0/raw' }
        let(:converted) { 'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0/raw' }
        it do
          expect(debugger.convert_to_text(url)).to eq(converted)
        end
      end
      describe 'raw' do
        let(:url) { 'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0' }
        let(:converted) { 'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0.txt' }
        it do
          expect(debugger.convert_to_text(url)).to eq(converted)
        end
      end
      describe 'raw gist' do
        let(:url) { 'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0/raw/c8f6be52da5b2b0eeaabb9aa75832b75793d35d1/controls.pp' }
        let(:converted) { 'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0/raw/c8f6be52da5b2b0eeaabb9aa75832b75793d35d1/controls.pp' }
        it do
          expect(debugger.convert_to_text(url)).to eq(converted)
        end
      end
      describe 'raw non gist' do
        let(:url) { 'https://raw.githubusercontent.com/nwops/puppet-debugger/master/lib/puppet-debugger.rb' }
        let(:converted) { 'https://raw.githubusercontent.com/nwops/puppet-debugger/master/lib/puppet-debugger.rb' }
        it do
          expect(debugger.convert_to_text(url)).to eq(converted)
        end
      end

      describe 'blob' do
        let(:url) { 'https://github.com/nwops/puppet-debugger/blob/master/lib/puppet-debugger.rb' }
        let(:converted) { 'https://github.com/nwops/puppet-debugger/raw/master/lib/puppet-debugger.rb' }
        it do
          expect(debugger.convert_to_text(url)).to eq(converted)
        end
      end

      describe 'gist' do
        let(:url) { 'https://gist.github.com/logicminds/f9b1ac65a3a440d562b0' }
        let(:converted) { 'https://gist.github.com/logicminds/f9b1ac65a3a440d562b0.txt' }
        it do
          expect(debugger.convert_to_text(url)).to eq(converted)
        end
      end
    end
  end
end
