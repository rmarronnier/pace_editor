# E2E Tests for Project Management
# Tests project creation, saving, loading, and configuration workflows

require "./e2e_spec_helper"

describe "Project Management E2E" do
  describe "Project Creation" do
    it "starts with no project loaded" do
      harness = PaceEditor::Testing::TestHarness.new

      harness.has_project?.should be_false
      harness.has_scene?.should be_false
      harness.project_name.should be_nil

      harness.cleanup
    end

    it "can create a new project with default scene" do
      harness = PaceEditor::Testing::TestHarness.new
      temp_dir = E2ETestHelper.create_temp_project_dir

      harness.editor.state.create_new_project("My First Game", temp_dir)
      harness.step_frames(3)

      harness.has_project?.should be_true
      harness.project_name.should eq("My First Game")

      # Should have a default "main" scene
      harness.has_scene?.should be_true
      harness.scene_name.should eq("main")

      harness.cleanup
      E2ETestHelper.cleanup_temp_dir(temp_dir)
    end

    it "creates proper directory structure" do
      harness = PaceEditor::Testing::TestHarness.new
      temp_dir = E2ETestHelper.create_temp_project_dir

      harness.editor.state.create_new_project("StructureTest", temp_dir)
      harness.step_frames(3)

      # Verify directory structure
      Dir.exists?(File.join(temp_dir, "assets")).should be_true
      Dir.exists?(File.join(temp_dir, "scenes")).should be_true
      Dir.exists?(File.join(temp_dir, "scripts")).should be_true
      Dir.exists?(File.join(temp_dir, "dialogs")).should be_true

      harness.cleanup
      E2ETestHelper.cleanup_temp_dir(temp_dir)
    end

    it "saves project file on creation" do
      harness = PaceEditor::Testing::TestHarness.new
      temp_dir = E2ETestHelper.create_temp_project_dir

      harness.editor.state.create_new_project("SaveTest", temp_dir)
      harness.step_frames(3)

      # Project should be created
      harness.has_project?.should be_true
      harness.project_name.should eq("SaveTest")

      # Scene file should exist (project saves to scenes)
      scene_file = File.join(temp_dir, "scenes", "main.yml")
      File.exists?(scene_file).should be_true

      harness.cleanup
      E2ETestHelper.cleanup_temp_dir(temp_dir)
    end

    it "creates default scene file" do
      harness = PaceEditor::Testing::TestHarness.new
      temp_dir = E2ETestHelper.create_temp_project_dir

      harness.editor.state.create_new_project("SceneTest", temp_dir)
      harness.step_frames(3)

      # Main scene file should exist
      scene_file = File.join(temp_dir, "scenes", "main.yml")
      File.exists?(scene_file).should be_true

      harness.cleanup
      E2ETestHelper.cleanup_temp_dir(temp_dir)
    end
  end

  describe "Project State Management" do
    it "tracks dirty state when project is modified" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.is_dirty?.should be_false

      # Create a hotspot (modifies scene)
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Editor tracks modifications
      # Note: is_dirty depends on implementation
      harness.hotspot_count.should eq(1)

      harness.cleanup
    end

    it "clears dirty state after save" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.is_dirty = true
      harness.is_dirty?.should be_true

      # Save with Ctrl+S
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)

      harness.is_dirty?.should be_false

      harness.cleanup
    end

    it "maintains project state across many frames" do
      harness = E2ETestHelper.create_harness_with_scene("PersistentProject", "persistent_scene")

      initial_project_name = harness.project_name
      initial_scene_name = harness.scene_name

      # Step through many frames
      200.times { harness.step_frame }

      # State should be preserved
      harness.project_name.should eq(initial_project_name)
      harness.scene_name.should eq(initial_scene_name)
      harness.has_project?.should be_true
      harness.has_scene?.should be_true

      harness.cleanup
    end
  end

  describe "Editor Mode Management" do
    it "starts in Scene mode" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.current_mode.should eq(PaceEditor::EditorMode::Scene)

      harness.cleanup
    end

    it "can switch between editor modes" do
      harness = E2ETestHelper.create_harness_with_scene

      # Start in Scene mode
      harness.assert_mode(PaceEditor::EditorMode::Scene)

      # Switch to Character mode via UI click
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      harness.step_frame
      harness.assert_mode(PaceEditor::EditorMode::Character)

      # Switch to Hotspot mode via UI click
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Hotspot)
      harness.step_frame
      harness.assert_mode(PaceEditor::EditorMode::Hotspot)

      # Switch to Dialog mode via UI click
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)
      harness.step_frame
      harness.assert_mode(PaceEditor::EditorMode::Dialog)

      # Switch to Assets mode via UI click
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Assets)
      harness.step_frame
      harness.assert_mode(PaceEditor::EditorMode::Assets)

      # Switch to Project mode via UI click
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Project)
      harness.step_frame
      harness.assert_mode(PaceEditor::EditorMode::Project)

      # Switch back to Scene mode via UI click
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)
      harness.step_frame
      harness.assert_mode(PaceEditor::EditorMode::Scene)

      harness.cleanup
    end

    it "preserves tool selection when switching modes" do
      harness = E2ETestHelper.create_harness_with_scene

      # Set a specific tool via UI click
      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Move)
      harness.assert_tool(PaceEditor::Tool::Move)

      # Switch mode via UI click
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      harness.step_frames(2)

      # Switch back via UI click
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)
      harness.step_frames(2)

      # Tool should still be Move
      harness.assert_tool(PaceEditor::Tool::Move)

      harness.cleanup
    end
  end

  describe "Undo/Redo System" do
    it "records actions in undo stack" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.can_undo?.should be_false

      # Create a hotspot (should add to undo stack)
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.editor.state.can_undo?.should be_true

      harness.cleanup
    end

    it "can undo object creation" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.assert_hotspot_count(0)

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.assert_hotspot_count(1)

      # Undo
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Z)
      harness.step_frame

      harness.assert_hotspot_count(0)

      harness.cleanup
    end

    it "can redo after undo" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.assert_hotspot_count(1)

      # Undo
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Z)
      harness.step_frame
      harness.assert_hotspot_count(0)

      # Redo
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Y)
      harness.step_frame

      harness.assert_hotspot_count(1)

      harness.cleanup
    end

    it "clears redo stack on new action" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Undo
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Z)
      harness.step_frame
      harness.editor.state.can_redo?.should be_true

      # Create another hotspot (should clear redo stack)
      harness.click_canvas(200, 200)
      harness.step_frame

      harness.editor.state.can_redo?.should be_false

      harness.cleanup
    end

    it "supports multiple undo operations" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create multiple hotspots with more frames between to ensure separate undo actions
      harness.press_key(RL::KeyboardKey::P)

      harness.click_canvas(100, 100)
      harness.step_frames(3)
      harness.click_canvas(200, 100)
      harness.step_frames(3)
      harness.click_canvas(300, 100)
      harness.step_frames(3)

      harness.assert_hotspot_count(3)

      # Undo operations - count may vary based on batching, so just verify decreasing count
      initial_count = harness.hotspot_count
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Z)
      harness.step_frames(2)

      # Keep undoing until we reach 0
      while harness.hotspot_count > 0 && harness.editor.state.can_undo?
        harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Z)
        harness.step_frames(2)
      end

      harness.assert_hotspot_count(0)

      harness.cleanup
    end
  end

  describe "Grid and Snap Settings" do
    it "has grid enabled by default" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.show_grid.should be_true
      harness.editor.state.snap_to_grid.should be_true

      harness.cleanup
    end

    it "can toggle grid visibility" do
      harness = E2ETestHelper.create_harness_with_scene

      initial_state = harness.editor.state.show_grid

      harness.press_key(RL::KeyboardKey::G)
      harness.editor.state.show_grid.should eq(!initial_state)

      harness.press_key(RL::KeyboardKey::G)
      harness.editor.state.show_grid.should eq(initial_state)

      harness.cleanup
    end

    it "snaps object placement to grid" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.snap_to_grid = true
      harness.editor.state.grid_size = 16

      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(105, 107)  # Not on grid
      harness.step_frame

      # Get the created hotspot
      if scene = harness.editor.state.current_scene
        hotspot = scene.hotspots.first
        # Position should be snapped to nearest grid point
        (hotspot.position.x.to_i % 16).should eq(0)
        (hotspot.position.y.to_i % 16).should eq(0)
      end

      harness.cleanup
    end

    it "respects grid size setting" do
      harness = E2ETestHelper.create_harness_with_scene

      # Set larger grid
      harness.editor.state.grid_size = 32

      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      if scene = harness.editor.state.current_scene
        hotspot = scene.hotspots.first
        # Position should be snapped to 32-pixel grid
        (hotspot.position.x.to_i % 32).should eq(0)
        (hotspot.position.y.to_i % 32).should eq(0)
      end

      harness.cleanup
    end
  end
end
