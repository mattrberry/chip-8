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
