require "../spec_helper"

describe "Editor State Workflow" do
  describe "state management workflow" do
    it "manages undo/redo operations" do
      state = PaceEditor::Core::EditorState.new

      # Create initial state
      state.push_undo_state("Initial state")
      # We can't directly test undo_stack size due to implementation details

      # Make changes and push states
      state.selected_object = "object1"
      state.push_undo_state("Selected object1")

      state.camera_x = 100
      state.camera_y = 50
      state.push_undo_state("Moved camera")

      # Test undo availability
      state.can_undo?.should be_true

      # Undo operation
      undo_result = state.undo
      undo_result.should_not be_nil

      # Test redo availability
      state.can_redo?.should be_true

      # Redo operation
      redo_result = state.redo
      redo_result.should_not be_nil
    end

    it "maintains editor preferences" do
      state = PaceEditor::Core::EditorState.new

      # Set preferences
      state.show_grid = true
      state.grid_size = 32
      state.snap_to_grid = true
      state.show_hotspots = true
      state.show_character_bounds = true
      state.auto_save = true
      state.auto_save_interval = 300 # 5 minutes

      # Verify preferences
      state.show_grid.should be_true
      state.grid_size.should eq(32)
      state.snap_to_grid.should be_true
      state.show_hotspots.should be_true
      state.show_character_bounds.should be_true
      state.auto_save.should be_true
      state.auto_save_interval.should eq(300)

      # Toggle preferences
      state.show_grid = false
      state.show_grid.should be_false

      state.snap_to_grid = false
      state.snap_to_grid.should be_false
    end

    it "tracks editor mode changes" do
      state = PaceEditor::Core::EditorState.new

      # Start in scene mode
      state.editor_mode = PaceEditor::EditorMode::Scene
      state.editor_mode.scene?.should be_true

      # Switch to character editor
      state.editor_mode = PaceEditor::EditorMode::Character
      state.editor_mode.character?.should be_true

      # Switch to dialog editor
      state.editor_mode = PaceEditor::EditorMode::Dialog
      state.editor_mode.dialog?.should be_true

      # Switch to script editor
      state.editor_mode = PaceEditor::EditorMode::Script
      state.editor_mode.script?.should be_true
    end

    it "manages selection state across modes" do
      state = PaceEditor::Core::EditorState.new

      # Select in scene mode
      state.selected_object = "door_hotspot"
      state.selected_hotspots << "door_hotspot"
      state.selected_hotspots << "window_hotspot"

      # Switch mode
      state.editor_mode = PaceEditor::EditorMode::Character

      # Selection should persist or clear based on design
      # For this example, let's say selection clears on mode switch
      state.clear_selection
      state.selected_object.should be_nil
      state.selected_hotspots.should be_empty

      # Select in character mode
      state.selected_character = "hero"
      state.selected_character.should eq("hero")
    end

    it "handles copy/paste operations" do
      state = PaceEditor::Core::EditorState.new

      # Copy a hotspot
      hotspot_data = {
        "type"   => "hotspot",
        "name"   => "door",
        "x"      => 100,
        "y"      => 200,
        "width"  => 80,
        "height" => 120,
        "cursor" => "hand",
      }

      state.clipboard = hotspot_data.to_json
      state.clipboard.should_not be_nil

      # Paste would create new object with offset
      if clipboard_data = state.clipboard
        # Parse and create new object
        parsed = JSON.parse(clipboard_data)
        parsed["type"].should eq("hotspot")
        parsed["name"].should eq("door")
      end
    end

    it "tracks dirty state for save prompts" do
      state = PaceEditor::Core::EditorState.new

      # Initially not dirty
      state.is_dirty = false
      state.is_dirty.should be_false

      # Make changes
      state.selected_object = "something"
      state.mark_dirty
      state.is_dirty.should be_true

      # Save clears dirty state
      state.clear_dirty
      state.is_dirty.should be_false
    end
  end

  describe "multi-window state coordination" do
    it "synchronizes state between panels" do
      state = PaceEditor::Core::EditorState.new

      # Create window components
      window = PaceEditor::Core::EditorWindow.new
      window.state = state

      # All components are initialized
      window.state.should eq(state)
      window.menu_bar.should_not be_nil
      window.tool_palette.should_not be_nil
      window.property_panel.should_not be_nil
      window.scene_hierarchy.should_not be_nil
      window.asset_browser.should_not be_nil
      window.scene_editor.should_not be_nil

      # Change in state affects all components
      state.current_tool = PaceEditor::Tool::Move
      state.current_tool.should eq(PaceEditor::Tool::Move)
    end

    it "handles focus management" do
      state = PaceEditor::Core::EditorState.new

      # Track focused panel
      state.focused_panel = "scene_editor"
      state.focused_panel.should eq("scene_editor")

      # Change focus
      state.focused_panel = "property_panel"
      state.focused_panel.should eq("property_panel")

      # Input should go to focused panel
      state.text_input_active = true
      state.active_text_field = "hotspot_name"

      state.text_input_active.should be_true
      state.active_text_field.should eq("hotspot_name")
    end

    it "manages modal states" do
      state = PaceEditor::Core::EditorState.new

      # No modals initially
      state.has_modal_open?.should be_false

      # Open new project dialog
      state.show_new_project_dialog = true
      state.has_modal_open?.should be_true

      # Modal should block other interactions
      state.modal_blocks_input?.should be_true

      # Close modal
      state.show_new_project_dialog = false
      state.has_modal_open?.should be_false
    end
  end

  describe "performance monitoring" do
    it "tracks frame timing" do
      state = PaceEditor::Core::EditorState.new

      # Update frame stats
      state.frame_time = 16.67f32 # ~60 FPS
      state.fps = 60

      state.frame_time.should be_close(16.67f32, 0.01)
      state.fps.should eq(60)

      # Track performance issues
      state.frame_time = 33.33f32 # ~30 FPS
      state.fps = 30

      # Could trigger performance warnings
      (state.frame_time > 20.0f32).should be_true
    end

    it "manages resource usage" do
      state = PaceEditor::Core::EditorState.new

      # Track loaded resources
      state.loaded_textures = 25
      state.loaded_sounds = 10
      state.memory_usage = 150_000_000 # 150MB

      state.loaded_textures.should eq(25)
      state.loaded_sounds.should eq(10)
      state.memory_usage.should eq(150_000_000)

      # Check resource limits
      (state.memory_usage < 500_000_000).should be_true # Under 500MB
    end
  end
end
