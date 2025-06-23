require "raylib-cr"

puts "Testing Raylib..."

begin
  RL.init_window(800, 600, "Test Window")
  RL.set_target_fps(60)

  puts "Window initialized"

  frame_count = 0
  while !RL.close_window? && frame_count < 300
    RL.begin_drawing
    RL.clear_background(RL::RAYWHITE)
    RL.draw_text("PACE Editor Test - Frame #{frame_count}", 10, 10, 20, RL::BLACK)
    RL.end_drawing
    frame_count += 1
  end

  puts "Closing after #{frame_count} frames"
  RL.close_window
rescue ex
  puts "Error: #{ex.message}"
  puts ex.backtrace.join("\n")
end

puts "Test complete"
