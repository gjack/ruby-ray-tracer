class Camera
  attr_reader :origin, :distance

  # initialize with origin and distance to projection plane
  def initialize(origin: [0,0,0], distance: 1)
    @origin = origin
    @distance = distance
  end
end
