# frozen_string_literal: true

require 'puppet-debugger/cli'
require 'puppet-debugger/version'
require 'awesome_print'
require 'awesome_print/ext/awesome_puppet'
require 'puppet-debugger/trollop'
require 'puppet/util/log'
require 'puppet-debugger/debugger_code'
require 'puppet-debugger/support/errors'
require 'plugins/puppet-debugger/input_responders/commands'
require 'puppet-debugger/monkey_patches'

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
