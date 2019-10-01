# frozen_string_literal: true
source 'http://rubygems.org'
gem 'awesome_print', '~> 1.7'
gem 'facterdb', '>= 0.5.0'
gem 'puppet', ENV['PUPPET_GEM_VERSION'] || '~> 4.10.1'
gem 'pluginator', '~> 1.5.0'
gem 'rb-readline'
gem 'table_print'
group :test, :development do
  # ruby versions prior to 2.0 cannot install json_pure 2.0.2+
  gem 'bundler'
  gem 'CFPropertyList'
  gem 'pry'
  gem 'puppet-debugger', path: './'
  gem 'rake', '= 12.3.3'
  gem 'rdoc', '~> 3.12'
  gem 'release_me'
  gem 'rspec', '~> 3.6'
  gem 'simplecov', '>= 0'
  gem 'rubocop', '= 0.48.0'

end

