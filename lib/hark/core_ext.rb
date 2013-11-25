module Kernel
  def hark *args, &block
    Hark.from *args, &block
  end

  def heed object, *args, &block
    listener = (block.arity == 1) ? hark(&block) : block.call
    object.send *args + [listener]
  end
end
