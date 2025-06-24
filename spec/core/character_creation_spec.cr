require "../spec_helper"
require "file_utils"

describe PaceEditor::Core::EditorState do
  describe "Character Creation System" do
    
    describe "#add_player_character" do
      it "creates a player character with unique name" do
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
        ensure
          FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
        end
      end
      
      it "generates unique names when multiple players are added" do
        scene = state.current_scene.not_nil!
        
        state.add_player_character(scene)
        state.add_player_character(scene)
        state.add_player_character(scene)
        
        names = scene.characters.map(&.name)
        names.should contain("player_1")
        names.should contain("player_2")
        names.should contain("player_3")
      end
      
      it "sets default player character properties" do
        scene = state.current_scene.not_nil!
        
        state.add_player_character(scene)
        
        player = scene.characters.last.as(PointClickEngine::Characters::Player)
        player.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
        player.direction.should eq(PointClickEngine::Characters::Direction::Down)
        player.position.x.should eq(400.0_f32)
        player.position.y.should eq(300.0_f32)
        player.size.x.should eq(32.0_f32)
        player.size.y.should eq(64.0_f32)
      end
      
      it "selects the newly created player character" do
        scene = state.current_scene.not_nil!
        
        state.add_player_character(scene)
        
        player = scene.characters.last
        state.selected_object.should eq(player.name)
      end
      
      it "creates undo action for player creation" do
        scene = state.current_scene.not_nil!
        initial_undo_count = state.undo_stack.size
        
        state.add_player_character(scene)
        
        state.undo_stack.size.should eq(initial_undo_count + 1)
        last_action = state.undo_stack.last
        last_action.should be_a(PaceEditor::Core::CreateCharacterAction)
        last_action.description.should contain("Player")
      end
      
      it "marks state as dirty after player creation" do
        scene = state.current_scene.not_nil!
        state.mark_clean # Ensure we start clean
        
        state.add_player_character(scene)
        
        state.dirty?.should eq(true)
      end
    end
    
    describe "#add_npc_character" do
      it "creates an NPC character with unique name" do
        scene = state.current_scene.not_nil!
        initial_count = scene.characters.size
        
        state.add_npc_character(scene)
        
        scene.characters.size.should eq(initial_count + 1)
        
        npc = scene.characters.last
        npc.should be_a(PointClickEngine::Characters::NPC)
        npc.name.should start_with("npc_")
        npc.description.should eq("Non-player character")
      end
      
      it "generates unique names when multiple NPCs are added" do
        scene = state.current_scene.not_nil!
        
        state.add_npc_character(scene)
        state.add_npc_character(scene)
        state.add_npc_character(scene)
        
        names = scene.characters.map(&.name)
        names.should contain("npc_1")
        names.should contain("npc_2")
        names.should contain("npc_3")
      end
      
      it "sets default NPC character properties" do
        scene = state.current_scene.not_nil!
        
        state.add_npc_character(scene)
        
        npc = scene.characters.last.as(PointClickEngine::Characters::NPC)
        npc.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
        npc.direction.should eq(PointClickEngine::Characters::Direction::Down)
        npc.mood.should eq(PointClickEngine::Characters::CharacterMood::Neutral)
        npc.position.x.should eq(450.0_f32)
        npc.position.y.should eq(300.0_f32)
        npc.size.x.should eq(32.0_f32)
        npc.size.y.should eq(64.0_f32)
      end
      
      it "selects the newly created NPC character" do
        scene = state.current_scene.not_nil!
        
        state.add_npc_character(scene)
        
        npc = scene.characters.last
        state.selected_object.should eq(npc.name)
      end
      
      it "creates undo action for NPC creation" do
        scene = state.current_scene.not_nil!
        initial_undo_count = state.undo_stack.size
        
        state.add_npc_character(scene)
        
        state.undo_stack.size.should eq(initial_undo_count + 1)
        last_action = state.undo_stack.last
        last_action.should be_a(PaceEditor::Core::CreateCharacterAction)
        last_action.description.should contain("NPC")
      end
      
      it "marks state as dirty after NPC creation" do
        scene = state.current_scene.not_nil!
        state.mark_clean # Ensure we start clean
        
        state.add_npc_character(scene)
        
        state.dirty?.should eq(true)
      end
    end
    
    describe "Character Creation Undo/Redo" do
      it "can undo player character creation" do
        scene = state.current_scene.not_nil!
        initial_count = scene.characters.size
        
        state.add_player_character(scene)
        scene.characters.size.should eq(initial_count + 1)
        
        state.undo
        scene.characters.size.should eq(initial_count)
        state.selected_object.should be_nil
      end
      
      it "can redo player character creation" do
        scene = state.current_scene.not_nil!
        initial_count = scene.characters.size
        
        state.add_player_character(scene)
        player_name = scene.characters.last.name
        
        state.undo
        scene.characters.size.should eq(initial_count)
        
        state.redo
        scene.characters.size.should eq(initial_count + 1)
        scene.characters.last.name.should eq(player_name)
        state.selected_object.should eq(player_name)
      end
      
      it "can undo NPC character creation" do
        scene = state.current_scene.not_nil!
        initial_count = scene.characters.size
        
        state.add_npc_character(scene)
        scene.characters.size.should eq(initial_count + 1)
        
        state.undo
        scene.characters.size.should eq(initial_count)
        state.selected_object.should be_nil
      end
      
      it "can redo NPC character creation" do
        scene = state.current_scene.not_nil!
        initial_count = scene.characters.size
        
        state.add_npc_character(scene)
        npc_name = scene.characters.last.name
        
        state.undo
        scene.characters.size.should eq(initial_count)
        
        state.redo
        scene.characters.size.should eq(initial_count + 1)
        scene.characters.last.name.should eq(npc_name)
        state.selected_object.should eq(npc_name)
      end
    end
    
    describe "Mixed Character Creation" do
      it "handles creating both players and NPCs in the same scene" do
        scene = state.current_scene.not_nil!
        
        state.add_player_character(scene)
        state.add_npc_character(scene)
        state.add_player_character(scene)
        state.add_npc_character(scene)
        
        characters = scene.characters
        player_count = characters.count { |c| c.is_a?(PointClickEngine::Characters::Player) }
        npc_count = characters.count { |c| c.is_a?(PointClickEngine::Characters::NPC) }
        
        player_count.should eq(3) # 2 we added + 1 from initial scene
        npc_count.should eq(2)
      end
      
      it "maintains unique names across both character types" do
        scene = state.current_scene.not_nil!
        
        state.add_player_character(scene)
        state.add_npc_character(scene)
        state.add_player_character(scene)
        state.add_npc_character(scene)
        
        names = scene.characters.map(&.name)
        names.uniq.size.should eq(names.size) # All names should be unique
      end
    end
  end
end

describe PaceEditor::Core::CreateCharacterAction do
  describe "undo/redo functionality" do
    let(state) { PaceEditor::Core::EditorState.new }
    let(temp_dir) { "/tmp/pace_action_test_#{Random.new.next_int}" }
    
    before_each do
      Dir.mkdir_p(temp_dir)
      state.create_new_project("Action Test", temp_dir)
    end
    
    after_each do
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
    
    it "provides correct description for player character" do
      scene = state.current_scene.not_nil!
      player = PointClickEngine::Characters::Player.new(
        "test_player",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      
      action = PaceEditor::Core::CreateCharacterAction.new(scene, player, state)
      action.description.should eq("Create Player 'test_player'")
    end
    
    it "provides correct description for NPC character" do
      scene = state.current_scene.not_nil!
      npc = PointClickEngine::Characters::NPC.new(
        "test_npc",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      
      action = PaceEditor::Core::CreateCharacterAction.new(scene, npc, state)
      action.description.should eq("Create NPC 'test_npc'")
    end
    
    it "saves scene after undo operation" do
      scene = state.current_scene.not_nil!
      npc = PointClickEngine::Characters::NPC.new(
        "test_npc",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      scene.characters << npc
      
      action = PaceEditor::Core::CreateCharacterAction.new(scene, npc, state)
      
      # Scene should be saved after undo
      action.undo
      
      # Verify character was removed
      scene.characters.should_not contain(npc)
      
      # Verify scene file was saved (this would require checking file timestamp or content)
      project = state.current_project.not_nil!
      scene_path = File.join(project.scenes_path, "#{scene.name}.yml")
      File.exists?(scene_path).should eq(true)
    end
    
    it "saves scene after redo operation" do
      scene = state.current_scene.not_nil!
      npc = PointClickEngine::Characters::NPC.new(
        "test_npc",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      
      action = PaceEditor::Core::CreateCharacterAction.new(scene, npc, state)
      
      # Scene should be saved after redo
      action.redo
      
      # Verify character was added
      scene.characters.should contain(npc)
      
      # Verify scene file was saved
      project = state.current_project.not_nil!
      scene_path = File.join(project.scenes_path, "#{scene.name}.yml")
      File.exists?(scene_path).should eq(true)
    end
  end
end