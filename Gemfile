# frozen_string_literal: true

source 'http://rubygems.org'
gem 'awesome_print', '~> 1.7'
gem 'facterdb', '>= 0.5.0'
gem 'pluginator', '~> 1.5.0'
gem 'puppet', ENV['PUPPET_GEM_VERSION'] || '~> 5.5'
gem 'rb-readline'
gem 'table_print'
gem 'tty-pager'
#gem 'bolt' if Gem::Version(ENV['PUPPET_GEM_VERSION'])

group :test, :development do
  # ruby versions prior to 2.0 cannot install json_pure 2.0.2+
  gem 'bundler'
  gem 'pry'
  gem 'puppet-debugger', path: './'
  gem 'rake', '~> 13.0'
  gem 'rdoc', '~> 3.12'
  gem 'release_me'
  gem 'rspec', '~> 3.6'
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rspec'
  gem 'simplecov', '>= 0'
end
