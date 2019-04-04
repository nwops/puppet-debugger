require 'json'

# A function that lets you know whether a specific module is on your modulepath.
Puppet::Functions.create_function(:'extlib::has_module') do
  # @param module_name The full name of the module you want to know exists or not.
  #   Namespace and modulename can be separated with either `-` or `/`.
  # @return Returns `true` or `false`.
  # @example Calling the function
  #   extlib::has_module('camptocamp/systemd')
  dispatch :has_module do
    param 'Pattern[/\A\w+[-\/]\w+\z/]', :module_name
    return_type 'Boolean'
  end

  def has_module(module_name) # rubocop:disable Style/PredicateName
    full_module_name = module_name.gsub(%r{/}, '-')
    module_name = full_module_name[%r{(?<=-).+}]
    begin
      module_path = call_function('get_module_path', module_name)
    rescue Puppet::ParseError
      # stdlib function get_module_path raises Puppet::ParseError if module isn't in your environment
      return false
    end

    metadata_json = File.join(module_path, 'metadata.json')

    return false unless File.exist?(metadata_json)

    metadata = JSON.parse(File.read(metadata_json))
    return true if metadata['name'] == full_module_name
    false
  end
end
