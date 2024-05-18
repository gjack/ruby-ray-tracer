require 'rmagick'

class Canvas
  attr_reader :width, :height, :img

  def initialize(width: 600, height: 600, filename: "demo.bmp")
    @width = width
    @height = height
  end

  def img
    @img ||= Magick::Image.new(width, height)
  end

  def put_pixel(x, y, color_codes)
    img.pixel_color(x, y, "rgb(#{color_codes.join(', ')})")
  end

  def save_image
    img.write(filename)
  end
end
