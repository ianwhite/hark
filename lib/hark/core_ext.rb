module Kernel
  def hark *args, &block
    Hark.from *args, &block
  end

  def to_hark *args, &block
    Hark.from self, *args, &block
  end
end
