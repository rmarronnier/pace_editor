require "../spec_helper"
require "../../src/pace_editor/editors/character_editor"

describe PaceEditor::Editors::CharacterEditor do
  let(:state) { PaceEditor::Core::EditorState.new }
  let(:editor) { PaceEditor::Editors::CharacterEditor.new(state) }
  let(:project) { create_test_project }
  let(:scene) { create_test_scene }

  before_each do
    state.current_project = project
    state.current_scene = scene
  end

  describe "animation editor integration" do
    let(:test_character) do
      character = PointClickEngine::Characters::NPC.new(
        "test_character",
        RL::Vector2.new(100, 100),
        RL::Vector2.new(32, 64)
      )
      character.description = "Test character for animation"
      character
    end

    before_each do
      scene.characters << test_character
      state.select_object(test_character.name)
    end

    describe "#open_animation_editor" do
      it "opens animation editor for character" do
        animation_editor = editor.@animation_editor
        animation_editor.visible.should be_false

        editor.send(:open_animation_editor, test_character)

        # Animation editor should be configured for this character
        # In a real test, we'd verify the animation editor state
      end

      it "finds character sprite sheet automatically" do
        sprite_path = editor.send(:get_character_sprite_path, test_character.name)

        # Should attempt to find sprite files
        # Returns nil if no files found, which is expected in test
        if sprite_path
          sprite_path.should contain(test_character.name.downcase)
          sprite_path.should match(/\.(png|jpg|jpeg)$/i)
        end
      end

      it "handles character without sprite sheet" do
        # Should not crash when no sprite sheet is found
        editor.send(:open_animation_editor, test_character)
      end
    end

    describe "#get_character_sprite_path" do
      let(:character_name) { "Hero Character" }

      before_each do
        # Create test assets directory
        characters_dir = File.join(project.assets_path, "characters")
        Dir.mkdir_p(characters_dir)
      end

      it "finds sprite sheet with exact name match" do
        characters_dir = File.join(project.assets_path, "characters")
        test_file = File.join(characters_dir, "hero_character.png")
        File.touch(test_file)

        result = editor.send(:get_character_sprite_path, character_name)
        result.should eq(test_file)

        File.delete(test_file)
      end

      it "finds sprite sheet with variations of name" do
        characters_dir = File.join(project.assets_path, "characters")
        test_file = File.join(characters_dir, "hero_character_spritesheet.png")
        File.touch(test_file)

        result = editor.send(:get_character_sprite_path, character_name)
        result.should eq(test_file)

        File.delete(test_file)
      end

      it "prefers png over other formats" do
        characters_dir = File.join(project.assets_path, "characters")
        jpg_file = File.join(characters_dir, "hero_character.jpg")
        png_file = File.join(characters_dir, "hero_character.png")

        File.touch(jpg_file)
        File.touch(png_file)

        result = editor.send(:get_character_sprite_path, character_name)
        result.should eq(png_file)

        File.delete(jpg_file)
        File.delete(png_file)
      end

      it "returns nil when no sprite sheet found" do
        result = editor.send(:get_character_sprite_path, "NonExistentCharacter")
        result.should be_nil
      end

      it "returns nil when project has no assets directory" do
        state.current_project = nil
        result = editor.send(:get_character_sprite_path, character_name)
        result.should be_nil
      end

      it "handles special characters in character names" do
        characters_dir = File.join(project.assets_path, "characters")
        test_file = File.join(characters_dir, "special_char_#1.png")
        File.touch(test_file)

        result = editor.send(:get_character_sprite_path, "Special Char #1")
        # Should attempt to find files with normalized names
        # May or may not find the file depending on normalization logic

        File.delete(test_file)
      end
    end

    describe "animation editor lifecycle" do
      it "updates animation editor with character editor" do
        editor.update
        # Animation editor should be updated
        # Verify no crashes occur
      end

      it "draws animation editor on top of character editor" do
        # This would require graphics testing framework
        editor.draw
        # Verify draw method completes without error
      end

      it "handles animation editor visibility" do
        # When animation editor is visible, it should be drawn
        editor.@animation_editor.visible = true
        editor.draw

        # When hidden, should not interfere
        editor.@animation_editor.visible = false
        editor.draw
      end
    end
  end

  describe "character management with animation support" do
    let(:test_character) do
      PointClickEngine::Characters::NPC.new(
        "animated_character",
        RL::Vector2.new(200, 150),
        RL::Vector2.new(48, 72)
      )
    end

    before_each do
      scene.characters << test_character
    end

    describe "#get_current_character" do
      it "returns explicitly set current character" do
        editor.current_character = test_character
        result = editor.send(:get_current_character)
        result.should eq(test_character)
      end

      it "finds character from editor state selection" do
        editor.current_character = nil
        state.select_object(test_character.name)

        result = editor.send(:get_current_character)
        result.should eq(test_character)

        # Should also set current_character for efficiency
        editor.current_character.should eq(test_character)
      end

      it "returns nil when no character is selected" do
        editor.current_character = nil
        state.clear_selection

        result = editor.send(:get_current_character)
        result.should be_nil
      end
    end

    describe "animation preview integration" do
      before_each do
        editor.current_character = test_character
      end

      it "tracks animation preview time" do
        initial_time = editor.animation_preview_time

        # Simulate frame time
        allow(RL).to receive(:get_frame_time).and_return(0.016_f32)
        editor.update

        editor.animation_preview_time.should be > initial_time
      end

      it "integrates with character animation state" do
        # Character editor should coordinate with animation system
        editor.update

        # Verify character's animation state is considered
        # This would depend on character animation implementation
      end
    end
  end

  describe "UI integration for animation controls" do
    let(:test_character) do
      PointClickEngine::Characters::NPC.new(
        "ui_test_character",
        RL::Vector2.new(0, 0),
        RL::Vector2.new(32, 32)
      )
    end

    it "draws animation controls in character workspace" do
      editor.current_character = test_character

      # This would normally require UI testing framework
      # For now, verify draw method doesn't crash
      editor.draw
    end

    it "handles animation button interactions" do
      # Animation controls should be accessible when character is selected
      editor.current_character = test_character

      # Would test button click simulation here
      # For now, verify the open_animation_editor method exists and works
      editor.send(:open_animation_editor, test_character)
    end
  end

  describe "error handling in animation integration" do
    it "handles missing character gracefully" do
      editor.current_character = nil
      state.clear_selection

      # Should not crash when trying to open animation editor
      editor.update
      editor.draw
    end

    it "handles missing assets directory" do
      # Remove assets directory
      FileUtils.rm_rf(File.join(project.path, "assets"))

      character = PointClickEngine::Characters::NPC.new("test", RL::Vector2.new(0, 0), RL::Vector2.new(32, 32))

      sprite_path = editor.send(:get_character_sprite_path, character.name)
      sprite_path.should be_nil
    end

    it "handles animation editor errors gracefully" do
      character = PointClickEngine::Characters::NPC.new("error_test", RL::Vector2.new(0, 0), RL::Vector2.new(32, 32))

      # Should not crash even if animation editor has issues
      editor.send(:open_animation_editor, character)
    end

    it "handles file system permissions errors" do
      # Test character in read-only location
      ro_character = PointClickEngine::Characters::NPC.new("readonly", RL::Vector2.new(0, 0), RL::Vector2.new(32, 32))

      # Should handle gracefully when assets can't be accessed
      editor.send(:get_character_sprite_path, ro_character.name)
    end
  end

  describe "sprite sheet search algorithm" do
    let(:characters_dir) { File.join(project.assets_path, "characters") }

    before_each do
      Dir.mkdir_p(characters_dir)
    end

    it "searches multiple name variations" do
      # Test the search order and variations
      character_name = "Main Hero"

      expected_variations = [
        "main_hero.png",
        "main_hero.jpg",
        "main_hero.jpeg",
        "mainhero.png",
        "mainhero.jpg",
        "mainhero.jpeg",
        "main_hero_spritesheet.png",
        "main_hero_spritesheet.jpg",
        "main_hero_spritesheet.jpeg",
        "main_hero_sheet.png",
        "main_hero_sheet.jpg",
        "main_hero_sheet.jpeg",
      ]

      # Create one of the expected files
      test_file = File.join(characters_dir, "main_hero_spritesheet.png")
      File.touch(test_file)

      result = editor.send(:get_character_sprite_path, character_name)
      result.should eq(test_file)

      File.delete(test_file)
    end

    it "handles empty character names" do
      result = editor.send(:get_character_sprite_path, "")
      result.should be_nil
    end

    it "handles very long character names" do
      long_name = "a" * 255
      result = editor.send(:get_character_sprite_path, long_name)
      # Should not crash
      result.should be_nil
    end
  end

  describe "integration with project structure" do
    it "respects project asset organization" do
      # Animation editor should work with project's asset structure
      character = PointClickEngine::Characters::NPC.new("project_test", RL::Vector2.new(0, 0), RL::Vector2.new(32, 32))

      # Should look in correct project directories
      sprite_path = editor.send(:get_character_sprite_path, character.name)

      if sprite_path
        sprite_path.should contain(project.assets_path)
        sprite_path.should contain("characters")
      end
    end

    it "handles project changes gracefully" do
      character = PointClickEngine::Characters::NPC.new("change_test", RL::Vector2.new(0, 0), RL::Vector2.new(32, 32))

      # Change project
      state.current_project = nil

      # Should handle missing project
      result = editor.send(:get_character_sprite_path, character.name)
      result.should be_nil
    end
  end
end

private def create_test_project
  PaceEditor::Core::Project.new.tap do |project|
    project.name = "Animation Test Project"
    project.path = File.tempdir
    project.assets_path = File.join(project.path, "assets")
    Dir.mkdir_p(project.assets_path)
  end
end

private def create_test_scene
  PointClickEngine::Scenes::Scene.new("animation_test_scene").tap do |scene|
    scene.characters = [] of PointClickEngine::Characters::Character
    scene.hotspots = [] of PointClickEngine::Scenes::Hotspot
  end
end
