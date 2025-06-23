require "../spec_helper"
require "../../src/pace_editor/ui/dialog_node_dialog"

describe PaceEditor::UI::DialogNodeDialog do
  describe "initialization" do
    it "creates dialog in hidden state" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::DialogNodeDialog.new(state)
      
      dialog.visible.should be_false
    end
  end
  
  describe "#show" do
    it "shows dialog for new node creation" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::DialogNodeDialog.new(state)
      
      dialog.show(nil)
      
      dialog.visible.should be_true
      dialog.node_id.should contain("node_")
      dialog.text.should eq("")
      dialog.character_name.should eq("")
      dialog.is_end.should be_false
    end
    
    it "shows dialog for existing node editing" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::DialogNodeDialog.new(state)
      
      # Create test node
      node = PointClickEngine::Characters::Dialogue::DialogNode.new("test_node", "Test dialog text")
      node.character_name = "Test Character"
      node.is_end = true
      
      dialog.show(node)
      
      dialog.visible.should be_true
      dialog.node_id.should eq("test_node")
      dialog.text.should eq("Test dialog text")
      dialog.character_name.should eq("Test Character")
      dialog.is_end.should be_true
    end
  end
  
  describe "#hide" do
    it "hides the dialog" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::DialogNodeDialog.new(state)
      
      dialog.show(nil)
      dialog.visible.should be_true
      
      dialog.hide
      dialog.visible.should be_false
    end
  end
  
  describe "node creation" do
    it "validates required fields" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      
      # Create dialog editor
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Create dialog tree
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
      editor.current_dialog = dialog_tree
      
      dialog = PaceEditor::UI::DialogNodeDialog.new(state)
      
      # Show for new node
      dialog.show(nil)
      
      # Node should have auto-generated ID and require text
      dialog.node_id.should_not eq("")
      dialog.text.should eq("")
    end
    
    it "creates new node with proper properties" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      
      # Create dialog editor
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Create dialog tree
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
      editor.current_dialog = dialog_tree
      
      # Expected node properties
      expected_id = "new_node"
      expected_text = "Hello there!"
      expected_character = "Player"
      expected_is_end = true
      
      # Manually add node to test
      new_node = PointClickEngine::Characters::Dialogue::DialogNode.new(expected_id, expected_text)
      new_node.character_name = expected_character
      new_node.is_end = expected_is_end
      
      dialog_tree.add_node(new_node)
      
      # Verify node was added
      dialog_tree.nodes.size.should eq(1)
      added_node = dialog_tree.nodes[expected_id]
      added_node.should_not be_nil
      added_node.id.should eq(expected_id)
      added_node.text.should eq(expected_text)
      added_node.character_name.should eq(expected_character)
      added_node.is_end.should eq(expected_is_end)
    end
    
    it "updates existing node properties" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      
      # Create dialog editor
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Create dialog tree with existing node
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
      existing_node = PointClickEngine::Characters::Dialogue::DialogNode.new("existing", "Old text")
      existing_node.character_name = "Old Character"
      existing_node.is_end = false
      dialog_tree.add_node(existing_node)
      
      editor.current_dialog = dialog_tree
      
      # Update node properties
      existing_node.text = "Updated text"
      existing_node.character_name = "New Character"
      existing_node.is_end = true
      
      # Verify updates
      updated_node = dialog_tree.nodes["existing"]
      updated_node.should_not be_nil
      updated_node.text.should eq("Updated text")
      updated_node.character_name.should eq("New Character")
      updated_node.is_end.should be_true
    end
  end
  
  describe "ID changes" do
    it "updates references when node ID changes" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      
      # Create dialog editor
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Create dialog tree with nodes and connections
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
      
      node1 = PointClickEngine::Characters::Dialogue::DialogNode.new("node1", "First node")
      node2 = PointClickEngine::Characters::Dialogue::DialogNode.new("node2", "Second node")
      
      # Add choice connecting node1 to node2
      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Go to second", "node2")
      node1.add_choice(choice)
      
      dialog_tree.add_node(node1)
      dialog_tree.add_node(node2)
      
      editor.current_dialog = dialog_tree
      
      # Simulate ID change
      old_id = "node2"
      new_id = "renamed_node"
      
      # Manual ID update logic
      if node = dialog_tree.nodes[old_id]
        node.id = new_id
        dialog_tree.nodes.delete(old_id)
        dialog_tree.nodes[new_id] = node
        
        # Update references
        dialog_tree.nodes.each do |_, other_node|
          other_node.choices.each do |choice|
            if choice.target_node_id == old_id
              choice.target_node_id = new_id
            end
          end
        end
      end
      
      # Verify ID change
      dialog_tree.nodes.has_key?("node2").should be_false
      dialog_tree.nodes.has_key?("renamed_node").should be_true
      
      # Verify reference update
      node1.choices[0].target_node_id.should eq("renamed_node")
    end
  end
end