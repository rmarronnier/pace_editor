require "point_click_engine"

# Simple test to see basic Raylib functions
RL.init_window(800, 600, "Test")
RL.set_target_fps(60)

while !RL.close_window?
  RL.begin_drawing
  RL.clear_background(RL::DARKGRAY)
  RL.draw_text("Hello PACE Editor!", 190, 200, 20, RL::LIGHTGRAY)
  RL.end_drawing
end

RL.close_window
