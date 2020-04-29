require "./chip-8/cpu"

# TODO: Write documentation for `Chip::8`
module Chip8
  VERSION = "0.1.0"

  # TODO: Put your code here

  extend self

  def run
    if ARGV.size != 1
      raise "Only arg should be the path to the rom"
    end

    rom = Bytes.new 0xfff - 0x200
    File.open(ARGV[0]) { |file| file.read rom }

    cpu = CPU.new rom
    cpu.run
  end
end

Chip8.run