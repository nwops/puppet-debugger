# @summary DEPRECATED.  Use the namespaced function [`extlib::resources_deep_merge`](#extlibresources_deep_merge) instead.
# DEPRECATED.  Use the namespaced function [`extlib::resources_deep_merge`](#extlibresources_deep_merge) instead.
Puppet::Functions.create_function(:resources_deep_merge) do
  dispatch :deprecation_gen do
    repeated_param 'Any', :args
  end
  def deprecation_gen(*args)
    call_function('deprecation', 'resources_deep_merge', 'This method is deprecated, please use extlib::resources_deep_merge instead.')
    call_function('extlib::resources_deep_merge', *args)
  end
end
