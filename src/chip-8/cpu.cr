class CPU
    @opcode : UInt16 = 0_u16
    @memory = Array(UInt8).new 4096, 0_u8
    @v = Array(UInt8).new 16, 0_u8
    @i : UInt16 = 0_u16
    @pc : UInt16 = 0x200_u16
    @gfx = Array(Array(UInt8)).new 32 { Array(UInt8).new(64, 0_u8) }
    @delay_timer : UInt8 = 0_u8
    @sound_timer : UInt8 = 0_u8
    @stack = Array(UInt16).new 16, 0_u16
    @sp : UInt16 = 0_u16
    @key = Array(UInt8).new 16, 0_u8
  
    @draw_flag = false
  
    @fontset = Array(UInt8){
      0xF0, 0x90, 0x90, 0x90, 0xF0, # 0
      0x20, 0x60, 0x20, 0x20, 0x70, # 1
      0xF0, 0x10, 0xF0, 0x80, 0xF0, # 2
      0xF0, 0x10, 0xF0, 0x10, 0xF0, # 3
      0x90, 0x90, 0xF0, 0x10, 0x10, # 4
      0xF0, 0x80, 0xF0, 0x10, 0xF0, # 5
      0xF0, 0x80, 0xF0, 0x90, 0xF0, # 6
      0xF0, 0x10, 0x20, 0x40, 0x40, # 7
      0xF0, 0x90, 0xF0, 0x90, 0xF0, # 8
      0xF0, 0x90, 0xF0, 0x10, 0xF0, # 9
      0xF0, 0x90, 0xF0, 0x90, 0x90, # A
      0xE0, 0x90, 0xE0, 0x90, 0xE0, # B
      0xF0, 0x80, 0x80, 0x80, 0xF0, # C
      0xE0, 0x90, 0x90, 0x90, 0xE0, # D
      0xF0, 0x80, 0xF0, 0x80, 0xF0, # E
      0xF0, 0x80, 0xF0, 0x80, 0x80  # F
    }
  
    def initialize(rom : Bytes)
      @fontset.each_with_index do |byte, i|
        # @memory[0x50 + i] = byte
        @memory[i] = byte
      end
      rom.each_with_index do |byte, i|
        @memory[0x200 + i] = byte
      end
      self.print_memory
    end
  
    def print_memory
      idx = @memory.size
      @memory.reverse_each do |e|
        if e != 0
          break
        else
          idx -= 1
        end
      end
  
      @memory.each_with_index do |e, i|
        if i % 16 == 0
          puts ""
        end
        if i >= idx
          break
        end
        if i.even?
          oc = (e.to_u16 << 8) | @memory[i + 1]
          if oc == 0
            print "````"
          else
            print oc.to_s(16).rjust 4, '0'
          end
          print " "
        end
      end
      puts ""
    end
  
    def run
      hrz = 60
      loop do
        start_time = Time.utc
        next_cycle = start_time + Time::Span.new(nanoseconds: (1_000_000_000 / hrz).to_i)
        self.emulate_cycle
        draw if @draw_flag
        end_time = Time.utc
        if next_cycle > end_time
          sleep next_cycle - end_time
        end
      end
    end
  
    def draw
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
      @draw_flag = false
    end
  
    def emulate_cycle : Nil
      @opcode = @memory[@pc].to_u16 << 8 | @memory[@pc + 1]
      # puts "  opcode: #{@opcode.to_s(16).rjust(4, '0')}, pc: #{@pc}"
  
      nnn = @opcode & 0x0fff
      nn = (@opcode & 0x00ff).to_u8
      n = nn & 0x0f
      x = (@opcode & 0x0f00) >> 8
      y = (@opcode & 0x00f0) >> 4
  
      case {(@opcode & 0xf000) >> 12, (@opcode & 0x0f00) >> 8, (@opcode & 0x00f0) > 4, @opcode & 0x000f}
      when {0x0, 0x0, 0xE, 0x0}
        (0...@gfx.size).each do |r|
          (0...@gfx[r].size).each do |c|
            @gfx[r][c] = 0
          end
        end
        @draw_flag = true
      when {0x0, 0x0, 0xE, 0xE}
        @sp -= 1
        @pc = @stack[@sp]
        @pc -= 2 # todo
      when {0x0, _, _, _} then nil # todo
      when {0x1, _, _, _} then @pc = nnn
      when {0x2, _, _, _}
        @stack[@sp] = @pc
        @sp += 1
        @pc = nnn
        @pc -= 2 # todo
      when {0x3, _, _, _} then @pc += 2 if @v[x] == nn
      when {0x4, _, _, _} then @pc += 2 if @v[x] != nn
      when {0x5, _, _, _} then @pc += 2 if @v[x] == @v[y]
      when {0x6, _, _, _} then @v[x] = nn
      when {0x7, _, _, _} then @v[x] &+= nn
      when {0x8, _, _, 0x0} then @v[x] = @v[y]
      when {0x8, _, _, 0x1} then @v[x] |= @v[y]
      when {0x8, _, _, 0x2} then @v[x] &= @v[y]
      when {0x8, _, _, 0x3} then @v[x] ^= @v[y]
      when {0x8, _, _, 0x4}
        @v[x] &+= @v[y]
        @v[0xF] = @v[x] < @v[y] ? 1_u8 : 0_u8
      when {0x8, _, _, 0x5}
        @v[0xF] = @v[y] > @v[x] ? 0_u8 : 1_u8
        @v[x] &-= @v[y]
      when {0x8, _, _, 0x6}
        @v[0xF] = @v[x] & 0x1
        @v[x] >>= 1
      when {0x8, _, _, 0x7}
        @v[0xF] = @v[x] > @v[y] ? 0_u8 : 1_u8
        @v[x] = @v[y] &- @v[x]
      when {0x8, _, _, 0xE}
        @v[0xF] = @v[x] & 0x80
        @v[x] <<= 1
      when {0x9, _, _, _} then @pc += 2 if @v[x] != @v[y]
      when {0xA, _, _, _} then @i = nnn
      when {0xB, _, _, _}
        @pc = @v[0].to_u16 + nnn
        @pc -= 2 # todo
      when {0xC, _, _, _} then @v[x] = (Random.rand * 256).to_u8 & nn
      when {0xD, _, _, _}
        height = n
        s = ""
        (0...8).each do |i|
          if @memory[@i + i] == 0
            s += "█"
          else
            s += " "
          end
        end
        puts "drawing #{s} at x:#{@v[x]} y:#{@v[y]} height:#{height} "
        @v[0xF] = 0
        (0...height).each do |row|
          pixel = @memory[@i + row]
          (0...8).each do |col|
            if pixel & 0x80 > 0
              @v[0xF] |= @gfx[@v[y] + row][@v[x] + col]
              @gfx[@v[y] + row][@v[x] + col] ^= 1
            end
          end
        end
        @draw_flag = true
      when {0xE, _, 0x9, 0xE} then nil # todo
      when {0xE, _, 0xA, 0x1} then @pc += 2 # todo
      when {0xF, _, 0x0, 0x7} then @v[x] = @delay_timer
      when {0xF, _, 0x0, 0xA} then nil # todo
      when {0xF, _, 0x1, 0x5} then @delay_timer = @v[x]
      when {0xF, _, 0x1, 0x8} then @sound_timer = @v[x]
      when {0xF, _, 0x1, 0xE} then @i &+= @v[x]
      when {0xF, _, 0x2, 0x9} then @i = @v[x].to_u16 * 5
      when {0xF, _, 0x3, 0x3}
        @memory[@i] = (@v[x] / 100).to_u8
        @memory[@i + 1] = ((@v[x] / 10) % 10).to_u8
        @memory[@i + 2] = ((@v[x] / 100) % 10).to_u8
      when {0xF, _, 0x5, 0x5} then (0...x).each { |i| @memory[@i + i] = @v[i] }
      when {0xF, _, 0x6, 0x5} then (0...x).each { |i| @v[i] = @memory[@i + i] }
      end
  
      @pc += 2
  
      # update timers
      @delay_timer -= 1 if @delay_timer > 0
      if @sound_timer > 0
        @sound_timer -= 1
        puts "sound"
      end
    end
  end
  