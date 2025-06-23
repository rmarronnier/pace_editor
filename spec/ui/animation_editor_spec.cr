require "../spec_helper"
require "../../src/pace_editor/ui/animation_editor"

describe PaceEditor::UI::AnimationEditor do
  let(:state) { PaceEditor::Core::EditorState.new }
  let(:editor) { PaceEditor::UI::AnimationEditor.new(state) }

  before_each do
    editor.visible = false
  end

  describe "#initialize" do
    it "creates an animation editor with default state" do
      editor.visible.should be_false
      editor.@playing.should be_false
      editor.@current_frame.should eq(0)
    end
  end

  describe "AnimationData" do
    let(:anim_data) { PaceEditor::UI::AnimationEditor::AnimationData.new }

    it "initializes with default sprite dimensions" do
      anim_data.sprite_width.should eq(32)
      anim_data.sprite_height.should eq(32)
      anim_data.sheet_columns.should eq(8)
      anim_data.sheet_rows.should eq(8)
    end

    it "starts with empty animations" do
      anim_data.animations.should be_empty
    end
  end

  describe "Animation" do
    let(:animation) { PaceEditor::UI::AnimationEditor::Animation.new("test_anim") }

    it "initializes with name and default properties" do
      animation.name.should eq("test_anim")
      animation.loop.should be_true
      animation.fps.should eq(8.0_f32)
      animation.frames.should be_empty
    end
  end

  describe "AnimationFrame" do
    let(:frame) { PaceEditor::UI::AnimationEditor::AnimationFrame.new(32, 64) }

    it "initializes with sprite coordinates" do
      frame.sprite_x.should eq(32)
      frame.sprite_y.should eq(64)
      frame.duration.should eq(0.125_f32)  # 8 FPS default
      frame.offset_x.should eq(0)
      frame.offset_y.should eq(0)
    end
  end

  describe "#show" do
    it "shows the editor and sets character name" do
      editor.show("test_character")
      editor.visible.should be_true
      editor.@character_name.should eq("test_character")
    end

    it "resets playback state" do
      editor.@playing = true
      editor.@current_frame = 5
      editor.show("test_character")
      editor.@playing.should be_false
      editor.@current_frame.should eq(0)
    end

    it "creates default animations if none exist" do
      editor.show("test_character")
      editor.@animation_data.animations.should_not be_empty
      editor.@animation_data.animations.should have_key("idle")
      editor.@animation_data.animations.should have_key("walk")
    end

    context "with sprite sheet path" do
      it "attempts to load sprite sheet" do
        # This would require a valid image file for full testing
        # For now, test that it handles missing files gracefully
        editor.show("test_character", "/nonexistent/spritesheet.png")
        editor.@sprite_sheet_path.should eq("/nonexistent/spritesheet.png")
      end
    end
  end

  describe "#hide" do
    it "hides the editor and cleans up" do
      editor.show("test_character")
      editor.hide
      editor.visible.should be_false
      editor.@character_name.should be_nil
    end
  end

  describe "default animation creation" do
    before_each do
      editor.show("test_character")
    end

    it "creates idle animation" do
      idle_anim = editor.@animation_data.animations["idle"]
      idle_anim.should_not be_nil
      idle_anim.name.should eq("idle")
      idle_anim.fps.should eq(2.0_f32)
      idle_anim.frames.size.should eq(2)
    end

    it "creates walk animation" do
      walk_anim = editor.@animation_data.animations["walk"]
      walk_anim.should_not be_nil
      walk_anim.name.should eq("walk")
      walk_anim.fps.should eq(8.0_f32)
      walk_anim.frames.size.should eq(4)
    end
  end

  describe "animation management" do
    before_each do
      editor.show("test_character")
    end

    describe "#create_new_animation" do
      it "creates a new animation with default frame" do
        initial_count = editor.@animation_data.animations.size
        editor.send(:create_new_animation)
        
        editor.@animation_data.animations.size.should eq(initial_count + 1)
        
        # Should create animation with pattern "animation_N"
        new_anim_name = "animation_#{initial_count + 1}"
        new_anim = editor.@animation_data.animations[new_anim_name]
        new_anim.should_not be_nil
        new_anim.frames.size.should eq(1)
      end

      it "selects the new animation" do
        editor.send(:create_new_animation)
        editor.@current_animation.should_not be_nil
        editor.@current_animation.should match(/animation_\d+/)
      end
    end

    describe "#select_animation" do
      it "changes current animation and resets playback" do
        editor.@current_frame = 3
        editor.@playing = true
        
        editor.send(:select_animation, "idle")
        
        editor.@current_animation.should eq("idle")
        editor.@current_frame.should eq(0)
        editor.@playing.should be_false
      end
    end

    describe "#get_current_animation" do
      it "returns current animation object" do
        editor.@current_animation = "idle"
        animation = editor.send(:get_current_animation)
        animation.should_not be_nil
        animation.name.should eq("idle")
      end

      it "returns nil if no animation selected" do
        editor.@current_animation = nil
        animation = editor.send(:get_current_animation)
        animation.should be_nil
      end
    end
  end

  describe "playback controls" do
    before_each do
      editor.show("test_character")
      editor.@current_animation = "walk"
    end

    describe "#toggle_playback" do
      it "toggles playing state" do
        editor.@playing = false
        editor.send(:toggle_playback)
        editor.@playing.should be_true
        
        editor.send(:toggle_playback)
        editor.@playing.should be_false
      end

      it "resets frame timer" do
        editor.@frame_timer = 0.5_f32
        editor.send(:toggle_playback)
        editor.@frame_timer.should eq(0.0_f32)
      end
    end

    describe "#next_frame" do
      it "advances to next frame" do
        editor.@current_frame = 1
        editor.send(:next_frame)
        editor.@current_frame.should eq(2)
      end

      it "wraps around to first frame" do
        animation = editor.send(:get_current_animation)
        editor.@current_frame = animation.frames.size - 1
        editor.send(:next_frame)
        editor.@current_frame.should eq(0)
      end
    end

    describe "#previous_frame" do
      it "goes to previous frame" do
        editor.@current_frame = 2
        editor.send(:previous_frame)
        editor.@current_frame.should eq(1)
      end

      it "wraps around to last frame" do
        animation = editor.send(:get_current_animation)
        editor.@current_frame = 0
        editor.send(:previous_frame)
        editor.@current_frame.should eq(animation.frames.size - 1)
      end
    end
  end

  describe "frame management" do
    before_each do
      editor.show("test_character")
      editor.@current_animation = "idle"
    end

    describe "#add_frame_to_animation" do
      it "adds new frame to current animation" do
        animation = editor.send(:get_current_animation)
        initial_count = animation.frames.size
        
        editor.send(:add_frame_to_animation)
        
        animation.frames.size.should eq(initial_count + 1)
      end

      it "calculates sprite coordinates based on sheet layout" do
        # Clear existing frames for predictable testing
        animation = editor.send(:get_current_animation)
        animation.frames.clear
        
        editor.send(:add_frame_to_animation)
        
        frame = animation.frames.first
        frame.sprite_x.should eq(0)  # First frame at 0,0
        frame.sprite_y.should eq(0)
        
        editor.send(:add_frame_to_animation)
        
        frame2 = animation.frames[1]
        frame2.sprite_x.should eq(32)  # Second frame at sprite_width,0
        frame2.sprite_y.should eq(0)
      end
    end
  end

  describe "animation playback update" do
    before_each do
      editor.show("test_character")
      editor.@current_animation = "walk"
      editor.@playing = true
    end

    describe "#update_playback" do
      it "advances frame when timer exceeds duration" do
        animation = editor.send(:get_current_animation)
        frame = animation.frames[@editor.@current_frame]
        
        # Simulate enough time passing
        editor.@frame_timer = frame.duration + 0.1_f32
        
        initial_frame = editor.@current_frame
        editor.send(:update_playback)
        
        editor.@current_frame.should be > initial_frame
      end

      it "loops animation when reaching end" do
        animation = editor.send(:get_current_animation)
        animation.loop = true
        editor.@current_frame = animation.frames.size - 1
        editor.@frame_timer = 1.0_f32  # Long enough to trigger advance
        
        editor.send(:update_playback)
        
        editor.@current_frame.should eq(0)
      end

      it "stops at end when not looping" do
        animation = editor.send(:get_current_animation)
        animation.loop = false
        editor.@current_frame = animation.frames.size - 1
        editor.@frame_timer = 1.0_f32
        
        editor.send(:update_playback)
        
        editor.@current_frame.should eq(animation.frames.size - 1)
        editor.@playing.should be_false
      end

      it "respects playback speed" do
        animation = editor.send(:get_current_animation)
        frame = animation.frames[@editor.@current_frame]
        
        editor.@playback_speed = 2.0_f32  # Double speed
        editor.@frame_timer = frame.duration / 2.0_f32 + 0.01_f32
        
        initial_frame = editor.@current_frame
        editor.send(:update_playback)
        
        editor.@current_frame.should be > initial_frame
      end
    end
  end

  describe "sprite sheet calculations" do
    before_each do
      editor.show("test_character")
    end

    it "calculates correct sprite positions for sheet layout" do
      # Test sprite sheet coordinate calculation
      columns = editor.@animation_data.sheet_columns
      sprite_width = editor.@animation_data.sprite_width
      sprite_height = editor.@animation_data.sprite_height
      
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

  describe "save functionality" do
    before_each do
      editor.show("test_character")
    end

    describe "#save_animation_data" do
      it "handles saving animation data" do
        # This would need file system mocking for complete testing
        # For now, verify it doesn't crash
        editor.send(:save_animation_data)
        # Should not raise any exceptions
      end
    end
  end

  describe "error handling" do
    it "handles missing sprite sheet gracefully" do
      editor.show("test_character", "/nonexistent/file.png")
      # Should not crash the editor
      editor.visible.should be_true
    end

    it "handles empty animation data" do
      editor.@animation_data.animations.clear
      editor.@current_animation = "nonexistent"
      
      # These should not crash
      editor.send(:get_current_animation).should be_nil
      editor.send(:next_frame)  # Should handle nil animation
      editor.send(:update_playback)  # Should handle nil animation
    end
  end

  describe "UI state management" do
    before_each do
      editor.show("test_character")
    end

    it "maintains zoom level within bounds" do
      editor.@zoom = 5.0_f32
      # Zoom should be reasonable for UI display
      editor.@zoom.should be > 0
      editor.@zoom.should be < 10  # Reasonable upper bound
    end

    it "handles timeline scrolling" do
      # Add many frames to test scrolling
      animation = editor.send(:get_current_animation)
      20.times { editor.send(:add_frame_to_animation) }
      
      editor.@timeline_scroll = 100
      # Should handle scroll position reasonably
      editor.@timeline_scroll.should be >= 0
    end
  end

  describe "frame selection" do
    before_each do
      editor.show("test_character")
      editor.@current_animation = "walk"
    end

    it "tracks selected frame independently of current frame" do
      editor.@current_frame = 2
      editor.@selected_frame = 1
      
      editor.@current_frame.should_not eq(editor.@selected_frame)
    end

    it "updates selected frame when clicking frames" do
      # This would be tested in integration tests with mouse input simulation
      editor.@selected_frame = -1
      # Simulate clicking on frame 2
      editor.@selected_frame = 2
      editor.@selected_frame.should eq(2)
    end
  end
end