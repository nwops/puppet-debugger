# @summary Take one or more paths and join them together using the os specific separator.
# Because in how windows uses a different separator this function
# will format a windows path into a equilivent unix like path.  This type of unix like
# path will work on windows.
#
# @param dirs Joins two or more directories by file separator.
# @return [Stdlib::Absolutepath] The joined path
# @example Joining Unix paths to return `/tmp/test/libs`
#   extlib::path_join('/tmp', 'test', 'libs')
# @example Joining Windows paths to return `/c/test/libs`
#   extlib::path_join('c:', 'test', 'libs')
function extlib::path_join(Array[String] $dirs) >> Stdlib::Absolutepath {
  $unix_sep = '/'
  $sep_regex = /\/|\\/
  $first_value = $dirs[0]
  # when first value is absolute path, append all other elements
  # by breaking the path into pieces first, then joining
  if $first_value =~ Stdlib::Absolutepath {
    $fixed_dirs = $first_value.split($sep_regex) + $dirs.delete($first_value)
  } else {
    $fixed_dirs = $dirs
  }
  $no_empty_dirs = $fixed_dirs.filter |$dir| { !empty($dir) }
  $dirs_without_sep = $no_empty_dirs.map |String $dir | {
    # remove : and file separator
    $dir.regsubst($sep_regex, '').regsubst(':', '')
  }
  join([$unix_sep,$dirs_without_sep.join($unix_sep)])
}
