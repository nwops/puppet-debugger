# @summary DEPRECATED.  Use the namespaced function [`extlib::dump_args`](#extlibdump_args) instead.
# DEPRECATED.  Use the namespaced function [`extlib::dump_args`](#extlibdump_args) instead.
Puppet::Functions.create_function(:dump_args) do
  dispatch :deprecation_gen do
    repeated_param 'Any', :args
  end
  def deprecation_gen(*args)
    call_function('deprecation', 'dump_args', 'This method is deprecated, please use extlib::dump_args instead.')
    call_function('extlib::dump_args', *args)
  end
end
