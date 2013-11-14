module Hark
  # A Listener holds a dispatcher, which it dispatches messages to
  #
  # A listener is by default a 'strict' listener, it will raise NoMethodError if
  # it is sent a message it doesn't know how to handle.
  #
  # A listener can be turned into a 'lax' listener, by sending it the #lax message.
  # A lax listener will silently swallow any unknown messages.
  class Listener
    def self.new *args, &block
      self == Listener ? StrictListener.new(*args, &block) : super(*args, &block)
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
    def respond_to?(method, *args)
      super || dispatcher.handles?(method)
    end

    def method_missing *args, &block
      (results = dispatcher.handle(*args, &block)).any? ? results : super
    end
  end

  class LaxListener < Listener
    def respond_to? *args
      true
    end

    def method_missing *args, &block
      dispatcher.handle(*args, &block)
    end
  end
end
