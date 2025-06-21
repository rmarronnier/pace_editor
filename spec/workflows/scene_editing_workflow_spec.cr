require "../spec_helper"

describe "Scene Editing Workflow" do
  before_all do
    RaylibTestHelper.init
  end

  after_all do
    RaylibTestHelper.cleanup
  end

  describe "complete scene editing workflow" do
    it "creates and edits a scene with hotspots and characters" do
      # Initialize editor state
      state = PaceEditor::Core::EditorState.new

      # Create a project and scene
      project = PaceEditor::Core::Project.new
      project.name = "scene_test"
      state.current_project = project

      # Create scene editor
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Create a new scene
      scene = PointClickEngine::Scenes::Scene.new("test_scene")

      # Add background
      scene.background_path = "village.png"

      # Add hotspots
      door_hotspot = PointClickEngine::Scenes::Hotspot.new(
        "door",
        RL::Vector2.new(x: 100, y: 200),
        RL::Vector2.new(x: 80, y: 120)
      )
      door_hotspot.description = "A wooden door"
      door_hotspot.cursor_type = :hand
      scene.hotspots << door_hotspot

      sign_hotspot = PointClickEngine::Scenes::Hotspot.new(
        "sign",
        RL::Vector2.new(x: 300, y: 250),
        RL::Vector2.new(x: 60, y: 80)
      )
      sign_hotspot.description = "Village sign"
      sign_hotspot.cursor_type = :look
      scene.hotspots << sign_hotspot

      # Add character
      merchant = PointClickEngine::Characters::TestCharacter.new("merchant")
      merchant.position = RL::Vector2.new(x: 400, y: 300)
      merchant.size = RL::Vector2.new(x: 64, y: 128)
      scene.characters << merchant

      # Verify scene contents
      scene.hotspots.size.should eq(2)
      scene.characters.size.should eq(1)
      scene.background_path.should eq("village.png")

      # Test selection workflow
      state.selected_object = nil
      state.selected_hotspots.clear
      state.selected_characters.clear

      # Select a hotspot
      state.selected_object = "door"
      state.selected_object.should eq("door")

      # Multi-select hotspots
      state.selected_hotspots << "door"
      state.selected_hotspots << "sign"
      state.selected_hotspots.size.should eq(2)

      # Clear selection
      state.clear_selection
      state.selected_object.should be_nil
      state.selected_hotspots.should be_empty
      state.selected_characters.should be_empty
    end

    it "handles camera movement and zoom" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Test camera panning
      initial_x = state.camera_x
      initial_y = state.camera_y

      state.camera_x += 100
      state.camera_y += 50

      state.camera_x.should eq(initial_x + 100)
      state.camera_y.should eq(initial_y + 50)

      # Test zoom
      state.zoom = 1.0f32

      # Zoom in
      state.zoom *= 1.5f32
      state.zoom.should be_close(1.5f32, 0.01)

      # Zoom out
      state.zoom *= 0.5f32
      state.zoom.should be_close(0.75f32, 0.01)

      # Test zoom limits
      state.zoom = 10.0f32
      state.zoom = state.zoom.clamp(0.1f32, 5.0f32)
      state.zoom.should eq(5.0f32)

      state.zoom = 0.01f32
      state.zoom = state.zoom.clamp(0.1f32, 5.0f32)
      state.zoom.should eq(0.1f32)
    end

    it "handles grid snapping" do
      state = PaceEditor::Core::EditorState.new
      state.snap_to_grid = true
      state.grid_size = 32

      # Test snapping positions
      pos1 = RL::Vector2.new(x: 45, y: 67)
      snapped1 = state.snap_to_grid(pos1)
      snapped1.x.should eq(32) # Nearest grid position
      snapped1.y.should eq(64) # Nearest grid position

      pos2 = RL::Vector2.new(x: 16, y: 16)
      snapped2 = state.snap_to_grid(pos2)
      snapped2.x.should eq(0) # 16/32 = 0.5, rounds to 0, 0*32 = 0
      snapped2.y.should eq(0) # 16/32 = 0.5, rounds to 0, 0*32 = 0

      # Test with snapping disabled
      state.snap_to_grid = false
      pos3 = RL::Vector2.new(x: 45, y: 67)
      unsnapped = state.snap_to_grid(pos3)
      unsnapped.x.should eq(45) # No snapping
      unsnapped.y.should eq(67) # No snapping
    end

    it "handles different editor tools" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Test tool switching
      state.current_tool = PaceEditor::Tool::Select
      state.current_tool.should eq(PaceEditor::Tool::Select)

      state.current_tool = PaceEditor::Tool::Move
      state.current_tool.should eq(PaceEditor::Tool::Move)

      state.current_tool = PaceEditor::Tool::Place
      state.current_tool.should eq(PaceEditor::Tool::Place)

      state.current_tool = PaceEditor::Tool::Delete
      state.current_tool.should eq(PaceEditor::Tool::Delete)

      # Tool should affect behavior (tested through state)
      state.current_tool = PaceEditor::Tool::Place
      # In place mode, clicking would create new objects
      state.current_tool.place?.should be_true

      state.current_tool = PaceEditor::Tool::Delete
      # In delete mode, clicking would remove objects
      state.current_tool.delete?.should be_true
    end

    it "manages scene viewport correctly" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      # Check initial viewport
      editor.viewport_x.should eq(100)
      editor.viewport_y.should eq(50)
      editor.viewport_width.should eq(800)
      editor.viewport_height.should eq(600)

      # Update viewport
      editor.update_viewport(200, 100, 1024, 768)

      editor.viewport_x.should eq(200)
      editor.viewport_y.should eq(100)
      editor.viewport_width.should eq(1024)
      editor.viewport_height.should eq(768)

      # Test coordinate transformations
      screen_pos = RL::Vector2.new(x: 300, y: 200)
      world_pos = state.screen_to_world(screen_pos)

      # World position should account for camera offset and zoom
      expected_x = screen_pos.x / state.zoom + state.camera_x
      expected_y = screen_pos.y / state.zoom + state.camera_y

      world_pos.x.should be_close(expected_x, 0.01)
      world_pos.y.should be_close(expected_y, 0.01)

      # Convert back to screen
      back_to_screen = state.world_to_screen(world_pos)
      back_to_screen.x.should be_close(screen_pos.x, 0.01)
      back_to_screen.y.should be_close(screen_pos.y, 0.01)
    end
  end
end
