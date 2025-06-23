require "../spec_helper"
require "../../src/pace_editor/core/editor_state"

describe "Multiple Object Selection" do
  describe "EditorState multi-selection" do
    it "supports selecting multiple objects" do
      state = PaceEditor::Core::EditorState.new

      # Create a test scene with objects
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot1 = PointClickEngine::Scenes::Hotspot.new(
        "hotspot1",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(64.0_f32, 64.0_f32)
      )
      hotspot2 = PointClickEngine::Scenes::Hotspot.new(
        "hotspot2",
        RL::Vector2.new(200.0_f32, 200.0_f32),
        RL::Vector2.new(64.0_f32, 64.0_f32)
      )
      scene.hotspots << hotspot1
      scene.hotspots << hotspot2
      state.current_scene = scene

      # Initially no selection
      state.get_selected_objects.should be_empty
      state.has_multiple_selection?.should be_false

      # Select first object
      state.select_object("hotspot1")
      state.get_selected_objects.should eq(["hotspot1"])
      state.is_selected?("hotspot1").should be_true
      state.has_multiple_selection?.should be_false

      # Add second object to selection
      state.select_object("hotspot2", multi_select: true)
      state.get_selected_objects.size.should eq(2)
      state.get_selected_objects.should contain("hotspot1")
      state.get_selected_objects.should contain("hotspot2")
      state.has_multiple_selection?.should be_true

      # Both should be selected
      state.is_selected?("hotspot1").should be_true
      state.is_selected?("hotspot2").should be_true
    end

    it "supports toggling object selection" do
      state = PaceEditor::Core::EditorState.new

      # Create a test scene
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "hotspot1",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(64.0_f32, 64.0_f32)
      )
      scene.hotspots << hotspot
      state.current_scene = scene

      # Initially not selected
      state.is_selected?("hotspot1").should be_false

      # Toggle to select
      state.toggle_object_selection("hotspot1")
      state.is_selected?("hotspot1").should be_true

      # Toggle to deselect
      state.toggle_object_selection("hotspot1")
      state.is_selected?("hotspot1").should be_false
    end

    it "supports deselecting individual objects" do
      state = PaceEditor::Core::EditorState.new

      # Create test scene with multiple objects
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot1 = PointClickEngine::Scenes::Hotspot.new(
        "hotspot1",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(64.0_f32, 64.0_f32)
      )
      hotspot2 = PointClickEngine::Scenes::Hotspot.new(
        "hotspot2",
        RL::Vector2.new(200.0_f32, 200.0_f32),
        RL::Vector2.new(64.0_f32, 64.0_f32)
      )
      scene.hotspots << hotspot1
      scene.hotspots << hotspot2
      state.current_scene = scene

      # Select both objects
      state.select_object("hotspot1")
      state.select_object("hotspot2", multi_select: true)
      state.get_selected_objects.size.should eq(2)

      # Deselect one object
      state.deselect_object("hotspot1")
      state.get_selected_objects.size.should eq(1)
      state.is_selected?("hotspot1").should be_false
      state.is_selected?("hotspot2").should be_true
    end

    it "clears all selections properly" do
      state = PaceEditor::Core::EditorState.new

      # Create test scene
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "hotspot1",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(64.0_f32, 64.0_f32)
      )
      character = PointClickEngine::Characters::NPC.new(
        "character1",
        RL::Vector2.new(150.0_f32, 150.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      scene.hotspots << hotspot
      scene.characters << character
      state.current_scene = scene

      # Select objects of different types
      state.select_object("hotspot1")
      state.select_object("character1", multi_select: true)
      state.get_selected_objects.size.should eq(2)

      # Clear all selections
      state.clear_selection
      state.get_selected_objects.should be_empty
      state.is_selected?("hotspot1").should be_false
      state.is_selected?("character1").should be_false
      state.has_multiple_selection?.should be_false
    end

    it "handles selection of mixed object types" do
      state = PaceEditor::Core::EditorState.new

      # Create test scene with different object types
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "hotspot1",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(64.0_f32, 64.0_f32)
      )
      character = PointClickEngine::Characters::NPC.new(
        "character1",
        RL::Vector2.new(150.0_f32, 150.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      scene.hotspots << hotspot
      scene.characters << character
      state.current_scene = scene

      # Select both types of objects
      state.select_object("hotspot1")
      state.select_object("character1", multi_select: true)

      # Both should be in appropriate selection arrays
      state.selected_hotspots.should contain("hotspot1")
      state.selected_characters.should contain("character1")
      state.get_selected_objects.size.should eq(2)
      state.has_multiple_selection?.should be_true
    end
  end

  describe "primary selection management" do
    it "updates primary selection when deselecting primary object" do
      state = PaceEditor::Core::EditorState.new

      # Create test scene
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot1 = PointClickEngine::Scenes::Hotspot.new("hotspot1", RL::Vector2.new(100.0_f32, 100.0_f32), RL::Vector2.new(64.0_f32, 64.0_f32))
      hotspot2 = PointClickEngine::Scenes::Hotspot.new("hotspot2", RL::Vector2.new(200.0_f32, 200.0_f32), RL::Vector2.new(64.0_f32, 64.0_f32))
      scene.hotspots << hotspot1
      scene.hotspots << hotspot2
      state.current_scene = scene

      # Select multiple objects
      state.select_object("hotspot1")
      state.select_object("hotspot2", multi_select: true)

      # Primary selection should be first selected
      state.selected_object.should eq("hotspot1")

      # Deselect primary object
      state.deselect_object("hotspot1")

      # Primary selection should update to remaining object
      state.selected_object.should eq("hotspot2")
    end

    it "handles empty selection gracefully" do
      state = PaceEditor::Core::EditorState.new

      # Test operations on empty selection
      state.get_selected_objects.should be_empty
      state.has_multiple_selection?.should be_false
      state.is_selected?("nonexistent").should be_false

      # Deselecting non-existent object should not crash
      state.deselect_object("nonexistent")
      state.get_selected_objects.should be_empty
    end
  end
end
