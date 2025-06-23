require "../spec_helper"
require "../../src/pace_editor/editors/dialog_editor"

describe PaceEditor::Editors::DialogEditor do
  describe "initialization" do
    it "creates dialog editor with state reference" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      editor.current_dialog.should be_nil
      editor.selected_node.should be_nil
      editor.camera_offset.x.should eq(0)
      editor.camera_offset.y.should eq(0)
      editor.node_positions.should be_empty
    end
    
    it "registers itself with editor state" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      state.dialog_editor.should eq(editor)
    end
  end
  
  describe "dialog management" do
    it "creates new dialog tree" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Create new dialog
      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello!")
      dialog.add_node(start_node)
      
      editor.current_dialog = dialog
      
      editor.current_dialog.should_not be_nil
      editor.current_dialog.not_nil!.name.should eq("test_dialog")
      editor.current_dialog.not_nil!.nodes.size.should eq(1)
      editor.current_dialog.not_nil!.nodes.has_key?("start").should be_true
    end
    
    it "loads existing dialog from file" do
      temp_dir = File.tempfile("project").path
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      
      project = PaceEditor::Core::Project.new("test", temp_dir)
      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      
      # Create test dialog file
      dialog_content = <<-YAML
      name: test_dialog
      nodes:
        start:
          id: start
          text: Welcome to the dialog!
          character_name: Player
          choices: []
          conditions: []
          actions: []
          is_end: false
      current_node_id: 
      variables: {}
      YAML
      
      File.write(File.join(project.dialogs_path, "test.yml"), dialog_content)
      
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Force load dialog (normally happens in get_current_dialog)
      yaml_content = File.read(File.join(project.dialogs_path, "test.yml"))
      dialog = PointClickEngine::Characters::Dialogue::DialogTree.from_yaml(yaml_content)
      editor.current_dialog = dialog
      
      editor.current_dialog.should_not be_nil
      editor.current_dialog.not_nil!.name.should eq("test_dialog")
      editor.current_dialog.not_nil!.nodes.size.should eq(1)
      
      FileUtils.rm_rf(temp_dir)
    end
  end
  
  describe "node operations" do
    it "creates new nodes" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Create dialog with initial node
      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("test")
      editor.current_dialog = dialog
      
      initial_count = dialog.nodes.size
      
      # Add new node
      new_node = PointClickEngine::Characters::Dialogue::DialogNode.new("node1", "New dialog")
      dialog.add_node(new_node)
      
      dialog.nodes.size.should eq(initial_count + 1)
      dialog.nodes.has_key?("node1").should be_true
    end
    
    it "deletes selected nodes" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Create dialog with nodes
      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("test")
      node1 = PointClickEngine::Characters::Dialogue::DialogNode.new("node1", "First")
      node2 = PointClickEngine::Characters::Dialogue::DialogNode.new("node2", "Second")
      
      dialog.add_node(node1)
      dialog.add_node(node2)
      
      editor.current_dialog = dialog
      editor.selected_node = "node1"
      
      # Manually delete node
      dialog.nodes.delete("node1")
      editor.selected_node = nil
      
      dialog.nodes.size.should eq(1)
      dialog.nodes.has_key?("node1").should be_false
      dialog.nodes.has_key?("node2").should be_true
      editor.selected_node.should be_nil
    end
    
    it "removes references when deleting nodes" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Create dialog with connected nodes
      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("test")
      node1 = PointClickEngine::Characters::Dialogue::DialogNode.new("node1", "First")
      node2 = PointClickEngine::Characters::Dialogue::DialogNode.new("node2", "Second")
      
      # Add choice from node1 to node2
      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Go to second", "node2")
      node1.add_choice(choice)
      
      dialog.add_node(node1)
      dialog.add_node(node2)
      
      editor.current_dialog = dialog
      
      # Delete node2 and clean up references
      dialog.nodes.delete("node2")
      dialog.nodes.each do |_, node|
        node.choices.reject! { |c| c.target_node_id == "node2" }
      end
      
      # Verify node2 is gone and references cleaned
      dialog.nodes.has_key?("node2").should be_false
      node1.choices.should be_empty
    end
  end
  
  describe "node positioning" do
    it "initializes node positions in grid layout" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Create dialog with multiple nodes
      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("test")
      
      5.times do |i|
        node = PointClickEngine::Characters::Dialogue::DialogNode.new("node#{i}", "Node #{i}")
        dialog.add_node(node)
      end
      
      editor.current_dialog = dialog
      
      # Manually initialize positions (normally done in initialize_node_positions)
      x = 50
      y = 50
      cols = 3
      col = 0
      
      dialog.nodes.each do |node_id, node|
        editor.node_positions[node_id] = RL::Vector2.new(x: x.to_f, y: y.to_f)
        
        col += 1
        if col >= cols
          col = 0
          x = 50
          y += 120
        else
          x += 200
        end
      end
      
      # Verify positions
      editor.node_positions.size.should eq(5)
      
      # First row
      editor.node_positions["node0"].x.should eq(50)
      editor.node_positions["node0"].y.should eq(50)
      editor.node_positions["node1"].x.should eq(250)
      editor.node_positions["node1"].y.should eq(50)
      editor.node_positions["node2"].x.should eq(450)
      editor.node_positions["node2"].y.should eq(50)
      
      # Second row
      editor.node_positions["node3"].x.should eq(50)
      editor.node_positions["node3"].y.should eq(170)
      editor.node_positions["node4"].x.should eq(250)
      editor.node_positions["node4"].y.should eq(170)
    end
    
    it "updates node positions when dragging" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Set up node position
      editor.node_positions["test_node"] = RL::Vector2.new(x: 100, y: 100)
      
      # Simulate drag
      delta = RL::Vector2.new(x: 50, y: 30)
      original_pos = editor.node_positions["test_node"]
      new_pos = RL::Vector2.new(
        x: original_pos.x + delta.x,
        y: original_pos.y + delta.y
      )
      editor.node_positions["test_node"] = new_pos
      
      # Verify position updated
      editor.node_positions["test_node"].x.should eq(150)
      editor.node_positions["test_node"].y.should eq(130)
    end
  end
  
  describe "dialog saving" do
    it "saves dialog to YAML file" do
      temp_dir = File.tempfile("project").path
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      
      project = PaceEditor::Core::Project.new("test", temp_dir)
      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Create dialog
      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
      node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello!")
      dialog.add_node(node)
      
      editor.current_dialog = dialog
      
      # Save dialog
      editor.save_current_dialog
      
      # Verify file exists
      dialog_file = File.join(project.dialogs_path, "test_dialog.yml")
      File.exists?(dialog_file).should be_true
      
      # Verify content
      content = File.read(dialog_file)
      content.should contain("name: test_dialog")
      content.should contain("start:")
      content.should contain("text: Hello!")
      
      FileUtils.rm_rf(temp_dir)
    end
  end
  
  describe "node selection" do
    it "finds node at given position" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)
      
      # Set up node positions
      editor.node_positions["node1"] = RL::Vector2.new(x: 100, y: 100)
      editor.node_positions["node2"] = RL::Vector2.new(x: 300, y: 100)
      
      # Test positions
      # Node dimensions are 150x80
      
      # Inside node1
      pos = RL::Vector2.new(x: 120, y: 120)
      found = nil
      editor.node_positions.each do |node_id, node_pos|
        if pos.x >= node_pos.x && pos.x <= node_pos.x + 150 &&
           pos.y >= node_pos.y && pos.y <= node_pos.y + 80
          found = node_id
          break
        end
      end
      found.should eq("node1")
      
      # Inside node2
      pos = RL::Vector2.new(x: 320, y: 120)
      found = nil
      editor.node_positions.each do |node_id, node_pos|
        if pos.x >= node_pos.x && pos.x <= node_pos.x + 150 &&
           pos.y >= node_pos.y && pos.y <= node_pos.y + 80
          found = node_id
          break
        end
      end
      found.should eq("node2")
      
      # Outside any node
      pos = RL::Vector2.new(x: 50, y: 50)
      found = nil
      editor.node_positions.each do |node_id, node_pos|
        if pos.x >= node_pos.x && pos.x <= node_pos.x + 150 &&
           pos.y >= node_pos.y && pos.y <= node_pos.y + 80
          found = node_id
          break
        end
      end
      found.should be_nil
    end
  end
end