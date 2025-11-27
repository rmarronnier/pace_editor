# E2E Stress Tests
# Tests performance, stability, and edge cases under heavy load

require "./e2e_spec_helper"

describe "Stress Tests E2E" do
  describe "Object Count Limits" do
    it "handles 100 hotspots" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)

      100.times do |i|
        harness.click_canvas((i % 10) * 80 + 40, (i // 10) * 80 + 40)
        harness.step_frame
      end

      harness.assert_hotspot_count(100)

      harness.cleanup
    end

    it "handles mixed objects (50 hotspots + 20 characters)" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspots
      harness.press_key(RL::KeyboardKey::P)
      50.times do |i|
        harness.click_canvas((i % 10) * 80 + 40, (i // 10) * 80 + 40)
        harness.step_frame
      end

      # Create characters
      if scene = harness.editor.state.current_scene
        20.times do
          harness.editor.state.add_npc_character(scene)
          harness.step_frame
        end
      end

      harness.assert_hotspot_count(50)
      harness.assert_character_count(20)

      harness.cleanup
    end

    it "select all works with many objects" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)
      50.times do |i|
        harness.click_canvas((i % 10) * 80 + 40, (i // 10) * 80 + 40)
        harness.step_frame
      end

      harness.press_key(RL::KeyboardKey::V)
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::A)
      harness.step_frame

      harness.selected_objects.size.should be >= 1

      harness.cleanup
    end

    it "delete all works with many objects" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)
      30.times do |i|
        harness.click_canvas((i % 6) * 100 + 50, (i // 6) * 100 + 50)
        harness.step_frame
      end

      harness.assert_hotspot_count(30)

      harness.press_key(RL::KeyboardKey::V)
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::A)
      harness.step_frame
      harness.press_key(RL::KeyboardKey::Delete)
      harness.step_frame

      harness.assert_hotspot_count(0)

      harness.cleanup
    end
  end

  describe "Frame Rate Stability" do
    it "maintains stability over 1000 frames" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create some content
      harness.press_key(RL::KeyboardKey::P)
      10.times do |i|
        harness.click_canvas(i * 80 + 50, 100)
        harness.step_frame
      end

      # Run for 1000 frames
      start_time = Time.monotonic
      1000.times { harness.step_frame }
      elapsed = Time.monotonic - start_time

      # Should complete in reasonable time (< 10 seconds)
      elapsed.total_seconds.should be < 10.0

      harness.cleanup
    end

    it "maintains stability with continuous input" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # Simulate continuous input for 500 frames
      500.times do |i|
        # Alternate between different actions
        case i % 5
        when 0
          harness.hold_key(RL::KeyboardKey::D)
        when 1
          harness.release_key(RL::KeyboardKey::D)
        when 2
          harness.scroll(0.1_f32)
        when 3
          harness.move_mouse(400 + (i % 100), 300 + (i % 100))
        when 4
          harness.press_key(RL::KeyboardKey::G)
        end
        harness.step_frame
      end

      # Should complete without errors
      harness.has_project?.should be_true

      harness.cleanup
    end
  end

  describe "Rapid Operations" do
    it "handles rapid object creation" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)

      # Create objects as fast as possible
      20.times do |i|
        harness.click_canvas((i % 5) * 100 + 50, (i // 5) * 100 + 50)
        # No step_frame - immediate clicks
      end
      harness.step_frames(5)

      harness.hotspot_count.should be >= 1  # At least some should be created

      harness.cleanup
    end

    it "handles rapid tool switching" do
      harness = E2ETestHelper.create_harness_with_scene

      # Rapid tool switches
      200.times do
        harness.press_key(RL::KeyboardKey::V)
        harness.press_key(RL::KeyboardKey::M)
        harness.press_key(RL::KeyboardKey::P)
        harness.press_key(RL::KeyboardKey::D)
      end

      # Should end in valid state
      [PaceEditor::Tool::Select, PaceEditor::Tool::Move,
       PaceEditor::Tool::Place, PaceEditor::Tool::Delete].includes?(harness.current_tool).should be_true

      harness.cleanup
    end

    it "handles rapid undo/redo" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create some content
      harness.press_key(RL::KeyboardKey::P)
      5.times do |i|
        harness.click_canvas(i * 80 + 50, 100)
        harness.step_frame
      end

      # Rapid undo/redo
      50.times do
        harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Z)
        harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Y)
      end

      # Should end in valid state
      harness.has_scene?.should be_true

      harness.cleanup
    end
  end

  describe "Memory and State Consistency" do
    it "maintains state after many create/delete cycles" do
      harness = E2ETestHelper.create_harness_with_scene

      50.times do |cycle|
        # Create at grid-aligned position
        harness.press_key(RL::KeyboardKey::P)
        harness.click_canvas(96, 96)
        harness.step_frames(2)

        # Delete - click at actual hotspot position
        harness.press_key(RL::KeyboardKey::D)
        if scene = harness.editor.state.current_scene
          if scene.hotspots.size > 0
            hotspot = scene.hotspots.first
            harness.click_canvas(hotspot.position.x.to_i + 32, hotspot.position.y.to_i + 32)
          else
            # If hotspot wasn't created, click at expected position
            harness.click_canvas(96 + 32, 96 + 32)
          end
        end
        harness.step_frames(2)
      end

      # State should be valid after many cycles
      harness.has_scene?.should be_true

      harness.cleanup
    end

    it "maintains state after many pan/zoom cycles" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      50.times do
        # Pan
        harness.hold_key(RL::KeyboardKey::D)
        5.times { harness.step_frame }
        harness.release_key(RL::KeyboardKey::D)

        # Zoom
        harness.scroll(0.5_f32)

        # Reset
        harness.press_key(RL::KeyboardKey::Home)
      end

      # Should be back at origin
      harness.assert_camera_position(0.0_f32, 0.0_f32, 5.0_f32)

      harness.cleanup
    end

    it "maintains selection state after many operations" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create object
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      hotspot_name = harness.selected_object

      # Many select/deselect cycles
      100.times do
        harness.press_key(RL::KeyboardKey::Escape)
        harness.step_frame
        harness.press_key(RL::KeyboardKey::V)
        harness.click_canvas(100, 100)
        harness.step_frame
      end

      harness.selected_object.should eq(hotspot_name)

      harness.cleanup
    end
  end

  describe "Edge Case Inputs" do
    it "handles mouse at extreme positions" do
      harness = E2ETestHelper.create_harness_with_scene

      # Move to corners
      harness.move_mouse(0, 0)
      harness.step_frame
      harness.move_mouse(1399, 899)
      harness.step_frame
      harness.move_mouse(0, 899)
      harness.step_frame
      harness.move_mouse(1399, 0)
      harness.step_frame

      # Should not crash
      harness.has_scene?.should be_true

      harness.cleanup
    end

    it "handles negative world coordinates" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # Pan to negative world coordinates
      harness.hold_key(RL::KeyboardKey::A)
      50.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::A)

      harness.hold_key(RL::KeyboardKey::W)
      50.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::W)

      # Create object at negative coordinates
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(-100, -100)
      harness.step_frame

      # Should handle gracefully
      harness.has_scene?.should be_true

      harness.cleanup
    end

    it "handles extreme zoom levels" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # Zoom in a lot
      50.times { harness.scroll(1.0_f32) }
      harness.zoom.should be <= 5.0_f32  # Should respect max

      # Zoom out a lot
      100.times { harness.scroll(-1.0_f32) }
      harness.zoom.should be >= 0.1_f32  # Should respect min

      harness.cleanup
    end

    it "handles simultaneous key presses" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # Hold multiple keys
      harness.hold_key(RL::KeyboardKey::LeftControl)
      harness.hold_key(RL::KeyboardKey::LeftShift)
      harness.hold_key(RL::KeyboardKey::W)
      harness.hold_key(RL::KeyboardKey::D)

      20.times { harness.step_frame }

      harness.release_key(RL::KeyboardKey::W)
      harness.release_key(RL::KeyboardKey::D)
      harness.release_key(RL::KeyboardKey::LeftShift)
      harness.release_key(RL::KeyboardKey::LeftControl)

      harness.step_frame

      # Should not crash
      harness.has_scene?.should be_true

      harness.cleanup
    end
  end

  describe "Long Running Sessions" do
    it "maintains stability over 5000 frames" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create initial content
      harness.press_key(RL::KeyboardKey::P)
      5.times do |i|
        harness.click_canvas(i * 100 + 50, 100)
        harness.step_frame
      end

      # Simulate long session
      5000.times do |frame|
        case frame % 100
        when 0..10
          harness.move_mouse(400 + (frame % 50), 300 + (frame % 50))
        when 50..55
          harness.press_key(RL::KeyboardKey::G) if frame % 100 == 50
        end
        harness.step_frame
      end

      # State should still be valid
      harness.has_project?.should be_true
      harness.has_scene?.should be_true
      harness.assert_hotspot_count(5)

      harness.cleanup
    end
  end

  describe "Recovery Scenarios" do
    it "recovers from invalid selection" do
      harness = E2ETestHelper.create_harness_with_scene

      # Set an invalid selection directly
      harness.editor.state.selected_object = "nonexistent_object"
      harness.step_frame

      # Try to use the selection
      harness.press_key(RL::KeyboardKey::Delete)
      harness.step_frame

      # Should handle gracefully
      harness.has_scene?.should be_true

      harness.cleanup
    end

    it "recovers from tool state inconsistency" do
      harness = E2ETestHelper.create_harness_with_scene

      # Manually set inconsistent tool state
      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Move)
      harness.editor.state.selected_object = nil

      # Try to use move tool without selection
      harness.drag_canvas(100, 100, 200, 200)

      # Should not crash
      harness.has_scene?.should be_true

      harness.cleanup
    end
  end
end

describe "Performance Benchmarks E2E" do
  it "measures object creation speed" do
    harness = E2ETestHelper.create_harness_with_scene

    harness.press_key(RL::KeyboardKey::P)

    start_time = Time.monotonic
    50.times do |i|
      harness.click_canvas((i % 10) * 70 + 50, (i // 10) * 70 + 50)
      harness.step_frame
    end
    elapsed = Time.monotonic - start_time

    harness.assert_hotspot_count(50)

    # Should create 50 objects in under 3 seconds
    elapsed.total_seconds.should be < 3.0

    harness.cleanup
  end

  it "measures frame step speed" do
    harness = E2ETestHelper.create_harness_with_scene

    # Create some content
    harness.press_key(RL::KeyboardKey::P)
    20.times do |i|
      harness.click_canvas((i % 5) * 100 + 50, (i // 5) * 100 + 50)
      harness.step_frame
    end

    start_time = Time.monotonic
    1000.times { harness.step_frame }
    elapsed = Time.monotonic - start_time

    # 1000 frames should complete in under 5 seconds
    elapsed.total_seconds.should be < 5.0

    harness.cleanup
  end

  it "measures selection operation speed" do
    harness = E2ETestHelper.create_harness_with_scene

    # Create objects
    harness.press_key(RL::KeyboardKey::P)
    30.times do |i|
      harness.click_canvas((i % 6) * 100 + 50, (i // 6) * 100 + 50)
      harness.step_frame
    end

    harness.press_key(RL::KeyboardKey::V)

    start_time = Time.monotonic
    100.times do
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::A)
      harness.step_frame
      harness.press_key(RL::KeyboardKey::Escape)
      harness.step_frame
    end
    elapsed = Time.monotonic - start_time

    # 100 select-all/deselect cycles should complete in under 5 seconds
    elapsed.total_seconds.should be < 5.0

    harness.cleanup
  end
end
