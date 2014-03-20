require "rsync/version"
require "rsync/command"
require "rsync/result"
require 'rsync/configure'

# The main interface to rsync
module Rsync
  extend Configure
  # Creates and runs an rsync {Command} and return the {Result}
  # @param source {String}
  # @param destination {String}
  # @param args {Array}
  # @return {Result}
  # @yield {Result}


  def self.run(source, destination, args = [], &block)
    ssh = get_ssh
    dest = get_destination(destination)

    if ssh
      result = Command.run(ssh: ssh, source: source, destination: dest, args: args)
    else
      result = Command.run(source: source, destination: dest, args: args)
    end

    yield(result) if block_given?
    result
  end

  def self.get_ssh
    if self.src_host
      if self.src_host_user
        "ssh #{self.src_host_user}@#{self.src_host}"
      else
        "ssh #{self.src_host}"
      end
    end
  end

  def self.get_destination(destination)
    if self.host
      if self.host_user
        "#{self.host_user}@#{self.host}:#{destination}"
      else
        "#{self.host}:#{destination}" if self.host
      end
    else
      destination
    end
  end
end
