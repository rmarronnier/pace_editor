# E2E Tests for Advanced Object Manipulation
# Tests complex operations, bulk actions, and edge cases

require "./e2e_spec_helper"

describe "Advanced Manipulation E2E" do
  describe "Bulk Operations" do
    it "can create many objects quickly" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)

      # Create 25 hotspots in a grid
      5.times do |row|
        5.times do |col|
          harness.click_canvas(col * 80 + 50, row * 80 + 50)
          harness.step_frame
        end
      end

      harness.assert_hotspot_count(25)

      harness.cleanup
    end

    it "can delete all objects at once" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create objects
      harness.press_key(RL::KeyboardKey::P)
      10.times do |i|
        harness.click_canvas(i * 70 + 50, 100)
        harness.step_frame
      end

      harness.assert_hotspot_count(10)

      # Select all and delete
      harness.press_key(RL::KeyboardKey::V)
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::A)
      harness.step_frame
      harness.press_key(RL::KeyboardKey::Delete)
      harness.step_frame

      harness.assert_hotspot_count(0)

      harness.cleanup
    end

    it "maintains performance with many objects" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create 50 hotspots
      harness.press_key(RL::KeyboardKey::P)
      50.times do |i|
        harness.click_canvas((i % 10) * 70 + 50, (i // 10) * 70 + 50)
        harness.step_frame
      end

      harness.assert_hotspot_count(50)

      # Step many frames to verify stability
      start_time = Time.monotonic
      100.times { harness.step_frame }
      elapsed = Time.monotonic - start_time

      # Should complete in reasonable time (less than 5 seconds for 100 frames)
      elapsed.total_seconds.should be < 5.0

      harness.cleanup
    end
  end

  describe "Complex Selection Scenarios" do
    it "can select objects after panning" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      hotspot_name = harness.selected_object

      # Pan camera
      harness.move_mouse(400, 300)
      harness.hold_key(RL::KeyboardKey::D)
      20.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)

      # Deselect
      harness.press_key(RL::KeyboardKey::V)
      harness.press_key(RL::KeyboardKey::Escape)
      harness.step_frame

      # Click at original world position
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.selected_object.should eq(hotspot_name)

      harness.cleanup
    end

    it "can select objects after zooming" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      hotspot_name = harness.selected_object

      # Zoom in
      harness.move_mouse(400, 300)
      3.times { harness.scroll(1.0_f32) }

      # Deselect
      harness.press_key(RL::KeyboardKey::V)
      harness.press_key(RL::KeyboardKey::Escape)
      harness.step_frame

      # Click at same world position
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.selected_object.should eq(hotspot_name)

      harness.cleanup
    end

    it "can select overlapping objects" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create overlapping hotspots
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.click_canvas(110, 110)  # Overlaps with first
      harness.step_frame

      harness.assert_hotspot_count(2)

      # Click on overlap area should select top one
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(110, 110)
      harness.step_frame

      harness.selected_object.should_not be_nil

      harness.cleanup
    end

    it "handles rapid selection changes" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspots
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.click_canvas(200, 100)
      harness.step_frame
      harness.click_canvas(300, 100)
      harness.step_frame

      harness.press_key(RL::KeyboardKey::V)

      # Rapidly click between objects
      10.times do
        harness.click_canvas(100, 100)
        harness.step_frame
        harness.click_canvas(200, 100)
        harness.step_frame
        harness.click_canvas(300, 100)
        harness.step_frame
      end

      # Should end with valid selection
      harness.selected_object.should_not be_nil

      harness.cleanup
    end
  end

  describe "Movement Edge Cases" do
    it "handles moving to same position" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Select and drag to same position
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.drag_canvas(100, 100, 100, 100)

      # Should not crash or corrupt state
      harness.assert_hotspot_count(1)

      harness.cleanup
    end

    it "handles moving to negative coordinates" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Select and drag towards origin
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.drag_canvas(100, 100, -50, -50)

      # Should handle gracefully
      harness.assert_hotspot_count(1)

      harness.cleanup
    end

    it "handles very small movements" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Select and make tiny drag
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.drag_canvas(100, 100, 101, 101)

      harness.assert_hotspot_count(1)

      harness.cleanup
    end

    it "handles large movements" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Select and drag very far
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.drag_canvas(100, 100, 1000, 1000)

      harness.assert_hotspot_count(1)

      harness.cleanup
    end
  end

  describe "Undo/Redo Edge Cases" do
    it "handles undo with no actions" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.can_undo?.should be_false

      # Try to undo anyway
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Z)
      harness.step_frame

      # Should not crash
      harness.assert_hotspot_count(0)

      harness.cleanup
    end

    it "handles redo with no redoable actions" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.can_redo?.should be_false

      # Try to redo anyway
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Y)
      harness.step_frame

      # Should not crash
      harness.assert_hotspot_count(0)

      harness.cleanup
    end

    it "handles many undo/redo cycles" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.assert_hotspot_count(1)

      # Undo/redo many times
      10.times do
        harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Z)
        harness.step_frame
        harness.assert_hotspot_count(0)

        harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Y)
        harness.step_frame
        harness.assert_hotspot_count(1)
      end

      harness.cleanup
    end
  end

  describe "Tool State Edge Cases" do
    it "handles rapid tool switching" do
      harness = E2ETestHelper.create_harness_with_scene

      100.times do
        harness.press_key(RL::KeyboardKey::V)
        harness.press_key(RL::KeyboardKey::M)
        harness.press_key(RL::KeyboardKey::P)
        harness.press_key(RL::KeyboardKey::D)
      end

      # Should end with valid tool
      [PaceEditor::Tool::Select, PaceEditor::Tool::Move,
       PaceEditor::Tool::Place, PaceEditor::Tool::Delete].includes?(harness.current_tool).should be_true

      harness.cleanup
    end

    it "handles tool switch during operation" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Start drag
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.input.press_mouse_button(RL::MouseButton::Left)
      harness.step_frame

      # Switch tool mid-drag
      harness.press_key(RL::KeyboardKey::P)

      harness.input.release_mouse_button(RL::MouseButton::Left)
      harness.step_frame

      # Should handle gracefully
      harness.assert_hotspot_count(1)

      harness.cleanup
    end
  end

  describe "Scene State Consistency" do
    it "maintains consistency after many operations" do
      harness = E2ETestHelper.create_harness_with_scene

      # Perform many mixed operations
      harness.press_key(RL::KeyboardKey::P)

      # Create
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.click_canvas(200, 100)
      harness.step_frame
      harness.click_canvas(300, 100)
      harness.step_frame

      # Select and move
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.drag_canvas(100, 100, 150, 150)

      # Delete
      harness.press_key(RL::KeyboardKey::D)
      harness.click_canvas(200, 100)
      harness.step_frame

      # Undo
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Z)
      harness.step_frame

      # Create more
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(400, 100)
      harness.step_frame

      # Scene should be consistent
      if scene = harness.editor.state.current_scene
        # All hotspots should have valid positions
        scene.hotspots.each do |h|
          h.position.x.should be >= 0
          h.position.y.should be >= 0
          h.size.x.should be > 0
          h.size.y.should be > 0
        end
      end

      harness.cleanup
    end

    it "handles empty scene operations" do
      harness = E2ETestHelper.create_harness_with_scene

      # Try operations on empty scene
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::A)
      harness.step_frame

      harness.press_key(RL::KeyboardKey::Delete)
      harness.step_frame

      # Should all succeed without error
      harness.assert_hotspot_count(0)

      harness.cleanup
    end
  end

  describe "View State Consistency" do
    it "maintains view after object operations" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # Set specific view
      harness.hold_key(RL::KeyboardKey::D)
      10.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)
      harness.scroll(1.0_f32)

      saved_pos = harness.camera_position
      saved_zoom = harness.zoom

      # Do object operations
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.press_key(RL::KeyboardKey::Delete)
      harness.step_frame

      # View should be preserved
      harness.camera_position[:x].should eq(saved_pos[:x])
      harness.camera_position[:y].should eq(saved_pos[:y])
      harness.zoom.should eq(saved_zoom)

      harness.cleanup
    end
  end
end
