require "../spec_helper"

describe PaceEditor::Core::EditorState do
  describe "#initialize" do
    it "initializes with correct default values" do
      state = PaceEditor::Core::EditorState.new

      state.current_project.should be_nil
      state.current_mode.should eq(PaceEditor::EditorMode::Scene)
      state.current_tool.should eq(PaceEditor::Tool::Select)
      state.selected_object.should be_nil
      state.camera_x.should eq(0.0f32)
      state.camera_y.should eq(0.0f32)
      state.zoom.should eq(1.0f32)
      state.grid_size.should eq(16)
      state.snap_to_grid.should be_true
      state.show_grid.should be_true
      state.show_hotspots.should be_true
      state.show_character_bounds.should be_true

      state.selected_hotspots.should be_empty
      state.selected_characters.should be_empty
      state.clipboard.should be_nil
    end
  end

  describe "#has_project?" do
    it "returns false when no project is loaded" do
      state = PaceEditor::Core::EditorState.new
      state.has_project?.should be_false
    end

    it "returns true when project is loaded" do
      state = PaceEditor::Core::EditorState.new
      test_dir = File.tempname("test_project")

      begin
        project = PaceEditor::Core::Project.new("Test", test_dir)
        state.current_project = project
        state.has_project?.should be_true
      ensure
        FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
      end
    end
  end

  describe "#create_new_project" do
    it "creates and sets a new project" do
      state = PaceEditor::Core::EditorState.new
      test_dir = File.tempname("test_project")

      begin
        result = state.create_new_project("Test Game", test_dir)

        result.should be_true
        state.has_project?.should be_true
        state.current_project.not_nil!.name.should eq("Test Game")
        state.current_mode.should eq(PaceEditor::EditorMode::Scene)
        state.selected_object.should be_nil
        state.selected_hotspots.should be_empty
        state.selected_characters.should be_empty
      ensure
        FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
      end
    end

    it "creates project with proper folder structure" do
      state = PaceEditor::Core::EditorState.new
      test_dir = File.tempname("test_project")

      begin
        result = state.create_new_project("My Adventure Game", test_dir)

        result.should be_true
        project = state.current_project.not_nil!

        # Verify the complete folder structure exists
        Dir.exists?(project.project_path).should be_true
        Dir.exists?(project.assets_path).should be_true
        Dir.exists?(project.scenes_path).should be_true
        Dir.exists?(project.scripts_path).should be_true
        Dir.exists?(project.dialogs_path).should be_true
        Dir.exists?(project.exports_path).should be_true

        # Verify asset subfolders
        Dir.exists?(File.join(project.assets_path, "backgrounds")).should be_true
        Dir.exists?(File.join(project.assets_path, "characters")).should be_true
        Dir.exists?(File.join(project.assets_path, "sounds")).should be_true
        Dir.exists?(File.join(project.assets_path, "music")).should be_true
        Dir.exists?(File.join(project.assets_path, "ui")).should be_true

        # Verify default files are created
        project.scenes.should contain("main_scene.yml")
        scene_file = File.join(project.scenes_path, "main_scene.yml")
        File.exists?(scene_file).should be_true

        # Verify project file exists
        project_file = File.join(project.project_path, "#{project.name}.pace")
        File.exists?(project_file).should be_true
      ensure
        FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
      end
    end

    it "handles creation failure gracefully" do
      state = PaceEditor::Core::EditorState.new

      # Try to create project in invalid path
      result = state.create_new_project("Test", "/invalid/path/that/cannot/exist")

      result.should be_false
      state.has_project?.should be_false
    end
  end

  describe "#load_project" do
    it "loads an existing project" do
      state = PaceEditor::Core::EditorState.new
      test_dir = File.tempname("test_project")

      begin
        # Create a project to load
        original_project = PaceEditor::Core::Project.new("Load Test", test_dir)
        original_project.save

        project_file = File.join(test_dir, "#{original_project.name}.pace")
        result = state.load_project(project_file)

        result.should be_true
        state.has_project?.should be_true
        state.current_project.not_nil!.name.should eq("Load Test")
        state.current_mode.should eq(PaceEditor::EditorMode::Scene)
      ensure
        FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
      end
    end

    it "handles load failure gracefully" do
      state = PaceEditor::Core::EditorState.new

      result = state.load_project("/nonexistent/project.pace")

      result.should be_false
      state.has_project?.should be_false
    end
  end

  describe "#clear_selection" do
    it "clears all selection state" do
      state = PaceEditor::Core::EditorState.new

      # Set some selection state
      state.selected_object = "test_object"
      state.selected_hotspots << "hotspot1"
      state.selected_hotspots << "hotspot2"
      state.selected_characters << "character1"

      state.clear_selection

      state.selected_object.should be_nil
      state.selected_hotspots.should be_empty
      state.selected_characters.should be_empty
    end
  end

  describe "#select_object" do
    it "selects object without multi-select" do
      state = PaceEditor::Core::EditorState.new

      state.select_object("test_object")

      state.selected_object.should eq("test_object")
      state.is_selected?("test_object").should be_true
    end

    it "clears previous selection when not multi-selecting" do
      state = PaceEditor::Core::EditorState.new

      state.selected_hotspots << "hotspot1"
      state.selected_characters << "character1"

      state.select_object("new_object")

      state.selected_object.should eq("new_object")
      state.selected_hotspots.should be_empty
      state.selected_characters.should be_empty
    end

    it "preserves selection with multi-select" do
      state = PaceEditor::Core::EditorState.new

      state.selected_hotspots << "hotspot1"

      state.select_object("new_object", multi_select: true)

      state.selected_object.should eq("new_object")
      state.selected_hotspots.should contain("hotspot1")
    end
  end

  describe "#is_selected?" do
    it "checks selection correctly" do
      state = PaceEditor::Core::EditorState.new

      state.selected_object = "object1"
      state.selected_hotspots << "hotspot1"
      state.selected_characters << "character1"

      state.is_selected?("object1").should be_true
      state.is_selected?("hotspot1").should be_true
      state.is_selected?("character1").should be_true
      state.is_selected?("not_selected").should be_false
    end
  end

  describe "#world_to_screen and #screen_to_world" do
    it "converts coordinates correctly" do
      state = PaceEditor::Core::EditorState.new
      state.camera_x = 100.0f32
      state.camera_y = 50.0f32
      state.zoom = 2.0f32

      world_pos = RL::Vector2.new(x: 200, y: 150)
      screen_pos = state.world_to_screen(world_pos)

      screen_pos.x.should eq((200 - 100) * 2) # (world_x - camera_x) * zoom
      screen_pos.y.should eq((150 - 50) * 2)  # (world_y - camera_y) * zoom

      # Convert back
      converted_world = state.screen_to_world(screen_pos)
      converted_world.x.should be_close(world_pos.x, 0.01f32)
      converted_world.y.should be_close(world_pos.y, 0.01f32)
    end
  end

  describe "#snap_to_grid" do
    it "snaps to grid when enabled" do
      state = PaceEditor::Core::EditorState.new
      state.snap_to_grid = true
      state.grid_size = 16

      input_pos = RL::Vector2.new(x: 23, y: 31)
      snapped = state.snap_to_grid(input_pos)

      snapped.x.should eq(16) # Nearest grid point
      snapped.y.should eq(32)
    end

    it "does not snap when disabled" do
      state = PaceEditor::Core::EditorState.new
      state.snap_to_grid = false

      input_pos = RL::Vector2.new(x: 23, y: 31)
      result = state.snap_to_grid(input_pos)

      result.x.should eq(23)
      result.y.should eq(31)
    end
  end

  describe "#set_zoom" do
    it "clamps zoom to valid range" do
      state = PaceEditor::Core::EditorState.new

      state.set_zoom(0.05f32) # Below minimum
      state.zoom.should eq(0.1f32)

      state.set_zoom(10.0f32) # Above maximum
      state.zoom.should eq(5.0f32)

      state.set_zoom(2.0f32) # Valid value
      state.zoom.should eq(2.0f32)
    end
  end

  describe "#zoom_in and #zoom_out" do
    it "adjusts zoom correctly" do
      state = PaceEditor::Core::EditorState.new
      initial_zoom = state.zoom

      state.zoom_in
      state.zoom.should be > initial_zoom

      current_zoom = state.zoom
      state.zoom_out
      state.zoom.should be < current_zoom
    end
  end

  describe "#reset_camera" do
    it "resets camera to default state" do
      state = PaceEditor::Core::EditorState.new

      # Change camera state
      state.camera_x = 100.0f32
      state.camera_y = 200.0f32
      state.zoom = 3.0f32

      state.reset_camera

      state.camera_x.should eq(0.0f32)
      state.camera_y.should eq(0.0f32)
      state.zoom.should eq(1.0f32)
    end
  end

  describe "undo/redo system" do
    it "tracks undo/redo state correctly" do
      state = PaceEditor::Core::EditorState.new

      # Initially no actions
      state.can_undo?.should be_false
      state.can_redo?.should be_false

      # Add an action
      action = MockEditorAction.new("test action")
      state.add_undo_action(action)

      state.can_undo?.should be_true
      state.can_redo?.should be_false

      # Undo
      result = state.undo
      result.should be_true
      action.undo_called.should be_true

      state.can_undo?.should be_false
      state.can_redo?.should be_true

      # Redo
      result = state.redo
      result.should be_true
      action.redo_called.should be_true

      state.can_undo?.should be_true
      state.can_redo?.should be_false
    end

    it "limits undo stack size" do
      state = PaceEditor::Core::EditorState.new

      # Add more than max undo levels
      60.times do |i|
        action = MockEditorAction.new("action #{i}")
        state.add_undo_action(action)
      end

      # Should be limited to 50 actions
      undo_count = 0
      while state.can_undo?
        state.undo
        undo_count += 1
      end

      undo_count.should eq(50)
    end

    it "clears redo stack when new action is added" do
      state = PaceEditor::Core::EditorState.new

      # Add action and undo it
      action1 = MockEditorAction.new("action 1")
      state.add_undo_action(action1)
      state.undo

      state.can_redo?.should be_true

      # Add new action - should clear redo stack
      action2 = MockEditorAction.new("action 2")
      state.add_undo_action(action2)

      state.can_redo?.should be_false
    end
  end
end

# Mock class for testing undo/redo
class MockEditorAction < PaceEditor::Core::EditorAction
  property undo_called : Bool = false
  property redo_called : Bool = false

  def initialize(@desc : String)
  end

  def undo
    @undo_called = true
  end

  def redo
    @redo_called = true
  end

  def description : String
    @desc
  end
end
