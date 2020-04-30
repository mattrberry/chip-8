require "./spec_helper"

display = Display.new
cpu = CPU.new Slice.new(0xFF, 0x0_u8), display

describe CPU do
  Spec.before_each do
    cpu.reset
  end

  describe "0x0..." do
    describe "0x00E0" do
      it "clears the screen" do
        display.gfx.each do |row|
          (0...row.size).each do |i|
            row[i] = (i % 2).to_u8
          end
        end

        cpu.process_opcode 0x00E0

        display.gfx.each do |row|
          row.each do |pixel|
            pixel.should eq 0
          end
        end
      end
    end

    describe "0x00EE" do
      it "updates the program counter, stack, and stack pointer in return" do
        addr = 0x123_u16
        cpu.pc = addr

        cpu.process_opcode 0x2456
        cpu.process_opcode 0x00EE

        cpu.pc.should eq addr + 2
        cpu.sp.should eq 0
      end
    end

    describe "0x0..." do
      # todo
    end
  end

  describe "0x1..." do
    it "updates program counter" do
      cpu.process_opcode 0x1234
      cpu.pc.should eq 0x0234
    end
  end

  describe "0x2..." do
    it "updates program counter, stack, and stack pointer in call" do
      addr = 0x123_u16
      cpu.pc = addr

      cpu.process_opcode 0x2456

      cpu.pc.should eq 0x0456
      cpu.sp.should eq 1
      cpu.stack[0].should eq addr + 2
    end
  end

  describe "0x3..." do
    it "skips if vx == nn" do
      cpu.pc = 0_u8
      cpu.v[1] = 0x23
      cpu.process_opcode 0x3123
      cpu.pc.should eq 4
    end

    it "doesn't skip if vx != nn" do
      cpu.pc = 0_u8
      cpu.v[1] = 0x23
      cpu.process_opcode 0x3125
      cpu.pc.should eq 2
    end
  end

  describe "0x4..." do
    it "doesn't skip if vx == nn" do
      cpu.pc = 0_u8
      cpu.v[1] = 0x23
      cpu.process_opcode 0x4123
      cpu.pc.should eq 2
    end

    it "skips if vx != nn" do
      cpu.pc = 0_u8
      cpu.v[1] = 0x23
      cpu.process_opcode 0x4125
      cpu.pc.should eq 4
    end
  end

  describe "0x5..." do
    it "skips if vx == vy" do
      cpu.pc = 0_u8
      cpu.v[1] = 0x23
      cpu.v[2] = 0x23
      cpu.process_opcode 0x5120
      cpu.pc.should eq 4
    end

    it "doesn't skip if vx != vy" do
      cpu.pc = 0_u8
      cpu.v[1] = 0x23
      cpu.v[2] = 0x34
      cpu.process_opcode 0x5120
      cpu.pc.should eq 2
    end
  end

  describe "0x6..." do
    it "sets vx to nn" do
      cpu.process_opcode 0x6371
      cpu.v[3].should eq 0x71
    end
  end

  describe "0x7..." do
    it "adds vx to nn" do
      cpu.v[3] = 0x3A
      cpu.process_opcode 0x7371
      cpu.v[3].should eq 0x71 + 0x3A
    end
  end

  describe "0x8..." do
    describe "0x8..0" do
      it "sets vx to vy" do
        cpu.v[0] = 0xAE
        cpu.process_opcode 0x8100
        cpu.v[1].should eq 0xAE
      end
    end

    describe "0x8..1" do
      it "sets vx to vx | vy" do
        cpu.v[0] = 0x0A
        cpu.v[1] = 0xF0
        cpu.process_opcode 0x8101
        cpu.v[1].should eq 0xFA
      end
    end

    describe "0x8..2" do
      it "sets vx to vx & vy" do
        cpu.v[0] = 0x02
        cpu.v[1] = 0xFA
        cpu.process_opcode 0x8102
        cpu.v[1].should eq 0x02
      end
    end

    describe "0x8..3" do
      it "sets vx to vx ^ vy" do
        cpu.v[0] = 0x0A
        cpu.v[1] = 0xFA
        cpu.process_opcode 0x8103
        cpu.v[1].should eq 0xF0
      end
    end

    describe "0x8..4" do
      it "adds vy to vx" do
        cpu.v[0] = 0xAE
        cpu.v[1] = 0x12
        cpu.process_opcode 0x8104
        cpu.v[1].should eq 0xC0
        cpu.v[0xF].should eq 0x0
      end

      it "adds vy to vx w/ overflow" do
        cpu.v[0] = 0x01
        cpu.v[1] = 0xFF
        cpu.process_opcode 0x8104
        cpu.v[1].should eq 0x0
        cpu.v[0xF].should eq 0x1
      end
    end

    describe "0x8..5" do
      it "subs vy from vx" do
        cpu.v[0] = 0x99
        cpu.v[1] = 0xFF
        cpu.process_opcode 0x8105
        cpu.v[1].should eq 0x66
        cpu.v[0xF].should eq 0x1
      end

      it "subs vy from vx w/ borrow" do
        cpu.v[0] = 0xFF
        cpu.v[1] = 0x99
        cpu.process_opcode 0x8105
        cpu.v[1].should eq 0x9A
        cpu.v[0xF].should eq 0x0
      end
    end

    describe "0x8..6" do
      it "stores lsb of vx and shifts right" do
        cpu.v[0] = 0b01010101
        cpu.process_opcode 0x8006
        cpu.v[0].should eq 0b00101010
        cpu.v[0xF].should eq 0x1
      end
    end

    describe "0x8..7" do
      it "subs vx from vy, stores in vx" do
        cpu.v[0] = 0xFF
        cpu.v[1] = 0x99
        cpu.process_opcode 0x8107
        cpu.v[1].should eq 0x66
        cpu.v[0xF].should eq 0x1
      end

      it "subs vx from vy, stores in vx w/ borrow" do
        cpu.v[0] = 0x99
        cpu.v[1] = 0xFF
        cpu.process_opcode 0x8107
        cpu.v[1].should eq 0x9A
        cpu.v[0xF].should eq 0x0
      end
    end

    describe "0x8..E" do
      it "stores msb of vx and shifts left" do
        cpu.v[0] = 0b10101010
        cpu.process_opcode 0x800E
        cpu.v[0].should eq 0b01010100
        cpu.v[0xF].should eq 0x1
      end
    end
  end

  describe "0x9..." do
    it "doesn't skip if vx == vy" do
      cpu.pc = 0_u8
      cpu.v[1] = 0x23
      cpu.v[2] = 0x23
      cpu.process_opcode 0x9120
      cpu.pc.should eq 2
    end

    it "skips if vx != vy" do
      cpu.pc = 0_u8
      cpu.v[1] = 0x23
      cpu.v[2] = 0x34
      cpu.process_opcode 0x9120
      cpu.pc.should eq 4
    end
  end

  describe "0xA..." do
    it "sets i to nnn" do
      cpu.process_opcode 0xA123
      cpu.i.should eq 0x123
    end
  end

  describe "0xB..." do
    it "jumps to nnn + v0" do
      cpu.v[0] = 0x66
      cpu.process_opcode 0xB612
      cpu.pc.should eq 0x0678
    end
  end

  describe "0xC..." do
    it "ands random with 0" do
      cpu.v[0] = 0x56
      cpu.process_opcode 0xC000
      cpu.v[0].should eq 0x0
    end
  end

  describe "0xD..." do
    it "draws a simple 1-tall sprite" do
      cpu.v[5] = 0x0
      cpu.v[6] = 0x0
      cpu.i = 0x300_u16
      cpu.memory[cpu.i] = 0b01010101

      cpu.process_opcode 0xD561

      display.gfx[0][0, 8].should eq [0, 1, 0, 1, 0, 1, 0, 1]
      display.gfx[1][0, 8].should eq [0, 0, 0, 0, 0, 0, 0, 0]
      cpu.v[0xF].should eq 0
    end

    it "draws a tall sprite" do
      cpu.v[5] = 0x0
      cpu.v[6] = 0x0
      cpu.i = 0x300_u16
      cpu.memory[cpu.i + 0] = 0b00000000
      cpu.memory[cpu.i + 1] = 0b00000001
      cpu.memory[cpu.i + 2] = 0b00000011
      cpu.memory[cpu.i + 3] = 0b00000111
      cpu.memory[cpu.i + 4] = 0b00001111
      cpu.memory[cpu.i + 5] = 0b00011111
      cpu.memory[cpu.i + 6] = 0b00111111
      cpu.memory[cpu.i + 7] = 0b01111111

      cpu.process_opcode 0xD568

      display.gfx[0][0, 8].should eq [0, 0, 0, 0, 0, 0, 0, 0]
      display.gfx[1][0, 8].should eq [0, 0, 0, 0, 0, 0, 0, 1]
      display.gfx[2][0, 8].should eq [0, 0, 0, 0, 0, 0, 1, 1]
      display.gfx[3][0, 8].should eq [0, 0, 0, 0, 0, 1, 1, 1]
      display.gfx[4][0, 8].should eq [0, 0, 0, 0, 1, 1, 1, 1]
      display.gfx[5][0, 8].should eq [0, 0, 0, 1, 1, 1, 1, 1]
      display.gfx[6][0, 8].should eq [0, 0, 1, 1, 1, 1, 1, 1]
      display.gfx[7][0, 8].should eq [0, 1, 1, 1, 1, 1, 1, 1]
      display.gfx[8][0, 8].should eq [0, 0, 0, 0, 0, 0, 0, 0]
      cpu.v[0xF].should eq 0
    end

    it "wraps sprites" do
      cpu.v[5] = 63
      cpu.v[6] = 31
      cpu.i = 0x300_u16
      cpu.memory[cpu.i + 0] = 0b11000000
      cpu.memory[cpu.i + 1] = 0b11000000

      cpu.process_opcode 0xD562

      cpu.v[0xF].should eq 0
      # top left pixel stays at bottom right of screen
      display.gfx[30][62, 2].should eq [0, 0]
      display.gfx[31][62, 2].should eq [0, 1]
      # top right pixel wraps to left of screen
      display.gfx[30][0, 2].should eq [0, 0]
      display.gfx[31][0, 2].should eq [1, 0]
      # bottom left pixel wraps to top of screen
      display.gfx[0][62, 2].should eq [0, 1]
      display.gfx[1][62, 2].should eq [0, 0]
      # bottom right pixel wraps to top left of screen
      display.gfx[0][0, 2].should eq [1, 0]
      display.gfx[1][0, 2].should eq [0, 0]
    end

    it "detects exact collision" do
      cpu.v[5] = 0x0
      cpu.v[6] = 0x0
      cpu.i = 0x300_u16
      cpu.memory[cpu.i] = 0xFF

      cpu.process_opcode 0xD561
      display.gfx[0][0, 8].should eq [1, 1, 1, 1, 1, 1, 1, 1]
      display.gfx[1][0, 8].should eq [0, 0, 0, 0, 0, 0, 0, 0]
      cpu.v[0xF].should eq 0

      cpu.process_opcode 0xD561
      display.gfx[0][0, 8].should eq [0, 0, 0, 0, 0, 0, 0, 0]
      display.gfx[1][0, 8].should eq [0, 0, 0, 0, 0, 0, 0, 0]
      cpu.v[0xF].should eq 1
    end

    it "detects corner collision" do
      cpu.v[5] = 0x0
      cpu.v[6] = 0x0
      cpu.v[7] = 0x7
      cpu.v[8] = 0x1
      cpu.i = 0x250_u16
      cpu.memory[cpu.i + 0] = 0x80
      cpu.memory[cpu.i + 1] = 0x01

      cpu.process_opcode 0xD562
      cpu.v[0xF].should eq 0

      cpu.process_opcode 0xD782
      cpu.v[0xF].should eq 1
    end

    it "doesn't count collisions without a flip" do
      cpu.v[5] = 0x0
      cpu.v[6] = 0x0
      cpu.i = 0x204_u16

      cpu.memory[cpu.i] = 0b01010101
      cpu.process_opcode 0xD561
      cpu.v[0xF].should eq 0

      cpu.memory[cpu.i] = 0b10101010
      cpu.process_opcode 0xD561
      cpu.v[0xF].should eq 0
    end
  end

  describe "0xE..." do
    # todo
  end

  describe "0xF..." do
    describe "0xF.07" do
      it "sets vx to delay timer" do
        cpu.delay_timer = 0x05_u8
        cpu.process_opcode 0xF007
        cpu.v[0].should eq 0x05
      end
    end

    describe "0xF.0A" do
      it "" do
        # todo
      end
    end

    describe "0xF.15" do
      it "sets delay timer to vx" do
        cpu.v[0] = 0x03
        cpu.process_opcode 0xF015
        cpu.delay_timer.should eq 0x03
      end
    end

    describe "0xF.18" do
      it "sets sound timer to vx" do
        cpu.v[0] = 0x04
        cpu.process_opcode 0xF018
        cpu.sound_timer.should eq 0x04
      end
    end

    describe "0xF.1E" do
      it "sets i to i + vx" do
        cpu.i = 3_u16
        cpu.v[1] = 2
        cpu.process_opcode 0xF11E
        cpu.i.should eq 5
      end
    end

    describe "0xF.29" do
      it "sets i to location of hexadecimal sprite" do
        cpu.v[3] = 5
        cpu.process_opcode 0xF329
        cpu.i.should eq 25
      end
    end

    describe "0xF.33" do
      it "does decimal math" do
        cpu.i = 0x0300_u16
        cpu.v[0] = 253
        cpu.process_opcode 0xF033
        cpu.memory[0x300].should eq 2
        cpu.memory[0x301].should eq 5
        cpu.memory[0x302].should eq 3
      end
    end

    describe "0xF.55" do
      it "copies registers into memory" do
        cpu.i = 0x300_u16
        cpu.v[0] = 4
        cpu.v[1] = 3
        cpu.v[2] = 2
        cpu.v[3] = 1
        cpu.v.size.should eq 16
        cpu.memory.size.should eq 4096
        cpu.process_opcode 0xF355
        cpu.memory[0x300].should eq 4
        cpu.memory[0x301].should eq 3
        cpu.memory[0x302].should eq 2
        cpu.memory[0x303].should eq 1
        cpu.v.size.should eq 16
        cpu.memory.size.should eq 4096
      end
    end

    describe "0xF.65" do
      it "copies memory into registers" do
        cpu.i = 0x300_u16
        cpu.memory[0x300] = 4
        cpu.memory[0x301] = 3
        cpu.memory[0x302] = 2
        cpu.memory[0x303] = 1
        cpu.v.size.should eq 16
        cpu.memory.size.should eq 4096
        cpu.process_opcode 0xF365
        cpu.v[0].should eq 4
        cpu.v[1].should eq 3
        cpu.v[2].should eq 2
        cpu.v[3].should eq 1
        cpu.v.size.should eq 16
        cpu.memory.size.should eq 4096
      end
    end
  end
end
