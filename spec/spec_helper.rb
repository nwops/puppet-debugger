require 'simplecov'
require_relative '../lib/puppet-repl'
begin
  require 'pry'
rescue LoadError
  # pry not required unless using interactively
end

module SimpleCov::Configuration
  def clean_filters
    @filters = []
  end
end

SimpleCov.configure do
  clean_filters
  load_adapter 'test_frameworks'
end

ENV["COVERAGE"] && SimpleCov.start do
  add_filter "/.rvm/"
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
