module Kernel
  def hark *args, &block
    Heed.listener *args, &block
  end

  def heed object, *args, &block
    listener = (block.arity == 1) ? Heed.listener(&block) : block.call
    object.send *args + [listener]
  end
end
