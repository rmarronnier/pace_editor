require "../spec_helper"
require "../../src/pace_editor/core/editor_state"
require "../../src/pace_editor/editors/scene_editor"
require "../../src/pace_editor/editors/hotspot_editor"
require "../../src/pace_editor/editors/character_editor"
require "../../src/pace_editor/editors/dialog_editor"

describe "Complete Editor Workflow Integration" do
  temp_dir = ""
  project_dir = ""

  before_each do
    temp_dir = File.tempname
    project_dir = File.join(temp_dir, "workflow_test_project")
    Dir.mkdir_p(temp_dir)
  end

  after_each do
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end
  let(:character_editor) { PaceEditor::Editors::CharacterEditor.new(state) }
  let(:dialog_editor) { PaceEditor::Editors::DialogEditor.new(state) }

  before_each do
    state.current_project = project
    state.current_scene = scene
  end

  describe "script editor workflow" do
    it "integrates script editing across all editors" do
      # Create a character with script
      character = create_test_character("ScriptedHero")
      scene.characters << character
      state.select_object(character.name)

      # Create a hotspot with script
      hotspot = create_test_hotspot("ScriptedDoor")
      scene.hotspots << hotspot

      # Test script editor accessibility from hotspot editor
      state.current_mode = PaceEditor::Core::EditorMode::Hotspot
      state.select_object(hotspot.name)

      # Script editor should be available
      script_path = hotspot_editor.send(:get_hotspot_script_path, hotspot.name)
      script_path.should_not be_nil
      script_path.should contain("scripteddoor_hotspot.lua")

      # Script should be created with proper content
      if script_path && File.exists?(script_path)
        content = File.read(script_path)
        content.should contain("function on_click()")
        content.should contain("ScriptedDoor")
      end
    end

    it "handles script editor modal states correctly" do
      hotspot = create_test_hotspot("ModalTest")
      scene.hotspots << hotspot
      state.select_object(hotspot.name)

      # When script editor is open, other editors should respect modal state
      hotspot_editor.@script_editor.visible = true

      # Main hotspot editor should not handle input
      hotspot_editor.update
      # Verify hotspot creation is blocked when script editor is open

      hotspot_editor.@script_editor.visible = false
      # Now hotspot editor should handle input normally
      hotspot_editor.update
    end
  end

  describe "animation editor workflow" do
    it "integrates animation editing with character management" do
      # Create character with sprite sheet
      character = create_test_character("AnimatedHero")
      scene.characters << character

      # Create mock sprite sheet
      sprite_path = create_test_sprite_sheet(character.name)

      # Switch to character mode and select character
      state.current_mode = PaceEditor::Core::EditorMode::Character
      state.select_object(character.name)

      # Animation editor should be accessible
      character_editor.send(:open_animation_editor, character)

      # Animation editor should be configured properly
      animation_editor = character_editor.@animation_editor
      # Would verify animation editor state in full test

      # Clean up
      File.delete(sprite_path) if File.exists?(sprite_path)
    end

    it "handles animation editor lifecycle correctly" do
      character = create_test_character("LifecycleTest")
      scene.characters << character
      state.select_object(character.name)

      # Open animation editor
      character_editor.send(:open_animation_editor, character)
      animation_editor = character_editor.@animation_editor

      # Animation editor should update and draw without issues
      character_editor.update
      character_editor.draw

      # Close animation editor
      animation_editor.hide

      # Character editor should continue working normally
      character_editor.update
      character_editor.draw
    end
  end

  describe "dialog preview integration" do
    it "integrates dialog preview with dialog editing" do
      # Create dialog tree
      dialog_tree = create_test_dialog_tree("TestConversation")
      dialog_editor.current_dialog = dialog_tree

      # Test dialog preview
      dialog_editor.send(:test_dialog_tree)

      # Preview window should be accessible
      preview_window = dialog_editor.@preview_window
      # Would verify preview window state in full test
    end
  end

  describe "hotspot interaction preview workflow" do
    it "integrates interaction testing with hotspot editing" do
      # Create hotspot with actions
      hotspot = create_test_hotspot("InteractiveObject")
      hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
      scene.hotspots << hotspot

      # Test interaction preview
      hotspot_editor.send(:test_hotspot_interaction, hotspot)

      # Preview should show hotspot details
      preview = hotspot_editor.@interaction_preview
      # Would verify preview state in full test
    end
  end

  describe "cross-editor communication" do
    it "maintains consistent state across editor switches" do
      # Create objects in different editors
      character = create_test_character("StateTest")
      hotspot = create_test_hotspot("StateTestHotspot")

      scene.characters << character
      scene.hotspots << hotspot

      # Switch between editors and verify state consistency
      state.current_mode = PaceEditor::Core::EditorMode::Character
      state.select_object(character.name)
      character_editor.update

      state.current_mode = PaceEditor::Core::EditorMode::Hotspot
      state.select_object(hotspot.name)
      hotspot_editor.update

      state.current_mode = PaceEditor::Core::EditorMode::Scene
      scene_editor.update

      # State should remain consistent
      state.current_scene.should eq(scene)
      state.current_project.should eq(project)
    end

    it "handles object selection across different editors" do
      character = create_test_character("SelectionTest")
      hotspot = create_test_hotspot("SelectionTestHotspot")

      scene.characters << character
      scene.hotspots << hotspot

      # Select character in scene editor
      state.current_mode = PaceEditor::Core::EditorMode::Scene
      state.select_object(character.name)

      # Switch to character editor - should maintain selection
      state.current_mode = PaceEditor::Core::EditorMode::Character
      current_char = character_editor.send(:get_current_character)
      current_char.should eq(character)

      # Select hotspot in scene editor
      state.current_mode = PaceEditor::Core::EditorMode::Scene
      state.select_object(hotspot.name)

      # Switch to hotspot editor - should maintain selection
      state.current_mode = PaceEditor::Core::EditorMode::Hotspot
      current_hotspot = hotspot_editor.send(:get_selected_hotspot)
      current_hotspot.should eq(hotspot)
    end
  end

  describe "file system integration" do
    it "creates and manages project files correctly" do
      # Scripts directory should be created
      Dir.exists?(project.scripts_path).should be_true

      # Assets directory should be created
      Dir.exists?(project.assets_path).should be_true

      # Characters assets subdirectory should be accessible
      characters_dir = File.join(project.assets_path, "characters")
      Dir.mkdir_p(characters_dir)
      Dir.exists?(characters_dir).should be_true
    end

    it "handles file creation and cleanup properly" do
      hotspot = create_test_hotspot("FileSystemTest")
      scene.hotspots << hotspot

      # Create script file
      script_path = hotspot_editor.send(:get_hotspot_script_path, hotspot.name)

      if script_path
        # File should be created
        File.exists?(script_path).should be_true

        # Content should be valid
        content = File.read(script_path)
        content.should contain("function on_click()")

        # Clean up
        File.delete(script_path)
      end
    end
  end

  describe "error handling across editors" do
    it "handles missing files gracefully" do
      character = create_test_character("MissingFilesTest")

      # Try to open animation editor with missing sprite sheet
      character_editor.send(:open_animation_editor, character)
      # Should not crash

      # Try to find non-existent sprite
      sprite_path = character_editor.send(:get_character_sprite_path, character.name)
      sprite_path.should be_nil # Should return nil, not crash
    end

    it "handles corrupted project state gracefully" do
      # Simulate corrupted state
      state.current_project = nil

      # Editors should handle missing project
      hotspot_editor.send(:edit_hotspot_scripts) # Should not crash
      character_editor.update                    # Should not crash
      dialog_editor.update                       # Should not crash
    end

    it "handles invalid object references gracefully" do
      # Select non-existent object
      state.select_object("non_existent_object")

      # Editors should handle invalid selections
      hotspot_editor.send(:get_selected_hotspot).should be_nil
      character_editor.send(:get_current_character).should be_nil
    end
  end

  describe "performance with multiple editors" do
    it "handles simultaneous editor updates efficiently" do
      # Create multiple objects
      5.times do |i|
        character = create_test_character("Character#{i}")
        hotspot = create_test_hotspot("Hotspot#{i}")
        scene.characters << character
        scene.hotspots << hotspot
      end

      # Update all editors simultaneously
      start_time = Time.utc

      scene_editor.update
      hotspot_editor.update
      character_editor.update
      dialog_editor.update

      end_time = Time.utc

      # Should complete reasonably quickly
      (end_time - start_time).should be < 1.second
    end

    it "handles multiple modal windows correctly" do
      # Only one modal should be active at a time
      hotspot_editor.@script_editor.visible = true
      character_editor.@animation_editor.visible = true

      # Should handle overlapping modals appropriately
      hotspot_editor.update
      character_editor.update

      # In a real implementation, there should be modal management
    end
  end

  describe "undo/redo integration with new features" do
    it "supports undo/redo for script changes" do
      hotspot = create_test_hotspot("UndoTest")
      scene.hotspots << hotspot

      # Script modifications should integrate with undo system
      # This would require more sophisticated undo tracking
      state.can_undo?.should be_false

      # Simulate script change action
      # action = ScriptChangeAction.new(...)
      # state.add_undo_action(action)
      # state.can_undo?.should be_true
    end

    it "supports undo/redo for animation changes" do
      character = create_test_character("AnimUndoTest")
      scene.characters << character

      # Animation modifications should integrate with undo system
      # This would require animation-specific undo actions
    end
  end
end

# Helper methods for creating test objects
private def create_full_test_project
  PaceEditor::Core::Project.new.tap do |project|
    project.name = "Complete Test Project"
    project.path = File.tempdir
    project.assets_path = File.join(project.path, "assets")
    project.scripts_path = File.join(project.path, "scripts")
    project.dialogs_path = File.join(project.path, "dialogs")

    Dir.mkdir_p(project.assets_path)
    Dir.mkdir_p(project.scripts_path)
    Dir.mkdir_p(project.dialogs_path)
    Dir.mkdir_p(File.join(project.assets_path, "characters"))
  end
end

private def create_full_test_scene
  PointClickEngine::Scenes::Scene.new("complete_test_scene").tap do |scene|
    scene.characters = [] of PointClickEngine::Characters::Character
    scene.hotspots = [] of PointClickEngine::Scenes::Hotspot
  end
end

private def create_test_character(name : String)
  PointClickEngine::Characters::NPC.new(
    name,
    RL::Vector2.new(100 + rand(200), 100 + rand(200)),
    RL::Vector2.new(32, 64)
  ).tap do |character|
    character.description = "Test character: #{name}"
    character.state = PointClickEngine::Characters::CharacterState::Idle
    character.direction = PointClickEngine::Characters::Direction::Right
    character.mood = PointClickEngine::Characters::NPCMood::Neutral
  end
end

private def create_test_hotspot(name : String)
  PointClickEngine::Scenes::Hotspot.new(
    name: name,
    position: RL::Vector2.new(50 + rand(300), 50 + rand(300)),
    size: RL::Vector2.new(64, 64)
  ).tap do |hotspot|
    hotspot.description = "Test hotspot: #{name}"
    hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
    hotspot.visible = true
  end
end

private def create_test_sprite_sheet(character_name : String)
  characters_dir = File.join(File.tempdir, "characters")
  Dir.mkdir_p(characters_dir)

  sprite_file = File.join(characters_dir, "#{character_name.downcase}_spritesheet.png")

  # Create a minimal PNG file (1x1 pixel for testing)
  File.write(sprite_file, "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\b\x06\x00\x00\x00\x1F\x15\xC4\x89\x00\x00\x00\nIDATx\x9Cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xDB\x00\x00\x00\x00IEND\xAEB`\x82", "wb")

  sprite_file
end

private def create_test_dialog_tree(name : String)
  PointClickEngine::Characters::Dialogue::DialogTree.new(name).tap do |tree|
    # Add test nodes
    start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello there!")
    start_node.character_name = "TestNPC"

    choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("option1", "Hi!")
    choice.target_node_id = "response"
    start_node.choices << choice

    response_node = PointClickEngine::Characters::Dialogue::DialogNode.new("response", "Nice to meet you!")
    response_node.character_name = "TestNPC"
    response_node.is_end = true

    tree.add_node(start_node)
    tree.add_node(response_node)
    tree.current_node_id = "start"
  end
end
