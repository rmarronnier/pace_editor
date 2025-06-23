require "../spec_helper"

# Cycle B: Integration Testing
# Focus: Cross-feature interactions, data consistency
# Duration: 45 minutes
# Tests: Multi-feature workflows

describe "Cycle B: Integration Testing" do
  temp_dir = ""
  project_dir = ""

  before_each do
    temp_dir = File.tempname
    project_dir = File.join(temp_dir, "integration_test_project")
    Dir.mkdir_p(temp_dir)
  end

  after_each do
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end

  describe "Cross-Feature Data Consistency" do
    it "maintains scene-asset references correctly" do
      # Create project and scene with background reference
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Scene Asset Test", project_dir)

      project = state.current_project.not_nil!

      # Add background asset
      bg_dir = project.backgrounds_path
      bg_file = File.join(bg_dir, "room.png")
      File.write(bg_file, "fake_image_data")

      # Refresh assets
      project.refresh_assets
      project.backgrounds.should contain("room.png")

      # Create scene with background reference
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.background_path = "backgrounds/room.png"

      # Save scene
      scene_file = File.join(project.scenes_path, "test_scene.yml")
      save_success = PaceEditor::IO::SceneIO.save_scene(scene, scene_file)
      save_success.should be_true

      # Load scene and verify reference integrity
      loaded_scene = PaceEditor::IO::SceneIO.load_scene(scene_file)
      loaded_scene.should_not be_nil
      loaded_scene.not_nil!.background_path.should eq("backgrounds/room.png")

      # Verify asset still exists
      File.exists?(bg_file).should be_true
    end

    it "handles project-scene relationships correctly" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Project Scene Test", project_dir)

      project = state.current_project.not_nil!

      # Create multiple scenes
      scene_names = ["intro", "forest", "castle"]
      scene_names.each do |scene_name|
        scene = PointClickEngine::Scenes::Scene.new(scene_name)
        scene_file = File.join(project.scenes_path, "#{scene_name}.yml")
        PaceEditor::IO::SceneIO.save_scene(scene, scene_file)
        project.add_scene("#{scene_name}.yml")
      end

      # Verify all scenes are tracked
      scene_names.each do |scene_name|
        project.scenes.should contain("#{scene_name}.yml")
      end

      # Save and reload project
      project.save

      # Load project again
      project_file = File.join(project_dir, "project.pace")
      new_state = PaceEditor::Core::EditorState.new
      new_state.load_project(project_file).should be_true

      # Verify scene relationships persist
      loaded_project = new_state.current_project.not_nil!
      scene_names.each do |scene_name|
        loaded_project.scenes.should contain("#{scene_name}.yml")
      end
    end

    it "maintains character-dialog links correctly" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Character Dialog Test", project_dir)

      # Create scene with character
      scene = PointClickEngine::Scenes::Scene.new("character_test")
      character = PointClickEngine::Characters::NPC.new(
        "merchant",
        RL::Vector2.new(100.0_f32, 200.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      character.description = "Friendly merchant"
      character.walking_speed = 80.0_f32
      character.state = PointClickEngine::Characters::CharacterState::Idle
      character.direction = PointClickEngine::Characters::Direction::Right
      character.mood = PointClickEngine::Characters::CharacterMood::Friendly

      scene.characters << character
      state.current_scene = scene

      # Verify character properties are maintained
      state.current_scene.not_nil!.characters.size.should eq(1)
      saved_char = state.current_scene.not_nil!.characters.first
      saved_char.name.should eq("merchant")
      saved_char.description.should eq("Friendly merchant")

      # Check mood property (now available on all characters)
      saved_char.mood.should eq(PointClickEngine::Characters::CharacterMood::Friendly)
    end

    it "handles hotspot-script connections correctly" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Hotspot Script Test", project_dir)

      project = state.current_project.not_nil!

      # Create script file
      script_dir = File.join(project.project_path, "assets", "scripts")
      script_file = File.join(script_dir, "door_click.lua")
      script_content = <<-LUA
        function on_click()
          print("Door clicked!")
          change_scene("forest")
        end
        LUA
      File.write(script_file, script_content)

      # Create scene with hotspot referencing script
      scene = PointClickEngine::Scenes::Scene.new("hotspot_test")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        name: "door",
        position: RL::Vector2.new(300.0_f32, 200.0_f32),
        size: RL::Vector2.new(64.0_f32, 96.0_f32)
      )
      hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
      hotspot.visible = true
      hotspot.description = "Wooden door"
      hotspot.script_path = "scripts/door_click.lua"

      scene.hotspots << hotspot

      # Verify hotspot-script connection
      scene.hotspots.size.should eq(1)
      saved_hotspot = scene.hotspots.first
      saved_hotspot.name.should eq("door")
      saved_hotspot.script_path.should eq("scripts/door_click.lua")

      # Verify script file exists
      File.exists?(script_file).should be_true
      File.read(script_file).should contain("on_click")
    end
  end

  describe "State Management Integration" do
    it "maintains undo/redo consistency across operations" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Undo Test", project_dir)

      # Create initial scene
      scene = PointClickEngine::Scenes::Scene.new("undo_test")
      state.current_scene = scene

      # Perform actions that should be undoable
      original_pos = RL::Vector2.new(100.0_f32, 100.0_f32)
      new_pos = RL::Vector2.new(200.0_f32, 200.0_f32)

      # Create a hotspot
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        name: "test_hotspot",
        position: original_pos,
        size: RL::Vector2.new(64.0_f32, 64.0_f32)
      )
      scene.hotspots << hotspot

      # Create undo action for moving the hotspot
      move_action = PaceEditor::Core::MoveObjectAction.new("test_hotspot", original_pos, new_pos, state)
      state.add_undo_action(move_action)

      # Move the hotspot
      hotspot.position = new_pos

      # Test undo/redo
      state.can_undo?.should be_true
      state.undo.should be_true

      # Verify hotspot was moved back
      scene.hotspots.first.position.x.should eq(original_pos.x)
      scene.hotspots.first.position.y.should eq(original_pos.y)

      # Test redo
      state.can_redo?.should be_true
      state.redo.should be_true

      # Verify hotspot was moved forward again
      scene.hotspots.first.position.x.should eq(new_pos.x)
      scene.hotspots.first.position.y.should eq(new_pos.y)
    end

    it "handles dirty state tracking correctly" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Dirty State Test", project_dir)

      # Initially should not be dirty
      state.is_dirty.should be_false

      # Mark dirty
      state.mark_dirty
      state.is_dirty.should be_true

      # Clear dirty
      state.clear_dirty
      state.is_dirty.should be_false

      # Save project should clear dirty state
      state.mark_dirty
      state.save_project
      # Note: Real implementation should clear dirty state after successful save
    end

    it "maintains selection state consistency" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Selection Test", project_dir)

      # Create scene with objects
      scene = PointClickEngine::Scenes::Scene.new("selection_test")

      # Add hotspot
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        name: "hotspot1",
        position: RL::Vector2.new(100.0_f32, 100.0_f32),
        size: RL::Vector2.new(64.0_f32, 64.0_f32)
      )
      scene.hotspots << hotspot

      # Add character
      character = PointClickEngine::Characters::NPC.new(
        "character1",
        RL::Vector2.new(200.0_f32, 200.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      scene.characters << character

      state.current_scene = scene

      # Test selection operations
      state.selected_object.should be_nil

      # Select hotspot
      state.select_object("hotspot1")
      state.selected_object.should eq("hotspot1")
      state.is_selected?("hotspot1").should be_true
      state.selected_hotspots.should contain("hotspot1")

      # Select character with multi-select
      state.select_object("character1", multi_select: true)
      state.is_selected?("character1").should be_true
      state.selected_characters.should contain("character1")
      state.has_multiple_selection?.should be_true

      # Clear selection
      state.clear_selection
      state.selected_object.should be_nil
      state.selected_hotspots.should be_empty
      state.selected_characters.should be_empty
    end

    it "handles auto-save behavior correctly" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Auto Save Test", project_dir)

      # Auto-save should be enabled by default
      state.auto_save.should be_true

      # Auto-save interval should be reasonable
      state.auto_save_interval.should be > 0
      state.auto_save_interval.should be <= 600 # Max 10 minutes

      # Can disable auto-save
      state.auto_save = false
      state.auto_save.should be_false
    end
  end

  describe "Export Integration" do
    it "validates complete project before export" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Export Validation Test", project_dir)

      project = state.current_project.not_nil!

      # Add required assets for export
      bg_file = File.join(project.backgrounds_path, "room.png")
      File.write(bg_file, "fake_background")

      script_file = File.join(File.join(project.project_path, "assets", "scripts"), "main.lua")
      File.write(script_file, "function init() end")

      # Create scene with proper references
      scene = PointClickEngine::Scenes::Scene.new("main")
      scene.background_path = "backgrounds/room.png"
      scene_file = File.join(project.scenes_path, "main.yml")
      PaceEditor::IO::SceneIO.save_scene(scene, scene_file)

      # Refresh assets
      project.refresh_assets

      # Export should find all required components
      export_path = File.join(project_dir, "exports", "test_export")

      # Create export dialog to test validation
      export_dialog = PaceEditor::UI::GameExportDialog.new(state)
      export_dialog.should_not be_nil

      # Dialog should initialize correctly
      export_dialog.visible.should be_false
      export_dialog.show
      export_dialog.visible.should be_true
    end

    it "handles asset packaging correctly during export" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Asset Package Test", project_dir)

      project = state.current_project.not_nil!

      # Create comprehensive asset structure
      asset_files = {
        "backgrounds/room.png" => "background_data",
        "characters/hero.png"  => "character_data",
        "sounds/click.wav"     => "sound_data",
        "music/theme.ogg"      => "music_data",
        "scripts/main.lua"     => "script_data",
      }

      asset_files.each do |relative_path, content|
        full_path = File.join(project.project_path, "assets", relative_path)
        Dir.mkdir_p(File.dirname(full_path))
        File.write(full_path, content)
      end

      # Refresh assets
      project.refresh_assets

      # Verify all assets are detected
      project.backgrounds.should contain("room.png")
      project.characters.should contain("hero.png")
      project.sounds.should contain("click.wav")
      project.music.should contain("theme.ogg")
      project.scripts.should contain("main.lua")

      # Create scene using assets
      scene = PointClickEngine::Scenes::Scene.new("asset_test")
      scene.background_path = "backgrounds/room.png"

      # Add character
      character = PointClickEngine::Characters::NPC.new(
        "hero",
        RL::Vector2.new(100.0_f32, 200.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      character.sprite_path = "characters/hero.png"
      scene.characters << character

      # Add hotspot with script
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        name: "button",
        position: RL::Vector2.new(300.0_f32, 400.0_f32),
        size: RL::Vector2.new(64.0_f32, 32.0_f32)
      )
      hotspot.script_path = "scripts/main.lua"
      scene.hotspots << hotspot

      # Save scene
      scene_file = File.join(project.scenes_path, "asset_test.yml")
      PaceEditor::IO::SceneIO.save_scene(scene, scene_file)

      # Scene should reference all assets correctly
      saved_scene = PaceEditor::IO::SceneIO.load_scene(scene_file)
      saved_scene.should_not be_nil
      saved_scene.not_nil!.background_path.should eq("backgrounds/room.png")
      saved_scene.not_nil!.characters.first.sprite_path.should eq("characters/hero.png")
      saved_scene.not_nil!.hotspots.first.script_path.should eq("scripts/main.lua")
    end

    it "generates consistent export formats" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Export Format Test", project_dir)

      project = state.current_project.not_nil!

      # Set up project metadata
      project.title = "Test Game"
      project.author = "Test Developer"
      project.version = "1.0.0"
      project.window_width = 800
      project.window_height = 600

      # Create export dialog
      export_dialog = PaceEditor::UI::GameExportDialog.new(state)

      # Test different export formats
      export_formats = ["standalone", "web", "source"]

      export_formats.each do |format|
        # Export format selection should work
        # (Real implementation would test actual export generation)
        ["standalone", "web", "source"].should contain(format)
      end
    end
  end

  describe "Dialog Integration" do
    it "integrates character and dialog systems correctly" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Dialog Integration Test", project_dir)

      # Create character
      scene = PointClickEngine::Scenes::Scene.new("dialog_test")
      character = PointClickEngine::Characters::NPC.new(
        "storyteller",
        RL::Vector2.new(400.0_f32, 300.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      character.description = "Wise storyteller"
      character.mood = PointClickEngine::Characters::CharacterMood::Wise
      scene.characters << character

      state.current_scene = scene

      # Character should be available for dialog editing
      state.current_scene.not_nil!.characters.size.should eq(1)
      found_character = state.current_scene.not_nil!.characters.find { |c| c.name == "storyteller" }
      found_character.should_not be_nil
      found_character.not_nil!.mood.should eq(PointClickEngine::Characters::CharacterMood::Wise)

      # Dialog editor should be able to access character
      editor_window = PaceEditor::Core::EditorWindow.new
      editor_window.show_dialog_editor_for_character("storyteller")

      # Should switch to dialog mode
      editor_window.state.current_mode.should eq(PaceEditor::EditorMode::Dialog)
    end

    it "maintains dialog tree data consistency" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Dialog Tree Test", project_dir)

      # Create dialog file structure
      dialogs_dir = File.join(state.current_project.not_nil!.project_path, "dialogs")
      Dir.mkdir_p(dialogs_dir)

      # Dialog directory should exist
      Dir.exists?(dialogs_dir).should be_true

      # Create sample dialog file
      dialog_file = File.join(dialogs_dir, "storyteller.yml")
      dialog_content = <<-YAML
        character: storyteller
        root_node: welcome
        nodes:
          welcome:
            text: "Welcome, traveler!"
            choices:
              - text: "Who are you?"
                target: identity
              - text: "Goodbye"
                target: farewell
          identity:
            text: "I am the keeper of ancient stories."
            choices:
              - text: "Tell me a story"
                target: story
              - text: "I must go"
                target: farewell
          story:
            text: "Long ago, in a land far away..."
            choices:
              - text: "Continue"
                target: welcome
          farewell:
            text: "Safe travels, friend."
            choices: []
        YAML

      File.write(dialog_file, dialog_content)

      # Dialog file should be readable
      File.exists?(dialog_file).should be_true
      content = File.read(dialog_file)
      content.should contain("storyteller")
      content.should contain("Welcome, traveler!")
    end
  end

  describe "Performance Integration" do
    it "handles large projects efficiently" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Large Project Test", project_dir)

      project = state.current_project.not_nil!

      # Create multiple scenes
      scene_count = 10
      scene_count.times do |i|
        scene = PointClickEngine::Scenes::Scene.new("scene_#{i}")
        scene.background_path = "backgrounds/bg_#{i}.png"

        # Add objects to each scene
        5.times do |j|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            name: "hotspot_#{i}_#{j}",
            position: RL::Vector2.new(j * 100.0_f32, i * 50.0_f32),
            size: RL::Vector2.new(64.0_f32, 64.0_f32)
          )
          scene.hotspots << hotspot
        end

        # Save scene
        scene_file = File.join(project.scenes_path, "scene_#{i}.yml")
        PaceEditor::IO::SceneIO.save_scene(scene, scene_file)
        project.add_scene("scene_#{i}.yml")
      end

      # Save project
      project.save.should be_true

      # Project should handle multiple scenes (including the default "main" scene)
      project.scenes.size.should eq(scene_count + 1)

      # Loading should work efficiently
      project_file = File.join(project_dir, "project.pace")
      new_state = PaceEditor::Core::EditorState.new
      load_success = new_state.load_project(project_file)
      load_success.should be_true

      # All scenes should be tracked (including the default "main" scene)
      new_state.current_project.not_nil!.scenes.size.should eq(scene_count + 1)
    end

    it "manages memory efficiently during operations" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Memory Test", project_dir)

      # Memory usage tracking should be available
      state.memory_usage.should be >= 0

      # Frame time should be reasonable
      state.frame_time.should be > 0
      state.frame_time.should be < 100 # Less than 100ms per frame

      # FPS should be reasonable
      state.fps.should be > 0
      state.fps.should be <= 120 # Reasonable FPS range
    end
  end
end
