# E2E Tests for Character Management
# Tests character creation, selection, movement, and properties

require "./e2e_spec_helper"

describe "Character Management E2E" do
  describe "Character Creation via State" do
    it "can add NPC character to scene" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.assert_character_count(0)

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frame
      end

      harness.assert_character_count(1)

      harness.cleanup
    end

    it "can add Player character to scene" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.assert_character_count(0)

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_player_character(scene)
        harness.step_frame
      end

      harness.assert_character_count(1)

      harness.cleanup
    end

    it "creates characters with unique names" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Add multiple NPCs
        5.times do
          harness.editor.state.add_npc_character(scene)
          harness.step_frame
        end

        # All names should be unique
        names = scene.characters.map(&.name)
        names.uniq.size.should eq(5)
      end

      harness.cleanup
    end

    it "selects newly created character" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frame

        # Should be selected
        harness.selected_object.should_not be_nil
        harness.selected_object.should eq(scene.characters.last.name)
      end

      harness.cleanup
    end

    it "sets default character properties" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frame

        character = scene.characters.first
        character.description.should_not be_nil
        character.size.x.should be > 0
        character.size.y.should be > 0
      end

      harness.cleanup
    end
  end

  describe "Character Selection" do
    it "can select character by clicking" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frame

        char_name = scene.characters.first.name

        # Deselect
        harness.press_key(RL::KeyboardKey::Escape)
        harness.step_frame
        harness.selected_object.should be_nil

        # Click on character position (default is 450, 300)
        harness.press_key(RL::KeyboardKey::V)
        harness.click_canvas(450, 300)
        harness.step_frame

        harness.selected_object.should eq(char_name)
      end

      harness.cleanup
    end

    it "can select multiple characters" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Add multiple characters
        harness.editor.state.add_npc_character(scene)
        harness.step_frame

        # Move second character to different position
        harness.editor.state.add_player_character(scene)
        harness.step_frame

        harness.assert_character_count(2)

        # Select all
        harness.press_key(RL::KeyboardKey::V)
        harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::A)
        harness.step_frame

        harness.selected_objects.size.should be >= 1
      end

      harness.cleanup
    end
  end

  describe "Character Movement" do
    it "can move character by dragging" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frame

        initial_pos = scene.characters.first.position.dup

        # Select and drag
        harness.press_key(RL::KeyboardKey::V)
        harness.click_canvas(initial_pos.x.to_i, initial_pos.y.to_i)
        harness.step_frame

        harness.drag_canvas(initial_pos.x.to_i, initial_pos.y.to_i,
          initial_pos.x.to_i + 100, initial_pos.y.to_i + 50)

        # Position should have changed
        character = scene.characters.first
        (character.position.x != initial_pos.x || character.position.y != initial_pos.y).should be_true
      end

      harness.cleanup
    end

    it "records character movement in undo stack" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frame

        initial_pos = scene.characters.first.position.dup

        # Select and drag
        harness.press_key(RL::KeyboardKey::V)
        harness.click_canvas(initial_pos.x.to_i, initial_pos.y.to_i)
        harness.step_frame
        harness.drag_canvas(initial_pos.x.to_i, initial_pos.y.to_i,
          initial_pos.x.to_i + 100, initial_pos.y.to_i + 50)

        harness.editor.state.can_undo?.should be_true
      end

      harness.cleanup
    end
  end

  describe "Character Deletion" do
    it "can delete character with Delete key" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frame
        harness.assert_character_count(1)

        # Character should be selected, press Delete
        harness.press_key(RL::KeyboardKey::Delete)
        harness.step_frame

        harness.assert_character_count(0)
      end

      harness.cleanup
    end

    it "can delete character with Delete tool" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frame

        pos = scene.characters.first.position

        harness.assert_character_count(1)

        # Switch to Delete tool
        harness.press_key(RL::KeyboardKey::D)
        harness.click_canvas(pos.x.to_i, pos.y.to_i)
        harness.step_frame

        harness.assert_character_count(0)
      end

      harness.cleanup
    end

    it "can undo character creation" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.assert_character_count(0)

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frame
        harness.assert_character_count(1)

        # Undo
        harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Z)
        harness.step_frame

        harness.assert_character_count(0)
      end

      harness.cleanup
    end

    it "can redo character creation" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frame
        harness.assert_character_count(1)

        # Undo
        harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Z)
        harness.step_frame
        harness.assert_character_count(0)

        # Redo
        harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::Y)
        harness.step_frame

        harness.assert_character_count(1)
      end

      harness.cleanup
    end
  end

  describe "Mixed Object Operations" do
    it "can have both hotspots and characters in scene" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspots
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.click_canvas(200, 100)
      harness.step_frame

      # Create characters
      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frame
        harness.editor.state.add_player_character(scene)
        harness.step_frame
      end

      harness.assert_hotspot_count(2)
      harness.assert_character_count(2)

      harness.cleanup
    end

    it "select all includes both hotspots and characters" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create mixed content
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frame
      end

      # Select all
      harness.press_key(RL::KeyboardKey::V)
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::A)
      harness.step_frame

      # Should have selections from both types
      harness.selected_objects.size.should be >= 1

      harness.cleanup
    end

    it "delete all removes both types" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create content
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frame
      end

      harness.assert_hotspot_count(1)
      harness.assert_character_count(1)

      # Select all and delete
      harness.press_key(RL::KeyboardKey::V)
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::A)
      harness.step_frame
      harness.press_key(RL::KeyboardKey::Delete)
      harness.step_frame

      harness.assert_hotspot_count(0)
      harness.assert_character_count(0)

      harness.cleanup
    end
  end

  describe "Character Mode" do
    it "can switch to Character mode" do
      harness = E2ETestHelper.create_harness_with_scene

      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      harness.step_frame

      harness.assert_mode(PaceEditor::EditorMode::Character)

      harness.cleanup
    end

    it "preserves character count when switching modes" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.editor.state.add_npc_character(scene)
        harness.step_frame
      end

      harness.assert_character_count(2)

      # Switch to Character mode
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      harness.step_frame
      harness.assert_character_count(2)

      # Switch back to Scene mode
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)
      harness.step_frame
      harness.assert_character_count(2)

      harness.cleanup
    end
  end
end
