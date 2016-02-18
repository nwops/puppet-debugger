require 'spec_helper'

describe "PuppetRepl" do
  let(:resource) do
    "service{'httpd': ensure => running}"
  end

  it 'can show the help screen' do

  end

  it 'can process a variable' do


  end

  it 'can process a resource' do

  end

  it 'can process a each block' do
    input = "['/tmp/test3', '/tmp/test4'].each |String $path| { file{$path: ensure => present} }"
  end


end
