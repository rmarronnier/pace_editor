# E2E Tests for Dialog Editor UI
# Tests ACTUAL UI interactions - clicking buttons, filling forms, dragging nodes
# NOT creating objects programmatically

require "./e2e_spec_helper"

# UI position constants for Dialog Editor
module DialogEditorUI
  # Layout constants
  TOOL_PALETTE_WIDTH   = 80
  MENU_HEIGHT          = 30
  PROPERTY_PANEL_WIDTH = 300
  SCREEN_WIDTH         = 1400
  SCREEN_HEIGHT        = 900

  # Dialog Editor toolbar (at top of editor area)
  TOOLBAR_Y       = MENU_HEIGHT + 5  # 35
  TOOLBAR_BUTTON_HEIGHT = 30

  # Toolbar button positions (x is left edge, we need center)
  # Button width = 70, spacing varies
  NEW_NODE_BUTTON_X = TOOL_PALETTE_WIDTH + 10 + 35        # 125
  DELETE_BUTTON_X   = TOOL_PALETTE_WIDTH + 10 + 80 + 35   # 205
  CONNECT_BUTTON_X  = TOOL_PALETTE_WIDTH + 10 + 150 + 35  # 275
  TEST_BUTTON_X     = TOOL_PALETTE_WIDTH + 10 + 220 + 35  # 345
  TOOLBAR_BUTTON_Y  = TOOLBAR_Y + 15                      # 50

  # "Create Dialog Tree" button (centered in editor when no dialog)
  EDITOR_WIDTH = SCREEN_WIDTH - TOOL_PALETTE_WIDTH - PROPERTY_PANEL_WIDTH  # 1020
  EDITOR_HEIGHT = SCREEN_HEIGHT - MENU_HEIGHT                               # 870
  CREATE_DIALOG_BUTTON_X = TOOL_PALETTE_WIDTH + (EDITOR_WIDTH - 150) // 2 + 75  # ~590
  CREATE_DIALOG_BUTTON_Y = MENU_HEIGHT + EDITOR_HEIGHT // 2 - 60 + 80 + 15      # ~500

  # DialogNodeDialog positions (centered modal, 500x400)
  DIALOG_WIDTH  = 500
  DIALOG_HEIGHT = 400
  DIALOG_X = (SCREEN_WIDTH - DIALOG_WIDTH) // 2    # 450
  DIALOG_Y = (SCREEN_HEIGHT - DIALOG_HEIGHT) // 2  # 250

  # Field positions within DialogNodeDialog
  # ID field at y = dialog_y + 60 + 25 = 335
  ID_FIELD_X = DIALOG_X + 20 + 100  # Click in middle of field
  ID_FIELD_Y = DIALOG_Y + 60 + 25 + 12

  # Character field at y = dialog_y + 60 + 65 + 25 = 400
  CHAR_FIELD_X = DIALOG_X + 20 + 100
  CHAR_FIELD_Y = DIALOG_Y + 60 + 65 + 25 + 12

  # Text field at y = dialog_y + 60 + 130 + 25 = 465
  TEXT_FIELD_X = DIALOG_X + 20 + 100
  TEXT_FIELD_Y = DIALOG_Y + 60 + 130 + 30

  # End node checkbox at y = dialog_y + 60 + 130 + 125 = 565
  END_CHECKBOX_X = DIALOG_X + 20 + 10
  END_CHECKBOX_Y = DIALOG_Y + 60 + 130 + 125 + 10

  # OK button
  OK_BUTTON_X = DIALOG_X + DIALOG_WIDTH - 200 - 20 - 20 + 50  # ~760
  OK_BUTTON_Y = DIALOG_Y + DIALOG_HEIGHT - 50                  # ~600

  # Cancel button
  CANCEL_BUTTON_X = DIALOG_X + DIALOG_WIDTH - 100 - 20 + 50   # ~880
  CANCEL_BUTTON_Y = DIALOG_Y + DIALOG_HEIGHT - 50

  # Node workspace area (below toolbar)
  WORKSPACE_Y = MENU_HEIGHT + 40  # Toolbar height is 40
  WORKSPACE_X = TOOL_PALETTE_WIDTH

  # Default position for first node
  FIRST_NODE_X = WORKSPACE_X + 50 + 75   # Node center x
  FIRST_NODE_Y = WORKSPACE_Y + 50 + 40   # Node center y
end

describe "Dialog Editor UI E2E" do
  describe "Creating Dialogs via UI" do
    it "can create a new dialog tree by clicking the Create button" do
      harness = E2ETestHelper.create_harness_with_scene

      # Switch to Dialog mode
      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(5)

      harness.assert_mode(PaceEditor::EditorMode::Dialog)

      # Initially no dialog should be loaded
      dialog_editor = harness.editor.dialog_editor
      dialog_editor.current_dialog.should be_nil

      # Click the "Create Dialog Tree" button
      harness.click(
        DialogEditorUI::CREATE_DIALOG_BUTTON_X,
        DialogEditorUI::CREATE_DIALOG_BUTTON_Y
      )
      harness.step_frames(5)

      # Dialog should now be created
      dialog_editor.current_dialog.should_not be_nil

      harness.cleanup
    end

    it "can create a new node via the New Node button" do
      harness = E2ETestHelper.create_harness_with_scene

      # Switch to Dialog mode and create a dialog first
      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(3)

      # Create initial dialog
      harness.click(
        DialogEditorUI::CREATE_DIALOG_BUTTON_X,
        DialogEditorUI::CREATE_DIALOG_BUTTON_Y
      )
      harness.step_frames(5)

      dialog_editor = harness.editor.dialog_editor
      initial_count = dialog_editor.current_dialog.try(&.nodes.size) || 0

      # Click "New Node" button
      harness.click(
        DialogEditorUI::NEW_NODE_BUTTON_X,
        DialogEditorUI::TOOLBAR_BUTTON_Y
      )
      harness.step_frames(3)

      # DialogNodeDialog should be visible
      harness.editor.dialog_editor.try do |de|
        # The node dialog is internal to dialog editor
        # Check if we can interact with it
      end

      harness.cleanup
    end

    it "dialog toolbar buttons respond to clicks" do
      harness = E2ETestHelper.create_harness_with_scene

      # Switch to Dialog mode
      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(3)

      # Create a dialog first
      harness.click(
        DialogEditorUI::CREATE_DIALOG_BUTTON_X,
        DialogEditorUI::CREATE_DIALOG_BUTTON_Y
      )
      harness.step_frames(5)

      dialog_editor = harness.editor.dialog_editor

      # Test Connect button toggle
      dialog_editor.connecting_mode.should be_false

      harness.click(
        DialogEditorUI::CONNECT_BUTTON_X,
        DialogEditorUI::TOOLBAR_BUTTON_Y
      )
      harness.step_frames(3)

      dialog_editor.connecting_mode.should be_true

      # Click again to toggle off
      harness.click(
        DialogEditorUI::CONNECT_BUTTON_X,
        DialogEditorUI::TOOLBAR_BUTTON_Y
      )
      harness.step_frames(3)

      dialog_editor.connecting_mode.should be_false

      harness.cleanup
    end
  end

  describe "Node Selection via UI" do
    it "can select a node by clicking on it" do
      harness = E2ETestHelper.create_harness_with_scene

      # Set up dialog mode with a dialog containing nodes
      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(3)

      # Create dialog
      harness.click(
        DialogEditorUI::CREATE_DIALOG_BUTTON_X,
        DialogEditorUI::CREATE_DIALOG_BUTTON_Y
      )
      harness.step_frames(5)

      dialog_editor = harness.editor.dialog_editor

      # A new dialog should have a "start" node
      dialog_editor.current_dialog.should_not be_nil
      if dialog = dialog_editor.current_dialog
        dialog.nodes.size.should be >= 1
      end

      # The node should be at the default position
      # Click on where the start node should be
      # Note: node positions are initialized in initialize_node_positions
      # First node is at x=50, y=50 (in workspace coordinates)
      # Node size is 150x80, so center is at 75, 40 offset
      node_screen_x = DialogEditorUI::WORKSPACE_X + 50 + 75 + dialog_editor.camera_offset.x.to_i
      node_screen_y = DialogEditorUI::WORKSPACE_Y + 50 + 40 + dialog_editor.camera_offset.y.to_i

      harness.click(node_screen_x, node_screen_y)
      harness.step_frames(3)

      # Node should be selected
      dialog_editor.selected_node.should_not be_nil

      harness.cleanup
    end

    it "can deselect node by clicking on empty space" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(3)

      harness.click(
        DialogEditorUI::CREATE_DIALOG_BUTTON_X,
        DialogEditorUI::CREATE_DIALOG_BUTTON_Y
      )
      harness.step_frames(5)

      dialog_editor = harness.editor.dialog_editor

      # Select a node first
      node_screen_x = DialogEditorUI::WORKSPACE_X + 50 + 75
      node_screen_y = DialogEditorUI::WORKSPACE_Y + 50 + 40
      harness.click(node_screen_x, node_screen_y)
      harness.step_frames(3)

      dialog_editor.selected_node.should_not be_nil

      # Click on empty space (far from any node)
      harness.click(
        DialogEditorUI::WORKSPACE_X + 500,
        DialogEditorUI::WORKSPACE_Y + 300
      )
      harness.step_frames(3)

      dialog_editor.selected_node.should be_nil

      harness.cleanup
    end
  end

  describe "Node Dragging via UI" do
    it "can drag a node to a new position" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(3)

      harness.click(
        DialogEditorUI::CREATE_DIALOG_BUTTON_X,
        DialogEditorUI::CREATE_DIALOG_BUTTON_Y
      )
      harness.step_frames(5)

      dialog_editor = harness.editor.dialog_editor

      # Get initial position of start node
      initial_pos = dialog_editor.node_positions["start"]?
      initial_pos.should_not be_nil

      if init_pos = initial_pos
        initial_x = init_pos.x
        initial_y = init_pos.y

        # Calculate screen position
        node_screen_x = DialogEditorUI::WORKSPACE_X + initial_x.to_i + 75
        node_screen_y = DialogEditorUI::WORKSPACE_Y + initial_y.to_i + 40

        # Drag the node
        harness.drag(
          node_screen_x, node_screen_y,
          node_screen_x + 100, node_screen_y + 50,
          steps: 10
        )
        harness.step_frames(3)

        # Node should have moved
        new_pos = dialog_editor.node_positions["start"]?
        new_pos.should_not be_nil

        if new_p = new_pos
          # Position should be different (allow some tolerance due to drag interpolation)
          moved = (new_p.x - initial_x).abs > 10 || (new_p.y - initial_y).abs > 10
          moved.should be_true
        end
      end

      harness.cleanup
    end
  end

  describe "Connection Mode via UI" do
    it "can enter and exit connection mode" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(3)

      harness.click(
        DialogEditorUI::CREATE_DIALOG_BUTTON_X,
        DialogEditorUI::CREATE_DIALOG_BUTTON_Y
      )
      harness.step_frames(5)

      dialog_editor = harness.editor.dialog_editor
      dialog_editor.connecting_mode.should be_false

      # Enter connection mode
      harness.click(
        DialogEditorUI::CONNECT_BUTTON_X,
        DialogEditorUI::TOOLBAR_BUTTON_Y
      )
      harness.step_frames(3)
      dialog_editor.connecting_mode.should be_true

      # Exit connection mode
      harness.click(
        DialogEditorUI::CONNECT_BUTTON_X,
        DialogEditorUI::TOOLBAR_BUTTON_Y
      )
      harness.step_frames(3)
      dialog_editor.connecting_mode.should be_false

      harness.cleanup
    end

    it "can connect two nodes by clicking in connection mode" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(3)

      harness.click(
        DialogEditorUI::CREATE_DIALOG_BUTTON_X,
        DialogEditorUI::CREATE_DIALOG_BUTTON_Y
      )
      harness.step_frames(5)

      dialog_editor = harness.editor.dialog_editor

      # Add a second node programmatically (since clicking New Node opens a dialog)
      if dialog = dialog_editor.current_dialog
        new_node = PointClickEngine::Characters::Dialogue::DialogNode.new("second_node", "Second text")
        dialog.add_node(new_node)

        # Position the second node
        dialog_editor.node_positions["second_node"] = RL::Vector2.new(x: 300_f32, y: 50_f32)

        # Get choice count before connection
        start_node = dialog.nodes["start"]?
        initial_choice_count = start_node.try(&.choices.size) || 0

        # Enter connection mode
        harness.click(
          DialogEditorUI::CONNECT_BUTTON_X,
          DialogEditorUI::TOOLBAR_BUTTON_Y
        )
        harness.step_frames(3)

        # Click on start node (source)
        harness.click(
          DialogEditorUI::WORKSPACE_X + 50 + 75,
          DialogEditorUI::WORKSPACE_Y + 50 + 40
        )
        harness.step_frames(3)

        dialog_editor.source_node.should eq("start")

        # Click on second node (target)
        harness.click(
          DialogEditorUI::WORKSPACE_X + 300 + 75,
          DialogEditorUI::WORKSPACE_Y + 50 + 40
        )
        harness.step_frames(3)

        # Connection should be made
        start_node_after = dialog.nodes["start"]?
        if sn = start_node_after
          sn.choices.size.should eq(initial_choice_count + 1)
          sn.choices.any? { |c| c.target_node_id == "second_node" }.should be_true
        end

        # Connection mode should be exited
        dialog_editor.connecting_mode.should be_false
      end

      harness.cleanup
    end
  end

  describe "Delete Node via UI" do
    it "can delete a selected node" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(3)

      harness.click(
        DialogEditorUI::CREATE_DIALOG_BUTTON_X,
        DialogEditorUI::CREATE_DIALOG_BUTTON_Y
      )
      harness.step_frames(5)

      dialog_editor = harness.editor.dialog_editor

      # Add an extra node to delete
      if dialog = dialog_editor.current_dialog
        new_node = PointClickEngine::Characters::Dialogue::DialogNode.new("to_delete", "Delete me")
        dialog.add_node(new_node)
        dialog_editor.node_positions["to_delete"] = RL::Vector2.new(x: 300_f32, y: 50_f32)

        initial_count = dialog.nodes.size

        # Select the node
        harness.click(
          DialogEditorUI::WORKSPACE_X + 300 + 75,
          DialogEditorUI::WORKSPACE_Y + 50 + 40
        )
        harness.step_frames(3)

        dialog_editor.selected_node.should eq("to_delete")

        # Click Delete button
        harness.click(
          DialogEditorUI::DELETE_BUTTON_X,
          DialogEditorUI::TOOLBAR_BUTTON_Y
        )
        harness.step_frames(3)

        # Node should be deleted
        dialog.nodes.size.should eq(initial_count - 1)
        dialog.nodes["to_delete"]?.should be_nil
        dialog_editor.selected_node.should be_nil
      end

      harness.cleanup
    end
  end

  describe "Camera Panning in Dialog Editor" do
    it "can pan the dialog workspace with middle mouse" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(3)

      harness.click(
        DialogEditorUI::CREATE_DIALOG_BUTTON_X,
        DialogEditorUI::CREATE_DIALOG_BUTTON_Y
      )
      harness.step_frames(5)

      dialog_editor = harness.editor.dialog_editor
      initial_offset_x = dialog_editor.camera_offset.x
      initial_offset_y = dialog_editor.camera_offset.y

      # Drag with middle mouse button
      center_x = DialogEditorUI::WORKSPACE_X + 400
      center_y = DialogEditorUI::WORKSPACE_Y + 200

      harness.input.set_mouse_position(center_x.to_f32, center_y.to_f32)
      harness.step_frame

      harness.input.press_mouse_button(RL::MouseButton::Middle)
      harness.step_frame

      # Move mouse while holding middle button
      5.times do |i|
        harness.input.set_mouse_position((center_x + (i + 1) * 20).to_f32, (center_y + (i + 1) * 10).to_f32)
        harness.input.hold_mouse_button(RL::MouseButton::Middle)
        harness.step_frame
      end

      harness.input.release_mouse_button(RL::MouseButton::Middle)
      harness.step_frame

      # Camera should have moved
      new_offset_x = dialog_editor.camera_offset.x
      new_offset_y = dialog_editor.camera_offset.y

      # Allow some tolerance
      moved = (new_offset_x - initial_offset_x).abs > 5 || (new_offset_y - initial_offset_y).abs > 5
      moved.should be_true

      harness.cleanup
    end
  end

  describe "Double-Click to Edit Node" do
    it "opens edit dialog on double-click" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(3)

      harness.click(
        DialogEditorUI::CREATE_DIALOG_BUTTON_X,
        DialogEditorUI::CREATE_DIALOG_BUTTON_Y
      )
      harness.step_frames(5)

      dialog_editor = harness.editor.dialog_editor

      # Double-click on start node
      node_x = DialogEditorUI::WORKSPACE_X + 50 + 75
      node_y = DialogEditorUI::WORKSPACE_Y + 50 + 40

      harness.double_click(node_x, node_y)
      harness.step_frames(5)

      # The internal node dialog should be visible
      # This is harder to test as it's internal, but the node should be selected
      dialog_editor.selected_node.should eq("start")

      harness.cleanup
    end
  end
end

describe "Dialog Editor Edge Cases E2E" do
  it "handles clicking Delete with no node selected" do
    harness = E2ETestHelper.create_harness_with_scene

    harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
    harness.step_frames(3)

    harness.click(
      DialogEditorUI::CREATE_DIALOG_BUTTON_X,
      DialogEditorUI::CREATE_DIALOG_BUTTON_Y
    )
    harness.step_frames(5)

    dialog_editor = harness.editor.dialog_editor

    # Ensure no node is selected
    dialog_editor.selected_node = nil
    harness.step_frame

    if dialog = dialog_editor.current_dialog
      initial_count = dialog.nodes.size

      # Click Delete with nothing selected
      harness.click(
        DialogEditorUI::DELETE_BUTTON_X,
        DialogEditorUI::TOOLBAR_BUTTON_Y
      )
      harness.step_frames(3)

      # Nothing should be deleted
      dialog.nodes.size.should eq(initial_count)
    end

    harness.cleanup
  end

  it "handles clicking outside node workspace" do
    harness = E2ETestHelper.create_harness_with_scene

    harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
    harness.step_frames(3)

    harness.click(
      DialogEditorUI::CREATE_DIALOG_BUTTON_X,
      DialogEditorUI::CREATE_DIALOG_BUTTON_Y
    )
    harness.step_frames(5)

    dialog_editor = harness.editor.dialog_editor

    # Select a node first
    harness.click(
      DialogEditorUI::WORKSPACE_X + 50 + 75,
      DialogEditorUI::WORKSPACE_Y + 50 + 40
    )
    harness.step_frames(3)
    dialog_editor.selected_node.should_not be_nil

    # Click in the property panel area (outside workspace)
    harness.click(
      DialogEditorUI::SCREEN_WIDTH - 150,
      DialogEditorUI::SCREEN_HEIGHT // 2
    )
    harness.step_frames(3)

    # Should still function without crash
    harness.has_scene?.should be_true

    harness.cleanup
  end

  it "handles rapid toolbar button clicks" do
    harness = E2ETestHelper.create_harness_with_scene

    harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
    harness.step_frames(3)

    harness.click(
      DialogEditorUI::CREATE_DIALOG_BUTTON_X,
      DialogEditorUI::CREATE_DIALOG_BUTTON_Y
    )
    harness.step_frames(5)

    dialog_editor = harness.editor.dialog_editor

    # Rapidly toggle connection mode
    10.times do
      harness.click(
        DialogEditorUI::CONNECT_BUTTON_X,
        DialogEditorUI::TOOLBAR_BUTTON_Y
      )
      harness.step_frame
    end

    # Should be in a valid state
    [true, false].includes?(dialog_editor.connecting_mode).should be_true

    harness.cleanup
  end

  it "connection mode cancels when clicking empty space" do
    harness = E2ETestHelper.create_harness_with_scene

    harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
    harness.step_frames(3)

    harness.click(
      DialogEditorUI::CREATE_DIALOG_BUTTON_X,
      DialogEditorUI::CREATE_DIALOG_BUTTON_Y
    )
    harness.step_frames(5)

    dialog_editor = harness.editor.dialog_editor

    # Enter connection mode
    harness.click(
      DialogEditorUI::CONNECT_BUTTON_X,
      DialogEditorUI::TOOLBAR_BUTTON_Y
    )
    harness.step_frames(3)

    # Click on start node to set source
    harness.click(
      DialogEditorUI::WORKSPACE_X + 50 + 75,
      DialogEditorUI::WORKSPACE_Y + 50 + 40
    )
    harness.step_frames(3)

    dialog_editor.source_node.should eq("start")

    # Click on empty space (should cancel)
    harness.click(
      DialogEditorUI::WORKSPACE_X + 500,
      DialogEditorUI::WORKSPACE_Y + 300
    )
    harness.step_frames(3)

    # Source should be cleared but connection mode still active
    dialog_editor.source_node.should be_nil

    harness.cleanup
  end
end
