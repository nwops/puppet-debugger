# @summary DEPRECATED.  Use the namespaced function [`extlib::ip_to_cron`](#extlibip_to_cron) instead.
# DEPRECATED.  Use the namespaced function [`extlib::ip_to_cron`](#extlibip_to_cron) instead.
Puppet::Functions.create_function(:ip_to_cron) do
  dispatch :deprecation_gen do
    repeated_param 'Any', :args
  end
  def deprecation_gen(*args)
    call_function('deprecation', 'ip_to_cron', 'This method is deprecated, please use extlib::ip_to_cron instead.')
    call_function('extlib::ip_to_cron', *args)
  end
end
