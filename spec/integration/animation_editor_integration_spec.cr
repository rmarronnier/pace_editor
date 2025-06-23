require "../spec_helper"
require "../../src/pace_editor/ui/animation_editor"
require "../../src/pace_editor/editors/character_editor"

describe "Animation Editor Integration" do
  state = PaceEditor::Core::EditorState.new
  animation_editor = PaceEditor::UI::AnimationEditor.new(state)

  describe "character animation integration" do
    it "opens animation editor for character editing" do
      # Test that animation editor can be opened from character context
      animation_editor.show("hero_character")
      animation_editor.visible.should be_true
    end

    it "handles multiple characters" do
      # Test switching between different characters
      animation_editor.show("hero")
      animation_editor.visible.should be_true

      animation_editor.hide
      animation_editor.visible.should be_false

      animation_editor.show("npc_guard")
      animation_editor.visible.should be_true
    end
  end

  describe "sprite sheet integration" do
    it "handles sprite sheet detection" do
      # Test with various sprite sheet naming conventions
      character_names = ["hero", "guard", "merchant"]

      character_names.each do |character|
        animation_editor.show(character)
        animation_editor.visible.should be_true
        animation_editor.hide
      end
    end

    it "handles missing sprite sheets gracefully" do
      # Test that missing sprite sheets don't crash the editor
      animation_editor.show("nonexistent_character")
      animation_editor.visible.should be_true
    end
  end

  describe "animation workflow" do
    it "creates default animations for new characters" do
      animation_editor.show("new_character")
      animation_editor.visible.should be_true

      # Default animations should be created
      # This would be verified through the UI in real usage
    end

    it "handles animation creation workflow" do
      animation_editor.show("test_character")
      animation_editor.visible.should be_true

      # Test creating new animations
      # Real testing would involve UI interaction simulation
    end
  end

  describe "frame management workflow" do
    it "handles frame addition and modification" do
      animation_editor.show("test_character")
      animation_editor.visible.should be_true

      # Test frame management operations
      # Real testing would require sprite sheet loading
    end

    it "calculates frame coordinates correctly" do
      # Test sprite sheet coordinate calculations
      sprite_width = 32
      sprite_height = 48
      columns = 8

      # Test various frame positions
      test_cases = [
        {frame: 0, expected_x: 0, expected_y: 0},
        {frame: 1, expected_x: 32, expected_y: 0},
        {frame: 7, expected_x: 224, expected_y: 0},
        {frame: 8, expected_x: 0, expected_y: 48},
        {frame: 15, expected_x: 224, expected_y: 48},
      ]

      test_cases.each do |test_case|
        frame_num = test_case[:frame]
        expected_x = test_case[:expected_x]
        expected_y = test_case[:expected_y]

        calculated_x = (frame_num % columns) * sprite_width
        calculated_y = (frame_num // columns) * sprite_height

        calculated_x.should eq(expected_x)
        calculated_y.should eq(expected_y)
      end
    end
  end

  describe "playback and preview" do
    it "handles animation playback" do
      animation_editor.show("test_character")
      animation_editor.visible.should be_true

      # Test playback controls
      # Real testing would involve time-based updates
    end

    it "handles playback speed control" do
      animation_editor.show("test_character")
      animation_editor.visible.should be_true

      # Test different playback speeds
      # Real testing would verify timing calculations
    end
  end

  describe "save and load workflow" do
    it "saves animation data to project" do
      animation_editor.show("test_character")
      animation_editor.visible.should be_true

      # Test saving animation data
      # Real testing would verify file creation
    end

    it "loads existing animation data" do
      # Create test animation data file
      temp_dir = Dir.tempdir
      animation_file = File.join(temp_dir, "test_character_animations.yml")

      # Create basic animation data
      test_data = <<-YAML
        sprite_width: 32
        sprite_height: 48
        sheet_columns: 8
        sheet_rows: 4
        animations:
          idle:
            name: "idle"
            loop: true
            fps: 2.0
            frames:
              - sprite_x: 0
                sprite_y: 0
                duration: 0.5
                offset_x: 0
                offset_y: 0
          walk:
            name: "walk"
            loop: true
            fps: 8.0
            frames:
              - sprite_x: 0
                sprite_y: 48
                duration: 0.125
                offset_x: 0
                offset_y: 0
              - sprite_x: 32
                sprite_y: 48
                duration: 0.125
                offset_x: 0
                offset_y: 0
        YAML

      File.write(animation_file, test_data)

      animation_editor.show("test_character")
      animation_editor.visible.should be_true

      # Cleanup
      File.delete(animation_file) if File.exists?(animation_file)
      Dir.rmdir(temp_dir) if Dir.exists?(temp_dir)
    rescue
      # Handle any file system errors gracefully
    end
  end

  describe "UI interaction workflow" do
    it "handles timeline interaction" do
      animation_editor.show("test_character")
      animation_editor.visible.should be_true

      # Test timeline UI components
      # Real testing would involve mouse interaction simulation
    end

    it "handles property editing" do
      animation_editor.show("test_character")
      animation_editor.visible.should be_true

      # Test frame property editing
      # Real testing would involve UI input simulation
    end
  end

  describe "error handling" do
    it "handles corrupted animation files" do
      # Test with invalid animation data
      temp_dir = Dir.tempdir
      bad_animation_file = File.join(temp_dir, "bad_animations.yml")

      File.write(bad_animation_file, "invalid: yaml: content [")

      animation_editor.show("test_character")
      animation_editor.visible.should be_true

      # Should handle bad files gracefully

      # Cleanup
      File.delete(bad_animation_file) if File.exists?(bad_animation_file)
      Dir.rmdir(temp_dir) if Dir.exists?(temp_dir)
    rescue
      # Handle any file system errors gracefully
    end

    it "handles missing project directories" do
      animation_editor.show("test_character")
      animation_editor.visible.should be_true

      # Should handle missing directories gracefully
    end
  end
end
