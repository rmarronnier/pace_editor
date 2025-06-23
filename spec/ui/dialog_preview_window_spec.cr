require "../spec_helper"
require "../../src/pace_editor/ui/dialog_preview_window"

describe PaceEditor::UI::DialogPreviewWindow do
  describe "#show" do
    it "shows the preview window with a dialog tree" do
      state = PaceEditor::Core::EditorState.new
      preview_window = PaceEditor::UI::DialogPreviewWindow.new(state)
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")

      # Create a simple dialog tree
      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello!")
      start_node.character_name = "NPC"
      dialog_tree.add_node(start_node)
      dialog_tree.current_node_id = "start"

      preview_window.visible.should be_false
      preview_window.show(dialog_tree)
      preview_window.visible.should be_true
    end

    it "resets conversation state when showing new dialog" do
      state = PaceEditor::Core::EditorState.new
      preview_window = PaceEditor::UI::DialogPreviewWindow.new(state)
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")

      # Create dialog with choice
      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Choose your path")
      start_node.character_name = "Guide"

      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Go left", "left_path")
      start_node.choices << choice

      dialog_tree.add_node(start_node)
      dialog_tree.current_node_id = "start"

      preview_window.show(dialog_tree)
      preview_window.visible.should be_true
    end
  end

  describe "#hide" do
    it "hides the preview window" do
      state = PaceEditor::Core::EditorState.new
      preview_window = PaceEditor::UI::DialogPreviewWindow.new(state)
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")

      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello!")
      dialog_tree.add_node(start_node)
      dialog_tree.current_node_id = "start"

      preview_window.show(dialog_tree)
      preview_window.visible.should be_true

      preview_window.hide
      preview_window.visible.should be_false
    end
  end

  describe "dialog navigation" do
    it "handles simple conversation flow" do
      state = PaceEditor::Core::EditorState.new
      preview_window = PaceEditor::UI::DialogPreviewWindow.new(state)
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")

      # Create a dialog chain: start -> middle -> end
      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Welcome!")
      start_node.character_name = "NPC"

      middle_node = PointClickEngine::Characters::Dialogue::DialogNode.new("middle", "How are you?")
      middle_node.character_name = "NPC"

      end_node = PointClickEngine::Characters::Dialogue::DialogNode.new("end", "Goodbye!")
      end_node.character_name = "NPC"
      end_node.is_end = true

      # Add choice from start to middle
      choice1 = PointClickEngine::Characters::Dialogue::DialogChoice.new("I'm fine", "middle")
      start_node.choices << choice1

      # Add choice from middle to end
      choice2 = PointClickEngine::Characters::Dialogue::DialogChoice.new("See you later", "end")
      middle_node.choices << choice2

      dialog_tree.add_node(start_node)
      dialog_tree.add_node(middle_node)
      dialog_tree.add_node(end_node)
      dialog_tree.current_node_id = "start"

      preview_window.show(dialog_tree)
      preview_window.visible.should be_true

      # Test that we can show the dialog without errors
      # In a real test, we'd simulate user interaction
    end
  end

  describe "error handling" do
    it "handles empty dialog trees gracefully" do
      state = PaceEditor::Core::EditorState.new
      preview_window = PaceEditor::UI::DialogPreviewWindow.new(state)
      empty_dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("empty")

      preview_window.show(empty_dialog)
      preview_window.visible.should be_true
      # Should not crash even with no start node
    end

    it "handles missing target nodes" do
      state = PaceEditor::Core::EditorState.new
      preview_window = PaceEditor::UI::DialogPreviewWindow.new(state)
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")

      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Choose")

      # Add choice pointing to non-existent node
      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Bad choice", "nonexistent")
      start_node.choices << choice

      dialog_tree.add_node(start_node)
      dialog_tree.current_node_id = "start"

      preview_window.show(dialog_tree)
      preview_window.visible.should be_true
      # Should handle missing target node gracefully
    end
  end
end
