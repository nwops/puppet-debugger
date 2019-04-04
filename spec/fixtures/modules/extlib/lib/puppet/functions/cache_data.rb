# @summary DEPRECATED.  Use the namespaced function [`extlib::cache_data`](#extlibcache_data) instead.
# DEPRECATED.  Use the namespaced function [`extlib::cache_data`](#extlibcache_data) instead.
Puppet::Functions.create_function(:cache_data) do
  dispatch :deprecation_gen do
    repeated_param 'Any', :args
  end
  def deprecation_gen(*args)
    call_function('deprecation', 'cache_data', 'This method is deprecated, please use extlib::cache_data instead.')
    call_function('extlib::cache_data', *args)
  end
end
