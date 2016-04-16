require_relative 'puppet-repl/cli'
require_relative 'version'
require 'awesome_print'
require_relative 'awesome_print/ext/awesome_puppet'
require_relative 'trollop'
# monkey patch in some color effects string methods
class String
  def red;            "\033[31m#{self}\033[0m" end
  def green;          "\033[32m#{self}\033[0m" end
  def cyan;           "\033[36m#{self}\033[0m" end
  def yellow;         "\033[33m#{self}\033[0m" end
  def warning;        yellow                   end
  def fatal;          red                      end
  def info;           green                    end

  def camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map(&:capitalize).join
  end
end
