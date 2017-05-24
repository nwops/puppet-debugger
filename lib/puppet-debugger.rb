# frozen_string_literal: true

require_relative 'puppet-debugger/cli'
require_relative 'version'
require 'awesome_print'
require_relative 'awesome_print/ext/awesome_puppet'
require_relative 'trollop'
require 'puppet/util/log'
require_relative 'puppet-debugger/debugger_code'
require_relative 'puppet-debugger/support/errors'

# monkey patch in some color effects string methods
class String
  def red
    "\033[31m#{self}\033[0m"
  end

  def bold
    "\033[1m#{self}\033[22m"
  end

  def black
    "\033[30m#{self}\033[0m"
  end

  def green
    "\033[32m#{self}\033[0m"
  end

  def cyan
    "\033[36m#{self}\033[0m"
  end

  def yellow
    "\033[33m#{self}\033[0m"
  end

  def warning
    yellow
  end

  def fatal
    red
  end

  def info
    green
  end

  def camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map(&:capitalize).join
  end
end

Puppet::Util::Log.newdesttype :buffer do
  require 'puppet/util/colors'
  include Puppet::Util::Colors

  attr_accessor :err_buffer, :out_buffer

  def initialize(err = $stderr, out = $stdout)
    @err_buffer = err
    @out_buffer = out
  end

  def handle(msg)
    levels = {
      emerg: { name: 'Emergency', color: :hred,  stream: err_buffer },
      alert: { name: 'Alert',     color: :hred,  stream: err_buffer },
      crit: { name: 'Critical', color: :hred, stream: err_buffer },
      err: { name: 'Error', color: :hred, stream: err_buffer },
      warning: { name: 'Warning', color: :hred, stream: err_buffer },
      notice: { name: 'Notice', color: :reset, stream: out_buffer },
      info: { name: 'Info', color: :green, stream: out_buffer },
      debug: { name: 'Debug', color: :cyan, stream: out_buffer }
    }

    str = msg.respond_to?(:multiline) ? msg.multiline : msg.to_s
    str = msg.source == 'Puppet' ? str : "#{msg.source}: #{str}"

    level = levels[msg.level]
    level[:stream].puts colorize(level[:color], "#{level[:name]}: #{str}")
  end
end
