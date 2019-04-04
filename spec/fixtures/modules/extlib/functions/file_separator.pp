# @summary Returns the os specific file path separator.
# @return [String] - The os specific path separator.
# @example Example of how to use
#  extlib::file_separator() => '/'
function extlib::file_separator() >> String {
  ($::facts['kernel'] == 'windows' ) ? { true => "\\", false => '/' }
}
