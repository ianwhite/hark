module Hark
  # AdHoc is a tiny class to facilitate creating an ad-hoc object that from either a hash or proc.
  #
  # Eg. from a hash:
  #
  #   handler = AdHoc.new(success: (o)-> { o.great_success }, failure: (o)-> { o.failed } )
  #
  # Eg. from a 'response' style block:
  #
  #   handler = AdHoc.new do |on|
  #     on.success {|o| o.great_success }
  #     on.failure {|o| o.failed }
  #   end
  #
  # Eg. adding methods after creation
  #
  #   obj = AdHoc.new
  #   obj.add_method!(:foo) { "bar" }
  #
  # All blocks keep their original binding.  This makes AdHoc suitable for creating
  # ad-hoc responses from controller type objects.
  #
  class AdHoc
    def self.new hash = {}, &proc
      super().tap do |ad_hoc|
        AddMethodsFromProc.new(proc, ad_hoc) if block_given?
        hash.each {|method, body| ad_hoc.add_method!(method, &body) }
      end
    end

    def add_method!(method, &body)
      singleton_class.send(:define_method, method) {|*args, &block| body.call(*args, &block) }
    end

    class AddMethodsFromProc
      def initialize proc, ad_hoc
        @ad_hoc = ad_hoc
        proc.call(self)
      end

      def method_missing method, *, &body
        @ad_hoc.add_method!(method, &body)
      end
    end
  end
end

