require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :benchmark do
  include_examples 'plugin_tests'
  let(:args) { ["benchmark", "md5('12345')" ] }

  describe 'mode' do
    before(:each) do
      debugger.handle_input('benchmark') # enable
    end
    it 'enable' do
      debugger.handle_input("md5('12345')")
      expect(output.string).to match(/Benchmark\ Mode\ On/)
      expect(output.string).to match(/Time\ elapsed/)
    end
    it 'disable' do
      debugger.handle_input('benchmark') # disable
      expect(output.string).to match(/Benchmark\ Mode\ Off/)
    end
  end

  describe 'onetime' do
    it 'run' do
      debugger.handle_input("benchmark md5('12345')")
      expect(output.string).to_not match(/Benchmark\ Mode\ On/)
      expect(output.string).to_not match(/Benchmark\ Mode\ Off/)
      expect(output.string).to match(/Time\ elapsed/)
    end
  end
end
