class Vector
  include Math

  attr_accessor :x, :y, :z

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

  def divide_by_scalar(num)
    self.x = self.x / num
    self.y = self.y / num
    self.z = self.z / num

    self
  end

  def multiply_by_scalar(num)
    self.x = self.x * num
    self.y = self.y * num
    self.z = self.z * num

    self
  end

  def self.subtract(minuend:, subtrahend:)
    new([minuend.x - subtrahend.x, minuend.y - subtrahend.y, minuend.z - subtrahend.z])
  end

  def invert_direction
    multiply_by_scalar(-1)
  end

  def as_coords
    [x, y, z]
  end
end
