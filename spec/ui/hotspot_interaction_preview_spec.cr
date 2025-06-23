require "../spec_helper"
require "../../src/pace_editor/ui/hotspot_interaction_preview"

describe PaceEditor::UI::HotspotInteractionPreview do
  describe "#show" do
    it "shows the preview window with hotspot data" do
      state = PaceEditor::Core::EditorState.new
      preview = PaceEditor::UI::HotspotInteractionPreview.new(state)

      # Create a test hotspot
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(100.0_f32, 200.0_f32),
        RL::Vector2.new(64.0_f32, 64.0_f32)
      )
      hotspot.description = "A test hotspot"
      hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand

      preview.visible.should be_false
      preview.show(hotspot)
      preview.visible.should be_true
    end

    it "shows preview with hotspot action data" do
      state = PaceEditor::Core::EditorState.new
      preview = PaceEditor::UI::HotspotInteractionPreview.new(state)

      # Create a test hotspot
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "interactive_hotspot",
        RL::Vector2.new(150.0_f32, 250.0_f32),
        RL::Vector2.new(32.0_f32, 32.0_f32)
      )
      hotspot.description = "An interactive hotspot with actions"
      hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Look

      # Create hotspot action data
      hotspot_data = PaceEditor::Models::HotspotData.new
      show_message_action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::ShowMessage
      )
      show_message_action.parameters["message"] = "Hello, world!"
      hotspot_data.add_action("on_click", show_message_action)

      preview.show(hotspot, hotspot_data)
      preview.visible.should be_true
    end
  end

  describe "#hide" do
    it "hides the preview window" do
      state = PaceEditor::Core::EditorState.new
      preview = PaceEditor::UI::HotspotInteractionPreview.new(state)

      # Create and show hotspot
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(100.0_f32, 200.0_f32),
        RL::Vector2.new(64.0_f32, 64.0_f32)
      )

      preview.show(hotspot)
      preview.visible.should be_true

      preview.hide
      preview.visible.should be_false
    end
  end

  describe "hotspot action simulation" do
    it "handles different action types" do
      state = PaceEditor::Core::EditorState.new
      preview = PaceEditor::UI::HotspotInteractionPreview.new(state)

      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "multi_action_hotspot",
        RL::Vector2.new(100.0_f32, 200.0_f32),
        RL::Vector2.new(64.0_f32, 64.0_f32)
      )

      # Create hotspot data with multiple action types
      hotspot_data = PaceEditor::Models::HotspotData.new

      # Show message action
      message_action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::ShowMessage
      )
      message_action.parameters["message"] = "Test message"
      hotspot_data.add_action("on_look", message_action)

      # Change scene action
      scene_action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::ChangeScene
      )
      scene_action.parameters["scene"] = "next_room"
      scene_action.parameters["entry_point"] = "door"
      hotspot_data.add_action("on_click", scene_action)

      # Set variable action
      variable_action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::SetVariable
      )
      variable_action.parameters["variable"] = "test_var"
      variable_action.parameters["value"] = "test_value"
      hotspot_data.add_action("on_use", variable_action)

      preview.show(hotspot, hotspot_data)
      preview.visible.should be_true

      # Test that the preview can handle different action types
      # In a real test, we would simulate interactions and check the log
    end
  end

  describe "cursor type display" do
    it "shows different cursor types correctly" do
      state = PaceEditor::Core::EditorState.new
      preview = PaceEditor::UI::HotspotInteractionPreview.new(state)

      cursor_types = [
        PointClickEngine::Scenes::Hotspot::CursorType::Default,
        PointClickEngine::Scenes::Hotspot::CursorType::Hand,
        PointClickEngine::Scenes::Hotspot::CursorType::Look,
        PointClickEngine::Scenes::Hotspot::CursorType::Talk,
        PointClickEngine::Scenes::Hotspot::CursorType::Use,
      ]

      cursor_types.each do |cursor_type|
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "cursor_test_#{cursor_type}",
          RL::Vector2.new(100.0_f32, 200.0_f32),
          RL::Vector2.new(64.0_f32, 64.0_f32)
        )
        hotspot.cursor_type = cursor_type

        preview.show(hotspot)
        preview.visible.should be_true
        preview.hide
      end
    end
  end

  describe "error handling" do
    it "handles hotspots without action data gracefully" do
      state = PaceEditor::Core::EditorState.new
      preview = PaceEditor::UI::HotspotInteractionPreview.new(state)

      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "no_data_hotspot",
        RL::Vector2.new(100.0_f32, 200.0_f32),
        RL::Vector2.new(64.0_f32, 64.0_f32)
      )

      # Show without hotspot data (should not crash)
      preview.show(hotspot, nil)
      preview.visible.should be_true
    end

    it "handles empty action lists" do
      state = PaceEditor::Core::EditorState.new
      preview = PaceEditor::UI::HotspotInteractionPreview.new(state)

      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "empty_actions_hotspot",
        RL::Vector2.new(100.0_f32, 200.0_f32),
        RL::Vector2.new(64.0_f32, 64.0_f32)
      )

      # Create empty hotspot data
      hotspot_data = PaceEditor::Models::HotspotData.new

      preview.show(hotspot, hotspot_data)
      preview.visible.should be_true
    end
  end
end
