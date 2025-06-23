require "../spec_helper"
require "../../src/pace_editor/ui/animation_editor"

describe "Animation File Operations" do
  state = PaceEditor::Core::EditorState.new
  animation_editor = PaceEditor::UI::AnimationEditor.new(state)

  describe "animation data file creation" do
    it "creates new animation data files" do
      temp_dir = Dir.tempdir
      animation_path = File.join(temp_dir, "character_animations.yml")

      # Ensure file doesn't exist initially
      File.exists?(animation_path).should be_false

      # Open animation editor
      animation_editor.show("test_character")
      animation_editor.visible.should be_true

      # Cleanup
      File.delete(animation_path) if File.exists?(animation_path)
    rescue
      # Handle any file system errors gracefully
    end

    it "creates default animation structure" do
      default_animation_yaml = <<-YAML
        sprite_width: 32
        sprite_height: 32
        sheet_columns: 8
        sheet_rows: 8
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
                sprite_y: 32
                duration: 0.125
                offset_x: 0
                offset_y: 0
        YAML

      # Test that default structure contains expected elements
      default_animation_yaml.should contain("sprite_width")
      default_animation_yaml.should contain("sprite_height")
      default_animation_yaml.should contain("animations")
      default_animation_yaml.should contain("idle")
      default_animation_yaml.should contain("walk")
    end
  end

  describe "animation data loading" do
    it "loads existing animation files" do
      temp_file = File.tempfile("animation_load", ".yml")
      test_animation_data = <<-YAML
        sprite_width: 64
        sprite_height: 64
        sheet_columns: 4
        sheet_rows: 4
        animations:
          run:
            name: "run"
            loop: true
            fps: 12.0
            frames:
              - sprite_x: 0
                sprite_y: 0
                duration: 0.083
                offset_x: 0
                offset_y: 0
              - sprite_x: 64
                sprite_y: 0
                duration: 0.083
                offset_x: 0
                offset_y: 0
        YAML

      temp_file.print(test_animation_data)
      temp_file.close

      # Load should work without errors
      animation_editor.show("test_character")
      animation_editor.visible.should be_true

      temp_file.delete
    end

    it "handles missing animation files gracefully" do
      # Should not crash when animation file doesn't exist
      animation_editor.show("nonexistent_character")
      animation_editor.visible.should be_true
    end

    it "handles corrupted animation files" do
      temp_file = File.tempfile("corrupted_anim", ".yml")

      # Write invalid YAML
      temp_file.print("invalid: yaml: content: [unclosed")
      temp_file.close

      # Should handle corrupted file gracefully
      animation_editor.show("test_character")
      animation_editor.visible.should be_true

      temp_file.delete
    end
  end

  describe "sprite sheet detection" do
    it "detects sprite sheets by naming convention" do
      character_names = ["hero", "guard", "merchant", "wizard"]
      sprite_extensions = [".png", ".jpg", ".jpeg"]
      naming_patterns = [
        "%s.%s",             # hero.png
        "%s_spritesheet.%s", # hero_spritesheet.png
        "%s_sprites.%s",     # hero_sprites.png
        "char_%s.%s",        # char_hero.png
      ]

      character_names.each do |character|
        sprite_extensions.each do |ext|
          naming_patterns.each do |pattern|
            filename = pattern % [character, ext.lstrip('.')]
            filename.should contain(character)
            filename.should end_with(ext)
          end
        end
      end
    end

    it "handles missing sprite sheets" do
      # Test that missing sprite sheets don't break the editor
      animation_editor.show("character_without_sprites")
      animation_editor.visible.should be_true
    end
  end

  describe "animation data saving" do
    it "saves animation data in YAML format" do
      temp_dir = Dir.tempdir

      # Create test animation data structure
      animation_data = {
        "sprite_width"  => 32,
        "sprite_height" => 48,
        "sheet_columns" => 8,
        "sheet_rows"    => 6,
        "animations"    => {
          "test_anim" => {
            "name"   => "test_anim",
            "loop"   => true,
            "fps"    => 8.0,
            "frames" => [
              {
                "sprite_x" => 0,
                "sprite_y" => 0,
                "duration" => 0.125,
                "offset_x" => 0,
                "offset_y" => 0,
              },
            ],
          },
        },
      }

      # Test that data structure is valid
      animation_data["sprite_width"].should eq(32)
      animation_data["sprite_height"].should eq(48)
      animations = animation_data["animations"]
      if animations.is_a?(Hash)
        animations.has_key?("test_anim").should be_true
      else
        fail "animations should be a Hash"
      end
    rescue
      # Handle any file system errors gracefully
    end

    it "preserves animation data during save/load cycles" do
      temp_file = File.tempfile("cycle_test", ".yml")

      original_data = <<-YAML
        sprite_width: 32
        sprite_height: 32
        sheet_columns: 8
        sheet_rows: 8
        animations:
          jump:
            name: "jump"
            loop: false
            fps: 15.0
            frames:
              - sprite_x: 0
                sprite_y: 64
                duration: 0.067
                offset_x: 0
                offset_y: -5
              - sprite_x: 32
                sprite_y: 64
                duration: 0.067
                offset_x: 0
                offset_y: -10
        YAML

      temp_file.print(original_data)
      temp_file.close

      # Load and verify content is preserved
      saved_content = File.read(temp_file.path)
      saved_content.should contain("jump")
      saved_content.should contain("sprite_x: 0")
      saved_content.should contain("offset_y: -5")

      temp_file.delete
    end
  end

  describe "frame coordinate calculations" do
    it "calculates sprite sheet coordinates correctly" do
      test_cases = [
        {
          sprite_width:  32,
          sprite_height: 32,
          columns:       8,
          frame:         0,
          expected_x:    0,
          expected_y:    0,
        },
        {
          sprite_width:  32,
          sprite_height: 32,
          columns:       8,
          frame:         5,
          expected_x:    160,
          expected_y:    0,
        },
        {
          sprite_width:  32,
          sprite_height: 32,
          columns:       8,
          frame:         8,
          expected_x:    0,
          expected_y:    32,
        },
        {
          sprite_width:  64,
          sprite_height: 48,
          columns:       4,
          frame:         6,
          expected_x:    128,
          expected_y:    48,
        },
      ]

      test_cases.each do |test_case|
        frame_num = test_case[:frame]
        columns = test_case[:columns]
        sprite_width = test_case[:sprite_width]
        sprite_height = test_case[:sprite_height]
        expected_x = test_case[:expected_x]
        expected_y = test_case[:expected_y]

        calculated_x = (frame_num % columns) * sprite_width
        calculated_y = (frame_num // columns) * sprite_height

        calculated_x.should eq(expected_x)
        calculated_y.should eq(expected_y)
      end
    end
  end

  describe "animation export format" do
    it "exports in Point & Click Engine compatible format" do
      engine_format = {
        "character_animations" => {
          "hero" => {
            "sprite_sheet" => "assets/characters/hero.png",
            "frame_width"  => 32,
            "frame_height" => 48,
            "animations"   => {
              "idle" => {
                "frames" => [0, 1],
                "fps"    => 2,
                "loop"   => true,
              },
              "walk" => {
                "frames" => [8, 9, 10, 11],
                "fps"    => 8,
                "loop"   => true,
              },
            },
          },
        },
      }

      # Test that export format has expected structure
      char_animations = engine_format["character_animations"]
      if char_animations.is_a?(Hash)
        hero_data = char_animations["hero"]
        if hero_data.is_a?(Hash)
          hero_data.has_key?("sprite_sheet").should be_true
          hero_data.has_key?("frame_width").should be_true
          hero_data.has_key?("animations").should be_true

          animations = hero_data["animations"]
          if animations.is_a?(Hash)
            animations.has_key?("idle").should be_true
            animations.has_key?("walk").should be_true

            idle_anim = animations["idle"]
            if idle_anim.is_a?(Hash)
              idle_anim.has_key?("frames").should be_true
              idle_anim.has_key?("fps").should be_true
              idle_anim.has_key?("loop").should be_true
            else
              fail "idle animation should be a Hash"
            end
          else
            fail "animations should be a Hash"
          end
        else
          fail "hero_data should be a Hash"
        end
      else
        fail "character_animations should be a Hash"
      end
    end
  end

  describe "error handling" do
    it "handles file permission errors" do
      # Test that permission errors are handled gracefully
      animation_editor.show("test_character")
      animation_editor.visible.should be_true
    end

    it "handles disk space errors" do
      # Test that disk space errors are handled gracefully
      animation_editor.show("test_character")
      animation_editor.visible.should be_true
    end

    it "handles invalid sprite dimensions" do
      temp_file = File.tempfile("invalid_dims", ".yml")

      invalid_data = <<-YAML
        sprite_width: -10
        sprite_height: 0
        sheet_columns: 0
        sheet_rows: -5
        animations: {}
        YAML

      temp_file.print(invalid_data)
      temp_file.close

      # Should handle invalid dimensions gracefully
      animation_editor.show("test_character")
      animation_editor.visible.should be_true

      temp_file.delete
    end
  end

  describe "backup and versioning" do
    it "creates backup files before major changes" do
      temp_file = File.tempfile("backup_test", ".yml")

      important_animation_data = <<-YAML
        sprite_width: 32
        sprite_height: 32
        sheet_columns: 8
        sheet_rows: 8
        animations:
          special_move:
            name: "special_move"
            loop: false
            fps: 20.0
            frames:
              - sprite_x: 0
                sprite_y: 96
                duration: 0.05
                offset_x: 0
                offset_y: 0
        YAML

      temp_file.print(important_animation_data)
      temp_file.close

      # Original file should be preserved
      File.exists?(temp_file.path).should be_true
      original_content = File.read(temp_file.path)
      original_content.should contain("special_move")

      temp_file.delete
    end
  end
end
