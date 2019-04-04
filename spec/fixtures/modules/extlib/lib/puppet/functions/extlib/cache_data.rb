require 'fileutils'
require 'yaml'
require 'etc'

# @summary Retrieves data from a cache file, or creates it with supplied data if the file doesn't exist
#
# Retrieves data from a cache file, or creates it with supplied data if the
# file doesn't exist
#
# Useful for having data that's randomly generated once on the master side
# (e.g. a password), but then stays the same on subsequent runs. Because it's
# stored on the master on disk, it doesn't work when you use mulitple Puppet
# masters that don't share their vardir.
#
# @example Calling the function
#   $password = cache_data('mysql', 'mysql_password', 'this_is_my_password')
#
# @example With a random password
#   $password = cache_data('mysql', 'mysql_password', random_password())
Puppet::Functions.create_function(:'extlib::cache_data') do
  # @param namespace Namespace for the cache
  # @param name Cache key within the namespace
  # @param initial_data The data for when there is no cache yet
  # @return The cached value when it exists. The initial data when no cache exists
  dispatch :cache_data do
    param 'String[1]', :namespace
    param 'String[1]', :name
    param 'Any', :initial_data
    return_type 'Any'
  end

  def cache_data(namespace, name, initial_data)
    cache_dir = File.join(Puppet[:vardir], namespace)
    cache = File.join(cache_dir, name)

    if File.exist? cache
      YAML.load(File.read(cache))
    else
      FileUtils.mkdir_p(cache_dir)
      File.open(cache, 'w', 0o600) do |c|
        c.write(YAML.dump(initial_data))
      end
      File.chown(File.stat(Puppet[:vardir]).uid, nil, cache)
      File.chown(File.stat(Puppet[:vardir]).uid, nil, cache_dir)
      initial_data
    end
  end
end
