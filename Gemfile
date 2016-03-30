source "http://rubygems.org"
gem 'puppet', ENV['PUPPET_GEM_VERSION'] || ">= 3.8"
gem 'facterdb'
# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.

group :test do
  gem "rspec"
  gem "bundler"
  gem "jeweler", "~> 2.0.1"
  gem "simplecov", ">= 0"
  gem 'rake'
end

group :development do
  gem 'pry'
  gem "rdoc", "~> 3.12"
end
