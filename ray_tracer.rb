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

  def canvas_to_viewport_vector(x, y) 
    [x * viewport.width.to_f / canvas.width, y * viewport.height.to_f / canvas.height, camera.distance]
  end

  def trace_ray(origin, canvas_to_viewport, t_min, t_max)
    closest_t = INFINITY
    closest_sphere = nil

    scene[:spheres].each do |sphere|
      t1, t2 = intersect_ray_sphere(camera.origin, canvas_to_viewport, sphere)
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

    closest_sphere[:color]
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
        ctv_vector = canvas_to_viewport_vector(x, y)
        color = trace_ray(camera.origin, ctv_vector, 1, INFINITY)
        canvas.put_pixel(x, y, color)
      end
    end

    canvas.save_image(filename: "first_example.bmp")
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
        }
      ]
    }
  end
end
