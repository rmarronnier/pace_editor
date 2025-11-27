# Comprehensive E2E tests for ALL UI elements in PACE Editor
# Tests every button, input field, and interactive element using simulated input

require "./e2e_spec_helper"

describe "Comprehensive UI E2E Tests" do
  describe "Tool Palette - Tool Selection Buttons" do
    it "can click Select tool button (V shortcut)" do
      harness = E2ETestHelper.create_harness_with_scene

      # Set a different tool first
      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Move)
      harness.step_frames(3)

      # Get Select tool button position (first tool at y=40 from menu)
      pos = harness.editor.tool_palette.get_tool_button_position(PaceEditor::Tool::Select)
      harness.click(pos[0] + 30, pos[1] + 30)

      harness.editor.state.current_tool.should eq(PaceEditor::Tool::Select)

      harness.cleanup
    end

    it "can click Move tool button (M shortcut)" do
      harness = E2ETestHelper.create_harness_with_scene

      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Select)
      harness.step_frames(3)

      pos = harness.editor.tool_palette.get_tool_button_position(PaceEditor::Tool::Move)
      harness.click(pos[0] + 30, pos[1] + 30)

      harness.editor.state.current_tool.should eq(PaceEditor::Tool::Move)

      harness.cleanup
    end

    it "can click Place tool button (P shortcut)" do
      harness = E2ETestHelper.create_harness_with_scene

      pos = harness.editor.tool_palette.get_tool_button_position(PaceEditor::Tool::Place)
      harness.click(pos[0] + 30, pos[1] + 30)

      harness.editor.state.current_tool.should eq(PaceEditor::Tool::Place)

      harness.cleanup
    end

    it "can click Delete tool button (D shortcut)" do
      harness = E2ETestHelper.create_harness_with_scene

      pos = harness.editor.tool_palette.get_tool_button_position(PaceEditor::Tool::Delete)
      harness.click(pos[0] + 30, pos[1] + 30)

      harness.editor.state.current_tool.should eq(PaceEditor::Tool::Delete)

      harness.cleanup
    end

    it "can click Paint tool button (B shortcut)" do
      harness = E2ETestHelper.create_harness_with_scene

      pos = harness.editor.tool_palette.get_tool_button_position(PaceEditor::Tool::Paint)
      harness.click(pos[0] + 30, pos[1] + 30)

      harness.editor.state.current_tool.should eq(PaceEditor::Tool::Paint)

      harness.cleanup
    end

    it "can click Zoom tool button (Z shortcut)" do
      harness = E2ETestHelper.create_harness_with_scene

      pos = harness.editor.tool_palette.get_tool_button_position(PaceEditor::Tool::Zoom)
      harness.click(pos[0] + 30, pos[1] + 30)

      harness.editor.state.current_tool.should eq(PaceEditor::Tool::Zoom)

      harness.cleanup
    end
  end

  describe "Tool Palette - Scene Tool Buttons" do
    it "can click Add Char button to create character" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      initial_count = harness.character_count

      # Click Add Char button in scene tools section
      pos = harness.editor.tool_palette.get_scene_tool_button_position("Add Char")
      harness.click(pos[0] + 35, pos[1] + 11)

      harness.character_count.should eq(initial_count + 1)

      harness.cleanup
    end

    it "can click Add Spot button to create hotspot" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      initial_count = harness.hotspot_count

      pos = harness.editor.tool_palette.get_scene_tool_button_position("Add Spot")
      harness.click(pos[0] + 35, pos[1] + 11)

      harness.hotspot_count.should eq(initial_count + 1)

      harness.cleanup
    end
  end

  describe "Progressive Menu" do
    it "can open File menu by clicking" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      pos = harness.editor.progressive_menu.get_menu_section_position("File")
      harness.click(pos[0].to_i, pos[1].to_i)

      harness.editor.progressive_menu.menu_open?("File").should be_true

      harness.cleanup
    end

    it "can open Edit menu when project exists" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      pos = harness.editor.progressive_menu.get_menu_section_position("Edit")
      harness.click(pos[0].to_i, pos[1].to_i)

      harness.editor.progressive_menu.menu_open?("Edit").should be_true

      harness.cleanup
    end

    it "can open Scene menu" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      pos = harness.editor.progressive_menu.get_menu_section_position("Scene")
      harness.click(pos[0].to_i, pos[1].to_i)

      harness.editor.progressive_menu.menu_open?("Scene").should be_true

      harness.cleanup
    end

    it "can close menu by clicking elsewhere" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      # Open menu first
      harness.editor.progressive_menu.open_menu_for_test("File")
      harness.step_frames(3)

      harness.editor.progressive_menu.menu_open?("File").should be_true

      # Click elsewhere to close
      harness.click(500, 500)

      harness.editor.progressive_menu.menu_open?("File").should be_false

      harness.cleanup
    end

    it "can click New Scene menu item to show wizard" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      # Open Scene menu
      harness.editor.progressive_menu.open_menu_for_test("Scene")
      harness.step_frames(3)

      # Click New Scene item
      pos = harness.editor.progressive_menu.get_dropdown_item_position("Scene", "new_scene")
      if item_pos = pos
        harness.click(item_pos[0].to_i, item_pos[1].to_i)
        harness.step_frames(3)

        harness.editor.scene_creation_wizard.visible.should be_true
      end

      harness.cleanup
    end
  end

  describe "Scene Hierarchy" do
    it "can expand hotspots node programmatically" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      harness.editor.scene_hierarchy.expand_node_for_test("hotspots")
      harness.editor.scene_hierarchy.node_expanded?("hotspots").should be_true

      harness.cleanup
    end

    it "can expand characters node programmatically" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      harness.editor.scene_hierarchy.expand_node_for_test("characters")
      harness.editor.scene_hierarchy.node_expanded?("characters").should be_true

      harness.cleanup
    end

    it "can collapse an expanded node" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      harness.editor.scene_hierarchy.expand_node_for_test("hotspots")
      harness.editor.scene_hierarchy.collapse_node_for_test("hotspots")
      harness.editor.scene_hierarchy.node_expanded?("hotspots").should be_false

      harness.cleanup
    end
  end

  describe "Property Panel" do
    it "can activate text field for editing" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      # Create a hotspot and select it
      scene = harness.editor.state.current_scene.not_nil!
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(x: 200, y: 200),
        RL::Vector2.new(x: 64, y: 64)
      )
      scene.add_hotspot(hotspot)
      harness.editor.state.selected_object = "test_hotspot"
      harness.step_frames(5)

      # Activate a field for editing
      harness.editor.property_panel.set_active_field_for_test("hotspot_desc", "Original")
      harness.editor.property_panel.active_field_for_test.should eq("hotspot_desc")

      harness.cleanup
    end

    it "can type in active text field" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      # Create and select a hotspot
      scene = harness.editor.state.current_scene.not_nil!
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(x: 200, y: 200),
        RL::Vector2.new(x: 64, y: 64)
      )
      scene.add_hotspot(hotspot)
      harness.editor.state.selected_object = "test_hotspot"
      harness.step_frames(5)

      # Activate field and type
      harness.editor.property_panel.set_active_field_for_test("hotspot_desc", "")
      harness.type_text("New Description")

      harness.editor.property_panel.edit_buffer_for_test.should eq("New Description")

      harness.cleanup
    end

    it "can apply edit with helper method" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      # Create and select a hotspot
      scene = harness.editor.state.current_scene.not_nil!
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(x: 200, y: 200),
        RL::Vector2.new(x: 64, y: 64)
      )
      scene.add_hotspot(hotspot)
      harness.editor.state.selected_object = "test_hotspot"
      harness.step_frames(5)

      harness.editor.property_panel.set_active_field_for_test("hotspot_desc", "Final Value")
      harness.editor.property_panel.apply_edit_for_test

      harness.editor.property_panel.active_field_for_test.should be_nil

      harness.cleanup
    end
  end

  describe "Dialog Editor" do
    it "can create new dialog node via toolbar click" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      # Switch to dialog mode
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)
      harness.step_frames(5)

      # Ensure dialog exists
      harness.editor.dialog_editor.ensure_dialog_for_test
      harness.step_frames(3)

      # Clicking "New Node" should show the node dialog
      pos = harness.editor.dialog_editor.get_toolbar_button_position("new_node")
      harness.click(pos[0], pos[1])

      # The node dialog should now be visible (this is the expected behavior)
      harness.editor.dialog_editor.node_dialog_showing?.should be_true

      harness.cleanup
    end

    it "can create node directly via helper" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)
      harness.step_frames(5)

      harness.editor.dialog_editor.ensure_dialog_for_test
      harness.step_frames(3)

      initial_count = harness.editor.dialog_editor.dialog_tree.nodes.size

      # Use helper to create node directly
      harness.editor.dialog_editor.create_node_for_test("new_node", "Hello World")
      harness.step_frames(3)

      harness.editor.dialog_editor.dialog_tree.nodes.size.should eq(initial_count + 1)

      harness.cleanup
    end

    it "can toggle connection mode via toolbar" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)
      harness.step_frames(5)

      harness.editor.dialog_editor.ensure_dialog_for_test
      harness.step_frames(3)

      initial_state = harness.editor.dialog_editor.connection_mode?

      pos = harness.editor.dialog_editor.get_toolbar_button_position("connect")
      harness.click(pos[0], pos[1])

      harness.editor.dialog_editor.connection_mode?.should eq(!initial_state)

      harness.cleanup
    end

    it "can select node programmatically" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)
      harness.step_frames(5)

      # Ensure dialog exists and create a node
      harness.editor.dialog_editor.ensure_dialog_for_test
      test_node = PointClickEngine::Characters::Dialogue::DialogNode.new("test_node", "Hello")
      harness.editor.dialog_editor.dialog_tree.add_node(test_node)
      harness.step_frames(3)

      # Select it programmatically
      harness.editor.dialog_editor.select_node_for_test("test_node")
      harness.editor.dialog_editor.selected_node.should eq("test_node")

      harness.cleanup
    end

    it "can delete selected node via toolbar" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)
      harness.step_frames(5)

      # Ensure dialog exists and create a node
      harness.editor.dialog_editor.ensure_dialog_for_test
      delete_node = PointClickEngine::Characters::Dialogue::DialogNode.new("delete_me", "Delete this")
      harness.editor.dialog_editor.dialog_tree.add_node(delete_node)
      harness.editor.dialog_editor.select_node_for_test("delete_me")
      harness.step_frames(3)

      initial_count = harness.editor.dialog_editor.dialog_tree.nodes.size

      # Click Delete button
      pos = harness.editor.dialog_editor.get_toolbar_button_position("delete")
      harness.click(pos[0], pos[1])

      harness.editor.dialog_editor.dialog_tree.nodes.size.should eq(initial_count - 1)

      harness.cleanup
    end
  end

  describe "Asset Browser" do
    it "can switch category tabs" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Assets)
      harness.step_frames(5)

      harness.editor.asset_browser.current_category.should eq("backgrounds")

      # Change category programmatically
      harness.editor.asset_browser.set_category_for_test("characters")
      harness.editor.asset_browser.current_category.should eq("characters")

      harness.cleanup
    end

    it "can click sounds tab via UI" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Assets)
      harness.step_frames(5)

      pos = harness.editor.asset_browser.get_category_tab_position("sounds")
      harness.click(pos[0], pos[1])

      harness.editor.asset_browser.current_category.should eq("sounds")

      harness.cleanup
    end

    it "can click import button" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Assets)
      harness.step_frames(5)

      pos = harness.editor.asset_browser.get_import_button_position
      harness.click(pos[0], pos[1])

      harness.editor.asset_import_dialog.visible.should be_true

      harness.cleanup
    end
  end

  describe "Keyboard Shortcuts" do
    it "V key selects Select tool" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Move)
      harness.press_key(RL::KeyboardKey::V)

      harness.editor.state.current_tool.should eq(PaceEditor::Tool::Select)

      harness.cleanup
    end

    it "M key selects Move tool" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      harness.press_key(RL::KeyboardKey::M)

      harness.editor.state.current_tool.should eq(PaceEditor::Tool::Move)

      harness.cleanup
    end

    it "P key selects Place tool" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      harness.press_key(RL::KeyboardKey::P)

      harness.editor.state.current_tool.should eq(PaceEditor::Tool::Place)

      harness.cleanup
    end

    it "D key selects Delete tool" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      harness.press_key(RL::KeyboardKey::D)

      harness.editor.state.current_tool.should eq(PaceEditor::Tool::Delete)

      harness.cleanup
    end

    it "G key toggles grid visibility" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      initial_state = harness.editor.state.show_grid
      harness.press_key(RL::KeyboardKey::G)

      harness.editor.state.show_grid.should eq(!initial_state)

      harness.cleanup
    end

    it "H key toggles hotspots visibility" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      initial_state = harness.editor.state.show_hotspots
      harness.press_key(RL::KeyboardKey::H)

      harness.editor.state.show_hotspots.should eq(!initial_state)

      harness.cleanup
    end
  end

  describe "Scene Editor Viewport" do
    it "can place hotspot in viewport with Place tool" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Place)
      harness.step_frames(3)

      initial_count = harness.hotspot_count

      # Click in viewport to place hotspot
      harness.click_canvas(300, 200)

      harness.hotspot_count.should eq(initial_count + 1)

      harness.cleanup
    end

    it "can select hotspot with Select tool" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      # Create a hotspot
      scene = harness.editor.state.current_scene.not_nil!
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "clickable_hotspot",
        RL::Vector2.new(x: 200, y: 200),
        RL::Vector2.new(x: 64, y: 64)
      )
      scene.add_hotspot(hotspot)
      harness.step_frames(3)

      # Switch to Select tool and deselect
      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Select)
      harness.editor.state.selected_object = nil
      harness.step_frames(3)

      # Click on the hotspot
      harness.click_canvas(232, 232)  # Center of hotspot

      harness.editor.state.selected_object.should eq("clickable_hotspot")

      harness.cleanup
    end

    it "can delete hotspot with Delete tool" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      # Create a hotspot
      scene = harness.editor.state.current_scene.not_nil!
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "deletable_hotspot",
        RL::Vector2.new(x: 200, y: 200),
        RL::Vector2.new(x: 64, y: 64)
      )
      scene.add_hotspot(hotspot)
      harness.step_frames(3)

      initial_count = harness.hotspot_count

      # Switch to Delete tool
      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Delete)
      harness.step_frames(3)

      # Click on the hotspot to delete it
      harness.click_canvas(232, 232)

      harness.hotspot_count.should eq(initial_count - 1)

      harness.cleanup
    end
  end

  describe "Complete Workflow: Character Creation" do
    it "can create a character via tool palette button" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(5)

      initial_count = harness.character_count

      # Click Add Char button
      pos = harness.editor.tool_palette.get_scene_tool_button_position("Add Char")
      harness.click(pos[0] + 35, pos[1] + 11)

      harness.character_count.should eq(initial_count + 1)

      # Character should be selected
      harness.selected_object.should_not be_nil

      harness.cleanup
    end
  end

  describe "Complete Workflow: Dialog Tree Creation" do
    it "can create a multi-node dialog tree" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)
      harness.step_frames(5)

      # Ensure dialog exists
      harness.editor.dialog_editor.ensure_dialog_for_test
      harness.step_frames(3)

      # Create multiple nodes using helper
      harness.editor.dialog_editor.create_node_for_test("node1", "First dialog line")
      harness.editor.dialog_editor.create_node_for_test("node2", "Second dialog line")
      harness.editor.dialog_editor.create_node_for_test("node3", "Third dialog line")
      harness.step_frames(3)

      # Should have at least 3 nodes (plus the start node)
      harness.editor.dialog_editor.dialog_tree.nodes.size.should be >= 3

      harness.cleanup
    end

    it "can enable connection mode for linking nodes" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.step_frames(3)

      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)
      harness.step_frames(5)

      # Create two nodes
      pos = harness.editor.dialog_editor.get_toolbar_button_position("new_node")
      harness.click(pos[0], pos[1])
      harness.step_frames(3)
      harness.click(pos[0], pos[1])
      harness.step_frames(3)

      # Select first node
      nodes = harness.editor.dialog_editor.dialog_tree.nodes.keys.to_a
      harness.editor.dialog_editor.select_node_for_test(nodes[0])
      harness.step_frames(3)

      # Enable connection mode
      connect_pos = harness.editor.dialog_editor.get_toolbar_button_position("connect")
      harness.click(connect_pos[0], connect_pos[1])

      harness.editor.dialog_editor.connection_mode?.should be_true

      harness.cleanup
    end
  end
end
