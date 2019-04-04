# vim: set ts=2 sw=2 et :
# encoding: utf-8

# random_password.rb
#
# Copyright 2012 Krzysztof Wilczynski
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# For example:
# ```
# Given the following statements:
#
#   $a = 4
#   $b = 8
#   $c = 16
#
#   notice random_password($a)
#   notice random_password($b)
#   notice random_password($c)
#
# The result will be as follows:
#
#   notice: Scope(Class[main]): fNDC
#   notice: Scope(Class[main]): KcKDLrjR
#   notice: Scope(Class[main]): FtvfvkS9j9wXLsd6
# ```

# A function to return a string of arbitrary length that contains randomly selected characters.
Puppet::Functions.create_function(:'extlib::random_password') do
  # @param length The length of random password you want generated.
  # @return [String] The random string returned consists of alphanumeric characters excluding 'look-alike' characters.
  # @example Calling the function
  #   random_password(42)
  dispatch :random_password do
    param 'Integer[1]', :length
    return_type 'String'
  end

  def random_password(length)
    # These are quite often confusing ...
    ambiguous_characters = %w[0 1 O I l]

    # Get allowed characters set ...
    set = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    set -= ambiguous_characters

    # Shuffle characters in the set at random and return desired number of them ...
    Array.new(length) do |_i|
      set[rand(set.length)]
    end.join
  end
end
