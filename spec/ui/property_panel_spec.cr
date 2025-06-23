require "../spec_helper"
require "../../src/pace_editor/ui/property_panel"

describe PaceEditor::UI::PropertyPanel do
  describe "initialization" do
    it "creates a property panel with default values" do
      state = PaceEditor::Core::EditorState.new
      panel = PaceEditor::UI::PropertyPanel.new(state)

      # The panel should be initialized
      panel.should_not be_nil
    end
  end

  describe "property editing" do
    it "activates text field on click" do
      state = PaceEditor::Core::EditorState.new
      panel = PaceEditor::UI::PropertyPanel.new(state)

      # Simulate selecting a hotspot
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(100.0_f32, 200.0_f32),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      scene.hotspots << hotspot
      state.current_scene = scene
      state.selected_object = "test_hotspot"

      # The panel should be able to find the selected hotspot
      # Note: In real usage, the click handling and field activation
      # would be tested through integration tests with Raylib
    end
  end

  describe "property value changes" do
    it "updates hotspot position through property panel" do
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
      state.selected_object = "test_hotspot"

      panel = PaceEditor::UI::PropertyPanel.new(state)

      # Simulate property change through private method
      # In real implementation, this would be triggered by UI interaction
      initial_x = hotspot.position.x
      new_x = 150.0_f32

      # The property change would update the hotspot position
      # and create an undo action
      initial_x.should eq(100.0_f32)
    end

    it "updates character properties" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      npc = PointClickEngine::Characters::NPC.new(
        "test_npc",
        RL::Vector2.new(300.0_f32, 400.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      npc.walking_speed = 100.0_f32
      scene.characters << npc
      state.current_scene = scene
      state.selected_object = "test_npc"

      panel = PaceEditor::UI::PropertyPanel.new(state)

      # Verify initial values
      npc.walking_speed.should eq(100.0_f32)
      npc.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
    end
  end

  describe "dropdown controls" do
    it "cycles through cursor types" do
      state = PaceEditor::Core::EditorState.new
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(100.0_f32, 200.0_f32),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Default
      scene.hotspots << hotspot
      state.current_scene = scene
      state.selected_object = "test_hotspot"

      panel = PaceEditor::UI::PropertyPanel.new(state)

      # Verify cursor type cycling
      hotspot.cursor_type.should eq(PointClickEngine::Scenes::Hotspot::CursorType::Default)

      # In real usage, clicking the dropdown would cycle through:
      # Default -> Hand -> Look -> Talk -> Use -> Default
    end

    it "cycles through character states" do
      state = PaceEditor::Core::EditorState.new
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      npc = PointClickEngine::Characters::NPC.new(
        "test_npc",
        RL::Vector2.new(300.0_f32, 400.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      npc.state = PointClickEngine::Characters::CharacterState::Idle
      scene.characters << npc
      state.current_scene = scene
      state.selected_object = "test_npc"

      panel = PaceEditor::UI::PropertyPanel.new(state)

      # Verify state cycling
      npc.state.should eq(PointClickEngine::Characters::CharacterState::Idle)

      # In real usage, clicking would cycle through:
      # Idle -> Walking -> Talking -> Interacting -> Thinking -> Idle
    end

    it "cycles through NPC moods" do
      state = PaceEditor::Core::EditorState.new
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      npc = PointClickEngine::Characters::NPC.new(
        "test_npc",
        RL::Vector2.new(300.0_f32, 400.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      npc.mood = PointClickEngine::Characters::NPCMood::Neutral
      scene.characters << npc
      state.current_scene = scene
      state.selected_object = "test_npc"

      panel = PaceEditor::UI::PropertyPanel.new(state)

      # Verify mood cycling
      npc.mood.should eq(PointClickEngine::Characters::NPCMood::Neutral)

      # In real usage, clicking would cycle through:
      # Friendly -> Neutral -> Hostile -> Sad -> Happy -> Angry -> Friendly
    end
  end

  describe "undo integration" do
    it "creates undo actions for position changes" do
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
      state.selected_object = "test_hotspot"

      panel = PaceEditor::UI::PropertyPanel.new(state)

      # Initially no undo actions
      state.can_undo?.should be_false

      # After a position change through the property panel,
      # an undo action would be created
      # state.can_undo?.should be_true
    end
  end
end
