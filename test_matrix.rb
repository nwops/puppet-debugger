# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'English'
@threads = {}

def run_container(image, puppet_version)
  pversion = puppet_version.match(/([\d\.]+)/)[0]
  ruby_version = image.split(':').last
  dir = File.join('.', 'local_test_results', pversion, ruby_version)
  real_dir = File.expand_path(dir)
  FileUtils.rm_rf(real_dir)
  FileUtils.mkdir_p(real_dir)
  cmd = "docker run -e OUT_DIR='#{dir}' -e RUBY_VERSION='#{ruby_version}' -e PUPPET_GEM_VERSION='#{puppet_version}' --rm -ti -v ${PWD}:/module --workdir /module #{image} /bin/bash run_container_test.sh"
  File.write(File.join(real_dir, 'command.txt'), cmd)
  output = `#{cmd}`
  if $CHILD_STATUS.success?
    File.write(File.join(dir, 'success.txt'), output)
  else
    File.write(File.join(dir, 'error.txt'), output)
  end
end

def ci_data
  @ci_data ||= YAML.load_file(File.expand_path('.gitlab-ci.yml'))
end

def matrix
  unless @matrix
    @matrix = {}
    ci_data.each do |id, data|
      @matrix[id] = data if id.match?(/^puppet/)
    end
  end
  @matrix
end

matrix.each do |id, item|
  @threads[id] = Thread.new do
    run_container(item['image'], item['variables']['PUPPET_GEM_VERSION'])
  end
end

@threads.each { |_id, thr| thr.join } # wait on thread to finish
