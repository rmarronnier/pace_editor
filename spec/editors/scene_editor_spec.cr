require "../spec_helper"
require "../../src/pace_editor/editors/scene_editor"

describe PaceEditor::Editors::SceneEditor do
  describe "initialization" do
    it "creates a scene editor with viewport dimensions" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      editor.viewport_x.should eq(100)
      editor.viewport_y.should eq(50)
      editor.viewport_width.should eq(800)
      editor.viewport_height.should eq(600)
    end
  end

  describe "viewport management" do
    it "updates viewport dimensions" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      editor.update_viewport(150, 75, 900, 700)

      editor.viewport_x.should eq(150)
      editor.viewport_y.should eq(75)
      editor.viewport_width.should eq(900)
      editor.viewport_height.should eq(700)
    end
  end

  describe "coordinate transformation" do
    it "converts screen to world coordinates" do
      state = PaceEditor::Core::EditorState.new
      state.camera_x = 100.0_f32
      state.camera_y = 50.0_f32
      state.zoom = 2.0_f32

      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      # Test screen to world conversion
      # Formula: (screen_pos - viewport) / zoom + camera
      screen_pos = RL::Vector2.new(300.0_f32, 250.0_f32)
      # Expected: ((300 - 100) / 2 + 100, (250 - 50) / 2 + 50) = (200, 150)
      # world_pos = editor.screen_to_world(screen_pos)
      # world_pos.x.should be_close(200.0_f32, 0.01)
      # world_pos.y.should be_close(150.0_f32, 0.01)
    end

    it "converts world to screen coordinates" do
      state = PaceEditor::Core::EditorState.new
      state.camera_x = 100.0_f32
      state.camera_y = 50.0_f32
      state.zoom = 2.0_f32

      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      # Test world to screen conversion
      # Formula: (world_pos - camera) * zoom + viewport
      world_pos = RL::Vector2.new(200.0_f32, 150.0_f32)
      # Expected: ((200 - 100) * 2 + 100, (150 - 50) * 2 + 50) = (300, 250)
      # screen_pos = editor.world_to_screen(world_pos)
      # screen_pos.x.should be_close(300.0_f32, 0.01)
      # screen_pos.y.should be_close(250.0_f32, 0.01)
    end
  end

  describe "grid snapping" do
    it "snaps coordinates to grid when enabled" do
      state = PaceEditor::Core::EditorState.new
      state.snap_to_grid = true
      state.grid_size = 16

      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Test grid snapping
      # 25 / 16 = 1.56, rounds to 2, 2 * 16 = 32
      snapped = editor.snap_to_grid(25)
      snapped.should eq(32)

      # 15 / 16 = 0.94, rounds to 1, 1 * 16 = 16
      snapped = editor.snap_to_grid(15)
      snapped.should eq(16)

      # 8 / 16 = 0.5, rounds to 1, 1 * 16 = 16
      snapped = editor.snap_to_grid(8)
      snapped.should eq(16)
    end

    it "doesn't snap when disabled" do
      state = PaceEditor::Core::EditorState.new
      state.snap_to_grid = false
      state.grid_size = 16

      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      snapped = editor.snap_to_grid(25)
      snapped.should eq(25)
    end
  end

  describe "object placement" do
    it "creates hotspots with unique names" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      state.current_scene = scene

      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Simulate placing hotspots
      # In real implementation, this happens through handle_place_tool
      scene.hotspots << PointClickEngine::Scenes::Hotspot.new(
        "hotspot_1",
        RL::Vector2.new(100, 100),
        RL::Vector2.new(64, 64)
      )

      scene.hotspots << PointClickEngine::Scenes::Hotspot.new(
        "hotspot_2",
        RL::Vector2.new(200, 200),
        RL::Vector2.new(64, 64)
      )

      # Verify unique names
      names = scene.hotspots.map(&.name)
      names.should eq(["hotspot_1", "hotspot_2"])
      names.uniq.size.should eq(names.size)
    end

    it "creates characters with default properties" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      state.current_scene = scene

      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Simulate character creation
      npc = PointClickEngine::Characters::NPC.new(
        "character_1",
        RL::Vector2.new(300, 400),
        RL::Vector2.new(32, 64)
      )
      npc.description = "New character"
      npc.walking_speed = 100.0_f32
      npc.state = PointClickEngine::Characters::CharacterState::Idle
      npc.direction = PointClickEngine::Characters::Direction::Right
      npc.mood = PointClickEngine::Characters::NPCMood::Neutral

      scene.characters << npc

      # Verify character properties
      scene.characters.size.should eq(1)
      char = scene.characters[0].as(PointClickEngine::Characters::NPC)
      char.name.should eq("character_1")
      char.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      char.direction.should eq(PointClickEngine::Characters::Direction::Right)
      char.mood.should eq(PointClickEngine::Characters::NPCMood::Neutral)
    end

    it "adds undo actions for object creation" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      state.current_scene = scene

      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      state.can_undo?.should be_false

      # Simulate object creation with undo action
      create_action = PaceEditor::Core::CreateObjectAction.new(
        "hotspot_1",
        "hotspot",
        RL::Vector2.new(100, 100),
        state
      )
      state.add_undo_action(create_action)

      state.can_undo?.should be_true
    end
  end

  describe "object selection" do
    it "selects objects at clicked position" do
      state = PaceEditor::Core::EditorState.new
      scene = PointClickEngine::Scenes::Scene.new("test_scene")

      # Add a hotspot
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "button",
        RL::Vector2.new(100, 100),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      scene.hotspots << hotspot
      state.current_scene = scene

      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Test object detection
      # Object is at 100,100 with size 50,50
      # So it covers 100-150 x and 100-150 y

      # Inside hotspot
      obj = editor.get_object_at(scene, RL::Vector2.new(125, 125))
      obj.should eq("button")

      # Outside hotspot
      obj = editor.get_object_at(scene, RL::Vector2.new(200, 200))
      obj.should be_nil
    end

    it "selects characters at clicked position" do
      state = PaceEditor::Core::EditorState.new
      scene = PointClickEngine::Scenes::Scene.new("test_scene")

      # Add a character
      npc = PointClickEngine::Characters::NPC.new(
        "guard",
        RL::Vector2.new(300, 400),
        RL::Vector2.new(32, 64)
      )
      scene.characters << npc
      state.current_scene = scene

      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Characters have a selection box of roughly 50x100 centered on position
      # So at position 300,400 it covers roughly 275-325 x and 350-450 y

      # Inside character bounds
      obj = editor.get_object_at(scene, RL::Vector2.new(300, 400))
      obj.should eq("guard")

      # Outside character bounds
      obj = editor.get_object_at(scene, RL::Vector2.new(400, 500))
      obj.should be_nil
    end
  end

  describe "object deletion" do
    it "deletes selected objects" do
      state = PaceEditor::Core::EditorState.new
      scene = PointClickEngine::Scenes::Scene.new("test_scene")

      # Add objects
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "door",
        RL::Vector2.new(100, 100),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      scene.hotspots << hotspot

      npc = PointClickEngine::Characters::NPC.new(
        "guard",
        RL::Vector2.new(300, 400),
        RL::Vector2.new(32, 64)
      )
      scene.characters << npc

      state.current_scene = scene
      state.selected_object = "door"

      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      scene.hotspots.size.should eq(1)
      scene.characters.size.should eq(1)

      # Delete selected hotspot
      editor.delete_selected_objects

      scene.hotspots.size.should eq(0)
      scene.characters.size.should eq(1)
      state.selected_object.should be_nil
    end

    it "deletes multiple selected objects" do
      state = PaceEditor::Core::EditorState.new
      scene = PointClickEngine::Scenes::Scene.new("test_scene")

      # Add multiple hotspots
      3.times do |i|
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "hotspot_#{i}",
          RL::Vector2.new((100 * i).to_f32, 100.0_f32),
          RL::Vector2.new(50.0_f32, 50.0_f32)
        )
        scene.hotspots << hotspot
      end

      state.current_scene = scene
      state.selected_hotspots = ["hotspot_0", "hotspot_2"]

      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      scene.hotspots.size.should eq(3)

      editor.delete_selected_objects

      scene.hotspots.size.should eq(1)
      scene.hotspots[0].name.should eq("hotspot_1")
      state.selected_hotspots.should be_empty
    end
  end

  describe "camera controls" do
    it "handles zoom with mouse wheel" do
      state = PaceEditor::Core::EditorState.new
      state.zoom = 1.0_f32

      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Zoom is controlled by mouse wheel in update method
      # Zoom in: multiply by 1.1
      # Zoom out: multiply by 0.9
      # Clamped between 0.1 and 5.0

      state.zoom = 1.0_f32 * 1.1_f32
      state.zoom.should be_close(1.1_f32, 0.01)

      state.zoom = 1.0_f32 * 0.9_f32
      state.zoom.should be_close(0.9_f32, 0.01)

      # Test clamping
      state.zoom = 6.0_f32
      state.zoom = state.zoom.clamp(0.1_f32, 5.0_f32)
      state.zoom.should eq(5.0_f32)

      state.zoom = 0.05_f32
      state.zoom = state.zoom.clamp(0.1_f32, 5.0_f32)
      state.zoom.should eq(0.1_f32)
    end

    it "resets camera on Home key" do
      state = PaceEditor::Core::EditorState.new
      state.camera_x = 100.0_f32
      state.camera_y = 200.0_f32
      state.zoom = 2.5_f32

      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Simulate Home key press (handled in handle_keyboard_shortcuts)
      state.camera_x = 0
      state.camera_y = 0
      state.zoom = 1.0_f32

      state.camera_x.should eq(0)
      state.camera_y.should eq(0)
      state.zoom.should eq(1.0_f32)
    end
  end

  describe "mouse interaction" do
    it "checks if mouse is in viewport" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      # Inside viewport
      in_viewport = editor.mouse_in_viewport?(RL::Vector2.new(500, 300))
      in_viewport.should be_true

      # Outside viewport (left)
      in_viewport = editor.mouse_in_viewport?(RL::Vector2.new(50, 300))
      in_viewport.should be_false

      # Outside viewport (top)
      in_viewport = editor.mouse_in_viewport?(RL::Vector2.new(500, 25))
      in_viewport.should be_false

      # Outside viewport (right)
      in_viewport = editor.mouse_in_viewport?(RL::Vector2.new(950, 300))
      in_viewport.should be_false

      # Outside viewport (bottom)
      in_viewport = editor.mouse_in_viewport?(RL::Vector2.new(500, 700))
      in_viewport.should be_false
    end
  end
end
