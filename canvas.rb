require 'rmagick'

class Canvas
  attr_reader :width, :height, :img

  def initialize(width: 600, height: 600)
    @width = width
    @height = height
  end

  def img
    @img ||= Magick::Image.new(width, height)
  end

  def put_pixel(x, y, color_codes)
    sx = width / 2 + x
    sy = height / 2 - y

    img.pixel_color(sx, sy, "rgb(#{color_codes.join(', ')})")
  end

  def save_image(filename: "demo.bmp")
    img.write(filename)
  end
end
