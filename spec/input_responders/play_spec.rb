require 'plugins/puppet-debugger/input_responders/play'
require 'spec_helper'

describe :play do

  let(:command) do
    instance = PuppetDebugger::InputResponders::Play.instance
    instance.debugger = debugger
    instance
  end

  let(:output) do
    StringIO.new
  end

  let(:debugger) do
    PuppetDebugger::Cli.new({ out_buffer: output }.merge(options))
  end

  let(:options) do
    {}
  end

  describe 'convert  url' do
    describe 'unsupported' do
      let(:url) { 'https://bitbuck.com/master/lib/log_helper.rb' }
      let(:converted) { 'https://bitbuck.com/master/lib/log_helper.rb' }
      it do
        expect(command.convert_to_text(url)).to eq(converted)
      end
    end
    describe 'gitlab' do
      describe 'blob' do
        let(:url) { 'https://gitlab.com/nwops/pdebugger-web/blob/master/lib/log_helper.rb' }
        let(:converted) { 'https://gitlab.com/nwops/pdebugger-web/raw/master/lib/log_helper.rb' }
        it do
          expect(command.convert_to_text(url)).to eq(converted)
        end
      end

      describe 'raw' do
        let(:url) { 'https://gitlab.com/nwops/pdebugger-web/raw/master/lib/log_helper.rb' }
        let(:converted) { 'https://gitlab.com/nwops/pdebugger-web/raw/master/lib/log_helper.rb' }
        it do
          expect(command.convert_to_text(url)).to eq(converted)
        end
      end

      describe 'snippet' do
        describe 'not raw' do
          let(:url) { 'https://gitlab.com/snippets/19471' }
          let(:converted) { 'https://gitlab.com/snippets/19471/raw' }
          it do
            expect(command.convert_to_text(url)).to eq(converted)
          end
        end

        describe 'raw' do
          let(:url) { 'https://gitlab.com/snippets/19471/raw' }
          let(:converted) { 'https://gitlab.com/snippets/19471/raw' }
          it do
            expect(command.convert_to_text(url)).to eq(converted)
          end
        end
      end
    end
    describe 'github' do
      describe 'raw' do
        let(:url) { 'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0/raw' }
        let(:converted) { 'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0/raw' }
        it do
          expect(command.convert_to_text(url)).to eq(converted)
        end
      end
      describe 'raw' do
        let(:url) { 'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0' }
        let(:converted) { 'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0.txt' }
        it do
          expect(command.convert_to_text(url)).to eq(converted)
        end
      end
      describe 'raw gist' do
        let(:url) { 'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0/raw/c8f6be52da5b2b0eeaabb9aa75832b75793d35d1/controls.pp' }
        let(:converted) { 'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0/raw/c8f6be52da5b2b0eeaabb9aa75832b75793d35d1/controls.pp' }
        it do
          expect(command.convert_to_text(url)).to eq(converted)
        end
      end
      describe 'raw non gist' do
        let(:url) { 'https://raw.githubusercontent.com/nwops/puppet-debugger/master/lib/puppet-debugger.rb' }
        let(:converted) { 'https://raw.githubusercontent.com/nwops/puppet-debugger/master/lib/puppet-debugger.rb' }
        it do
          expect(command.convert_to_text(url)).to eq(converted)
        end
      end

      describe 'blob' do
        let(:url) { 'https://github.com/nwops/puppet-debugger/blob/master/lib/puppet-debugger.rb' }
        let(:converted) { 'https://github.com/nwops/puppet-debugger/raw/master/lib/puppet-debugger.rb' }
        it do
          expect(command.convert_to_text(url)).to eq(converted)
        end
      end

      describe 'gist' do
        let(:url) { 'https://gist.github.com/logicminds/f9b1ac65a3a440d562b0' }
        let(:converted) { 'https://gist.github.com/logicminds/f9b1ac65a3a440d562b0.txt' }
        it do
          expect(command.convert_to_text(url)).to eq(converted)
        end
      end
    end
  end

  describe 'multiple lines of input' do
    before(:each) do

    end
    describe '3 lines' do
      let(:input) do
        "$var1 = 'test'\nfile{\"/tmp/${var1}.txt\": ensure => present, mode => '0755'}\nvars"
      end
      it do
        command.play_back_string(input)
        expect(output.string).to match(/server_facts/) if Gem::Version.new(Puppet.version) >= Gem::Version.new(4.1)
        expect(output.string).to match(/test/)
        expect(output.string).to match(/Puppet::Type::File/)
      end
    end
    describe '2 lines' do
      let(:input) do
        "$var1 = 'test'\n $var2 = 'test2'"
      end
      it do
        command.play_back_string(input)
        expect(output.string).to include("$var1 = 'test'")
        expect(output.string).to include('"test"')
        expect(output.string).to include("$var2 = 'test2'")
        expect(output.string).to include('"test2"')
      end
    end
    describe '1 lines' do
      let(:input) do
        "$var1 = 'test'"
      end
      it do
        command.play_back_string(input)
        expect(output.string).to include("$var1 = 'test'")
        expect(output.string).to include('"test"')
      end
    end
  end

  describe 'play' do
    let(:fixtures_file) do
      File.join(fixtures_dir, 'sample_manifest.pp')
    end

    let(:file_url) do
      'https://gist.github.com/logicminds/f9b1ac65a3a440d562b0'
    end
    let(:input) do
      "play #{file_url}"
    end
    # requires internet and stops testing
    xit 'url' do
      allow(debugger).to receive(:fetch_url_data).with(file_url + '.txt').and_return(File.read(fixtures_file))
      debugger.handle_input(input)
      expect(output.string).to match(/test/)
      expect(output.string).to match(/Puppet::Type::File/)
    end

    it 'file' do
      debugger.handle_input("play #{fixtures_file}")
      expect(output.string).to match(/Puppet::Type::File/)
    end
  end
end