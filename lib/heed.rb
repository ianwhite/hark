require "heed/version"
require "heed/ad_hoc"
require "heed/dispatcher"
require "heed/listener"
require "heed/core_ext"

module Heed
  def self.listener(*args, &block)
    Listener.new(*args, &block)
  end
end
