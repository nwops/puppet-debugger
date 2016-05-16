require 'spec_helper'

describe 'prepl' do
  let(:fixtures_file) do
    File.join(fixtures_dir, 'sample_manifest.pp')
  end

  let(:file_url) do
    'https://gist.githubusercontent.com/logicminds/f9b1ac65a3a440d562b0/raw'
  end

  it do
    expect(`echo 'file{"/tmp/test":}'| bundle exec bin/prepl`)
      .to match(/Puppet::Type::File/)
  end

  it do
    expect(`bundle exec bin/prepl #{fixtures_file} --run-once`)
      .to match(/Puppet::Type::File/)
  end
  it do
    expect(`bundle exec bin/prepl --play #{fixtures_file} --run-once`)
      .to match(/Puppet::Type::File/)
  end
  it do
    expect(`bundle exec bin/prepl --play #{file_url} --run-once`)
      .to match(/Puppet::Type::File/)
  end

  describe 'remote_node' do
    let(:node_obj) do
      YAML.load_file(File.join(fixtures_dir, 'node_obj.yaml'))
    end
    let(:node_name) do
      'puppetdev.localdomain'
    end
    before :each do
      allow(PuppetRepl).to receive(:get_remote_node).with(node_name).and_return(node_obj)
    end
    xit do
      expect(`echo 'vars'| bundle exec bin/prepl -n #{node_name}`)
        .to match(/server_facts/)
    end
  end
end
