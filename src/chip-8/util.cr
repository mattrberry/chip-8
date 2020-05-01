def repeat(hz : Int, &block)
  loop do
    start_time = Time.utc
    block.call
    end_time = Time.utc
    next_cycle = start_time + Time::Span.new nanoseconds: (1_000_000_000 / hz).to_i
    if next_cycle > end_time
      sleep next_cycle - end_time
    end
  end
end

def repeat(hz : Int, in_fiber : Bool, &block)
  if in_fiber
    spawn do
      repeat hz, &block
    end
  else
    repeat hz, &block
  end
end

def generate_tone(frequency : Int, volume : Int, duration : Float, sample_rate = 44100)
  amplitude = (volume.to_f / 100) * Int16::MAX
  increment = frequency / sample_rate
  samples = sample_rate * duration
  raw = Array(Int16).new(samples.to_i) { |i| (amplitude * Math.sin(i * increment * 2 * Math::PI)).to_i16 }
  SF::Sound.new(SF::SoundBuffer.from_samples raw, 1, sample_rate)
end
