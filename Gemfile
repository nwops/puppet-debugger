source "http://rubygems.org"
gem 'puppet', ENV['PUPPET_GEM_VERSION'] || ">= 3.8"
gem 'facterdb', ">= 0.3.8"
gem 'awesome_print', "~> 1.6"

group :test do
  # ruby versions prior to 2.0 cannot install json_pure 2.0.2+
  gem 'json_pure', '<= 2.0.1'
  gem "rdoc", "~> 3.12"
  gem "rspec"
  gem "bundler"
  gem "simplecov", ">= 0"
  gem 'rake'
  gem 'release_me'
end

group :validate do
  gem 'rubocop'
end

group :development do
  gem 'pry'
end
