#!/usr/bin/env bash
export PATH=$PATH:/usr/local/bundle
gem install bundler > /dev/null
gem update --system > /dev/null
bundle install --no-color --without development
bundle exec puppet module install puppetlabs-stdlib
echo "Running tests, output to ${OUT_DIR}/results.txt"
bundle exec rspec --out "${OUT_DIR}/results.txt" --format documentation
# due to concurrency issues we can't build this in parallel
#gem build puppet-repl.gemspec

# docker run -e RUBY_VERSION='ruby:1.9.3' -e PUPPET_GEM_VERSION='~> 3.8' --rm -ti -v ${PWD}:/module --workdir /module ruby:1.9.3 /bin/bash run_container_test.sh
