require_relative "canvas"
require_relative "viewport"
require_relative "camera"
require_relative "vector"

class RayTracer
  include Math
  
  attr_reader :canvas, :camera, :viewport, :scene

  INFINITY = Float::INFINITY
  BACKGROUND_COLOR = [255, 255, 255] # white

  def initialize
    @canvas ||= Canvas.new
  end

  def canvas_to_viewport_coordinates(x, y)
    [x * viewport.width.to_f / canvas.width, y * viewport.height.to_f / canvas.height, camera.distance]
  end

  def trace_ray(origin, canvas_to_viewport, t_min, t_max)
    closest_t = INFINITY
    closest_sphere = nil

    scene[:spheres].each do |sphere|
      t1, t2 = intersect_ray_sphere(origin, canvas_to_viewport, sphere)
      if (t_min .. t_max).cover?(t1) && t1 < closest_t 
        closest_t = t1
        closest_sphere = sphere
      end
      if (t_min .. t_max).cover?(t2) && t2 < closest_t 
        closest_t = t2
        closest_sphere = sphere
      end
    end
    if closest_sphere.nil?
      return BACKGROUND_COLOR
    end

    # calculate the point where the light touches the sphere
    light_intersection = (0..2).map do |i|
      origin[i] + canvas_to_viewport.map {|coord| coord * closest_t}[i]
    end

    # find the vector normal to the surface at the intersection point
    normal_at_intersection = Vector.from_two_points(head: light_intersection, tail: closest_sphere[:center])

    # normalize the vector
    normalized = normal_at_intersection.divide_by_scalar(normal_at_intersection.magnitude)

    # calculate the light intensity at the point
    light_intensity = compute_lighting(light_intersection, normalized)

    # calculate the shade of the color at the corresponding pixel
    closest_sphere[:color].map do |code|
      code * light_intensity
    end
  end

  def intersect_ray_sphere(origin, canvas_to_viewport, sphere)
    r = sphere[:radius]
    vector_co = Vector.from_two_points(tail: sphere[:center], head: origin)
    vector_ctv = Vector.new(canvas_to_viewport)

    a = vector_ctv.dot_product(vector_ctv)
    b = 2 * vector_co.dot_product(vector_ctv)
    c = vector_co.dot_product(vector_co) - (r * r)

    discriminant = (b * b) - (4 * a * c)  

    if discriminant < 0
      return [INFINITY, INFINITY]
    end
    
    t1 = (-b + sqrt(discriminant)) / 2 * a
    t2 = (-b - sqrt(discriminant)) / 2 * a

    [t1, t2]
  end

  def paint_scene
    (-canvas.width / 2 .. canvas.width / 2).each do |x|
      (-canvas.height / 2 .. canvas.height / 2).each do |y|
        ctv = canvas_to_viewport_coordinates(x, y)
        color = trace_ray(camera.origin, ctv, 1, INFINITY)
        canvas.put_pixel(x, y, color)
      end
    end

    canvas.save_image(filename: "second_example.bmp")
  end

  # calculate the light intensity for each point
  # by combining the intensity of all light sources
  def compute_lighting(light_intersection, norm)
    intensity = 0.0

    scene[:lights].each do |light|
      if light[:type] == "ambient"
        intensity += light[:intensity]
      else
        light_ray = light[:type] == "point" ? Vector.from_two_points(head: light[:position], tail: light_intersection) : Vector.new(light[:direction])

        n_dot_l = norm.dot_product(light_ray)

        # if the product is zero this light source is not located in any useful place that contributes
        # to the ilumination of the scene
        if n_dot_l > 0
          intensity += light[:intensity] * n_dot_l / (norm.magnitude * light_ray.magnitude)
        end
      end
    end
    intensity
  end

  def viewport
    @viewport ||= scene[:viewport]
  end

  def camera
    @camera ||= scene[:camera]
  end

  def scene
    @scene ||= {
      camera: Camera.new,
      viewport: Viewport.new,
      spheres: [
       {
          center: [0, -1, 3],
          radius: 1,
          color: [255, 0, 0]  # Red
        },
        {
          center: [2, 0, 4],
          radius: 1,
          color: [0, 0, 255] # Blue
        },
        {
          center: [-2, 0, 4],
          radius: 1,
          color: [0, 255, 0] # Green
        },
        {
          center: [0, -5001, 0], # Yellow
          radius: 5000,
          color: [255, 255, 0]
        }
      ],
      lights: [
        {
          type: "ambient",
          intensity: 0.2
        },
        {
          type: "point",
          intensity: 0.6,
          position: [2, 1, 0]
        },
        {
          type: "directional",
          intensity: 0.2,
          direction: [1, 4, 4]
        }
      ]
    }
  end
end
