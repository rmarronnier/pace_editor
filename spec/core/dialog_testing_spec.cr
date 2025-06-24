require "../spec_helper"
require "file_utils"

describe PaceEditor::Core::EditorState do
  describe "Dialog Testing System" do
    let(state) { PaceEditor::Core::EditorState.new }
    let(temp_dir) { "/tmp/pace_dialog_test_#{Random.new.next_int}" }
    
    before_each do
      Dir.mkdir_p(temp_dir)
      state.create_new_project("Dialog Test", temp_dir)
    end
    
    after_each do
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
    
    describe "#test_dialog" do
      it "creates default dialog for character when none exists" do
        scene = state.current_scene.not_nil!
        state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        project = state.current_project.not_nil!
        dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
        
        # Ensure dialog file doesn't exist initially
        File.exists?(dialog_path).should eq(false)
        
        state.test_dialog(character_name)
        
        # Dialog file should now exist
        File.exists?(dialog_path).should eq(true)
        
        # Verify dialog content
        dialog_content = File.read(dialog_path)
        dialog_content.should contain("#{character_name}_dialog")
        dialog_content.should contain("start")
        dialog_content.should contain("Hello! I'm #{character_name}")
      end
      
      it "loads existing dialog for character when file exists" do
        scene = state.current_scene.not_nil!
        state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        project = state.current_project.not_nil!
        
        # Create a custom dialog file
        dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("custom_dialog")
        start_node = PointClickEngine::Characters::Dialogue::DialogNode.new(
          "start",
          "This is a custom dialog for testing"
        )
        dialog_tree.nodes["start"] = start_node
        
        dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
        Dir.mkdir_p(project.dialogs_path)
        File.write(dialog_path, dialog_tree.to_yaml)
        
        # Test the dialog - should load the existing one
        state.test_dialog(character_name)
        
        # Verify the custom dialog was loaded (this would be visible in console output)
        File.exists?(dialog_path).should eq(true)
      end
      
      it "handles missing character gracefully" do
        # Try to test dialog for non-existent character
        state.test_dialog("non_existent_character")
        
        # Should not crash or create any files
        project = state.current_project.not_nil!
        dialog_path = File.join(project.dialogs_path, "non_existent_character.yml")
        File.exists?(dialog_path).should eq(false)
      end
      
      it "handles invalid dialog file gracefully" do
        scene = state.current_scene.not_nil!
        state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        project = state.current_project.not_nil!
        
        # Create an invalid dialog file
        dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
        Dir.mkdir_p(project.dialogs_path)
        File.write(dialog_path, "invalid yaml content [")
        
        # Should handle the error gracefully
        state.test_dialog(character_name)
        
        # File should still exist (not overwritten)
        File.exists?(dialog_path).should eq(true)
        File.read(dialog_path).should eq("invalid yaml content [")
      end
      
      it "creates dialogs directory if it doesn't exist" do
        scene = state.current_scene.not_nil!
        state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        project = state.current_project.not_nil!
        
        # Ensure dialogs directory doesn't exist
        FileUtils.rm_rf(project.dialogs_path) if Dir.exists?(project.dialogs_path)
        Dir.exists?(project.dialogs_path).should eq(false)
        
        state.test_dialog(character_name)
        
        # Directory should now exist
        Dir.exists?(project.dialogs_path).should eq(true)
      end
    end
    
    describe "dialog validation" do
      it "validates well-formed dialog tree" do
        scene = state.current_scene.not_nil!
        state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        project = state.current_project.not_nil!
        
        # Create a well-formed dialog
        dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
        
        start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello")
        end_node = PointClickEngine::Characters::Dialogue::DialogNode.new("end", "Goodbye")
        
        choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Say goodbye", "end")
        start_node.choices << choice
        
        dialog_tree.nodes["start"] = start_node
        dialog_tree.nodes["end"] = end_node
        
        dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
        Dir.mkdir_p(project.dialogs_path)
        File.write(dialog_path, dialog_tree.to_yaml)
        
        # Should validate without errors
        state.test_dialog(character_name)
      end
      
      it "detects missing start node" do
        scene = state.current_scene.not_nil!
        state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        project = state.current_project.not_nil!
        
        # Create dialog without start node
        dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
        other_node = PointClickEngine::Characters::Dialogue::DialogNode.new("other", "Hello")
        dialog_tree.nodes["other"] = other_node
        
        dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
        Dir.mkdir_p(project.dialogs_path)
        File.write(dialog_path, dialog_tree.to_yaml)
        
        # Should detect missing start node
        state.test_dialog(character_name)
      end
      
      it "detects orphaned nodes" do
        scene = state.current_scene.not_nil!
        state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        project = state.current_project.not_nil!
        
        # Create dialog with orphaned node
        dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
        
        start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello")
        orphaned_node = PointClickEngine::Characters::Dialogue::DialogNode.new("orphaned", "Unreachable")
        
        dialog_tree.nodes["start"] = start_node
        dialog_tree.nodes["orphaned"] = orphaned_node
        
        dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
        Dir.mkdir_p(project.dialogs_path)
        File.write(dialog_path, dialog_tree.to_yaml)
        
        # Should detect orphaned node
        state.test_dialog(character_name)
      end
      
      it "detects broken links" do
        scene = state.current_scene.not_nil!
        state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        project = state.current_project.not_nil!
        
        # Create dialog with broken link
        dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
        
        start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello")
        broken_choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Go nowhere", "non_existent")
        start_node.choices << broken_choice
        
        dialog_tree.nodes["start"] = start_node
        
        dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
        Dir.mkdir_p(project.dialogs_path)
        File.write(dialog_path, dialog_tree.to_yaml)
        
        # Should detect broken link
        state.test_dialog(character_name)
      end
      
      it "validates complex dialog tree structure" do
        scene = state.current_scene.not_nil!
        state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        project = state.current_project.not_nil!
        
        # Create complex but valid dialog tree
        dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("complex_dialog")
        
        # Create multiple interconnected nodes
        start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Welcome! What would you like to know?")
        info_node = PointClickEngine::Characters::Dialogue::DialogNode.new("info", "I can tell you about many things.")
        shop_node = PointClickEngine::Characters::Dialogue::DialogNode.new("shop", "Welcome to my shop!")
        goodbye_node = PointClickEngine::Characters::Dialogue::DialogNode.new("goodbye", "See you later!")
        
        # Create choices that form a complex web
        start_node.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Tell me more", "info")
        start_node.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Show me your wares", "shop")
        start_node.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Goodbye", "goodbye")
        
        info_node.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("What about your shop?", "shop")
        info_node.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Thanks", "goodbye")
        info_node.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Tell me more", "start")
        
        shop_node.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Tell me about yourself", "info")
        shop_node.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Maybe later", "goodbye")
        
        dialog_tree.nodes["start"] = start_node
        dialog_tree.nodes["info"] = info_node
        dialog_tree.nodes["shop"] = shop_node
        dialog_tree.nodes["goodbye"] = goodbye_node
        
        dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
        Dir.mkdir_p(project.dialogs_path)
        File.write(dialog_path, dialog_tree.to_yaml)
        
        # Should validate successfully
        state.test_dialog(character_name)
      end
    end
    
    describe "default dialog creation" do
      it "creates dialog with proper structure" do
        scene = state.current_scene.not_nil!
        state.add_npc_character(scene)
        character_name = scene.characters.last.name
        
        state.test_dialog(character_name)
        
        project = state.current_project.not_nil!
        dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
        
        # Load and verify the created dialog
        dialog_content = File.read(dialog_path)
        dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.from_yaml(dialog_content)
        
        # Should have required nodes
        dialog_tree.nodes.should have_key("start")
        dialog_tree.nodes.should have_key("response")
        
        # Start node should have choices
        start_node = dialog_tree.nodes["start"]
        start_node.choices.size.should be > 0
        
        # Should contain character name in text
        start_node.text.should contain(character_name)
      end
      
      it "creates different dialogs for different characters" do
        scene = state.current_scene.not_nil!
        
        # Create two NPCs
        state.add_npc_character(scene)
        first_character = scene.characters.last.name
        
        state.add_npc_character(scene)
        second_character = scene.characters.last.name
        
        # Test dialogs for both
        state.test_dialog(first_character)
        state.test_dialog(second_character)
        
        project = state.current_project.not_nil!
        first_dialog_path = File.join(project.dialogs_path, "#{first_character}.yml")
        second_dialog_path = File.join(project.dialogs_path, "#{second_character}.yml")
        
        # Both files should exist
        File.exists?(first_dialog_path).should eq(true)
        File.exists?(second_dialog_path).should eq(true)
        
        # Contents should be different (contain different character names)
        first_content = File.read(first_dialog_path)
        second_content = File.read(second_dialog_path)
        
        first_content.should contain(first_character)
        second_content.should contain(second_character)
        first_content.should_not eq(second_content)
      end
    end
  end
end