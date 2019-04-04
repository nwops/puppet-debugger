# @summary DEPRECATED.  Use the namespaced function [`extlib::default_content`](#extlibdefault_content) instead.
# DEPRECATED.  Use the namespaced function [`extlib::default_content`](#extlibdefault_content) instead.
Puppet::Functions.create_function(:default_content) do
  dispatch :deprecation_gen do
    repeated_param 'Any', :args
  end
  def deprecation_gen(*args)
    call_function('deprecation', 'default_content', 'This method is deprecated, please use extlib::default_content instead.')
    call_function('extlib::default_content', *args)
  end
end
