# A function that sorts an array of version numbers.
Puppet::Functions.create_function(:'extlib::sort_by_version') do
  # @param versions An array of version strings you want sorted.
  # @return Returns the sorted array.
  # @example Calling the function
  #   extlib::sort_by_version(['10.0.0b12', '10.0.0b3', '10.0.0a2', '9.0.10', '9.0.3'])
  dispatch :sort_by_version do
    param 'Array[String]', :versions
    return_type 'Array[String]'
  end

  def sort_by_version(versions)
    versions.sort_by { |v| Gem::Version.new(v) }
  end
end
