module Kernel
  def hark *args, &block
    Hark.from *args, &block
  end
end
