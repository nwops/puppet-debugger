# @summary Splits the given directory or directories into individual paths.
#
# Use this function when you need to split a absolute path into multiple absolute paths
# that all descend from the given path.
#
# @param dirs [Variant[Stdlib::Absolutepath, Array[Stdlib::Absolutepath]]] - either an absolute path or a array of absolute paths.
# @return [Array[String]] - an array of absolute paths after being cut into individual paths.
# @example calling the function
#  extlib::dir_split('/opt/puppetlabs') => ['/opt', '/opt/puppetlabs']
function extlib::dir_split(Variant[Stdlib::Absolutepath, Array[Stdlib::Absolutepath]] $dirs) >> Array[String] {
  $sep = extlib::file_separator()

  $dirs_array = [$dirs].flatten.unique.map | Stdlib::Absolutepath $dir | {
    $dir.split(shell_escape($sep)).reduce([]) |Array $acc, $value  | {
        $counter = $acc.length - 1
        $acc_value = ($acc[$counter] =~ Undef) ? { true => '', false => $acc[$counter] }
        unless empty($value) {
          $acc + extlib::path_join([$acc_value, $value])
        } else {
          $acc
        }
      }
  }
  $dirs_array.flatten.unique
}
