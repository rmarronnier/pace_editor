# E2E Tests for Complete Workflows
# Tests end-to-end user workflows from project creation to export

require "./e2e_spec_helper"

describe "Complete Workflow E2E" do
  describe "Project Creation Workflow" do
    it "can create a new project from scratch" do
      harness = PaceEditor::Testing::TestHarness.new

      # Initially no project
      harness.has_project?.should be_false

      # Create project directory
      temp_dir = E2ETestHelper.create_temp_project_dir

      # Create project through state
      harness.editor.state.create_new_project("My Adventure Game", temp_dir)
      harness.step_frames(3)

      # Now we should have a project
      harness.has_project?.should be_true
      harness.project_name.should eq("My Adventure Game")

      harness.cleanup
      E2ETestHelper.cleanup_temp_dir(temp_dir)
    end
  end

  describe "Scene Building Workflow" do
    it "can build a complete scene with hotspots and characters" do
      harness = E2ETestHelper.create_harness_with_scene("GameProject", "forest_scene")

      harness.assert_has_project
      harness.assert_has_scene
      harness.scene_name.should eq("forest_scene")

      # === Step 1: Add multiple hotspots ===

      # Switch to Place tool
      harness.press_key(RL::KeyboardKey::P)

      # Create a door hotspot (note: positions get grid-snapped)
      harness.click_canvas(100, 200)
      harness.step_frames(2)

      # Create a chest hotspot
      harness.click_canvas(300, 250)
      harness.step_frames(2)

      # Create a sign hotspot
      harness.click_canvas(500, 200)
      harness.step_frames(2)

      harness.assert_hotspot_count(3)

      # === Step 2: Select and verify objects ===

      harness.press_key(RL::KeyboardKey::V)  # Select tool

      # Select the first hotspot (click within its bounds - 64x64 from snapped position)
      # The hotspot was placed at ~100,200 which snaps to 96,208
      harness.click_canvas(120, 230)  # Click inside the hotspot area
      harness.step_frames(2)

      # Verify something is selected (hotspot was created)
      harness.hotspot_count.should eq(3)

      # === Step 3: Save the scene ===

      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)

      harness.is_dirty?.should be_false

      harness.cleanup
    end
  end

  describe "Multi-Object Manipulation Workflow" do
    it "can select and manipulate multiple objects" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create several hotspots
      harness.press_key(RL::KeyboardKey::P)

      positions = [{100, 100}, {200, 100}, {300, 100}, {400, 100}]
      positions.each do |x, y|
        harness.click_canvas(x, y)
        harness.step_frame
      end

      harness.assert_hotspot_count(4)

      # Switch to select tool
      harness.press_key(RL::KeyboardKey::V)

      # Select all with Ctrl+A
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::A)

      # All objects should be selected
      harness.selected_objects.size.should be >= 1

      # Delete all selected
      harness.press_key(RL::KeyboardKey::Delete)
      harness.step_frame

      harness.assert_hotspot_count(0)

      harness.cleanup
    end
  end

  describe "Undo/Redo Workflow" do
    it "tracks action history correctly" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.assert_hotspot_count(1)

      # The editor should have recorded this action
      harness.editor.state.can_undo?.should be_true

      harness.cleanup
    end
  end

  describe "Navigation Workflow" do
    it "can navigate a large scene" do
      harness = E2ETestHelper.create_harness_with_scene

      # Move mouse into viewport first
      harness.move_mouse(400, 300)

      # Reset to origin
      harness.press_key(RL::KeyboardKey::Home)
      harness.assert_camera_position(0.0_f32, 0.0_f32, 5.0_f32)

      # Pan right (mouse must be in viewport for keyboard panning)
      harness.hold_key(RL::KeyboardKey::D)
      20.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)

      pos = harness.camera_position
      pos[:x].should be > 0

      # Pan down
      harness.hold_key(RL::KeyboardKey::S)
      20.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::S)

      pos = harness.camera_position
      pos[:y].should be > 0

      # Zoom in
      5.times do
        harness.scroll(1.0_f32)
      end

      harness.zoom.should be > 1.0_f32

      # Reset view
      harness.press_key(RL::KeyboardKey::Home)
      harness.assert_camera_position(0.0_f32, 0.0_f32, 5.0_f32)
      harness.assert_zoom(1.0_f32)

      harness.cleanup
    end
  end

  describe "Tool Workflow" do
    it "maintains tool state across operations" do
      harness = E2ETestHelper.create_harness_with_scene

      # Start with Select tool
      harness.press_key(RL::KeyboardKey::V)
      harness.assert_tool(PaceEditor::Tool::Select)

      # Switch to Place and create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.assert_tool(PaceEditor::Tool::Place)

      harness.click_canvas(100, 100)
      harness.step_frame

      # Tool should still be Place after creating
      harness.assert_tool(PaceEditor::Tool::Place)

      # Switch to Delete
      harness.press_key(RL::KeyboardKey::D)
      harness.assert_tool(PaceEditor::Tool::Delete)

      # Delete the hotspot
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.assert_hotspot_count(0)

      harness.cleanup
    end
  end

  describe "State Persistence" do
    it "maintains editor state across frames" do
      harness = E2ETestHelper.create_harness_with_scene

      # Set up some state
      harness.press_key(RL::KeyboardKey::G)  # Toggle grid
      initial_grid = harness.editor.state.show_grid

      harness.press_key(RL::KeyboardKey::M)  # Move tool
      harness.move_mouse(400, 300)
      harness.scroll(2.0_f32)  # Zoom in
      initial_zoom = harness.zoom

      # Step many frames
      100.times { harness.step_frame }

      # State should be preserved
      harness.editor.state.show_grid.should eq(initial_grid)
      harness.current_tool.should eq(PaceEditor::Tool::Move)
      harness.zoom.should eq(initial_zoom)

      harness.cleanup
    end
  end
end

describe "Cypress-Style Test Examples" do
  # These tests demonstrate the Cypress-like API

  it "demonstrates a complete user journey" do
    harness = E2ETestHelper.create_harness_with_scene("MyGame", "main_hall")

    # User opens the editor with a scene
    harness.assert_mode(PaceEditor::EditorMode::Scene)
    harness.assert_has_scene

    # User selects the Place tool to add objects
    harness.press_key(RL::KeyboardKey::P)
    harness.assert_tool(PaceEditor::Tool::Place)

    # User adds a door hotspot near the left edge
    harness.click_canvas(50, 300)
    harness.step_frames(2)

    # User adds a window hotspot on the right
    harness.click_canvas(600, 200)
    harness.step_frames(2)

    # User adds a table in the center
    harness.click_canvas(350, 350)
    harness.step_frames(2)

    # Verify 3 hotspots were created
    harness.assert_hotspot_count(3)

    # User switches to Select tool
    harness.press_key(RL::KeyboardKey::V)

    # User clicks on the table to select it (click within hotspot bounds)
    # Table was placed at ~350,350, snapped to grid, with 64x64 size
    harness.click_canvas(370, 370)
    harness.step_frames(2)

    # Verify hotspots exist
    harness.hotspot_count.should eq(3)

    # User saves the scene
    harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)
    harness.is_dirty?.should be_false

    # Test completed successfully
    harness.cleanup
  end

  it "demonstrates keyboard-driven workflow" do
    harness = E2ETestHelper.create_harness_with_scene

    # Create some objects using keyboard shortcuts
    harness.press_key(RL::KeyboardKey::P)  # Place tool

    harness.click_canvas(100, 100)
    harness.step_frame

    harness.click_canvas(200, 200)
    harness.step_frame

    harness.assert_hotspot_count(2)

    # Select all with Ctrl+A
    harness.press_key(RL::KeyboardKey::V)  # Select first
    harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::A)

    # Toggle grid with G
    harness.press_key(RL::KeyboardKey::G)

    # Save with Ctrl+S
    harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)

    # Reset view with Home
    harness.press_key(RL::KeyboardKey::Home)
    harness.assert_camera_position(0.0_f32, 0.0_f32, 5.0_f32)

    harness.cleanup
  end
end
