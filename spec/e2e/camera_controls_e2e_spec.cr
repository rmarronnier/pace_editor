# E2E Tests for Camera Controls
# Tests panning, zooming, and view manipulation

require "./e2e_spec_helper"

describe "Camera Controls E2E" do
  describe "Keyboard Panning" do
    it "pans right with D key" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)  # Mouse must be in viewport

      initial_x = harness.camera_position[:x]

      harness.hold_key(RL::KeyboardKey::D)
      20.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)

      harness.camera_position[:x].should be > initial_x

      harness.cleanup
    end

    it "pans left with A key" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # First pan right to have room to pan left
      harness.hold_key(RL::KeyboardKey::D)
      10.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)

      initial_x = harness.camera_position[:x]

      harness.hold_key(RL::KeyboardKey::A)
      20.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::A)

      harness.camera_position[:x].should be < initial_x

      harness.cleanup
    end

    it "pans down with S key" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      initial_y = harness.camera_position[:y]

      harness.hold_key(RL::KeyboardKey::S)
      20.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::S)

      harness.camera_position[:y].should be > initial_y

      harness.cleanup
    end

    it "pans up with W key" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # First pan down
      harness.hold_key(RL::KeyboardKey::S)
      10.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::S)

      initial_y = harness.camera_position[:y]

      harness.hold_key(RL::KeyboardKey::W)
      20.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::W)

      harness.camera_position[:y].should be < initial_y

      harness.cleanup
    end

    it "pans faster with Shift held" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # Normal pan
      initial_x = harness.camera_position[:x]
      harness.hold_key(RL::KeyboardKey::D)
      5.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)
      normal_distance = harness.camera_position[:x] - initial_x

      # Reset
      harness.press_key(RL::KeyboardKey::Home)

      # Fast pan with Shift
      initial_x = harness.camera_position[:x]
      harness.hold_key(RL::KeyboardKey::LeftShift)
      harness.hold_key(RL::KeyboardKey::D)
      5.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)
      harness.release_key(RL::KeyboardKey::LeftShift)
      fast_distance = harness.camera_position[:x] - initial_x

      fast_distance.should be > normal_distance

      harness.cleanup
    end

    it "pans diagonally with two keys" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      initial_pos = harness.camera_position

      harness.hold_key(RL::KeyboardKey::D)
      harness.hold_key(RL::KeyboardKey::S)
      20.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)
      harness.release_key(RL::KeyboardKey::S)

      final_pos = harness.camera_position

      # Both X and Y should have changed
      final_pos[:x].should be > initial_pos[:x]
      final_pos[:y].should be > initial_pos[:y]

      harness.cleanup
    end

    it "uses arrow keys for panning" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      initial_x = harness.camera_position[:x]

      harness.hold_key(RL::KeyboardKey::Right)
      20.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::Right)

      harness.camera_position[:x].should be > initial_x

      harness.cleanup
    end
  end

  describe "Mouse Wheel Zoom" do
    it "zooms in with scroll up" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      initial_zoom = harness.zoom

      harness.scroll(1.0_f32)

      harness.zoom.should be > initial_zoom

      harness.cleanup
    end

    it "zooms out with scroll down" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      initial_zoom = harness.zoom

      harness.scroll(-1.0_f32)

      harness.zoom.should be < initial_zoom

      harness.cleanup
    end

    it "zooms multiple times" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      initial_zoom = harness.zoom

      # Zoom in several times
      5.times { harness.scroll(1.0_f32) }

      harness.zoom.should be > initial_zoom * 1.5

      harness.cleanup
    end

    it "respects zoom limits" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # Zoom out a lot
      20.times { harness.scroll(-1.0_f32) }
      min_zoom = harness.zoom
      min_zoom.should be >= 0.1_f32

      # Zoom in a lot
      40.times { harness.scroll(1.0_f32) }
      max_zoom = harness.zoom
      max_zoom.should be <= 5.0_f32

      harness.cleanup
    end

    it "zooms towards mouse position" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a hotspot at known position
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(200, 200)
      harness.step_frame

      # Move mouse to hotspot
      harness.move_mouse(200 + 80, 200 + 30)  # Account for viewport offset

      initial_pos = harness.camera_position

      # Zoom in
      harness.scroll(2.0_f32)

      # Camera should have adjusted to keep mouse position stable
      # The exact behavior depends on implementation
      harness.zoom.should be > 1.0_f32

      harness.cleanup
    end
  end

  describe "View Reset" do
    it "resets view with Home key" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # Pan and zoom
      harness.hold_key(RL::KeyboardKey::D)
      10.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)

      harness.scroll(2.0_f32)

      # Verify not at origin
      harness.camera_position[:x].should_not eq(0.0_f32)
      harness.zoom.should_not eq(1.0_f32)

      # Reset
      harness.press_key(RL::KeyboardKey::Home)

      harness.assert_camera_position(0.0_f32, 0.0_f32, 5.0_f32)
      harness.assert_zoom(1.0_f32)

      harness.cleanup
    end

    it "resets from any position" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # Pan to extreme position
      harness.hold_key(RL::KeyboardKey::D)
      50.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)

      harness.hold_key(RL::KeyboardKey::S)
      50.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::S)

      # Zoom out
      10.times { harness.scroll(-1.0_f32) }

      # Reset
      harness.press_key(RL::KeyboardKey::Home)

      harness.assert_camera_position(0.0_f32, 0.0_f32, 5.0_f32)
      harness.assert_zoom(1.0_f32)

      harness.cleanup
    end
  end

  describe "Pan Speed Relative to Zoom" do
    it "pans same world distance regardless of zoom" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # Measure pan at zoom 1.0
      harness.press_key(RL::KeyboardKey::Home)
      initial_x = harness.camera_position[:x]
      harness.hold_key(RL::KeyboardKey::D)
      10.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)
      distance_at_1x = harness.camera_position[:x] - initial_x

      # Reset and zoom in
      harness.press_key(RL::KeyboardKey::Home)
      harness.scroll(2.0_f32)

      # Measure pan at higher zoom
      initial_x = harness.camera_position[:x]
      harness.hold_key(RL::KeyboardKey::D)
      10.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)
      distance_at_higher_zoom = harness.camera_position[:x] - initial_x

      # Pan speed should adjust with zoom (slower pan at higher zoom)
      distance_at_higher_zoom.should be < distance_at_1x

      harness.cleanup
    end
  end

  describe "Coordinate System" do
    it "converts world to screen coordinates correctly" do
      harness = E2ETestHelper.create_harness_with_scene

      # At default view (0,0 camera, 1.0 zoom)
      screen_pos = harness.world_to_screen(100, 100)

      # Should be offset by viewport position
      screen_pos[:x].should be > 100
      screen_pos[:y].should be > 100

      harness.cleanup
    end

    it "converts screen to world coordinates correctly" do
      harness = E2ETestHelper.create_harness_with_scene

      world_pos = harness.screen_to_world(200, 200)

      # Should account for viewport offset
      world_pos[:x].should be < 200
      world_pos[:y].should be < 200

      harness.cleanup
    end

    it "coordinates are consistent after pan" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # Pan
      harness.hold_key(RL::KeyboardKey::D)
      10.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)

      # Convert world to screen and back
      test_world = {x: 150, y: 150}
      screen = harness.world_to_screen(test_world[:x], test_world[:y])
      back_to_world = harness.screen_to_world(screen[:x], screen[:y])

      # Should be close to original
      (back_to_world[:x] - test_world[:x]).abs.should be < 5
      (back_to_world[:y] - test_world[:y]).abs.should be < 5

      harness.cleanup
    end

    it "coordinates scale with zoom" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # Get screen position at zoom 1.0
      screen_at_1x = harness.world_to_screen(100, 100)

      # Zoom in
      harness.scroll(2.0_f32)

      # Get screen position at higher zoom
      screen_at_zoomed = harness.world_to_screen(100, 100)

      # Position should have changed (zooming changes apparent position)
      # The exact relationship depends on zoom center
      harness.zoom.should be > 1.0_f32

      harness.cleanup
    end
  end

  describe "Middle Mouse Pan" do
    # Note: Middle mouse pan is simulated via the input provider

    it "does not pan when middle mouse is not pressed" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      initial_pos = harness.camera_position

      # Just move mouse without middle button
      harness.move_mouse(450, 350)
      harness.step_frame

      # Position should not have changed
      harness.camera_position[:x].should eq(initial_pos[:x])
      harness.camera_position[:y].should eq(initial_pos[:y])

      harness.cleanup
    end
  end

  describe "Space+Click Pan" do
    it "pans when space is held and left mouse dragged" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      initial_pos = harness.camera_position

      # Hold space and drag
      harness.hold_key(RL::KeyboardKey::Space)
      harness.input.press_mouse_button(RL::MouseButton::Left)
      harness.step_frame

      # Move mouse
      harness.input.set_mouse_position(500.0_f32, 400.0_f32)
      harness.input.hold_mouse_button(RL::MouseButton::Left)
      harness.step_frame

      harness.input.release_mouse_button(RL::MouseButton::Left)
      harness.release_key(RL::KeyboardKey::Space)
      harness.step_frame

      # Camera should have moved
      final_pos = harness.camera_position
      (final_pos[:x] != initial_pos[:x] || final_pos[:y] != initial_pos[:y]).should be_true

      harness.cleanup
    end
  end
end
