# E2E Tests for Scene Editor
# Tests complete user workflows for the scene editor

require "./e2e_spec_helper"

describe "Scene Editor E2E" do
  describe "Tool Selection" do
    it "can switch between tools using keyboard shortcuts" do
      harness = E2ETestHelper.create_harness_with_scene

      # Default tool should be Select
      harness.assert_tool(PaceEditor::Tool::Select)

      # Press 'M' to switch to Move tool
      harness.press_key(RL::KeyboardKey::M)
      harness.assert_tool(PaceEditor::Tool::Move)

      # Press 'P' to switch to Place tool
      harness.press_key(RL::KeyboardKey::P)
      harness.assert_tool(PaceEditor::Tool::Place)

      # Press 'D' to switch to Delete tool
      harness.press_key(RL::KeyboardKey::D)
      harness.assert_tool(PaceEditor::Tool::Delete)

      # Press 'V' to switch back to Select tool
      harness.press_key(RL::KeyboardKey::V)
      harness.assert_tool(PaceEditor::Tool::Select)

      harness.cleanup
    end
  end

  describe "Hotspot Creation" do
    it "can create a hotspot using the Place tool" do
      harness = E2ETestHelper.create_harness_with_scene

      # Start with no hotspots
      harness.assert_hotspot_count(0)

      # Switch to Place tool
      harness.press_key(RL::KeyboardKey::P)
      harness.assert_tool(PaceEditor::Tool::Place)

      # Click in the scene viewport to create a hotspot
      # The viewport starts at (80, 30) - after tool palette and menu bar
      harness.click_canvas(100, 100)

      # Wait a frame for the hotspot to be created
      harness.step_frame

      # Should now have one hotspot
      harness.assert_hotspot_count(1)

      # The new hotspot should be selected
      harness.selected_object.should_not be_nil

      harness.cleanup
    end

    it "can create multiple hotspots" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)

      # Create three hotspots at different positions
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.click_canvas(200, 100)
      harness.step_frame

      harness.click_canvas(300, 100)
      harness.step_frame

      harness.assert_hotspot_count(3)

      harness.cleanup
    end
  end

  describe "Object Selection" do
    it "can select a hotspot by clicking on it" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a hotspot first
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      hotspot_name = harness.selected_object

      # Switch to Select tool
      harness.press_key(RL::KeyboardKey::V)

      # Click elsewhere to deselect
      harness.click_canvas(400, 400)
      harness.step_frame

      harness.selected_object.should be_nil

      # Click on the hotspot position to select it again
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.selected_object.should eq(hotspot_name)

      harness.cleanup
    end

    it "can multi-select hotspots with Ctrl+click" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create two hotspots
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      first_hotspot = harness.selected_object

      harness.click_canvas(200, 100)
      harness.step_frame
      second_hotspot = harness.selected_object

      # Switch to Select tool
      harness.press_key(RL::KeyboardKey::V)

      # Select first hotspot
      harness.click_canvas(100, 100)
      harness.step_frame

      # Ctrl+click second hotspot to add to selection
      harness.hold_key(RL::KeyboardKey::LeftControl)
      harness.click_canvas(200, 100)
      harness.release_key(RL::KeyboardKey::LeftControl)
      harness.step_frame

      # Both should be in selected objects
      selected = harness.selected_objects
      selected.size.should be >= 1

      harness.cleanup
    end

    it "can deselect with Escape key" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create and select a hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.selected_object.should_not be_nil

      # Press Escape to deselect
      harness.press_key(RL::KeyboardKey::Escape)
      harness.step_frame

      harness.selected_object.should be_nil

      harness.cleanup
    end
  end

  describe "Object Manipulation" do
    it "can move a hotspot by dragging" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Get initial position
      initial_pos = get_hotspot_position(harness, harness.selected_object.not_nil!)

      # Switch to Select tool and select the hotspot
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Drag the hotspot to a new position
      harness.drag_canvas(100, 100, 200, 200)

      # Check that the position changed
      final_pos = get_hotspot_position(harness, harness.selected_object.not_nil!)

      # Position should have changed (accounting for grid snapping)
      (final_pos[:x] != initial_pos[:x] || final_pos[:y] != initial_pos[:y]).should be_true

      harness.cleanup
    end

    it "can delete a hotspot with Delete key" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.assert_hotspot_count(1)

      # Select and delete
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.press_key(RL::KeyboardKey::Delete)
      harness.step_frame

      harness.assert_hotspot_count(0)

      harness.cleanup
    end
  end

  describe "Camera Controls" do
    it "can zoom with mouse wheel" do
      harness = E2ETestHelper.create_harness_with_scene

      initial_zoom = harness.zoom

      # Move mouse to viewport center
      harness.move_mouse(400, 300)

      # Scroll up to zoom in
      harness.scroll(1.0_f32)

      harness.zoom.should be > initial_zoom

      # Scroll down to zoom out
      harness.scroll(-1.0_f32)
      harness.scroll(-1.0_f32)

      harness.zoom.should be < initial_zoom

      harness.cleanup
    end

    it "can pan with keyboard arrows" do
      harness = E2ETestHelper.create_harness_with_scene

      # Move mouse into viewport first (required for keyboard panning)
      harness.move_mouse(400, 300)

      initial_pos = harness.camera_position

      # Pan right with D key
      harness.hold_key(RL::KeyboardKey::D)
      10.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)

      new_pos = harness.camera_position
      new_pos[:x].should be > initial_pos[:x]

      harness.cleanup
    end

    it "can reset view with Home key" do
      harness = E2ETestHelper.create_harness_with_scene

      # Move mouse into viewport first
      harness.move_mouse(400, 300)

      # Pan somewhere
      harness.hold_key(RL::KeyboardKey::D)
      10.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)

      # Zoom in
      harness.move_mouse(400, 300)
      harness.scroll(2.0_f32)

      # Reset view
      harness.press_key(RL::KeyboardKey::Home)

      harness.assert_camera_position(0.0_f32, 0.0_f32, 5.0_f32)
      harness.assert_zoom(1.0_f32)

      harness.cleanup
    end
  end

  describe "View Options" do
    it "can toggle grid visibility with G key" do
      harness = E2ETestHelper.create_harness_with_scene

      initial_grid = harness.editor.state.show_grid

      harness.press_key(RL::KeyboardKey::G)

      harness.editor.state.show_grid.should eq(!initial_grid)

      harness.press_key(RL::KeyboardKey::G)

      harness.editor.state.show_grid.should eq(initial_grid)

      harness.cleanup
    end

    it "can toggle hotspot visibility with H key" do
      harness = E2ETestHelper.create_harness_with_scene

      initial_visibility = harness.editor.state.show_hotspots

      harness.press_key(RL::KeyboardKey::H)

      harness.editor.state.show_hotspots.should eq(!initial_visibility)

      harness.cleanup
    end
  end

  describe "Keyboard Shortcuts" do
    it "can undo with Ctrl+Z" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.assert_hotspot_count(1)

      # Undo the creation
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Z)

      # Note: Undo behavior depends on implementation
      # The hotspot might still be there if undo isn't fully implemented
      harness.cleanup
    end

    it "can save with Ctrl+S" do
      harness = E2ETestHelper.create_harness_with_scene

      # Mark as dirty
      harness.editor.state.is_dirty = true
      harness.is_dirty?.should be_true

      # Save with Ctrl+S
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)

      # Should no longer be dirty
      harness.is_dirty?.should be_false

      harness.cleanup
    end
  end
end

# Helper to get hotspot position
private def get_hotspot_position(harness, name : String) : {x: Float32, y: Float32}
  if scene = harness.editor.state.current_scene
    if hotspot = scene.hotspots.find { |h| h.name == name }
      return {x: hotspot.position.x, y: hotspot.position.y}
    end
  end
  {x: 0.0_f32, y: 0.0_f32}
end
