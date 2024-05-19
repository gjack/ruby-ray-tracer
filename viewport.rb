class Viewport
  attr_reader :width, :height

  def initialize(width: 1, height: 1)
    @width = width
    @height = height
  end
end
