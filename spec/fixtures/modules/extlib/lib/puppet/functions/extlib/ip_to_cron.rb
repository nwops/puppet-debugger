# Provides a "random" value to cron based on the last bit of the machine IP address.
# used to avoid starting a certain cron job at the same time on all servers.
# Takes the runinterval in seconds as parameter and returns an array of [hour, minute]
#
# example usage
# ```
# ip_to_cron(3600) - returns [ '*', one value between 0..59 ]
# ip_to_cron(1800) - returns [ '*', an array of two values between 0..59 ]
# ip_to_cron(7200) - returns [ an array of twelve values between 0..23, one value between 0..59 ]
# ```
Puppet::Functions.create_function(:'extlib::ip_to_cron') do
  # @param runinterval The number of seconds to use as the run interval
  # return [Array] Returns an array of the form `[hour, minute]`
  dispatch :ip_to_cron do
    optional_param 'Integer[1]', :runinterval
    return_type 'Array'
  end

  def ip_to_cron(runinterval = 1800)
    facts = closure_scope['facts']
    ip = facts['networking']['ip']
    ip_last_octet = ip.to_s.split('.')[3].to_i

    if runinterval <= 3600
      occurances = 3600 / runinterval
      scope = 60
      base = ip_last_octet % scope
      hour = '*'
      minute = (1..occurances).map { |i| (base - (scope / occurances * i)) % scope }.sort
    else
      occurances = 86_400 / runinterval
      scope = 24
      base = ip_last_octet % scope
      hour = (1..occurances).map { |i| (base - (scope / occurances * i)) % scope }.sort
      minute = ip_last_octet % 60
    end
    [hour, minute]
  end
end
