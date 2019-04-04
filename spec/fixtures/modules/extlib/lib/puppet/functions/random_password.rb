# @summary DEPRECATED.  Use the namespaced function [`extlib::random_password`](#extlibrandom_password) instead.
# DEPRECATED.  Use the namespaced function [`extlib::random_password`](#extlibrandom_password) instead.
Puppet::Functions.create_function(:random_password) do
  dispatch :deprecation_gen do
    repeated_param 'Any', :args
  end
  def deprecation_gen(*args)
    call_function('deprecation', 'random_password', 'This method is deprecated, please use extlib::random_password instead.')
    call_function('extlib::random_password', *args)
  end
end
