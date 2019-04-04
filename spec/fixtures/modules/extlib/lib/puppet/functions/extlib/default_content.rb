# Takes an optional content and an optional template name and returns the contents of a file.
Puppet::Functions.create_function(:'extlib::default_content') do
  # @param content
  # @param template_name
  #   The path to an .erb or .epp template file or `undef`.
  # @return
  #   Returns the value of the content parameter if it's a non empty string.
  #   Otherwise returns the rendered output from `template_name`.
  #   Returns `undef` if both `content` and `template_name` are `undef`.
  #
  # @example Using the function with a file resource.
  #   $config_file_content = default_content($file_content, $template_location)
  #   file { '/tmp/x':
  #     ensure  => 'file',
  #     content => $config_file_content,
  #   }
  dispatch :default_content do
    param 'Optional[String]', :content
    param 'Optional[String]', :template_name
    return_type 'Optional[String]'
  end

  def emptyish(x)
    x.nil? || x.empty? || x == :undef
  end

  def default_content(content = :undef, template_name = :undef)
    return content unless emptyish(content)

    unless emptyish(template_name)
      return call_function('template', template_name) unless template_name.end_with?('.epp')
      return call_function('epp', template_name)
    end

    :undef
  end
end
