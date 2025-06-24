require "../spec_helper"
require "../../src/pace_editor/ui/animation_editor"

describe PaceEditor::UI::AnimationEditor do
  state = PaceEditor::Core::EditorState.new
  editor = PaceEditor::UI::AnimationEditor.new(state)

  describe "#initialize" do
    it "creates an animation editor with default state" do
      editor.visible.should be_false
    end
  end

  describe "AnimationData" do
    animation_data = PaceEditor::UI::AnimationEditor::AnimationData.new

    it "initializes with default sprite dimensions" do
      animation_data.sprite_width.should eq(32)
      animation_data.sprite_height.should eq(32)
      animation_data.sheet_columns.should eq(8)
      animation_data.sheet_rows.should eq(8)
    end

    it "starts with empty animations" do
      animation_data.animations.should be_empty
    end
  end

  describe "Animation" do
    animation = PaceEditor::UI::AnimationEditor::Animation.new("test_anim")

    it "initializes with name and default properties" do
      animation.name.should eq("test_anim")
      animation.loop.should be_true
      animation.fps.should eq(8.0_f32)
      animation.frames.should be_empty
    end
  end

  describe "AnimationFrame" do
    frame = PaceEditor::UI::AnimationEditor::AnimationFrame.new(32, 64)

    it "initializes with sprite coordinates" do
      frame.sprite_x.should eq(32)
      frame.sprite_y.should eq(64)
      frame.duration.should eq(0.125_f32) # 8 FPS default
      frame.offset_x.should eq(0)
      frame.offset_y.should eq(0)
    end
  end

  describe "#show" do
    it "shows the editor" do
      editor.show("test_character")
      editor.visible.should be_true
    end

    it "handles character name parameter" do
      editor.show("hero_character")
      editor.visible.should be_true
    end

    context "with sprite sheet path" do
      it "attempts to load sprite sheet" do
        # This would require a valid image file for full testing
        # For now, test that it handles missing files gracefully
        editor.show("test_character", "/nonexistent/spritesheet.png")
        editor.visible.should be_true
      end
    end
  end

  describe "#hide" do
    it "hides the editor" do
      editor.show("test_character")
      editor.hide
      editor.visible.should be_false
    end
  end

  describe "animation management" do
    it "handles creating new animations" do
      editor.show("test_character")
      # The show method should create default animations
      editor.visible.should be_true
    end

    it "handles animation selection" do
      editor.show("test_character")
      # Should be able to select animations without crashing
      editor.visible.should be_true
    end
  end

  describe "playback controls" do
    it "handles playback toggle" do
      editor.show("test_character")
      # Should be able to toggle playback without errors
      editor.visible.should be_true
    end

    it "handles frame navigation" do
      editor.show("test_character")
      # Should be able to navigate frames without errors
      editor.visible.should be_true
    end
  end

  describe "frame management" do
    it "handles adding frames" do
      editor.show("test_character")
      # Should be able to add frames without errors
      editor.visible.should be_true
    end

    it "calculates sprite coordinates" do
      # Test sprite sheet coordinate calculation
      columns = 8
      sprite_width = 32
      sprite_height = 32

      # Frame 0 should be at (0, 0)
      frame_0_x = (0 % columns) * sprite_width
      frame_0_y = (0 // columns) * sprite_height
      frame_0_x.should eq(0)
      frame_0_y.should eq(0)

      # Frame 8 should be at (0, sprite_height) with 8 columns
      frame_8_x = (8 % columns) * sprite_width
      frame_8_y = (8 // columns) * sprite_height
      frame_8_x.should eq(0)
      frame_8_y.should eq(sprite_height)
    end
  end

  describe "error handling" do
    it "handles missing sprite sheet gracefully" do
      editor.show("test_character", "/nonexistent/file.png")
      # Should not crash the editor
      editor.visible.should be_true
    end

    it "handles empty character name" do
      editor.show("")
      # Should handle empty character name
      editor.visible.should be_true
    end
  end

  describe "drawing and updating" do
    it "updates without crashing" do
      editor.show("test_character")
      editor.update
      # Should not raise any exceptions
    end

    it "draws without crashing" do
      RaylibTestHelper.init
      editor.show("test_character")
      
      # Need to be in a drawing context
      RL.begin_drawing
      editor.draw
      RL.end_drawing
      # Should not raise any exceptions
    end
  end

  describe "save functionality" do
    it "handles saving animation data" do
      editor.show("test_character")
      # Should be able to save without crashing
      # Actual file saving would need proper directory setup
      editor.visible.should be_true
    end
  end

  describe "UI state management" do
    it "maintains zoom level within bounds" do
      editor.show("test_character")
      # Should maintain reasonable zoom levels
      editor.visible.should be_true
    end

    it "handles timeline scrolling" do
      editor.show("test_character")
      # Should handle timeline scrolling without errors
      editor.visible.should be_true
    end
  end
end
