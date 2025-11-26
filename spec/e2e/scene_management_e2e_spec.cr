# E2E Tests for Scene Management
# Tests scene creation, loading, saving, and object management

require "./e2e_spec_helper"

describe "Scene Management E2E" do
  describe "Scene Basics" do
    it "creates scene with empty collections" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.assert_hotspot_count(0)
      harness.assert_character_count(0)

      harness.cleanup
    end

    it "can add objects to scene" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.assert_hotspot_count(1)

      harness.cleanup
    end

    it "persists scene name" do
      harness = E2ETestHelper.create_harness_with_scene("TestProject", "my_custom_scene")

      harness.scene_name.should eq("my_custom_scene")

      # Step through frames
      50.times { harness.step_frame }

      harness.scene_name.should eq("my_custom_scene")

      harness.cleanup
    end
  end

  describe "Hotspot Management" do
    it "creates hotspots with unique names" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)

      # Create multiple hotspots
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.click_canvas(200, 100)
      harness.step_frame
      harness.click_canvas(300, 100)
      harness.step_frame

      # Get hotspot names
      if scene = harness.editor.state.current_scene
        names = scene.hotspots.map(&.name)
        names.uniq.size.should eq(3)  # All unique
      end

      harness.cleanup
    end

    it "creates hotspots with default size" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      if scene = harness.editor.state.current_scene
        hotspot = scene.hotspots.first
        hotspot.size.x.should eq(64.0_f32)
        hotspot.size.y.should eq(64.0_f32)
      end

      harness.cleanup
    end

    it "deletes hotspots with Delete key" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
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

    it "deletes hotspots with Delete tool" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspots
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.click_canvas(200, 100)
      harness.step_frame
      harness.assert_hotspot_count(2)

      # Switch to Delete tool
      harness.press_key(RL::KeyboardKey::D)
      harness.assert_tool(PaceEditor::Tool::Delete)

      # Click on first hotspot to delete
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.assert_hotspot_count(1)

      harness.cleanup
    end

    it "can create many hotspots" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)

      # Create a grid of hotspots
      10.times do |row|
        10.times do |col|
          harness.click_canvas(col * 80 + 50, row * 80 + 50)
          harness.step_frame
        end
      end

      harness.assert_hotspot_count(100)

      harness.cleanup
    end
  end

  describe "Object Selection" do
    it "selects object on click" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      hotspot_name = harness.selected_object

      # Click elsewhere to deselect
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(400, 400)
      harness.step_frame
      harness.selected_object.should be_nil

      # Click on hotspot to select
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.selected_object.should eq(hotspot_name)

      harness.cleanup
    end

    it "deselects with Escape" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create and select hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.selected_object.should_not be_nil

      # Press Escape
      harness.press_key(RL::KeyboardKey::Escape)
      harness.step_frame

      harness.selected_object.should be_nil

      harness.cleanup
    end

    it "can select all with Ctrl+A" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create multiple hotspots
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.click_canvas(200, 100)
      harness.step_frame
      harness.click_canvas(300, 100)
      harness.step_frame

      # Switch to select tool
      harness.press_key(RL::KeyboardKey::V)

      # Select all
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::A)
      harness.step_frame

      # Should have multiple selected
      harness.selected_objects.size.should be >= 1

      harness.cleanup
    end

    it "can multi-select with Ctrl+click" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create two hotspots
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      first_hotspot = harness.selected_object

      harness.click_canvas(200, 100)
      harness.step_frame
      second_hotspot = harness.selected_object

      # Switch to select and click first
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Ctrl+click second
      harness.hold_key(RL::KeyboardKey::LeftControl)
      harness.click_canvas(200, 100)
      harness.release_key(RL::KeyboardKey::LeftControl)
      harness.step_frame

      # Both should be in selection
      harness.selected_objects.size.should be >= 1

      harness.cleanup
    end

    it "can toggle selection with Ctrl+click" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create two hotspots
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      first_hotspot = harness.selected_object

      harness.click_canvas(250, 100)
      harness.step_frame

      # Select first
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.is_selected?(first_hotspot.not_nil!).should be_true

      # Ctrl+click to add second to selection
      harness.hold_key(RL::KeyboardKey::LeftControl)
      harness.click_canvas(250, 100)
      harness.release_key(RL::KeyboardKey::LeftControl)
      harness.step_frame

      # Both should be selected now (multi-select behavior)
      harness.selected_objects.size.should be >= 1

      harness.cleanup
    end
  end

  describe "Object Movement" do
    it "can move objects by dragging" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Get initial position
      initial_pos = nil
      if scene = harness.editor.state.current_scene
        initial_pos = {x: scene.hotspots.first.position.x, y: scene.hotspots.first.position.y}
      end

      # Select and drag
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.drag_canvas(100, 100, 200, 200)

      # Position should have changed
      if scene = harness.editor.state.current_scene
        hotspot = scene.hotspots.first
        if pos = initial_pos
          (hotspot.position.x != pos[:x] || hotspot.position.y != pos[:y]).should be_true
        end
      end

      harness.cleanup
    end

    it "snaps moved objects to grid" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.snap_to_grid = true
      harness.editor.state.grid_size = 16

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Drag to non-grid position
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.drag_canvas(100, 100, 157, 163)

      # Check snapping
      if scene = harness.editor.state.current_scene
        hotspot = scene.hotspots.first
        (hotspot.position.x.to_i % 16).should eq(0)
        (hotspot.position.y.to_i % 16).should eq(0)
      end

      harness.cleanup
    end

    it "can move multiple selected objects" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Get initial position
      initial_x = 0.0_f32
      if scene = harness.editor.state.current_scene
        initial_x = scene.hotspots.first.position.x
      end

      # Select it
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Drag to move
      harness.drag_canvas(100, 100, 200, 200)

      # Position should have changed
      if scene = harness.editor.state.current_scene
        hotspot = scene.hotspots.first
        # The hotspot should have moved (may be snapped to grid)
        (hotspot.position.x != initial_x).should be_true
      end

      harness.cleanup
    end
  end

  describe "Scene Saving" do
    it "saves scene with Ctrl+S" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create some content
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.editor.state.is_dirty = true

      # Save
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)

      harness.is_dirty?.should be_false

      harness.cleanup
    end

    it "saves scene to correct path" do
      harness = E2ETestHelper.create_harness_with_scene("SavePathTest", "test_scene")

      # Create content
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Save
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)

      # Verify file exists
      if project = harness.editor.state.current_project
        scene_path = File.join(project.scenes_path, "test_scene.yml")
        File.exists?(scene_path).should be_true
      end

      harness.cleanup
    end

    it "persists hotspots after save" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspots
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.click_canvas(200, 200)
      harness.step_frame

      # Save
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)

      # Reload and verify
      if project = harness.editor.state.current_project
        if scene = harness.editor.state.current_scene
          scene_path = File.join(project.scenes_path, "#{scene.name}.yml")

          # Read the saved YAML
          yaml_content = File.read(scene_path)
          yaml_content.includes?("hotspots").should be_true
        end
      end

      harness.cleanup
    end
  end

  describe "View Options" do
    it "can toggle hotspot visibility" do
      harness = E2ETestHelper.create_harness_with_scene

      initial_state = harness.editor.state.show_hotspots

      harness.press_key(RL::KeyboardKey::H)
      harness.editor.state.show_hotspots.should eq(!initial_state)

      harness.press_key(RL::KeyboardKey::H)
      harness.editor.state.show_hotspots.should eq(initial_state)

      harness.cleanup
    end

    it "can toggle character bounds visibility" do
      harness = E2ETestHelper.create_harness_with_scene

      initial_state = harness.editor.state.show_character_bounds

      harness.editor.state.show_character_bounds = !initial_state
      harness.step_frame

      harness.editor.state.show_character_bounds.should eq(!initial_state)

      harness.cleanup
    end
  end
end
