class Display
  property gfx : Slice(Slice(UInt8))
  property window

  def initialize(@width = 64, @height = 32, @scale = 10)
    @gfx = Slice(Slice(UInt8)).new @height { Slice(UInt8).new(@width, 0_u8) }

    @window = SDL::Window.new("Chip-8 :: Crystal", @width * @scale, @height * @scale)
    @renderer = SDL::Renderer.new @window
    @renderer.logical_size = {@width, @height}
  end

  def draw : Nil
    @gfx.each_with_index do |row, y|
      row.each_with_index do |pixel, x|
        @renderer.draw_color = (pixel == 1 ? SDL::Color[0xFF] : SDL::Color[0x00])
        @renderer.draw_point x, y
      end
    end
    @renderer.present
  end

  def clear : Nil
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
