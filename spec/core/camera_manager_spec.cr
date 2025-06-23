require "../spec_helper"

describe PaceEditor::Core::CameraManager do
  let(camera) { PaceEditor::Core::CameraManager.new(800, 600) }
  
  describe "#initialize" do
    it "creates camera with default values" do
      camera.x.should eq(0.0_f32)
      camera.y.should eq(0.0_f32)
      camera.zoom.should eq(PaceEditor::Constants::DEFAULT_ZOOM)
      camera.viewport_width.should eq(800)
      camera.viewport_height.should eq(600)
    end
    
    it "creates camera without viewport dimensions" do
      empty_camera = PaceEditor::Core::CameraManager.new
      empty_camera.viewport_width.should eq(0)
      empty_camera.viewport_height.should eq(0)
    end
  end
  
  describe "#update" do
    it "smoothly moves to target position" do
      camera.target_x = 100.0_f32
      camera.target_y = 50.0_f32
      
      initial_x = camera.x
      initial_y = camera.y
      
      camera.update(0.016_f32)  # ~60 FPS
      
      # Should move towards target but not reach it immediately with smooth movement
      camera.x.should be > initial_x
      camera.y.should be > initial_y
      camera.x.should be < 100.0_f32
      camera.y.should be < 50.0_f32
    end
    
    it "instantly moves to target with smooth movement disabled" do
      camera.smooth_movement = false
      camera.target_x = 100.0_f32
      camera.target_y = 50.0_f32
      
      camera.update(0.016_f32)
      
      camera.x.should eq(100.0_f32)
      camera.y.should eq(50.0_f32)
    end
    
    it "clamps zoom to valid range" do
      camera.target_zoom = -1.0_f32
      camera.update(0.016_f32)
      camera.zoom.should eq(PaceEditor::Constants::MIN_ZOOM)
      
      camera.target_zoom = 10.0_f32
      camera.update(0.016_f32)
      camera.zoom.should eq(PaceEditor::Constants::MAX_ZOOM)
    end
  end
  
  describe "#pan" do
    it "pans camera by relative amount" do
      initial_target_x = camera.target_x
      initial_target_y = camera.target_y
      
      camera.pan(50.0_f32, 30.0_f32)
      
      camera.target_x.should eq(initial_target_x + 50.0_f32)
      camera.target_y.should eq(initial_target_y + 30.0_f32)
    end
    
    it "accounts for zoom when panning" do
      camera.zoom = 2.0_f32
      initial_target_x = camera.target_x
      
      camera.pan(100.0_f32, 0.0_f32)
      
      # Pan amount should be divided by zoom
      camera.target_x.should eq(initial_target_x + 50.0_f32)
    end
  end
  
  describe "#set_position" do
    it "sets camera target position directly" do
      camera.set_position(123.5_f32, 456.7_f32)
      
      camera.target_x.should eq(123.5_f32)
      camera.target_y.should eq(456.7_f32)
    end
  end
  
  describe "#set_zoom" do
    it "sets zoom level within bounds" do
      camera.set_zoom(2.0_f32)
      camera.target_zoom.should eq(2.0_f32)
    end
    
    it "clamps zoom to minimum" do
      camera.set_zoom(-1.0_f32)
      camera.target_zoom.should eq(PaceEditor::Constants::MIN_ZOOM)
    end
    
    it "clamps zoom to maximum" do
      camera.set_zoom(10.0_f32)
      camera.target_zoom.should eq(PaceEditor::Constants::MAX_ZOOM)
    end
  end
  
  describe "#screen_to_world" do
    it "converts screen coordinates to world coordinates" do
      camera.x = 100.0_f32
      camera.y = 50.0_f32
      camera.zoom = 2.0_f32
      camera.smooth_movement = false
      camera.update(0.0_f32)  # Apply position immediately
      
      screen_pos = RL::Vector2.new(400.0_f32, 300.0_f32)  # Center of 800x600 screen
      world_pos = camera.screen_to_world(screen_pos)
      
      world_pos.x.should eq(100.0_f32)  # Should equal camera position at center
      world_pos.y.should eq(50.0_f32)
    end
  end
  
  describe "#world_to_screen" do
    it "converts world coordinates to screen coordinates" do
      camera.x = 100.0_f32
      camera.y = 50.0_f32
      camera.zoom = 2.0_f32
      camera.smooth_movement = false
      camera.update(0.0_f32)
      
      world_pos = RL::Vector2.new(100.0_f32, 50.0_f32)
      screen_pos = camera.world_to_screen(world_pos)
      
      screen_pos.x.should eq(400.0_f32)  # Center of 800x600 screen
      screen_pos.y.should eq(300.0_f32)
    end
  end
  
  describe "#is_visible?" do
    it "returns true for visible rectangles" do
      # Rectangle at camera center should be visible
      rect = RL::Rectangle.new(0.0_f32, 0.0_f32, 50.0_f32, 50.0_f32)
      camera.is_visible?(rect).should be_true
    end
    
    it "returns false for rectangles outside view" do
      # Rectangle far away should not be visible
      rect = RL::Rectangle.new(10000.0_f32, 10000.0_f32, 50.0_f32, 50.0_f32)
      camera.is_visible?(rect).should be_false
    end
  end
  
  describe "#get_visible_world_bounds" do
    it "returns visible world area" do
      camera.x = 100.0_f32
      camera.y = 50.0_f32
      camera.zoom = 1.0_f32
      camera.smooth_movement = false
      camera.update(0.0_f32)
      
      bounds = camera.get_visible_world_bounds
      
      # Bounds should be centered on camera position
      bounds.x.should be < 100.0_f32
      bounds.y.should be < 50.0_f32
      bounds.width.should be > 0
      bounds.height.should be > 0
    end
  end
  
  describe "#focus_on" do
    it "sets camera target to focus point" do
      camera.focus_on(200.0_f32, 150.0_f32)
      
      camera.target_x.should eq(200.0_f32)
      camera.target_y.should eq(150.0_f32)
    end
  end
  
  describe "#focus_on_bounds" do
    it "focuses camera on rectangle bounds" do
      bounds = RL::Rectangle.new(100.0_f32, 100.0_f32, 200.0_f32, 100.0_f32)
      camera.focus_on_bounds(bounds)
      
      # Should center on bounds
      camera.target_x.should eq(200.0_f32)  # 100 + 200/2
      camera.target_y.should eq(150.0_f32)  # 100 + 100/2
      
      # Should set appropriate zoom
      camera.target_zoom.should be > 0
    end
  end
  
  describe "#reset" do
    it "resets camera to default state" do
      camera.set_position(100.0_f32, 50.0_f32)
      camera.set_zoom(2.0_f32)
      
      camera.reset
      
      camera.target_x.should eq(0.0_f32)
      camera.target_y.should eq(0.0_f32)
      camera.target_zoom.should eq(PaceEditor::Constants::DEFAULT_ZOOM)
    end
  end
  
  describe "#set_viewport_size" do
    it "updates viewport dimensions" do
      camera.set_viewport_size(1024, 768)
      
      camera.viewport_width.should eq(1024)
      camera.viewport_height.should eq(768)
    end
  end
  
  describe "#to_hash and #from_hash" do
    it "serializes and deserializes camera state" do
      camera.x = 123.0_f32
      camera.y = 456.0_f32
      camera.zoom = 2.5_f32
      
      hash = camera.to_hash
      
      new_camera = PaceEditor::Core::CameraManager.new
      new_camera.from_hash(hash)
      
      new_camera.x.should eq(123.0_f32)
      new_camera.y.should eq(456.0_f32)
      new_camera.zoom.should eq(2.5_f32)
    end
    
    it "handles missing hash values" do
      hash = Hash(String, Float32).new
      camera.from_hash(hash)
      
      camera.x.should eq(0.0_f32)
      camera.y.should eq(0.0_f32)
      camera.zoom.should eq(PaceEditor::Constants::DEFAULT_ZOOM)
    end
  end
  
  describe "#to_s" do
    it "provides readable string representation" do
      camera.x = 123.45_f32
      camera.y = 678.90_f32
      camera.zoom = 1.5_f32
      
      string_repr = camera.to_s
      string_repr.should contain("Camera")
      string_repr.should contain("123.45")
      string_repr.should contain("678.9")
      string_repr.should contain("1.5")
    end
  end
  
  describe "coordinate transformation consistency" do
    it "maintains consistency between screen_to_world and world_to_screen" do
      camera.set_position(50.0_f32, 25.0_f32)
      camera.set_zoom(1.5_f32)
      camera.smooth_movement = false
      camera.update(0.0_f32)
      
      # Pick an arbitrary screen position
      original_screen = RL::Vector2.new(300.0_f32, 200.0_f32)
      
      # Convert to world and back to screen
      world_pos = camera.screen_to_world(original_screen)
      final_screen = camera.world_to_screen(world_pos)
      
      # Should be very close to original (allowing for floating point precision)
      (final_screen.x - original_screen.x).abs.should be < 0.001
      (final_screen.y - original_screen.y).abs.should be < 0.001
    end
  end
end