# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
describe 'PuppetDebugger' do
  let(:resource) do
    "service{'httpd': ensure => running}"
  end

  before(:each) do
    debugger.handle_input('reset')
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

  let(:input) do
    "file{'/tmp/test2.txt': ensure => present, mode => '0755'}"
  end

  let(:resource_types) do
    debugger.parser.evaluate_string(debugger.scope, input)
  end

  describe 'native classes' do
    describe 'create' do
      let(:input) do
        'class testfoo {}'
      end
      let(:debugger_output) do
        " => Puppet::Type::Component {\n  loglevel\e[0;37m => \e[0m\e[0;36mnotice\e[0m,\n      name\e[0;37m => \e[0m\e[0;33m\"Testfoo\"\e[0m,\n     title\e[0;37m => \e[0m\e[0;33m\"Class[Testfoo]\"\e[0m\n}\n"
      end
      it do
        debugger.handle_input(input)
        expect(output.string).to eq('')
        expect(debugger.known_resource_types[:hostclasses]).to include('testfoo')
      end
      it do
        debugger.handle_input(input)
        debugger.handle_input('include testfoo')
        expect(debugger.scope.compiler.catalog.classes).to include('testfoo')
      end
      it do
        debugger.handle_input(input)
        debugger.handle_input('include testfoo')
        expect(debugger.scope.compiler.catalog.resources.map(&:name)).to include('Testfoo')
      end
    end
  end

  describe 'native definitions' do
    describe 'create' do
      let(:input) do
        'define testfoodefine {}'
      end
      let(:debugger_output) do
        " => Puppet::Type::Component {\n  loglevel\e[0;37m => \e[0m\e[0;36mnotice\e[0m,\n      name\e[0;37m => \e[0m\e[0;33m\"some_name\"\e[0m,\n     title\e[0;37m => \e[0m\e[0;33m\"Testfoo[some_name]\"\e[0m\n}\n"
      end
      it do
        debugger.handle_input(input)
        expect(debugger.scope.environment.known_resource_types.definitions.keys).to include('testfoodefine')
        expect(output.string).to eq('')
      end
      it do
        debugger.handle_input(input)
        debugger.handle_input("testfoodefine{'some_name':}")
        expect(output.string).to include(' => Puppet::Type::Component')
      end
    end
  end

  describe 'key_words' do
    it do
      expect(debugger.key_words.count).to be >= 30 if supports_datatypes?
    end

    it do
      expect(debugger.key_words.count).to be >= 0 unless supports_datatypes?
    end
  end

  describe 'native functions', native_functions: true do
    let(:func) do
      <<-OUT
      function debugger::bool2http($arg) {
        case $arg {
          false, undef, /(?i:false)/ : { 'Off' }
          true, /(?i:true)/          : { 'On' }
          default               : { "$arg" }
        }
      }
      OUT
    end
    before(:each) do
      debugger.handle_input(func)
    end
    describe 'create' do
      it 'shows function' do
        expect(output.string).to eq('')
      end
    end
    describe 'run' do
      let(:input) do
        <<-OUT
        debugger::bool2http(false)
        OUT
      end
      it do
        debugger.handle_input(input)
        expect(output.string).to include('Off')
      end
    end
  end

  describe 'returns a array of resource_types' do
    it 'returns resource type' do
      expect(resource_types.first.class.to_s).to eq('Puppet::Pops::Types::PResourceType')
    end
  end

  describe 'empty' do
    let(:input) do
      ''
    end
    it 'can run' do
      debugger_output = ''
      debugger.handle_input(input)
      debugger.handle_input(input)
      expect(output.string).to eq(debugger_output)
    end
    describe 'space' do
      let(:input) do
        ' '
      end
      it 'can run' do
        debugger_output = ''
        debugger.handle_input(input)
        expect(output.string).to eq(debugger_output)
      end
    end
  end

  describe 'variables' do
    let(:input) do
      "$file_path = '/tmp/test2.txt'"
    end
    it 'can process a variable' do
      debugger.handle_input(input)
      expect(output.string).to match(%r{/tmp/test2.txt})
    end
  end

  describe 'resource' do
    let(:input) do
      "file{'/tmp/test2.txt': ensure => present, mode => '0755'}"
    end
    it 'can process a resource' do
      debugger_output = /Puppet::Type::File/
      debugger.handle_input(input)
      expect(output.string).to match(debugger_output)
    end
  end

  describe 'bad input' do
    let(:input) do
      'Service{'
    end
    it 'can process' do
      debugger.handle_input(input)
      expect(output.string).to match(/Syntax error at end of/)
    end
  end

  describe 'map block' do
    let(:input) do
      "['/tmp/test3', '/tmp/test4'].map |String $path| { file{$path: ensure => present} }"
    end
    it 'can process a each block' do
      debugger_output = /Puppet::Type::File/
      debugger.handle_input(input)
      expect(output.string).to match(debugger_output)
    end
  end

  describe 'each block' do
    let(:input) do
      "['/tmp/test3', '/tmp/test4'].each |String $path| { file{$path: ensure => present} }"
    end
    it 'can process a each block' do
      debugger.handle_input(input)
      expect(output.string).to match(%r{/tmp/test3})
      expect(output.string).to match(%r{/tmp/test4})
    end
  end

  describe 'string' do
    let(:input) do
      'String'
    end
    it 'shows type' do
      debugger.handle_input(input)
      expect(output.string).to eq(" => String\n")
    end
  end
  describe 'Array', type_function: true do
    let(:input) do
      'type([1,2,3,4])'
    end
    it 'shows type' do
      debugger.handle_input(input)
      out = " => Tuple[Integer[1, 1], Integer[2, 2], Integer[3, 3], Integer[4, 4]]\n"
      expect(output.string).to eq(out)
    end
  end

  describe 'multi diemension array' do
    let(:input) do
      '[[1, [23,4], [22], [1,[2232]]]]'
    end

    it 'handles multi array' do
      debugger.handle_input(input)
      expect(output.string.count('[')).to be >= 17
    end
  end

  describe 'command_completion' do
    it 'should complete on tabs' do
      allow(Readline).to receive(:line_buffer).and_return("\n")
      expect(debugger.command_completion.call('').count).to be >= 200
    end

    it '#key_words' do
      expect(debugger.key_words.count).to be >= 100
    end
  end

  describe 'error message' do
    let(:input) do
      "file{'/tmp/test': ensure => present, contact => 'blah'}"
    end
    if Gem::Version.new(Puppet.version) >= Gem::Version.new('4.0')
      it 'show error message' do
        debugger_output = /no\ parameter\ named\ 'contact'/
        debugger.handle_input(input)
        expect(output.string).to match(debugger_output)
      end
    else
      it 'show error message' do
        debugger_output = /Invalid\ parameter\ contact/
        debugger.handle_input(input)
        expect(output.string).to match(debugger_output)
      end
    end
  end
end
