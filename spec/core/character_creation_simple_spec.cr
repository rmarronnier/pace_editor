require "../spec_helper"
require "file_utils"

describe "Character Creation System" do
  it "can create player characters" do
    state = PaceEditor::Core::EditorState.new
    temp_dir = "/tmp/pace_character_test_#{Random.new.next_int}"
    
    begin
      Dir.mkdir_p(temp_dir)
      state.create_new_project("Character Test", temp_dir)
      
      scene = state.current_scene.not_nil!
      initial_count = scene.characters.size
      
      state.add_player_character(scene)
      
      scene.characters.size.should eq(initial_count + 1)
      
      player = scene.characters.last
      player.should be_a(PointClickEngine::Characters::Player)
      player.name.should start_with("player_")
      player.description.should eq("Player character")
      player.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      player.direction.should eq(PointClickEngine::Characters::Direction::Down)
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end
  
  it "can create NPC characters" do
    state = PaceEditor::Core::EditorState.new
    temp_dir = "/tmp/pace_character_test_#{Random.new.next_int}"
    
    begin
      Dir.mkdir_p(temp_dir)
      state.create_new_project("Character Test", temp_dir)
      
      scene = state.current_scene.not_nil!
      initial_count = scene.characters.size
      
      state.add_npc_character(scene)
      
      scene.characters.size.should eq(initial_count + 1)
      
      npc = scene.characters.last
      npc.should be_a(PointClickEngine::Characters::NPC)
      npc.name.should start_with("npc_")
      npc.description.should eq("Non-player character")
      npc.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      npc.direction.should eq(PointClickEngine::Characters::Direction::Down)
      
      npc_typed = npc.as(PointClickEngine::Characters::NPC)
      npc_typed.mood.should eq(PointClickEngine::Characters::CharacterMood::Neutral)
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end
  
  it "generates unique character names" do
    state = PaceEditor::Core::EditorState.new
    temp_dir = "/tmp/pace_character_test_#{Random.new.next_int}"
    
    begin
      Dir.mkdir_p(temp_dir)
      state.create_new_project("Character Test", temp_dir)
      
      scene = state.current_scene.not_nil!
      
      # Create multiple characters
      state.add_player_character(scene)
      state.add_npc_character(scene)
      state.add_player_character(scene)
      state.add_npc_character(scene)
      
      names = scene.characters.map(&.name)
      names.uniq.size.should eq(names.size) # All names should be unique
      
      # Should have specific naming pattern
      player_names = names.select { |n| n.starts_with?("player_") }
      npc_names = names.select { |n| n.starts_with?("npc_") }
      
      player_names.size.should be >= 2
      npc_names.size.should be >= 2
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end
  
  it "can undo character creation" do
    state = PaceEditor::Core::EditorState.new
    temp_dir = "/tmp/pace_character_test_#{Random.new.next_int}"
    
    begin
      Dir.mkdir_p(temp_dir)
      state.create_new_project("Character Test", temp_dir)
      
      scene = state.current_scene.not_nil!
      initial_count = scene.characters.size
      
      state.add_npc_character(scene)
      scene.characters.size.should eq(initial_count + 1)
      
      state.undo
      scene.characters.size.should eq(initial_count)
      state.selected_object.should be_nil
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end
  
  it "can redo character creation" do
    state = PaceEditor::Core::EditorState.new
    temp_dir = "/tmp/pace_character_test_#{Random.new.next_int}"
    
    begin
      Dir.mkdir_p(temp_dir)
      state.create_new_project("Character Test", temp_dir)
      
      scene = state.current_scene.not_nil!
      initial_count = scene.characters.size
      
      state.add_npc_character(scene)
      character_name = scene.characters.last.name
      
      state.undo
      scene.characters.size.should eq(initial_count)
      
      state.redo
      scene.characters.size.should eq(initial_count + 1)
      scene.characters.last.name.should eq(character_name)
      state.selected_object.should eq(character_name)
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end
end

describe "Dialog Testing System" do
  it "can test character dialogs" do
    state = PaceEditor::Core::EditorState.new
    temp_dir = "/tmp/pace_dialog_test_#{Random.new.next_int}"
    
    begin
      Dir.mkdir_p(temp_dir)
      state.create_new_project("Dialog Test", temp_dir)
      
      scene = state.current_scene.not_nil!
      state.add_npc_character(scene)
      character_name = scene.characters.last.name
      
      project = state.current_project.not_nil!
      dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
      
      # Initially no dialog file
      File.exists?(dialog_path).should eq(false)
      
      # Test dialog should create default dialog
      state.test_dialog(character_name)
      
      # Dialog file should now exist
      File.exists?(dialog_path).should eq(true)
      
      # Dialog should have proper structure
      dialog_content = File.read(dialog_path)
      dialog_content.should contain(character_name)
      dialog_content.should contain("start")
      dialog_content.should contain("response")
      
      # Should be valid YAML that can be parsed
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.from_yaml(dialog_content)
      dialog_tree.should_not be_nil
      dialog_tree.nodes.has_key?("start").should eq(true)
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end
  
  it "handles missing characters gracefully" do
    state = PaceEditor::Core::EditorState.new
    temp_dir = "/tmp/pace_dialog_test_#{Random.new.next_int}"
    
    begin
      Dir.mkdir_p(temp_dir)
      state.create_new_project("Dialog Test", temp_dir)
      
      # Should not crash when testing dialog for non-existent character
      state.test_dialog("non_existent_character")
      
      project = state.current_project.not_nil!
      dialog_path = File.join(project.dialogs_path, "non_existent_character.yml")
      File.exists?(dialog_path).should eq(false)
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end
  
  it "validates dialog tree structure" do
    state = PaceEditor::Core::EditorState.new
    temp_dir = "/tmp/pace_dialog_test_#{Random.new.next_int}"
    
    begin
      Dir.mkdir_p(temp_dir)
      state.create_new_project("Dialog Test", temp_dir)
      
      scene = state.current_scene.not_nil!
      state.add_npc_character(scene)
      character_name = scene.characters.last.name
      
      # Create a dialog with validation issues
      project = state.current_project.not_nil!
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
      
      # Missing start node
      other_node = PointClickEngine::Characters::Dialogue::DialogNode.new("other", "Hello")
      dialog_tree.nodes["other"] = other_node
      
      dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
      Dir.mkdir_p(project.dialogs_path)
      File.write(dialog_path, dialog_tree.to_yaml)
      
      # Should detect validation issues but not crash
      state.test_dialog(character_name)
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end
end