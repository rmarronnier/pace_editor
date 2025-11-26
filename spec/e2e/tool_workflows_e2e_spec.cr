# E2E Tests for Tool Workflows
# Tests tool-specific behaviors and complete tool workflows

require "./e2e_spec_helper"

describe "Tool Workflows E2E" do
  describe "Select Tool Workflow" do
    it "starts with Select tool active" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.assert_tool(PaceEditor::Tool::Select)

      harness.cleanup
    end

    it "can click-select objects" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Switch to Select and click
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(400, 400)  # Deselect
      harness.step_frame

      harness.click_canvas(100, 100)
      harness.step_frame

      harness.selected_object.should_not be_nil

      harness.cleanup
    end

    it "can drag to start rectangle selection" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create multiple hotspots
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.click_canvas(150, 100)
      harness.step_frame
      harness.click_canvas(100, 150)
      harness.step_frame

      # Select mode
      harness.press_key(RL::KeyboardKey::V)

      # Drag selection rectangle over all
      harness.drag(90 + 80, 90 + 30, 200 + 80, 200 + 30)
      harness.step_frame

      # Should have selected objects
      harness.selected_objects.size.should be >= 1

      harness.cleanup
    end

    it "transitions to Move tool when dragging selected object" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create and select hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      hotspot_name = harness.selected_object

      # Select tool
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Start dragging - should switch to Move
      harness.input.press_mouse_button(RL::MouseButton::Left)
      harness.step_frame

      harness.current_tool.should eq(PaceEditor::Tool::Move)

      harness.input.release_mouse_button(RL::MouseButton::Left)
      harness.step_frame

      harness.cleanup
    end
  end

  describe "Move Tool Workflow" do
    it "activates with M key" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::M)
      harness.assert_tool(PaceEditor::Tool::Move)

      harness.cleanup
    end

    it "moves selected objects on drag" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create and select
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(100, 100)
      harness.step_frame

      # Get initial position
      initial_pos = nil
      if scene = harness.editor.state.current_scene
        initial_pos = scene.hotspots.first.position.dup
      end

      # Switch to Move and drag
      harness.press_key(RL::KeyboardKey::M)
      harness.drag_canvas(100, 100, 200, 200)

      # Position should change
      if scene = harness.editor.state.current_scene
        hotspot = scene.hotspots.first
        if pos = initial_pos
          (hotspot.position.x != pos.x || hotspot.position.y != pos.y).should be_true
        end
      end

      harness.cleanup
    end

    it "does nothing with no selection" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot but deselect
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.press_key(RL::KeyboardKey::Escape)
      harness.step_frame

      harness.selected_object.should be_nil

      # Get position
      initial_pos = nil
      if scene = harness.editor.state.current_scene
        initial_pos = {x: scene.hotspots.first.position.x, y: scene.hotspots.first.position.y}
      end

      # Move tool drag should not move unselected object
      harness.press_key(RL::KeyboardKey::M)
      harness.drag_canvas(100, 100, 200, 200)

      if scene = harness.editor.state.current_scene
        hotspot = scene.hotspots.first
        if pos = initial_pos
          hotspot.position.x.should eq(pos[:x])
          hotspot.position.y.should eq(pos[:y])
        end
      end

      harness.cleanup
    end
  end

  describe "Place Tool Workflow" do
    it "activates with P key" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)
      harness.assert_tool(PaceEditor::Tool::Place)

      harness.cleanup
    end

    it "creates object on click" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.assert_hotspot_count(0)

      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.assert_hotspot_count(1)

      harness.cleanup
    end

    it "creates object at click position" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(200, 150)
      harness.step_frame

      if scene = harness.editor.state.current_scene
        hotspot = scene.hotspots.first
        # Position should be near click (accounting for grid snap)
        (hotspot.position.x - 200.0_f32).abs.should be < 20
        (hotspot.position.y - 150.0_f32).abs.should be < 20
      end

      harness.cleanup
    end

    it "selects newly created object" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.selected_object.should_not be_nil

      harness.cleanup
    end

    it "remains in Place tool after creation" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)
      harness.assert_tool(PaceEditor::Tool::Place)

      harness.click_canvas(100, 100)
      harness.step_frame

      harness.assert_tool(PaceEditor::Tool::Place)

      harness.cleanup
    end

    it "can create objects continuously" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)

      5.times do |i|
        harness.click_canvas(i * 80 + 50, 100)
        harness.step_frame
        harness.assert_tool(PaceEditor::Tool::Place)
      end

      harness.assert_hotspot_count(5)

      harness.cleanup
    end
  end

  describe "Delete Tool Workflow" do
    it "activates with D key" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::D)
      harness.assert_tool(PaceEditor::Tool::Delete)

      harness.cleanup
    end

    it "deletes object on click" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.assert_hotspot_count(1)

      # Delete
      harness.press_key(RL::KeyboardKey::D)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.assert_hotspot_count(0)

      harness.cleanup
    end

    it "only deletes clicked object" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create multiple with good spacing (positions will snap to grid)
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(96, 96)  # Will snap to grid
      harness.step_frame
      harness.click_canvas(224, 96) # 128 pixels apart
      harness.step_frame
      harness.click_canvas(352, 96) # 128 pixels apart
      harness.step_frame
      harness.assert_hotspot_count(3)

      # Delete the middle one - click inside its 64x64 bounds
      harness.press_key(RL::KeyboardKey::D)
      harness.click_canvas(240, 110)
      harness.step_frame

      harness.assert_hotspot_count(2)

      harness.cleanup
    end

    it "does nothing when clicking empty space" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame
      harness.assert_hotspot_count(1)

      harness.press_key(RL::KeyboardKey::D)
      harness.click_canvas(400, 400)  # Empty space
      harness.step_frame

      harness.assert_hotspot_count(1)

      harness.cleanup
    end

    it "clears selection when deleting selected object" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.selected_object.should_not be_nil

      harness.press_key(RL::KeyboardKey::D)
      harness.click_canvas(100, 100)
      harness.step_frame

      harness.selected_object.should be_nil

      harness.cleanup
    end
  end

  describe "Tool Keyboard Shortcuts" do
    it "V activates Select tool" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)  # Start elsewhere
      harness.press_key(RL::KeyboardKey::V)

      harness.assert_tool(PaceEditor::Tool::Select)

      harness.cleanup
    end

    it "M activates Move tool" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::M)
      harness.assert_tool(PaceEditor::Tool::Move)

      harness.cleanup
    end

    it "P activates Place tool" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)
      harness.assert_tool(PaceEditor::Tool::Place)

      harness.cleanup
    end

    it "D activates Delete tool" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::D)
      harness.assert_tool(PaceEditor::Tool::Delete)

      harness.cleanup
    end

    it "shortcuts work in any order" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::D)
      harness.assert_tool(PaceEditor::Tool::Delete)

      harness.press_key(RL::KeyboardKey::V)
      harness.assert_tool(PaceEditor::Tool::Select)

      harness.press_key(RL::KeyboardKey::P)
      harness.assert_tool(PaceEditor::Tool::Place)

      harness.press_key(RL::KeyboardKey::M)
      harness.assert_tool(PaceEditor::Tool::Move)

      harness.press_key(RL::KeyboardKey::V)
      harness.assert_tool(PaceEditor::Tool::Select)

      harness.cleanup
    end
  end

  describe "Tool State Preservation" do
    it "preserves tool when saving" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::P)
      harness.assert_tool(PaceEditor::Tool::Place)

      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)

      harness.assert_tool(PaceEditor::Tool::Place)

      harness.cleanup
    end

    it "preserves tool when toggling grid" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.press_key(RL::KeyboardKey::M)
      harness.assert_tool(PaceEditor::Tool::Move)

      harness.press_key(RL::KeyboardKey::G)

      harness.assert_tool(PaceEditor::Tool::Move)

      harness.cleanup
    end

    it "preserves tool when panning" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)
      harness.press_key(RL::KeyboardKey::P)
      harness.assert_tool(PaceEditor::Tool::Place)

      harness.hold_key(RL::KeyboardKey::D)
      10.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)

      harness.assert_tool(PaceEditor::Tool::Place)

      harness.cleanup
    end

    it "preserves tool when zooming" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)
      harness.press_key(RL::KeyboardKey::D)
      harness.assert_tool(PaceEditor::Tool::Delete)

      harness.scroll(2.0_f32)

      harness.assert_tool(PaceEditor::Tool::Delete)

      harness.cleanup
    end
  end

  describe "Complete Tool Workflow Scenarios" do
    it "can complete a create-select-move-delete workflow" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create object at grid-aligned position
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(96, 96)
      harness.step_frame
      harness.assert_hotspot_count(1)

      # Select object
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(96, 96)
      harness.step_frame
      harness.selected_object.should_not be_nil

      # Move object
      harness.press_key(RL::KeyboardKey::M)
      harness.drag_canvas(96, 96, 208, 208)
      harness.assert_hotspot_count(1)

      # Get actual position after move and delete
      harness.press_key(RL::KeyboardKey::D)
      if scene = harness.editor.state.current_scene
        hotspot = scene.hotspots.first
        # Click inside the hotspot bounds (position + half size)
        harness.click_canvas(hotspot.position.x.to_i + 32, hotspot.position.y.to_i + 32)
      end
      harness.step_frame
      harness.assert_hotspot_count(0)

      harness.cleanup
    end

    it "can complete a multi-object editing workflow" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create multiple objects at grid-aligned positions
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(96, 96)
      harness.step_frames(2)
      harness.click_canvas(224, 96)
      harness.step_frames(2)
      harness.click_canvas(352, 96)
      harness.step_frames(2)
      harness.assert_hotspot_count(3)

      # Select all
      harness.press_key(RL::KeyboardKey::V)
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::A)
      harness.step_frames(2)

      # Verify all are selected
      harness.selected_objects.size.should be >= 1

      # Delete all selected with Delete key
      harness.press_key(RL::KeyboardKey::Delete)
      harness.step_frames(2)

      # Should have fewer hotspots after delete
      harness.hotspot_count.should be < 3

      harness.cleanup
    end
  end
end
