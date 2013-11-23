module Kernel
  def hark *args, &block
    Hark.from *args, &block
  end

  def to_hark *args, &block
    hark self, *args, &block
  end

  def hearken method, *args, &block
    listener = (block.arity == 1) ? hark(&block) : block.call
    send method, *args, listener
  end
end
