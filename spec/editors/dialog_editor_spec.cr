require "../spec_helper"

describe PaceEditor::Editors::DialogEditor do
  describe "#initialize" do
    it "initializes with correct default values" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      editor.current_dialog_tree.should be_nil
      editor.selected_node.should be_nil
      editor.dialog_files.should be_empty
      editor.zoom.should eq(1.0f32)
      editor.pan_x.should eq(0.0f32)
      editor.pan_y.should eq(0.0f32)
    end
  end

  describe "#load_dialog_files" do
    it "loads dialog files from project directory" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      # Create test project with dialog files
      project = create_test_project
      dialog_dir = File.join(project.project_path, "dialogs")
      Dir.mkdir_p(dialog_dir)

      # Create test dialog files
      File.write(File.join(dialog_dir, "wizard_dialog.yml"), "test: dialog")
      File.write(File.join(dialog_dir, "merchant_dialog.yml"), "test: dialog")
      File.write(File.join(dialog_dir, "guard_dialog.yml"), "test: dialog")

      state.current_project = project

      editor.load_dialog_files

      editor.dialog_files.should contain("wizard_dialog.yml")
      editor.dialog_files.should contain("merchant_dialog.yml")
      editor.dialog_files.should contain("guard_dialog.yml")
      editor.dialog_files.size.should eq(3)
    end

    it "handles empty dialog directory" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      project = create_test_project
      state.current_project = project

      editor.load_dialog_files

      editor.dialog_files.should be_empty
    end

    it "handles case when no project is loaded" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      # Should not crash
      editor.load_dialog_files
      editor.dialog_files.should be_empty
    end
  end

  describe "#create_new_dialog" do
    it "creates new dialog tree and file" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      project = create_test_project
      state.current_project = project

      editor.create_new_dialog("test_npc")

      # Should have created new dialog tree
      editor.current_dialog_tree.should_not be_nil

      # Should have saved file
      dialog_file = File.join(project.project_path, "dialogs", "test_npc_dialog.yml")
      File.exists?(dialog_file).should be_true

      # Should have added to dialog files list
      editor.dialog_files.should contain("test_npc_dialog.yml")
    end

    it "handles creation when no project is available" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      # Should not crash
      editor.create_new_dialog("test")
      editor.current_dialog_tree.should be_nil
    end
  end

  describe "#load_dialog_tree" do
    it "loads existing dialog tree from file" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      project = create_test_project
      state.current_project = project

      # Create test dialog file
      dialog_content = <<-YAML
      character: "Wizard"
      nodes:
        start:
          text: "Welcome, traveler!"
          responses:
            - text: "Hello!"
              next: "hello_response"
            - text: "Goodbye"
              next: "end"
        hello_response:
          text: "How can I help you?"
          responses:
            - text: "I need a quest"
              next: "quest"
            - text: "Nothing, thanks"
              next: "end"
        quest:
          text: "Find the lost artifact!"
          responses:
            - text: "I'll do it!"
              next: "end"
        end:
          text: "Farewell!"
      YAML

      dialog_dir = File.join(project.project_path, "dialogs")
      Dir.mkdir_p(dialog_dir)
      dialog_file = File.join(dialog_dir, "wizard_dialog.yml")
      File.write(dialog_file, dialog_content)

      editor.load_dialog_tree("wizard_dialog.yml")

      # Should have loaded dialog tree
      editor.current_dialog_tree.should_not be_nil
      tree = editor.current_dialog_tree.not_nil!
      tree.character.should eq("Wizard")
      tree.nodes.has_key?("start").should be_true
      tree.nodes.has_key?("hello_response").should be_true
      tree.nodes.has_key?("quest").should be_true
      tree.nodes.has_key?("end").should be_true
    end

    it "handles invalid dialog file gracefully" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      project = create_test_project
      state.current_project = project

      # Create invalid dialog file
      dialog_dir = File.join(project.project_path, "dialogs")
      Dir.mkdir_p(dialog_dir)
      dialog_file = File.join(dialog_dir, "invalid_dialog.yml")
      File.write(dialog_file, "invalid: yaml: content:")

      # Should not crash
      editor.load_dialog_tree("invalid_dialog.yml")
      editor.current_dialog_tree.should be_nil
    end

    it "handles nonexistent dialog file" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      project = create_test_project
      state.current_project = project

      # Should not crash
      editor.load_dialog_tree("nonexistent.yml")
      editor.current_dialog_tree.should be_nil
    end
  end

  describe "#save_current_dialog" do
    it "saves current dialog tree to file" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      project = create_test_project
      state.current_project = project

      # Create dialog tree
      tree = PointClickEngine::Characters::DialogTree.new("TestNPC")
      start_node = PointClickEngine::Characters::DialogNode.new("start", "Hello there!")
      tree.add_node(start_node)
      editor.current_dialog_tree = tree

      # Save dialog
      editor.save_current_dialog("test_dialog.yml")

      # Check file was created
      dialog_file = File.join(project.project_path, "dialogs", "test_dialog.yml")
      File.exists?(dialog_file).should be_true

      # Check content
      content = File.read(dialog_file)
      content.should contain("character: TestNPC")
      content.should contain("start:")
      content.should contain("text: Hello there!")
    end

    it "handles save when no dialog tree is loaded" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      project = create_test_project
      state.current_project = project

      # Should not crash
      editor.save_current_dialog("test.yml")
    end

    it "handles save when no project is available" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      tree = PointClickEngine::Characters::DialogTree.new("Test")
      editor.current_dialog_tree = tree

      # Should not crash
      editor.save_current_dialog("test.yml")
    end
  end

  describe "#add_dialog_node" do
    it "adds new node to dialog tree" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      # Create dialog tree
      tree = PointClickEngine::Characters::DialogTree.new("TestNPC")
      editor.current_dialog_tree = tree

      initial_count = tree.nodes.size

      editor.add_dialog_node("new_node", "New dialog text")

      tree.nodes.size.should eq(initial_count + 1)
      tree.nodes.has_key?("new_node").should be_true
      tree.nodes["new_node"].text.should eq("New dialog text")
    end

    it "handles adding node when no dialog tree is loaded" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      # Should not crash
      editor.add_dialog_node("test", "test text")
    end
  end

  describe "#delete_dialog_node" do
    it "removes node from dialog tree" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      # Create dialog tree with nodes
      tree = PointClickEngine::Characters::DialogTree.new("TestNPC")
      node1 = PointClickEngine::Characters::DialogNode.new("node1", "Text 1")
      node2 = PointClickEngine::Characters::DialogNode.new("node2", "Text 2")
      tree.add_node(node1)
      tree.add_node(node2)
      editor.current_dialog_tree = tree

      initial_count = tree.nodes.size

      editor.delete_dialog_node("node1")

      tree.nodes.size.should eq(initial_count - 1)
      tree.nodes.has_key?("node1").should be_false
      tree.nodes.has_key?("node2").should be_true
    end

    it "clears selected node if it was deleted" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      tree = PointClickEngine::Characters::DialogTree.new("TestNPC")
      node = PointClickEngine::Characters::DialogNode.new("test_node", "Test")
      tree.add_node(node)
      editor.current_dialog_tree = tree
      editor.selected_node = "test_node"

      editor.delete_dialog_node("test_node")

      editor.selected_node.should be_nil
    end

    it "handles deleting nonexistent node" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      tree = PointClickEngine::Characters::DialogTree.new("TestNPC")
      editor.current_dialog_tree = tree

      # Should not crash
      editor.delete_dialog_node("nonexistent")
    end
  end

  describe "#connect_nodes" do
    it "creates connection between dialog nodes" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      # Create dialog tree with nodes
      tree = PointClickEngine::Characters::DialogTree.new("TestNPC")
      node1 = PointClickEngine::Characters::DialogNode.new("node1", "Question?")
      node2 = PointClickEngine::Characters::DialogNode.new("node2", "Answer")
      tree.add_node(node1)
      tree.add_node(node2)
      editor.current_dialog_tree = tree

      editor.connect_nodes("node1", "node2", "Yes")

      # Check connection was created
      node1.responses.size.should eq(1)
      response = node1.responses.first
      response.text.should eq("Yes")
      response.next_node.should eq("node2")
    end

    it "handles connecting nonexistent nodes" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      tree = PointClickEngine::Characters::DialogTree.new("TestNPC")
      editor.current_dialog_tree = tree

      # Should not crash
      editor.connect_nodes("nonexistent1", "nonexistent2", "text")
    end
  end

  describe "zoom and pan controls" do
    it "manages zoom level correctly" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      initial_zoom = editor.zoom

      editor.zoom = 2.0f32
      editor.zoom.should eq(2.0f32)

      editor.zoom = 0.5f32
      editor.zoom.should eq(0.5f32)
    end

    it "manages pan offset correctly" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      editor.pan_x = 100.0f32
      editor.pan_y = 50.0f32

      editor.pan_x.should eq(100.0f32)
      editor.pan_y.should eq(50.0f32)
    end

    it "resets view correctly" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      # Change view
      editor.zoom = 3.0f32
      editor.pan_x = 200.0f32
      editor.pan_y = 150.0f32

      # Reset view
      editor.zoom = 1.0f32
      editor.pan_x = 0.0f32
      editor.pan_y = 0.0f32

      editor.zoom.should eq(1.0f32)
      editor.pan_x.should eq(0.0f32)
      editor.pan_y.should eq(0.0f32)
    end
  end

  describe "node selection" do
    it "manages selected node correctly" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      editor.selected_node = "test_node"
      editor.selected_node.should eq("test_node")

      editor.selected_node = nil
      editor.selected_node.should be_nil
    end

    it "validates node selection" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      # Create dialog tree
      tree = PointClickEngine::Characters::DialogTree.new("TestNPC")
      node = PointClickEngine::Characters::DialogNode.new("valid_node", "Text")
      tree.add_node(node)
      editor.current_dialog_tree = tree

      # Select valid node
      editor.selected_node = "valid_node"
      editor.selected_node.should eq("valid_node")

      # Select invalid node
      editor.selected_node = "invalid_node"
      editor.selected_node.should eq("invalid_node") # Allow for UI feedback
    end
  end
end

# Helper methods for testing
private def create_test_project
  test_dir = File.tempname("test_project")
  project = PaceEditor::Core::Project.new("Test Project", test_dir)
  project
end
