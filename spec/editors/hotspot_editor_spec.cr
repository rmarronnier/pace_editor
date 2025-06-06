require "../spec_helper"

describe PaceEditor::Editors::HotspotEditor do
  describe "#initialize" do
    it "initializes with correct default values" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      editor.current_hotspot.should be_nil
      editor.creating_hotspot.should be_false
      editor.hotspot_start.should be_nil
    end
  end

  describe "#get_current_hotspot" do
    it "returns cached hotspot when available" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      # Create test hotspot
      hotspot = PointClickEngine::Hotspot.new("test_hotspot", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 50, y: 50))
      hotspot.description = "Test hotspot description"
      editor.current_hotspot = hotspot

      result = editor.get_current_hotspot
      result.should eq(hotspot)
    end

    it "finds hotspot from selection when no cached hotspot" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      # Create test scene with hotspot
      scene = PointClickEngine::Scene.new("test_scene")
      hotspot = PointClickEngine::Hotspot.new("selected_hotspot", RL::Vector2.new(x: 200, y: 150), RL::Vector2.new(x: 80, y: 60))
      hotspot.description = "Selected hotspot"
      scene.add_hotspot(hotspot)

      # Set up state
      state.current_project = create_test_project
      state.selected_object = "selected_hotspot"

      # Mock current scene
      allow(state).to receive(:current_scene).and_return(scene)

      result = editor.get_current_hotspot
      result.should eq(hotspot)
      editor.current_hotspot.should eq(hotspot) # Should cache it
    end

    it "returns nil when no hotspot found" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      result = editor.get_current_hotspot
      result.should be_nil
    end
  end

  describe "#start_hotspot_creation" do
    it "sets creation mode correctly" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      editor.start_hotspot_creation("rectangle")

      editor.creating_hotspot.should be_true
      state.current_mode.should eq(PaceEditor::EditorMode::Scene)
    end

    it "handles different hotspot shapes" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      editor.start_hotspot_creation("circle")
      editor.creating_hotspot.should be_true

      editor.creating_hotspot = false
      editor.start_hotspot_creation("rectangle")
      editor.creating_hotspot.should be_true
    end
  end

  describe "#create_hotspot_from_drag" do
    it "creates hotspot with correct dimensions" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      # Create test scene
      scene = PointClickEngine::Scene.new("test_scene")
      initial_hotspot_count = scene.hotspots.size

      # Set up state
      state.current_project = create_test_project
      allow(state).to receive(:current_scene).and_return(scene)
      allow(state).to receive(:save_current_scene)

      # Create hotspot from drag
      start_pos = RL::Vector2.new(x: 100, y: 100)
      end_pos = RL::Vector2.new(x: 180, y: 160)

      editor.create_hotspot_from_drag(start_pos, end_pos)

      # Should have added one hotspot
      scene.hotspots.size.should eq(initial_hotspot_count + 1)

      # Should set as current hotspot
      editor.current_hotspot.should_not be_nil
      new_hotspot = editor.current_hotspot.not_nil!

      # Check dimensions
      new_hotspot.position.x.should eq(100)
      new_hotspot.position.y.should eq(100)
      new_hotspot.size.x.should eq(80) # 180 - 100
      new_hotspot.size.y.should eq(60) # 160 - 100

      # Should select the new hotspot
      state.selected_object.should eq(new_hotspot.name)
    end

    it "handles reverse drag correctly" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      scene = PointClickEngine::Scene.new("test_scene")
      state.current_project = create_test_project
      allow(state).to receive(:current_scene).and_return(scene)
      allow(state).to receive(:save_current_scene)

      # Drag from bottom-right to top-left
      start_pos = RL::Vector2.new(x: 180, y: 160)
      end_pos = RL::Vector2.new(x: 100, y: 100)

      editor.create_hotspot_from_drag(start_pos, end_pos)

      new_hotspot = editor.current_hotspot.not_nil!

      # Should normalize to top-left origin
      new_hotspot.position.x.should eq(100)
      new_hotspot.position.y.should eq(100)
      new_hotspot.size.x.should eq(80)
      new_hotspot.size.y.should eq(60)
    end

    it "enforces minimum hotspot size" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      scene = PointClickEngine::Scene.new("test_scene")
      state.current_project = create_test_project
      allow(state).to receive(:current_scene).and_return(scene)
      allow(state).to receive(:save_current_scene)

      # Very small drag
      start_pos = RL::Vector2.new(x: 100, y: 100)
      end_pos = RL::Vector2.new(x: 102, y: 103)

      editor.create_hotspot_from_drag(start_pos, end_pos)

      new_hotspot = editor.current_hotspot.not_nil!

      # Should have minimum size of 10x10
      new_hotspot.size.x.should eq(10)
      new_hotspot.size.y.should eq(10)
    end

    it "handles case when no scene is available" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      # No current scene
      allow(state).to receive(:current_scene).and_return(nil)

      start_pos = RL::Vector2.new(x: 100, y: 100)
      end_pos = RL::Vector2.new(x: 180, y: 160)

      editor.create_hotspot_from_drag(start_pos, end_pos)

      # Should not crash, hotspot should remain nil
      editor.current_hotspot.should be_nil
    end
  end

  describe "#delete_current_hotspot" do
    it "removes hotspot from scene" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      # Create test scene with hotspot
      scene = PointClickEngine::Scene.new("test_scene")
      hotspot = PointClickEngine::Hotspot.new("to_delete", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 50, y: 50))
      scene.add_hotspot(hotspot)
      editor.current_hotspot = hotspot

      initial_count = scene.hotspots.size

      # Set up state
      state.current_project = create_test_project
      allow(state).to receive(:current_scene).and_return(scene)
      allow(state).to receive(:save_current_scene)
      allow(state).to receive(:clear_selection)

      editor.delete_current_hotspot

      # Should have removed the hotspot
      scene.hotspots.size.should eq(initial_count - 1)
      scene.hotspots.should_not contain(hotspot)

      # Should clear current hotspot
      editor.current_hotspot.should be_nil
    end

    it "handles case when no current hotspot" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      # No current hotspot
      editor.current_hotspot = nil

      # Should not crash
      editor.delete_current_hotspot
      editor.current_hotspot.should be_nil
    end

    it "handles case when no scene available" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      hotspot = PointClickEngine::Hotspot.new("test", RL::Vector2.new(x: 0, y: 0), RL::Vector2.new(x: 10, y: 10))
      editor.current_hotspot = hotspot

      # No current scene
      allow(state).to receive(:current_scene).and_return(nil)

      # Should not crash
      editor.delete_current_hotspot
    end
  end

  describe "#test_hotspot_interaction" do
    it "tests hotspot without crashing" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      hotspot = PointClickEngine::Hotspot.new("test_hotspot", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 50, y: 50))
      hotspot.description = "Test interaction"

      # Should not crash
      editor.test_hotspot_interaction(hotspot)
    end
  end

  describe "hotspot creation state" do
    it "manages creation state correctly" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      # Initially not creating
      editor.creating_hotspot.should be_false
      editor.hotspot_start.should be_nil

      # Start creation
      editor.creating_hotspot = true
      editor.hotspot_start = RL::Vector2.new(x: 100, y: 100)

      editor.creating_hotspot.should be_true
      editor.hotspot_start.should eq(RL::Vector2.new(x: 100, y: 100))

      # End creation
      editor.creating_hotspot = false
      editor.hotspot_start = nil

      editor.creating_hotspot.should be_false
      editor.hotspot_start.should be_nil
    end
  end

  describe "hotspot properties" do
    it "handles hotspot with various properties" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      # Create hotspot with specific properties
      hotspot = PointClickEngine::Hotspot.new(
        "interactive_door",
        RL::Vector2.new(x: 150, y: 200),
        RL::Vector2.new(x: 60, y: 120)
      )
      hotspot.description = "A wooden door"
      hotspot.active = true

      editor.current_hotspot = hotspot

      hotspot.name.should eq("interactive_door")
      hotspot.description.should eq("A wooden door")
      hotspot.position.x.should eq(150)
      hotspot.position.y.should eq(200)
      hotspot.size.x.should eq(60)
      hotspot.size.y.should eq(120)
      hotspot.active.should be_true
    end

    it "validates hotspot properties" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      hotspot = PointClickEngine::Hotspot.new(
        "valid_hotspot",
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 1, y: 1)
      )

      editor.current_hotspot = hotspot

      # Basic validation
      hotspot.name.should_not be_empty
      hotspot.size.x.should be > 0
      hotspot.size.y.should be > 0
    end
  end
end

# Helper methods for testing
private def create_test_project
  test_dir = File.tempname("test_project")
  project = PaceEditor::Core::Project.new("Test Project", test_dir)
  project
end

# Simple mock helpers
private def allow(object)
  MockHelper.new
end

private class MockHelper
  def receive(method_name)
    self
  end

  def and_return(value)
    value
  end
end
