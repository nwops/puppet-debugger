# encoding: utf-8
# frozen_string_literal: true

require 'rubygems'
require 'bundler'
require 'bundler/gem_tasks'
require 'rake/testtask'

begin
  Bundler.setup(:default, :development, :test)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'rake'

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task default: :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ''
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "puppet-debugger #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Creates generic input_responder spec files'
task :make_input_responder_tests do
  files = Dir.glob("lib/plugins/**/*.rb")
  new_files = files.collect do |pathname|
    orig_file = File.basename(pathname, ".*")
    test_file = File.join('spec', 'input_responders', "#{orig_file}_spec.rb")
    unless File.exist?(test_file)
      new_file = File.new(test_file, "w")
      contents = <<-EOS
        require 'spec_helper'
        require 'puppet-debugger'
        require 'puppet-debugger/plugin_test_helper'

        describe :#{orig_file} do
        include_examples 'plugin_tests'
        let(:args) { [] }

        end
      EOS
      File.write(test_file, contents)
    end
  end
end
