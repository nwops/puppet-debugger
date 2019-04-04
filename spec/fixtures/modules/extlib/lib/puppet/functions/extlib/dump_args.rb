require 'json'

# @summary Prints the args to STDOUT in Pretty JSON format.
#
# Prints the args to STDOUT in Pretty JSON format.
#
# Useful for debugging purposes only. Ideally you would use this in
# conjunction with a rspec-puppet unit test.  Otherwise the output will
# be shown during a puppet run when verbose/debug options are enabled.
Puppet::Functions.create_function(:'extlib::dump_args') do
  # @param args The data you want to dump as pretty JSON.
  # @return [Undef] Returns nothing.
  dispatch :dump_args do
    param 'Any', :args
  end

  def dump_args(args)
    puts JSON.pretty_generate(args)
  end
end
