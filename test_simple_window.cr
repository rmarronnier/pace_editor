require "raylib-cr"

puts "Testing simple Raylib window..."

begin
  Raylib.init_window(800, 600, "Test Window")
  puts "Window initialized successfully"
  
  Raylib.set_target_fps(60)
  
  frame_count = 0
  while !Raylib.close_window?
    Raylib.begin_drawing
    Raylib.clear_background(Raylib::RAYWHITE)
    Raylib.draw_text("Test Window - Press ESC to close", 10, 10, 20, Raylib::BLACK)
    Raylib.draw_text("Frame: #{frame_count}", 10, 40, 20, Raylib::BLACK)
    Raylib.end_drawing
    
    frame_count += 1
    
    # Auto-close after 5 seconds for testing
    if frame_count > 300
      puts "Auto-closing after 300 frames"
      break
    end
  end
  
  Raylib.close_window
  puts "Window closed successfully"
rescue ex
  puts "Error: #{ex.message}"
  puts ex.backtrace.join("\n")
end

puts "Test complete"