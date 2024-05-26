class Camera
  attr_reader :origin, :distance, :rotation

  # initialize with origin and distance to projection plane
  # add possibility of applying rotation through a transformation matrix
  # default to the identity matrix if none is supplied
  def initialize(origin: [0,0,0], distance: 1, rotation: [[1, 0, 0], [0, 1, 0], [0, 0, 1]])
    @origin = origin
    @distance = distance
    @rotation = rotation
  end
end
