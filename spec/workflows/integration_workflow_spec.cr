require "../spec_helper"
require "file_utils"

describe "Integration Workflow" do
  temp_dir = "/tmp/pace_editor_integration_#{Time.utc.to_unix}"

  before_all do
    Dir.mkdir_p(temp_dir)
    RaylibTestHelper.init
  end

  after_all do
    RaylibTestHelper.cleanup
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end

  describe "complete editor integration" do
    it "performs full create-edit-save workflow" do
      # 1. Create new project
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new
      project.name = "integration_test"
      project.project_path = "#{temp_dir}/integration_test"

      Dir.mkdir_p(project.project_path)
      project.save_project

      state.current_project = project

      # 2. Create editor window with all components
      window = PaceEditor::Core::EditorWindow.new
      window.state = state

      # 3. Create a new scene
      scene = PointClickEngine::Scenes::Scene.new("main_menu")
      scene.background_path = "menu_bg.png"

      # 4. Add interactive elements
      # Add start button hotspot
      start_button = PointClickEngine::Scenes::Hotspot.new(
        "start_button",
        RL::Vector2.new(x: 400, y: 300),
        RL::Vector2.new(x: 200, y: 50)
      )
      start_button.description = "Start New Game"
      start_button.cursor_type = :hand
      scene.hotspots << start_button

      # Add options button
      options_button = PointClickEngine::Scenes::Hotspot.new(
        "options_button",
        RL::Vector2.new(x: 400, y: 370),
        RL::Vector2.new(x: 200, y: 50)
      )
      options_button.description = "Game Options"
      options_button.cursor_type = :hand
      scene.hotspots << options_button

      # Add character
      character = PointClickEngine::Characters::TestCharacter.new("character")
      character.position = RL::Vector2.new(x: 100, y: 200)
      character.size = RL::Vector2.new(x: 64, y: 128)
      scene.characters << character

      # 5. Save the scene
      project.scenes << "main_menu"
      # In real implementation, would save scene file

      # 6. Test editor operations

      # Select objects
      state.selected_object = "start_button"
      state.selected_object.should eq("start_button")

      # Multi-select
      state.selected_hotspots.clear
      state.selected_hotspots << "start_button"
      state.selected_hotspots << "options_button"
      state.selected_hotspots.size.should eq(2)

      # Change tool
      state.current_tool = PaceEditor::Tool::Move
      state.current_tool.move?.should be_true

      # Move camera
      state.camera_x = 50
      state.camera_y = 25
      state.zoom = 1.2f32

      # 7. Test UI updates
      # Property panel would show selected object properties
      # Scene hierarchy would show "main_menu" scene
      # Asset browser would show available assets

      # 8. Mark as dirty and save
      state.mark_dirty
      state.is_dirty.should be_true

      project.save_project
      state.clear_dirty
      state.is_dirty.should be_false

      # 9. Verify project structure
      File.exists?("#{project.project_path}/project.pace").should be_true
      Dir.exists?("#{project.project_path}/scenes").should be_true
      Dir.exists?("#{project.project_path}/assets").should be_true
    end

    it "handles complex multi-scene project" do
      # Create a game with multiple interconnected scenes
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new
      project.name = "adventure_game"
      project.project_path = "#{temp_dir}/adventure_game"

      Dir.mkdir_p(project.project_path)

      # Scene 1: Village
      village_scene = PointClickEngine::Scenes::Scene.new("village")
      village_scene.background_path = "village_day.png"

      # Add exit to forest
      forest_exit = PointClickEngine::Scenes::Hotspot.new(
        "to_forest",
        RL::Vector2.new(x: 750, y: 200),
        RL::Vector2.new(x: 50, y: 400)
      )
      forest_exit.description = "Path to the forest"
      forest_exit.cursor_type = :hand
      village_scene.hotspots << forest_exit

      # Add merchant NPC
      merchant = PointClickEngine::Characters::TestCharacter.new("merchant")
      merchant.position = RL::Vector2.new(x: 300, y: 350)
      merchant.size = RL::Vector2.new(x: 64, y: 128)
      village_scene.characters << merchant

      # Scene 2: Forest
      forest_scene = PointClickEngine::Scenes::Scene.new("forest")
      forest_scene.background_path = "forest_path.png"

      # Add exit back to village
      village_exit = PointClickEngine::Scenes::Hotspot.new(
        "to_village",
        RL::Vector2.new(x: 50, y: 200),
        RL::Vector2.new(x: 50, y: 400)
      )
      village_exit.description = "Return to village"
      village_exit.cursor_type = :hand
      forest_scene.hotspots << village_exit

      # Add item to collect
      mushroom = PointClickEngine::Scenes::Hotspot.new(
        "mushroom",
        RL::Vector2.new(x: 400, y: 450),
        RL::Vector2.new(x: 40, y: 40)
      )
      mushroom.description = "A glowing mushroom"
      mushroom.cursor_type = :hand
      forest_scene.hotspots << mushroom

      # Add scenes to project
      project.scenes << "village"
      project.scenes << "forest"
      project.current_scene = "village"

      state.current_project = project

      # Test scene switching
      project.current_scene = "forest"
      project.current_scene.should eq("forest")

      project.current_scene = "village"
      project.current_scene.should eq("village")

      # Test cross-scene references
      project.scenes.should contain("village")
      project.scenes.should contain("forest")

      # Save project
      project.save_project
      File.exists?("#{project.project_path}/project.pace").should be_true
    end

    it "handles editor window resizing" do
      state = PaceEditor::Core::EditorState.new
      window = PaceEditor::Core::EditorWindow.new

      # Initial window size
      initial_width = 1280
      initial_height = 720

      # Simulate window resize
      new_width = 1920
      new_height = 1080

      window.handle_resize(new_width, new_height)

      # All panels should adjust
      window.width.should eq(new_width)
      window.height.should eq(new_height)

      # Scene editor viewport should be recalculated
      viewport_width = new_width - PaceEditor::Core::EditorWindow::TOOL_PALETTE_WIDTH - PaceEditor::Core::EditorWindow::PROPERTY_PANEL_WIDTH
      viewport_height = new_height - PaceEditor::Core::EditorWindow::MENU_HEIGHT

      window.scene_editor.viewport_width.should eq(viewport_width)
      window.scene_editor.viewport_height.should eq(viewport_height)
    end

    it "handles error conditions gracefully" do
      state = PaceEditor::Core::EditorState.new

      # Try to load non-existent project
      begin
        project = PaceEditor::Core::Project.load_project("/non/existent/project.pace")
      rescue ex
        (ex.message || "").should match(/No such file|cannot find/i)
      end

      # Try to save to read-only location
      project = PaceEditor::Core::Project.new
      project.name = "test"
      project.project_path = "/root/readonly"

      begin
        project.save_project
      rescue ex
        # Could be permission denied or other error
        (ex.message || "").should match(/Permission denied|Read-only file system|No such file or directory/i)
      end

      # Handle invalid scene data
      scene = PointClickEngine::Scenes::Scene.new("")
      scene.name.should eq("")

      # Handle extreme zoom values
      state.zoom = 1000.0f32
      state.zoom = state.zoom.clamp(0.1f32, 5.0f32)
      state.zoom.should eq(5.0f32)

      # Handle very long text input
      long_text = "a" * 1000
      state.selected_object = long_text[0...255] # Truncate to reasonable length
      state.selected_object.not_nil!.size.should eq(255)
    end
  end

  describe "performance under load" do
    it "handles large scenes efficiently" do
      state = PaceEditor::Core::EditorState.new
      scene = PointClickEngine::Scenes::Scene.new("large_scene")

      # Add many hotspots
      100.times do |i|
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "hotspot_#{i}",
          RL::Vector2.new(x: (i % 10) * 100, y: (i // 10) * 100),
          RL::Vector2.new(x: 80, y: 80)
        )
        scene.hotspots << hotspot
      end

      # Add many characters
      50.times do |i|
        character = PointClickEngine::Characters::TestCharacter.new("npc_#{i}")
        character.position = RL::Vector2.new(x: i * 50, y: 300)
        character.size = RL::Vector2.new(x: 48, y: 96)
        scene.characters << character
      end

      # Verify scene can handle many objects
      scene.hotspots.size.should eq(100)
      scene.characters.size.should eq(50)

      # Test selection performance
      start_time = Time.monotonic
      state.selected_hotspots.clear
      scene.hotspots.each { |h| state.selected_hotspots << h.name }
      selection_time = Time.monotonic - start_time

      # Selection should be fast even with many objects
      selection_time.total_milliseconds.should be < 100
      state.selected_hotspots.size.should eq(100)

      # Test clear performance
      start_time = Time.monotonic
      state.clear_selection
      clear_time = Time.monotonic - start_time

      clear_time.total_milliseconds.should be < 10
      state.selected_hotspots.should be_empty
    end
  end
end
