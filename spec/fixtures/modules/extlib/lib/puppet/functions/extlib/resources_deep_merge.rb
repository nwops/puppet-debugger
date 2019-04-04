# @summary Deeply merge a "defaults" hash into a "resources" hash like the ones expected by `create_resources()`.
#
# Deeply merge a "defaults" hash into a "resources" hash like the ones expected by `create_resources()`.
#
# Internally calls the puppetlabs-stdlib function `deep_merge()`. In case of
# duplicate keys the `resources` hash keys win over the `defaults` hash keys.
#
# Example
# ```puppet
# $defaults_hash = {
#   'one'   => '1',
#   'two'   => '2',
#   'three' => '3',
#   'four'  => {
#     'five'  => '5',
#     'six'   => '6',
#     'seven' => '7',
#   }
# }
#
# $numbers_hash = {
#   'german' => {
#     'one'   => 'eins',
#     'three' => 'drei',
#     'four'  => {
#       'six' => 'sechs',
#     },
#   },
#   'french' => {
#     'one' => 'un',
#     'two' => 'deux',
#     'four' => {
#       'five'  => 'cinq',
#       'seven' => 'sept',
#     },
#   }
# }
#
# $result_hash = resources_deep_merge($numbers_hash, $defaults_hash)
# ```
#
# The $result_hash then looks like this:
#
# ```puppet
# $result_hash = {
#   'german' => {
#     'one'   => 'eins',
#     'two'   => '2',
#     'three' => 'drei',
#     'four'  => {
#       'five'  => '5',
#       'six'   => 'sechs',
#       'seven' => '7',
#     }
#   },
#   'french' => {
#     'one'   => 'un',
#     'two'   => 'deux',
#     'three' => '3',
#     'four'  => {
#       'five'  => 'cinq',
#       'six'   => '6',
#       'seven' => 'sept',
#     }
#   }
# }
# ```
Puppet::Functions.create_function(:'extlib::resources_deep_merge') do
  # Deep-merges defaults into a resources hash
  # @param resources The hash of resources.
  # @param defaults The hash of defaults to merge.
  # @return Returns the merged hash.
  dispatch :resources_deep_merge do
    param 'Hash', :resources
    param 'Hash', :defaults
    return_type 'Hash'
  end

  def resources_deep_merge(resources, defaults)
    deep_merged_resources = {}
    resources.each do |title, params|
      deep_merged_resources[title] = call_function('deep_merge', defaults, params)
    end

    deep_merged_resources
  end
end
