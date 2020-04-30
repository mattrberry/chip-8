require "./chip-8/cpu"
require "./chip-8/display"

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

    display = Display.new
    cpu = CPU.new rom, display
    cpu.run
  end
end

unless PROGRAM_NAME.includes?("crystal-run-spec")
  Chip8.run
end
