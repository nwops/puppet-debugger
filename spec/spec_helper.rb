require 'simplecov'
require_relative '../lib/puppet-repl'
require 'yaml'
module SimpleCov::Configuration
  def clean_filters
    @filters = []
  end
end

SimpleCov.configure do
  clean_filters
  load_profile 'test_frameworks'
end

SimpleCov.start do
  add_filter "/.rvm/"
  add_filter "vendor"
  add_filter "bundler"
end
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'puppet-repl'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

def stdlib_path
  File.join(Puppet[:basemodulepath].split(':').first, 'stdlib')
end

# def install_stdlib
#   `bundle exec puppet module install puppetlabs/stdlib` unless File.exists?(stdlib_path)
# end
#
# install_stdlib

def fixtures_dir
  File.join(File.dirname(__FILE__), 'fixtures')
end

def environments_dir
  File.join(fixtures_dir, 'environments')
end

RSpec.configure do |config|
end
