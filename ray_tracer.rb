require_relative "canvas"
require_relative "viewport"
require_relative "camera"
require_relative "vector"

class RayTracer
  include Math
  
  attr_reader :canvas, :camera, :viewport, :scene

  INFINITY = Float::INFINITY
  BACKGROUND_COLOR = [0, 0, 0] # black

  def initialize
    @canvas ||= Canvas.new
  end

  def canvas_to_viewport_coordinates(x, y)
    [x * viewport.width.to_f / canvas.width, y * viewport.height.to_f / canvas.height, camera.distance]
  end

  def trace_ray(origin, canvas_to_viewport, t_min, t_max, recursion_depth = 3)
    closest_sphere, closest_t = closest_intersection(origin, canvas_to_viewport, t_min, t_max)
    if closest_sphere.nil?
      return BACKGROUND_COLOR
    end

    # calculate the point where the light touches the sphere
    light_intersection = (0..2).map do |i|
      origin[i] + (canvas_to_viewport[i] * closest_t)
    end

    # find the vector normal to the surface at the intersection point
    normal_at_intersection = Vector.from_two_points(head: light_intersection, tail: closest_sphere[:center])

    # normalize the vector
    normalized = Vector.divide(normal_at_intersection, normal_at_intersection.magnitude)

    # calculate the light intensity at the point
    light_intensity = compute_lighting(light_intersection, normalized, Vector.invert_direction(Vector.new(canvas_to_viewport)), closest_sphere[:specular])

    # calculate the shade of the color at the corresponding pixel
    local_color = closest_sphere[:color].map do |code|
      [255, [0 , (code * light_intensity)].max].min
    end

    # if we hit the recursion limit or the object is not reflective we are done
    rf = closest_sphere[:reflective]
    if recursion_depth <= 0 || rf <= 0
      return local_color
    end

    # compute the reflected color
    reflected = reflect_ray(Vector.invert_direction(Vector.new(canvas_to_viewport)), normalized)
    reflected_color = trace_ray(light_intersection, reflected.as_coords, 0.0001, INFINITY, recursion_depth - 1)

    # blend colors

    local_weigthed =local_color.map {|code| code * (1 - rf) }
    reflected_weighted =  reflected_color.map { |code| code * rf }

    [local_weigthed[0] + reflected_weighted[0], local_weigthed[1] + reflected_weighted[1], local_weigthed[2] + reflected_weighted[2]]
  end

  def closest_intersection(origin, canvas_to_viewport, t_min, t_max)
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

    [closest_sphere, closest_t]
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
    
    t1 = (-b + sqrt(discriminant)) / (2 * a)
    t2 = (-b - sqrt(discriminant)) / (2 * a)

    [t1, t2]
  end

  def paint_scene
    (-canvas.width / 2 .. canvas.width / 2).each do |x|
      (-canvas.height / 2 .. canvas.height / 2).each do |y|
        ctv = canvas_to_viewport_coordinates(x, y)
        direction = Vector.multiply_vector_matrix(ctv, camera.rotation)
        color = trace_ray(camera.origin, direction, 1, INFINITY)
        canvas.put_pixel(x, y, color)
      end
    end

    canvas.save_image(filename: "sixth_example.bmp")
  end

  def reflect_ray(ray, normal)
    Vector.subtract(minuend: Vector.multiply(normal, 2.0 * normal.dot_product(ray)), subtrahend: ray)
  end

  # calculate the light intensity for each point
  # by combining the intensity of all light sources
  def compute_lighting(light_intersection, norm, vector_obj_camera, specular)
    intensity = 0.0

    scene[:lights].each do |light|
      if light[:type] == "ambient"
        intensity += light[:intensity]
      else
        light_ray = if light[:type] == "point"
          t_max = 1
          Vector.from_two_points(head: light[:position], tail: light_intersection)
        else
          t_max = INFINITY
          Vector.new(light[:direction])
        end

        # Shadow check
        shadow_sphere, _shadow_t = closest_intersection(light_intersection, light_ray.as_coords, 0.0001, t_max)

        return intensity unless shadow_sphere.nil?

        # diffuse
        n_dot_l = norm.dot_product(light_ray)

        # if the product is zero this light source is not located in any useful place that contributes
        # to the ilumination of the scene
        if n_dot_l > 0
          intensity += light[:intensity] * (n_dot_l / (norm.magnitude * light_ray.magnitude))
        end

        # specular
        if specular != -1
          reflection_vector = reflect_ray(light_ray, norm)
          ref_dot_vector_obj_camera = reflection_vector.dot_product(vector_obj_camera)

          if ref_dot_vector_obj_camera > 0
            intensity += light[:intensity] * (ref_dot_vector_obj_camera / (reflection_vector.magnitude * vector_obj_camera.magnitude))**specular
          end
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
      camera: Camera.new(rotation: [[0.7071, 0, -0.7071], [0, 1, 0], [0.7071, 0, 0.7071]], origin: [3, 0, 1]),
      viewport: Viewport.new,
      spheres: [
       {
          center: [0, -1, 3],
          radius: 1,
          color: [255, 0, 0],  # Red
          specular: 500, # shiny
          reflective: 0.2  # a little reflective
        },
        {
          center: [2, 0, 4],
          radius: 1,
          color: [0, 0, 255], # Blue
          specular: 500, # shiny
          reflective: 0.3 # more reflective
        },
        {
          center: [-2, 0, 4],
          radius: 1,
          color: [0, 255, 0], # Green
          specular: 10, # somewhat shiny
          reflective: 0.4
        },
        {
          center: [0, -5001, 0], # Yellow
          radius: 5000,
          color: [255, 255, 0],
          specular: 1000, # very shiny
          reflective: 0.5 # half of possible reflectiveness
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
