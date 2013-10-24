module Hark
  # A Listener holds a dispatcher, which it dispatches messages to
  #
  # A listener is by default a 'lax' listener, it will silently swallow any unknown messages
  #
  # A listener can be turned into a 'strict' listener, by sending it the #strict message.
  # A strict listener will raise NoMethodError if it is sent a message it doesn't know
  # how to handle.
  class Listener
    def self.new *args, &block
      self == Listener ? LaxListener.new(*args, &block) : super(*args, &block)
    end

    attr_reader :dispatcher

    def initialize(*args, &block)
      @dispatcher = Dispatcher.from(*args, &block)
      freeze
    end

    def strict
      StrictListener.new dispatcher
    end

    def lax
      LaxListener.new dispatcher
    end

    def hark *args, &block
      self.class.new dispatcher, *args, &block
    end
  end

  class StrictListener < Listener
    def respond_to_missing? method, *args
      dispatcher.handles?(method) || super
    end

    def method_missing *args, &block
      (results = dispatcher.handle(*args, &block)).any? ? results : super
    end
  end

  class LaxListener < Listener
    def respond_to_missing? *args
      true
    end

    def method_missing *args, &block
      dispatcher.handle(*args, &block)
    end
  end
end
