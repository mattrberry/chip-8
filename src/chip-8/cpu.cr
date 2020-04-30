require "./util"

class CPU
  property memory : Array(UInt8)
  property v : Array(UInt8)
  property i : UInt16
  property pc : UInt16
  property delay_timer : UInt8
  property sound_timer : UInt8
  property stack : Array(UInt16)
  property sp : UInt16

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
    0xF0, 0x80, 0xF0, 0x80, 0x80, # F
  }

  def initialize(@rom : Bytes, @display : Display)
    @memory = Array.new 4096, 0_u8
    @v = Array.new 16, 0_u8
    @i = 0_u16
    @pc = 0x200_u16
    @delay_timer = 0_u8
    @sound_timer = 0_u8
    @stack = Array.new 16, 0_u16
    @sp = 0_u16

    self.reset
  end

  def reset : Nil
    @memory = Array.new 4096, 0_u8
    @v = Array.new 16, 0_u8
    @i = 0_u16
    @pc = 0x200_u16
    @delay_timer = 0_u8
    @sound_timer = 0_u8
    @stack = Array.new 16, 0_u16
    @sp = 0_u16

    @fontset.each_with_index do |byte, i|
      @memory[i] = byte
    end
    @rom.each_with_index do |byte, i|
      @memory[0x200 + i] = byte
    end

    @display.clear
  end

  def run : Nil
    repeat hz: 60, in_fiber: true { update_timers }
    repeat hz: 500 { emulate_cycle }
  end

  def emulate_cycle : Nil
    while event = @display.window.poll_event
      case event
      when SF::Event::Closed
        @display.window.close
        puts "window closed"
        exit 0
      end
    end

    opcode = read_opcode
    process_opcode opcode
  end

  def read_opcode : UInt16
    @memory[@pc].to_u16 << 8 | @memory[@pc + 1]
  end

  def process_opcode(opcode : UInt16) : Nil
    op_1 = (opcode & 0xF000) >> 12
    op_2 = (opcode & 0x0F00) >> 8
    op_3 = (opcode & 0x00F0) >> 4
    op_4 = (opcode & 0x000F)

    x = op_2
    y = op_3
    n = op_4.to_u8
    nn = (opcode & 0x00FF).to_u8
    nnn = opcode & 0x0FFF

    @pc += 2

    case {op_1, op_2, op_3, op_4}
    when {0x0, 0x0, 0xE, 0x0} then @display.clear
    when {0x0, 0x0, 0xE, 0xE} then @pc = @stack[@sp -= 1]
    when {0x0, _, _, _}       then nil # todo
    when {0x1, _, _, _}       then @pc = nnn
    when {0x2, _, _, _}
      @stack[@sp] = @pc
      @sp += 1
      @pc = nnn
    when {0x3, _, _, _}   then @pc += 2 if @v[x] == nn
    when {0x4, _, _, _}   then @pc += 2 if @v[x] != nn
    when {0x5, _, _, _}   then @pc += 2 if @v[x] == @v[y]
    when {0x6, _, _, _}   then @v[x] = nn
    when {0x7, _, _, _}   then @v[x] &+= nn
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
      @v[0xF] = (@v[x] & 0x80) >> 7
      @v[x] <<= 1
    when {0x9, _, _, _}     then @pc += 2 if @v[x] != @v[y]
    when {0xA, _, _, _}     then @i = nnn
    when {0xB, _, _, _}     then @pc = @v[0].to_u16 + nnn
    when {0xC, _, _, _}     then @v[x] = (Random.rand * 256).to_u8 & nn
    when {0xD, _, _, _}     then @v[0xF] = @display.add_sprite @v[x], @v[y], @memory[@i, n]
    when {0xE, _, 0x9, 0xE} then nil      # todo
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
      @memory[@i + 2] = ((@v[x] % 100) % 10).to_u8
    when {0xF, _, 0x5, 0x5} then @memory[@i, x + 1] = @v[0, x + 1]
    when {0xF, _, 0x6, 0x5} then @v[0, x + 1] = @memory[@i, x + 1]
    else
      puts "unmatched case #{opcode.to_s 16}"
      exit 1
    end
  end

  def update_timers : Nil
    @delay_timer -= 1 if @delay_timer > 0
    @sound_timer -= 1 if @sound_timer > 0
  end
end
