require "../spec_helper"
require "file_utils"

# Create testable version of EditorWindow that doesn't initialize Raylib
class TestableEditorWindow < PaceEditor::Core::EditorWindow
  # Override the Raylib-dependent parts for testing
  def initialize
    @state = PaceEditor::Core::EditorState.new
    @window_width = 1400
    @window_height = 900
    @is_fullscreen = false

    # Initialize basic components without Raylib
    @ui_state = PaceEditor::UI::UIState.new
    @confirm_dialog = nil
    
    # Mock the dialog editor for testing
    @dialog_editor = MockDialogEditor.new
  end
  
  # Expose dialog editor for testing
  getter dialog_editor
end

# Mock dialog editor for testing
class MockDialogEditor
  property current_dialog : PointClickEngine::Characters::Dialogue::DialogTree? = nil
  property loaded_dialog_path : String? = nil
  
  def current_dialog=(dialog : PointClickEngine::Characters::Dialogue::DialogTree?)
    @current_dialog = dialog
    @loaded_dialog_path = "mock_loaded_dialog"
  end
end

describe PaceEditor::Core::EditorWindow do
  describe "Dialog Editor Integration" do
    let(window) { TestableEditorWindow.new }
    let(temp_dir) { "/tmp/pace_window_dialog_test_#{Random.new.next_int}" }
    
    before_each do
      Dir.mkdir_p(temp_dir)
      window.state.create_new_project("Window Dialog Test", temp_dir)
    end
    
    after_each do
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
    
    describe "#show_dialog_editor_for_character" do
      it "creates dialog file when none exists" do
        # Add a character to the scene
        scene = window.state.current_scene.not_nil!
        window.state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        project = window.state.current_project.not_nil!
        dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
        
        # Ensure dialog file doesn't exist initially
        File.exists?(dialog_path).should eq(false)
        
        window.show_dialog_editor_for_character(character_name)
        
        # Dialog file should now exist
        File.exists?(dialog_path).should eq(true)
        
        # Dialog editor should have loaded the dialog
        window.dialog_editor.current_dialog.should_not be_nil
        window.dialog_editor.loaded_dialog_path.should eq("mock_loaded_dialog")
      end
      
      it "creates dialogs directory if it doesn't exist" do
        # Add a character to the scene
        scene = window.state.current_scene.not_nil!
        window.state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        project = window.state.current_project.not_nil!
        
        # Remove dialogs directory if it exists
        FileUtils.rm_rf(project.dialogs_path) if Dir.exists?(project.dialogs_path)
        Dir.exists?(project.dialogs_path).should eq(false)
        
        window.show_dialog_editor_for_character(character_name)
        
        # Directory should be created
        Dir.exists?(project.dialogs_path).should eq(true)
      end
      
      it "loads existing dialog file" do
        # Add a character to the scene
        scene = window.state.current_scene.not_nil!
        window.state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        project = window.state.current_project.not_nil!
        dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
        
        # Create existing dialog file
        Dir.mkdir_p(project.dialogs_path)
        existing_content = "existing dialog content"
        File.write(dialog_path, existing_content)
        
        window.show_dialog_editor_for_character(character_name)
        
        # Should load the existing file
        window.dialog_editor.current_dialog.should_not be_nil
        window.dialog_editor.loaded_dialog_path.should eq("mock_loaded_dialog")
        File.read(dialog_path).should eq(existing_content) # Should not overwrite
      end
      
      it "handles missing project gracefully" do
        # Clear the current project
        window.state.instance_variable_set(:@current_project, nil)
        
        # Should return early without error
        window.show_dialog_editor_for_character("test_character")
        
        # Dialog editor should not have loaded anything
        window.dialog_editor.current_dialog.should be_nil
      end
      
      it "switches to dialog mode" do
        # Add a character to the scene
        scene = window.state.current_scene.not_nil!
        window.state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        initial_mode = window.state.current_mode
        
        window.show_dialog_editor_for_character(character_name)
        
        # Should switch to dialog mode
        window.state.current_mode.should eq(PaceEditor::EditorMode::Dialog)
      end
    end
    
    describe "default dialog creation" do
      it "creates dialog with proper structure for character" do
        # Add a character to the scene
        scene = window.state.current_scene.not_nil!
        window.state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        window.show_dialog_editor_for_character(character_name)
        
        project = window.state.current_project.not_nil!
        dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
        
        # Verify dialog structure
        dialog_content = File.read(dialog_path)
        dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.from_yaml(dialog_content)
        
        # Should have proper dialog name
        dialog_tree.name.should eq("#{character_name}_dialog")
        
        # Should have required nodes
        dialog_tree.nodes.should have_key("start")
        dialog_tree.nodes.should have_key("goodbye")
        dialog_tree.nodes.should have_key("info")
        
        # Start node should reference character name
        start_node = dialog_tree.nodes["start"]
        start_node.text.should contain(character_name)
        
        # Should have proper choice structure
        start_node.choices.size.should eq(2)
        choice_texts = start_node.choices.map(&.text)
        choice_texts.should contain("Goodbye")
        choice_texts.should contain("Tell me about yourself")
        
        # Verify connectivity
        info_node = dialog_tree.nodes["info"]
        info_node.choices.size.should eq(2)
        
        info_choices = info_node.choices.map(&.target_node_id)
        info_choices.should contain("start")
        info_choices.should contain("goodbye")
      end
      
      it "creates different dialogs for different characters" do
        # Add two characters
        scene = window.state.current_scene.not_nil!
        window.state.add_npc_character(scene)
        first_character = scene.characters.last.name
        
        window.state.add_npc_character(scene)
        second_character = scene.characters.last.name
        
        # Create dialogs for both
        window.show_dialog_editor_for_character(first_character)
        window.show_dialog_editor_for_character(second_character)
        
        project = window.state.current_project.not_nil!
        first_dialog_path = File.join(project.dialogs_path, "#{first_character}.yml")
        second_dialog_path = File.join(project.dialogs_path, "#{second_character}.yml")
        
        # Both should exist
        File.exists?(first_dialog_path).should eq(true)
        File.exists?(second_dialog_path).should eq(true)
        
        # Content should be different
        first_content = File.read(first_dialog_path)
        second_content = File.read(second_dialog_path)
        
        first_content.should contain(first_character)
        second_content.should contain(second_character)
        first_content.should_not eq(second_content)
      end
      
      it "creates well-formed YAML" do
        # Add a character to the scene
        scene = window.state.current_scene.not_nil!
        window.state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        window.show_dialog_editor_for_character(character_name)
        
        project = window.state.current_project.not_nil!
        dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
        
        # Should be valid YAML that can be parsed
        dialog_content = File.read(dialog_path)
        
        # Should not raise an exception
        dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.from_yaml(dialog_content)
        dialog_tree.should_not be_nil
      end
    end
  end
  
  describe "Dialog Integration Workflow" do
    let(window) { TestableEditorWindow.new }
    let(temp_dir) { "/tmp/pace_workflow_test_#{Random.new.next_int}" }
    
    before_each do
      Dir.mkdir_p(temp_dir)
      window.state.create_new_project("Workflow Test", temp_dir)
    end
    
    after_each do
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
    
    it "handles full character creation and dialog setup workflow" do
      scene = window.state.current_scene.not_nil!
      
      # Step 1: Create character
      window.state.add_npc_character(scene)
      character = scene.characters.last
      character_name = character.name
      
      # Step 2: Open dialog editor for character
      window.show_dialog_editor_for_character(character_name)
      
      # Step 3: Verify dialog was created and loaded
      project = window.state.current_project.not_nil!
      dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
      
      File.exists?(dialog_path).should eq(true)
      window.dialog_editor.current_dialog.should_not be_nil
      window.state.current_mode.should eq(PaceEditor::EditorMode::Dialog)
      
      # Step 4: Test the dialog
      window.state.test_dialog(character_name)
      
      # Dialog should still exist and be valid
      File.exists?(dialog_path).should eq(true)
      dialog_content = File.read(dialog_path)
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.from_yaml(dialog_content)
      dialog_tree.should_not be_nil
    end
    
    it "maintains consistency across character operations" do
      scene = window.state.current_scene.not_nil!
      
      # Create multiple characters and dialogs
      characters = [] of String
      3.times do
        window.state.add_npc_character(scene)
        character_name = scene.characters.last.name
        characters << character_name
        window.show_dialog_editor_for_character(character_name)
      end
      
      project = window.state.current_project.not_nil!
      
      # All dialogs should exist
      characters.each do |character_name|
        dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
        File.exists?(dialog_path).should eq(true)
        
        # Each dialog should be valid and contain the character name
        dialog_content = File.read(dialog_path)
        dialog_content.should contain(character_name)
        
        dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.from_yaml(dialog_content)
        dialog_tree.name.should eq("#{character_name}_dialog")
      end
      
      # Test all dialogs
      characters.each do |character_name|
        window.state.test_dialog(character_name)
      end
    end
  end
end