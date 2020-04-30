require "crsfml"

class Display
  property gfx : Array(Array(UInt8))

  def initialize(@width = 64, @height = 32, @scale = 10)
    @gfx = Array(Array(UInt8)).new 32 { Array(UInt8).new(64, 0_u8) }
  end

  def draw : Nil
    (0...6).each do
      (0...10).each do |i|
        if i.even?
          print i
        else
          print " "
        end
      end
    end
    puts ""
    @gfx.each do |row|
      row.each do |pixel|
        if pixel == 0
          print "█"
        else
          print " "
        end
      end
      puts ""
    end
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
