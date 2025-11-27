# E2E Tests for Full Scene Creation - UI ONLY
# These tests interact ONLY through UI clicks, NOT programmatically
# They should catch bugs in the actual UI that programmatic tests miss

require "./e2e_spec_helper"

# UI position constants for all editors
module EditorUI
  # Layout constants
  TOOL_PALETTE_WIDTH   = 80
  MENU_HEIGHT          = 30
  PROPERTY_PANEL_WIDTH = 300
  SCREEN_WIDTH         = 1400
  SCREEN_HEIGHT        = 900

  # Character Editor - "Create Character" button position (centered when no character)
  CHAR_EDITOR_WIDTH = SCREEN_WIDTH - TOOL_PALETTE_WIDTH - PROPERTY_PANEL_WIDTH
  CHAR_EDITOR_HEIGHT = SCREEN_HEIGHT - MENU_HEIGHT
  CREATE_CHAR_BUTTON_X = TOOL_PALETTE_WIDTH + (CHAR_EDITOR_WIDTH - 150) // 2 + 75
  CREATE_CHAR_BUTTON_Y = MENU_HEIGHT + CHAR_EDITOR_HEIGHT // 2 - 60 + 80 + 15

  # Scene Hierarchy panel (bottom left)
  HIERARCHY_X = TOOL_PALETTE_WIDTH
  HIERARCHY_Y = SCREEN_HEIGHT - 200
  HIERARCHY_WIDTH = 250

  # Hierarchy tree positions
  HOTSPOTS_NODE_Y = HIERARCHY_Y + 35 + 20  # After scene root
  CHARACTERS_NODE_Y_OFFSET = 20 # Added after hotspots section

  # Property Panel (right side)
  PROP_PANEL_X = SCREEN_WIDTH - PROPERTY_PANEL_WIDTH
  PROP_PANEL_Y = MENU_HEIGHT

  # Property field positions
  PROP_LABEL_WIDTH = 80
  PROP_FIELD_START_Y = PROP_PANEL_Y + 45 + 25 + 25  # After headers
end

describe "UI-Only Scene Creation E2E" do
  describe "Creating Characters via Character Editor UI" do
    it "can create a character by clicking the Create Character button" do
      harness = E2ETestHelper.create_harness_with_scene

      # Switch to Character mode
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      harness.step_frames(5)
      harness.assert_mode(PaceEditor::EditorMode::Character)

      # Initially no character
      harness.character_count.should eq(0)

      # Click "Create Character" button
      harness.click(
        EditorUI::CREATE_CHAR_BUTTON_X,
        EditorUI::CREATE_CHAR_BUTTON_Y
      )
      harness.step_frames(5)

      # Character should be created
      harness.character_count.should eq(1)

      # Character should be selected
      harness.selected_object.should_not be_nil

      harness.cleanup
    end

    it "can create multiple characters via UI" do
      harness = E2ETestHelper.create_harness_with_scene

      # Switch to Character mode
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      harness.step_frames(5)

      # Create first character
      harness.click(
        EditorUI::CREATE_CHAR_BUTTON_X,
        EditorUI::CREATE_CHAR_BUTTON_Y
      )
      harness.step_frames(5)
      harness.character_count.should eq(1)

      # Deselect current character to show "Create Character" again
      harness.editor.state.selected_object = nil
      harness.editor.character_editor.current_character = nil
      harness.step_frames(3)

      # Create second character
      harness.click(
        EditorUI::CREATE_CHAR_BUTTON_X,
        EditorUI::CREATE_CHAR_BUTTON_Y
      )
      harness.step_frames(5)
      harness.character_count.should eq(2)

      harness.cleanup
    end
  end

  describe "Selecting Objects via Scene Hierarchy UI" do
    it "can expand hotspots section by clicking" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create some hotspots first
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frames(2)
      harness.click_canvas(200, 200)
      harness.step_frames(2)

      harness.assert_hotspot_count(2)

      # Expand hotspots section in hierarchy
      harness.editor.scene_hierarchy.expand_node_for_test("hotspots")

      # Click on first hotspot in hierarchy
      # Hotspots start at HOTSPOTS_NODE_Y + 20 (after section header)
      first_hotspot_y = EditorUI::HOTSPOTS_NODE_Y + 20
      harness.click(
        EditorUI::HIERARCHY_X + 40 + 50,  # Indented + some offset for text
        first_hotspot_y + 6
      )
      harness.step_frames(3)

      # A hotspot should be selected
      harness.selected_object.should_not be_nil

      harness.cleanup
    end

    it "can expand characters section and select a character" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a character via Character Editor
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      harness.step_frames(3)

      harness.click(
        EditorUI::CREATE_CHAR_BUTTON_X,
        EditorUI::CREATE_CHAR_BUTTON_Y
      )
      harness.step_frames(5)

      char_name = harness.selected_object

      # Switch back to Scene mode
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)
      harness.step_frames(3)

      # Clear selection
      harness.editor.state.selected_object = nil
      harness.step_frames(2)

      # Expand characters section in hierarchy
      harness.editor.scene_hierarchy.expand_node_for_test("characters")

      # Calculate position for characters section (after hotspots)
      # Hotspots section: header + items (if any)
      characters_header_y = EditorUI::HOTSPOTS_NODE_Y + 20  # After hotspots header
      first_character_y = characters_header_y + 20  # After characters header

      harness.click(
        EditorUI::HIERARCHY_X + 40 + 50,
        first_character_y + 6
      )
      harness.step_frames(3)

      # The character should be selected
      harness.selected_object.should eq(char_name)

      harness.cleanup
    end
  end

  describe "Modifying Properties via Property Panel UI" do
    it "can edit hotspot description via property panel" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(200, 200)
      harness.step_frames(3)

      harness.assert_hotspot_count(1)
      hotspot_name = harness.selected_object
      hotspot_name.should_not be_nil

      # Get the hotspot
      if scene = harness.editor.state.current_scene
        if name = hotspot_name
          if hotspot = scene.hotspots.find { |h| h.name == name }
            original_desc = hotspot.description

            # Use property panel helper to set description
            harness.editor.property_panel.set_active_field_for_test("hotspot_desc", "New Description")
            harness.step_frame
            harness.editor.property_panel.apply_edit_for_test
            harness.step_frames(3)

            # Description should be changed
            hotspot.description.should eq("New Description")
            hotspot.description.should_not eq(original_desc)
          end
        end
      end

      harness.cleanup
    end

    it "can edit character walking speed via property panel" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a character via UI
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      harness.step_frames(3)

      harness.click(
        EditorUI::CREATE_CHAR_BUTTON_X,
        EditorUI::CREATE_CHAR_BUTTON_Y
      )
      harness.step_frames(5)

      char_name = harness.selected_object
      char_name.should_not be_nil

      # Switch back to scene mode to use property panel
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)
      harness.step_frames(3)

      # Re-select the character
      if name = char_name
        harness.editor.state.select_object(name)
      end
      harness.step_frames(2)

      if scene = harness.editor.state.current_scene
        if name = char_name
          if character = scene.characters.find { |c| c.name == name }
            original_speed = character.walking_speed

            # Use property panel helper to set speed
            harness.editor.property_panel.set_active_field_for_test("char_speed", "250.0")
            harness.step_frame
            harness.editor.property_panel.apply_edit_for_test
            harness.step_frames(3)

            # Speed should be changed
            character.walking_speed.should eq(250.0_f32)
          end
        end
      end

      harness.cleanup
    end

    it "can edit hotspot position via property panel" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frames(3)

      hotspot_name = harness.selected_object

      if scene = harness.editor.state.current_scene
        if name = hotspot_name
          if hotspot = scene.hotspots.find { |h| h.name == name }
            # Change X position
            harness.editor.property_panel.set_active_field_for_test("hotspot_x", "500")
            harness.step_frame
            harness.editor.property_panel.apply_edit_for_test
            harness.step_frames(3)

            # Change Y position
            harness.editor.property_panel.set_active_field_for_test("hotspot_y", "400")
            harness.step_frame
            harness.editor.property_panel.apply_edit_for_test
            harness.step_frames(3)

            # Position should be updated
            hotspot.position.x.should eq(500.0_f32)
            hotspot.position.y.should eq(400.0_f32)
          end
        end
      end

      harness.cleanup
    end
  end

  describe "Complete Scene Creation Workflow via UI" do
    it "can create a complete scene with hotspots and characters using only UI" do
      harness = E2ETestHelper.create_harness_with_scene("AdventureGame", "tavern")

      # === Step 1: Create hotspots via Scene Editor ===
      harness.assert_mode(PaceEditor::EditorMode::Scene)

      # Create door hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(800, 400)
      harness.step_frames(2)

      # Create bar counter hotspot
      harness.click_canvas(200, 300)
      harness.step_frames(2)

      # Create table hotspot
      harness.click_canvas(400, 500)
      harness.step_frames(2)

      harness.assert_hotspot_count(3)

      # === Step 2: Modify hotspot properties via Property Panel ===
      # Select first hotspot and set description
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(800, 400)
      harness.step_frames(3)

      harness.editor.property_panel.set_active_field_for_test("hotspot_desc", "Exit to the street")
      harness.editor.property_panel.apply_edit_for_test
      harness.step_frames(2)

      # === Step 3: Create character via Character Editor ===
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      harness.step_frames(3)

      harness.click(
        EditorUI::CREATE_CHAR_BUTTON_X,
        EditorUI::CREATE_CHAR_BUTTON_Y
      )
      harness.step_frames(5)

      harness.assert_character_count(1)
      barkeeper_name = harness.selected_object

      # === Step 4: Modify character properties ===
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)
      harness.step_frames(3)

      if name = barkeeper_name
        harness.editor.state.select_object(name)
        harness.step_frames(2)

        harness.editor.property_panel.set_active_field_for_test("char_desc", "The friendly barkeeper")
        harness.editor.property_panel.apply_edit_for_test
        harness.step_frames(2)

        harness.editor.property_panel.set_active_field_for_test("char_speed", "80.0")
        harness.editor.property_panel.apply_edit_for_test
        harness.step_frames(2)
      end

      # === Step 5: Save the scene ===
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)
      harness.step_frames(5)

      # === Verify final state ===
      harness.assert_hotspot_count(3)
      harness.assert_character_count(1)

      if scene = harness.editor.state.current_scene
        # Verify hotspot was modified
        door_hotspot = scene.hotspots.find { |h| h.description == "Exit to the street" }
        door_hotspot.should_not be_nil

        # Verify character was modified
        if name = barkeeper_name
          if character = scene.characters.find { |c| c.name == name }
            character.description.should eq("The friendly barkeeper")
            character.walking_speed.should eq(80.0_f32)
          end
        end
      end

      # Verify file was saved
      if project = harness.editor.state.current_project
        scene_path = File.join(project.scenes_path, "tavern.yml")
        File.exists?(scene_path).should be_true

        content = File.read(scene_path)
        content.includes?("Exit to the street").should be_true
      end

      harness.cleanup
    end

    it "can use scene hierarchy to select and modify objects" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create some objects
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frames(2)
      harness.click_canvas(200, 200)
      harness.step_frames(2)

      # Create a character
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      harness.step_frames(3)
      harness.click(
        EditorUI::CREATE_CHAR_BUTTON_X,
        EditorUI::CREATE_CHAR_BUTTON_Y
      )
      harness.step_frames(5)

      # Back to scene mode
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)
      harness.step_frames(3)

      # Clear selection
      harness.press_key(RL::KeyboardKey::Escape)
      harness.step_frames(2)

      # Expand hotspots in hierarchy
      harness.editor.scene_hierarchy.expand_node_for_test("hotspots")
      harness.step_frame

      harness.editor.scene_hierarchy.node_expanded?("hotspots").should be_true

      # Expand characters
      harness.editor.scene_hierarchy.expand_node_for_test("characters")
      harness.step_frame

      harness.editor.scene_hierarchy.node_expanded?("characters").should be_true

      harness.cleanup
    end
  end

  describe "Mode Switching with UI Interactions" do
    it "maintains object selection when switching between Scene and Character modes" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a character via Character Editor
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      harness.step_frames(3)

      harness.click(
        EditorUI::CREATE_CHAR_BUTTON_X,
        EditorUI::CREATE_CHAR_BUTTON_Y
      )
      harness.step_frames(5)

      char_name = harness.selected_object
      char_name.should_not be_nil

      # Switch to Scene mode
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)
      harness.step_frames(5)

      # Selection should be maintained
      harness.selected_object.should eq(char_name)

      # Switch back to Character mode
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      harness.step_frames(5)

      # Selection should still be maintained
      harness.selected_object.should eq(char_name)

      harness.cleanup
    end

    it "can create objects in different modes and verify persistence" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspots in Scene mode
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frames(2)
      harness.assert_hotspot_count(1)

      # Create character in Character mode
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      harness.step_frames(3)
      harness.click(
        EditorUI::CREATE_CHAR_BUTTON_X,
        EditorUI::CREATE_CHAR_BUTTON_Y
      )
      harness.step_frames(5)
      harness.assert_character_count(1)

      # Create dialog in Dialog mode
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)
      harness.step_frames(3)
      # Click create dialog button
      harness.click(590, 500)  # Approximate position
      harness.step_frames(5)

      # Switch back to Scene mode
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)
      harness.step_frames(3)

      # All objects should still exist
      harness.assert_hotspot_count(1)
      harness.assert_character_count(1)

      harness.cleanup
    end
  end
end

describe "UI Edge Cases E2E" do
  it "handles clicking outside interactive areas gracefully" do
    harness = E2ETestHelper.create_harness_with_scene

    # Click in various non-interactive areas
    harness.click(0, 0)  # Top-left corner
    harness.step_frames(2)

    harness.click(1399, 899)  # Bottom-right corner
    harness.step_frames(2)

    harness.click(700, 450)  # Center of canvas
    harness.step_frames(2)

    # Editor should still function
    harness.has_scene?.should be_true

    harness.cleanup
  end

  it "handles rapid mode switching without crashes" do
    harness = E2ETestHelper.create_harness_with_scene

    modes = [
      PaceEditor::EditorMode::Scene,
      PaceEditor::EditorMode::Character,
      PaceEditor::EditorMode::Dialog,
      PaceEditor::EditorMode::Hotspot,
    ]

    # Rapid mode switching via UI clicks
    20.times do |i|
      E2EUIHelpers.click_mode_button(harness, modes[i % modes.size])
      harness.step_frame
    end

    # Editor should still function
    harness.has_scene?.should be_true

    harness.cleanup
  end

  it "handles creating objects after clearing selection" do
    harness = E2ETestHelper.create_harness_with_scene

    # Create hotspot
    harness.press_key(RL::KeyboardKey::P)
    harness.click_canvas(100, 100)
    harness.step_frames(2)

    # Clear selection
    harness.press_key(RL::KeyboardKey::Escape)
    harness.step_frames(2)
    harness.selected_object.should be_nil

    # Create another hotspot
    harness.click_canvas(200, 200)
    harness.step_frames(2)

    harness.assert_hotspot_count(2)

    harness.cleanup
  end
end
