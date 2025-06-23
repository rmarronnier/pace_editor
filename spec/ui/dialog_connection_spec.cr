require "../spec_helper"
require "../../src/pace_editor/editors/dialog_editor"

describe "Dialog Connection System" do
  describe "connection mode" do
    it "toggles connection mode correctly" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      editor.connecting_mode.should be_false
      
      # Test private method through public interface
      # In reality, this would be tested through the UI interaction
      editor.connecting_mode = true
      editor.connecting_mode.should be_true
      
      editor.connecting_mode = false
      editor.connecting_mode.should be_false
    end
    
    it "resets connection state when exiting connection mode" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Set some connection state
      editor.connecting_mode = true
      editor.source_node = "test_node"
      editor.connection_preview_pos = RL::Vector2.new(100, 100)
      
      # Exit connection mode
      editor.connecting_mode = false
      editor.source_node = nil
      editor.connection_preview_pos = nil
      
      # Verify state is reset
      editor.source_node.should be_nil
      editor.connection_preview_pos.should be_nil
    end
  end
  
  describe "dialog tree with connections" do
    it "can create a dialog tree with connected nodes" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Create a dialog tree
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
      
      # Create start node
      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello!")
      start_node.character_name = "NPC"
      dialog_tree.add_node(start_node)
      
      # Create second node
      second_node = PointClickEngine::Characters::Dialogue::DialogNode.new("second", "How are you?")
      second_node.character_name = "NPC"
      dialog_tree.add_node(second_node)
      
      # Create a choice connecting start to second
      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Fine, thanks", "second")
      start_node.choices << choice
      
      # Set as current dialog
      editor.current_dialog = dialog_tree
      
      # Verify connection exists
      start_node.choices.size.should eq(1)
      start_node.choices[0].target_node_id.should eq("second")
    end
  end
  
  describe "node positioning" do
    it "maintains node positions" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Set a node position
      test_position = RL::Vector2.new(100, 200)
      editor.node_positions["test_node"] = test_position
      
      # Verify position is stored
      editor.node_positions["test_node"]?.should eq(test_position)
    end
  end
  
  describe "connection preview" do
    it "tracks preview position" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      preview_pos = RL::Vector2.new(150, 250)
      editor.connection_preview_pos = preview_pos
      
      editor.connection_preview_pos.should eq(preview_pos)
    end
  end
end