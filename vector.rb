class Vector
  include Math

  attr_reader :x, :y, :z

  def self.from_two_points(tail:, head:)
    new([head[0] - tail[0], head[1] - tail[1], head[2] - tail[2]])
  end

  def initialize(coordinates)
    @x = coordinates[0]
    @y = coordinates[1]
    @z = coordinates[2]
  end

  def dot_product(other)
    (x * other.x) + (y * other.y) + (z * other.z)
  end

  def magnitude
    sqrt(dot_product(self))
  end
end
