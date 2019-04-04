# @summary DEPRECATED.  Use the namespaced function [`extlib::echo`](#extlibecho) instead.
# DEPRECATED.  Use the namespaced function [`extlib::echo`](#extlibecho) instead.
Puppet::Functions.create_function(:echo) do
  dispatch :deprecation_gen do
    repeated_param 'Any', :args
  end
  def deprecation_gen(*args)
    call_function('deprecation', 'echo', 'This method is deprecated, please use extlib::echo instead.')
    call_function('extlib::echo', *args)
  end
end
