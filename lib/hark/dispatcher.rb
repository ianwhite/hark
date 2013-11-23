module Hark
  class Dispatcher
    #  from(:success) do
    #    "success"
    #  end
    #
    #  from(success: ->{ "success" })
    #
    #  from do |on|
    #    on.success { "success" }
    #  end
    #
    def self.from(*args, &block)
      if block
        args << (args.last.is_a?(Symbol) ? {args.pop => block} : block)
      end

      new args.map{|o| to_handler(o) }.flatten.freeze
    end

    def self.to_handler object
      case object
      when Listener then object.dispatcher.handlers
      when Dispatcher then object.handlers
      when Hash then AdHoc.new(object)
      when Proc then AdHoc.new(&object)
      when Array then object.map{|o| to_handler(o) }
      else object
      end
    end

    attr_reader :handlers

    def initialize handlers
      @handlers = handlers
      freeze
    end

    def handles? method
      handlers.any? {|handler| handler.respond_to?(method) }
    end

    def handle method, *args, &block
      results = []
      handlers.each do |handler|
        results << handler.send(method, *args, &block) if handler.respond_to?(method)
      end
      results
    end
  end
end
