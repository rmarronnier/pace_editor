require "../spec_helper"
require "../../src/pace_editor/ui/animation_editor"

describe PaceEditor::UI::AnimationEditor do
  state = PaceEditor::Core::EditorState.new

  describe "#initialize" do
    it "creates animation editor with default state" do
      editor = PaceEditor::UI::AnimationEditor.new(state)
      editor.visible.should be_false
    end
  end

  describe "#show and #hide" do
    it "toggles visibility" do
      editor = PaceEditor::UI::AnimationEditor.new(state)

      editor.show("test_character")
      editor.visible.should be_true

      editor.hide
      editor.visible.should be_false
    end
  end

  describe "animation data" do
    it "loads animation data for character" do
      # Create test project structure
      temp_base = File.tempname("anim_project")
      temp_dir = "#{temp_base}_#{Time.utc.to_unix_ms}"
      project = PaceEditor::Core::Project.new("test", temp_dir)
      state.current_project = project

      editor = PaceEditor::UI::AnimationEditor.new(state)
      editor.show("test_character")

      # Animation data should be loaded or created
      editor.visible.should be_true

      FileUtils.rm_rf(temp_dir)
    end
  end

  describe "with sprite sheet" do
    it "can show editor with sprite sheet path" do
      # Create test project structure
      temp_base = File.tempname("anim_project")
      temp_dir = "#{temp_base}_#{Time.utc.to_unix_ms}"
      project = PaceEditor::Core::Project.new("test", temp_dir)
      state.current_project = project

      # Create a dummy sprite sheet
      sprite_path = File.join(project.characters_path, "test_sprite.png")
      File.write(sprite_path, "dummy")

      editor = PaceEditor::UI::AnimationEditor.new(state)
      editor.show("test_character", sprite_path)

      # Should be visible
      editor.visible.should be_true

      FileUtils.rm_rf(temp_dir)
    end
  end
end
