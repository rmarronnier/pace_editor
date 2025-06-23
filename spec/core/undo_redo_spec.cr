require "../spec_helper"
require "../../src/pace_editor/core/editor_state"

describe "Undo/Redo System" do
  describe PaceEditor::Core::MoveObjectAction do
    it "undoes object movement" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(100.0_f32, 200.0_f32),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      scene.hotspots << hotspot
      state.current_scene = scene
      
      # Create move action
      old_pos = RL::Vector2.new(100.0_f32, 200.0_f32)
      new_pos = RL::Vector2.new(150.0_f32, 250.0_f32)
      action = PaceEditor::Core::MoveObjectAction.new("test_hotspot", old_pos, new_pos, state)
      
      # Move the object
      hotspot.position = new_pos
      
      # Undo should restore old position
      action.undo
      hotspot.position.x.should eq(100.0_f32)
      hotspot.position.y.should eq(200.0_f32)
    end
    
    it "redoes object movement" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(100.0_f32, 200.0_f32),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      scene.hotspots << hotspot
      state.current_scene = scene
      
      old_pos = RL::Vector2.new(100.0_f32, 200.0_f32)
      new_pos = RL::Vector2.new(150.0_f32, 250.0_f32)
      action = PaceEditor::Core::MoveObjectAction.new("test_hotspot", old_pos, new_pos, state)
      
      # Start at old position
      hotspot.position = old_pos
      
      # Redo should apply new position
      action.redo
      hotspot.position.x.should eq(150.0_f32)
      hotspot.position.y.should eq(250.0_f32)
    end
    
    it "works with character objects" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      npc = PointClickEngine::Characters::NPC.new(
        "test_npc",
        RL::Vector2.new(300.0_f32, 400.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      scene.characters << npc
      state.current_scene = scene
      
      old_pos = RL::Vector2.new(300.0_f32, 400.0_f32)
      new_pos = RL::Vector2.new(350.0_f32, 450.0_f32)
      action = PaceEditor::Core::MoveObjectAction.new("test_npc", old_pos, new_pos, state)
      
      # Move the character
      npc.position = new_pos
      
      # Undo should restore old position
      action.undo
      npc.position.x.should eq(300.0_f32)
      npc.position.y.should eq(400.0_f32)
    end
    
    it "provides descriptive text" do
      state = PaceEditor::Core::EditorState.new
      action = PaceEditor::Core::MoveObjectAction.new(
        "door",
        RL::Vector2.new(0, 0),
        RL::Vector2.new(10, 10),
        state
      )
      
      action.description.should eq("Move door")
    end
  end
  
  describe PaceEditor::Core::CreateObjectAction do
    it "undoes object creation by removing it" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      state.current_scene = scene
      
      # Create a hotspot
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "new_hotspot",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      scene.hotspots << hotspot
      state.selected_object = "new_hotspot"
      
      action = PaceEditor::Core::CreateObjectAction.new(
        "new_hotspot",
        "hotspot",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        state
      )
      
      scene.hotspots.size.should eq(1)
      
      # Undo should remove the object
      action.undo
      scene.hotspots.size.should eq(0)
      state.selected_object.should be_nil
    end
    
    it "redoes object creation by recreating it" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      state.current_scene = scene
      
      action = PaceEditor::Core::CreateObjectAction.new(
        "new_hotspot",
        "hotspot",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        state
      )
      
      scene.hotspots.size.should eq(0)
      
      # Redo should create the object
      action.redo
      scene.hotspots.size.should eq(1)
      scene.hotspots[0].name.should eq("new_hotspot")
      scene.hotspots[0].position.x.should eq(100.0_f32)
      scene.hotspots[0].position.y.should eq(100.0_f32)
      state.selected_object.should eq("new_hotspot")
    end
    
    it "creates characters correctly" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      state.current_scene = scene
      
      action = PaceEditor::Core::CreateObjectAction.new(
        "new_npc",
        "character",
        RL::Vector2.new(200.0_f32, 300.0_f32),
        state
      )
      
      scene.characters.size.should eq(0)
      
      # Redo should create the character
      action.redo
      scene.characters.size.should eq(1)
      npc = scene.characters[0].as(PointClickEngine::Characters::NPC)
      npc.name.should eq("new_npc")
      npc.position.x.should eq(200.0_f32)
      npc.position.y.should eq(300.0_f32)
      npc.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      npc.mood.should eq(PointClickEngine::Characters::NPCMood::Neutral)
    end
    
    it "provides descriptive text" do
      state = PaceEditor::Core::EditorState.new
      action = PaceEditor::Core::CreateObjectAction.new(
        "button",
        "hotspot",
        RL::Vector2.new(0, 0),
        state
      )
      
      action.description.should eq("Create button")
    end
  end
  
  describe "EditorState undo/redo management" do
    it "manages undo stack correctly" do
      state = PaceEditor::Core::EditorState.new
      
      state.can_undo?.should be_false
      state.can_redo?.should be_false
      
      # Add an action
      action = PaceEditor::Core::SimpleAction.new("Test action")
      state.add_undo_action(action)
      
      state.can_undo?.should be_true
      state.can_redo?.should be_false
    end
    
    it "performs undo operation" do
      state = PaceEditor::Core::EditorState.new
      
      action = PaceEditor::Core::SimpleAction.new("Test action")
      state.add_undo_action(action)
      
      result = state.undo
      result.should be_true
      
      state.can_undo?.should be_false
      state.can_redo?.should be_true
    end
    
    it "performs redo operation" do
      state = PaceEditor::Core::EditorState.new
      
      action = PaceEditor::Core::SimpleAction.new("Test action")
      state.add_undo_action(action)
      state.undo
      
      result = state.redo
      result.should be_true
      
      state.can_undo?.should be_true
      state.can_redo?.should be_false
    end
    
    it "clears redo stack when new action is added" do
      state = PaceEditor::Core::EditorState.new
      
      action1 = PaceEditor::Core::SimpleAction.new("Action 1")
      action2 = PaceEditor::Core::SimpleAction.new("Action 2")
      
      state.add_undo_action(action1)
      state.undo
      state.can_redo?.should be_true
      
      # Adding new action should clear redo stack
      state.add_undo_action(action2)
      state.can_redo?.should be_false
    end
    
    it "limits undo stack size" do
      state = PaceEditor::Core::EditorState.new
      
      # Add more actions than the limit (50)
      60.times do |i|
        action = PaceEditor::Core::SimpleAction.new("Action #{i}")
        state.add_undo_action(action)
      end
      
      # Stack should be limited to max_undo_levels (50)
      undo_count = 0
      while state.can_undo?
        state.undo
        undo_count += 1
      end
      
      undo_count.should eq(50)
    end
    
    it "returns false when undo stack is empty" do
      state = PaceEditor::Core::EditorState.new
      
      result = state.undo
      result.should be_false
    end
    
    it "returns false when redo stack is empty" do
      state = PaceEditor::Core::EditorState.new
      
      result = state.redo
      result.should be_false
    end
  end
end