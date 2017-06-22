require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :whereami do
  include_examples 'plugin_tests'
  let(:input) do
    File.expand_path File.join(fixtures_dir, 'sample_start_debugger.pp')
  end
  let(:options) do
    {
      source_file: input,
      source_line: 10
    }
  end

  before(:each) do
    debugger.handle_input('whereami')
  end

  it 'runs' do
    expect(output.string).to match(/\s+5/)
  end

  it 'contains marker' do
    expect(output.string).to match(/\s+=>\s10/)
  end
end
