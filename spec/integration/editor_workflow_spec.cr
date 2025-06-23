require "../spec_helper"

describe "Editor Workflow Integration" do
  # This test verifies that all the editor components work together
  it "simulates complete scene creation workflow" do
    # Setup
    temp_dir = File.tempname("editor_workflow_#{Time.utc.to_unix_ms}")

    # 1. Create project
    project = PaceEditor::Core::Project.new("Editor Test Game", temp_dir)
    state = PaceEditor::Core::EditorState.new
    state.current_project = project

    # 2. Create new scene (simulating menu action)
    scene_name = "test_scene"
    scene = PointClickEngine::Scenes::Scene.new(scene_name)
    state.current_scene = scene

    # 3. Set background (simulating background selector)
    scene.background_path = "backgrounds/test_room.png"

    # 4. Add hotspot (simulating place tool)
    hotspot = PointClickEngine::Scenes::Hotspot.new(
      "door",
      RL::Vector2.new(500.0_f32, 300.0_f32),
      RL::Vector2.new(100.0_f32, 200.0_f32)
    )
    hotspot.description = "A wooden door"
    hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
    scene.hotspots << hotspot

    # 5. Add character (simulating character placement)
    npc = PointClickEngine::Characters::NPC.new(
      "guard",
      RL::Vector2.new(200.0_f32, 400.0_f32),
      RL::Vector2.new(64.0_f32, 128.0_f32)
    )
    npc.add_dialogue("Halt! Who goes there?")
    scene.characters << npc

    # 6. Save scene (simulating Ctrl+S)
    scene_path = PaceEditor::IO::SceneIO.get_scene_file_path(project, scene_name)
    PaceEditor::IO::SceneIO.save_scene(scene, scene_path)

    # 7. Create hotspot script
    script_content = <<-LUA
    -- Script for door hotspot
    function on_click()
        change_scene("next_room")
    end
    
    function on_look()
        show_message("A sturdy wooden door leads to the next room.")
    end
    LUA

    script_path = File.join(project.scripts_path, "door.lua")
    File.write(script_path, script_content)

    # === Verify Results ===

    # Project structure exists
    Dir.exists?(project.project_path).should be_true
    Dir.exists?(project.scenes_path).should be_true
    Dir.exists?(project.scripts_path).should be_true

    # Scene was saved
    File.exists?(scene_path).should be_true

    # Scene can be loaded back
    loaded_scene = PaceEditor::IO::SceneIO.load_scene(scene_path)
    loaded_scene.should_not be_nil

    if loaded_scene
      # Verify scene properties
      loaded_scene.name.should eq("test_scene")
      loaded_scene.background_path.should eq("backgrounds/test_room.png")

      # Verify hotspot
      loaded_scene.hotspots.size.should eq(1)
      door = loaded_scene.hotspots.first
      door.name.should eq("door")
      door.position.x.should eq(500.0_f32)
      door.position.y.should eq(300.0_f32)
      door.description.should eq("A wooden door")

      # Verify character
      loaded_scene.characters.size.should eq(1)
      guard = loaded_scene.characters.first
      guard.name.should eq("guard")
      guard.position.x.should eq(200.0_f32)
      guard.position.y.should eq(400.0_f32)
    end

    # Script exists
    File.exists?(script_path).should be_true

    # Cleanup
    FileUtils.rm_rf(temp_dir)
  end

  it "tests editor state management" do
    state = PaceEditor::Core::EditorState.new

    # Test mode switching
    state.current_mode = PaceEditor::EditorMode::Scene
    state.current_mode.should eq(PaceEditor::EditorMode::Scene)

    state.current_mode = PaceEditor::EditorMode::Hotspot
    state.current_mode.should eq(PaceEditor::EditorMode::Hotspot)

    # Test tool switching
    state.current_tool = PaceEditor::Tool::Select
    state.current_tool.should eq(PaceEditor::Tool::Select)

    state.current_tool = PaceEditor::Tool::Place
    state.current_tool.should eq(PaceEditor::Tool::Place)

    # Test selection
    state.selected_object = "test_object"
    state.selected_object.should eq("test_object")

    # Test dirty flag
    state.is_dirty = true
    state.is_dirty.should be_true
  end

  it "tests property editing workflow" do
    # Setup
    temp_dir = File.tempname("property_test_#{Time.utc.to_unix_ms}")
    project = PaceEditor::Core::Project.new("Property Test", temp_dir)
    state = PaceEditor::Core::EditorState.new
    state.current_project = project

    # Create scene with hotspot
    scene = PointClickEngine::Scenes::Scene.new("prop_test_scene")
    hotspot = PointClickEngine::Scenes::Hotspot.new(
      "test_hotspot",
      RL::Vector2.new(100.0_f32, 100.0_f32),
      RL::Vector2.new(50.0_f32, 50.0_f32)
    )
    scene.hotspots << hotspot
    state.current_scene = scene
    state.selected_object = "test_hotspot"

    # Simulate property changes
    hotspot.position = RL::Vector2.new(200.0_f32, 150.0_f32)
    hotspot.size = RL::Vector2.new(75.0_f32, 100.0_f32)
    hotspot.description = "Updated description"

    # Save and reload
    scene_path = PaceEditor::IO::SceneIO.get_scene_file_path(project, scene.name)
    PaceEditor::IO::SceneIO.save_scene(scene, scene_path)

    loaded_scene = PaceEditor::IO::SceneIO.load_scene(scene_path)
    loaded_scene.should_not be_nil

    if loaded_scene && (updated_hotspot = loaded_scene.hotspots.first?)
      updated_hotspot.position.x.should eq(200.0_f32)
      updated_hotspot.position.y.should eq(150.0_f32)
      updated_hotspot.size.x.should eq(75.0_f32)
      updated_hotspot.size.y.should eq(100.0_f32)
      updated_hotspot.description.should eq("Updated description")
    end

    # Cleanup
    FileUtils.rm_rf(temp_dir)
  end
end
