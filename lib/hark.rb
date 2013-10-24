require "hark/version"
require "hark/ad_hoc"
require "hark/dispatcher"
require "hark/listener"
require "hark/core_ext"

module Hark
  def self.from(*args, &block)
    Listener.new(*args, &block)
  end
end
