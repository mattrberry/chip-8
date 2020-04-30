require "crsfml"

class Display
  property gfx : Array(Array(UInt8))
  property window

  def initialize(@width = 64, @height = 32, @scale = 10)
    @gfx = Array(Array(UInt8)).new @height { Array(UInt8).new(@width, 0_u8) }
    @window = SF::RenderWindow.new(
      SF::VideoMode.new(@width * @scale, @height * @scale), "Chip-8 :: Crystal",
      settings: SF::ContextSettings.new(depth: 24, antialiasing: 8)
    )
    @window.vertical_sync_enabled = true
  end

  def draw : Nil
    @window.clear
    @gfx.each_with_index do |row, y|
      row.each_with_index do |pixel, x|
        shape = SF::RectangleShape.new(SF.vector2(@scale, @scale))
        shape.position = SF.vector2(x * @scale, y * @scale)
        if pixel == 1
          @window.draw shape
        end
      end
    end
    @window.display
  end

  def clear : Nil
    @window.clear
    (0...@gfx.size).each do |r|
      (0...@gfx[r].size).each do |c|
        @gfx[r][c] = 0
      end
    end
    draw
  end

  def add_sprite(x : UInt8, y : UInt8, sprite : Array(UInt8)) : UInt8
    collision = 0_u8
    sprite.each_with_index do |pixel, row|
      (0...8).each do |col|
        if pixel & (0x80 >> col) > 0
          y_pos = (y + row) % @height
          x_pos = (x + col) % @width
          collision |= @gfx[y_pos][x_pos]
          @gfx[y_pos][x_pos] ^= 1
        end
      end
    end
    draw
    collision
  end
end
