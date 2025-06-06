require "../spec_helper"

describe PaceEditor::Editors::SceneEditor do
  describe "#initialize" do
    it "initializes with correct default values" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      editor.drag_start.should be_nil
      editor.dragging_object.should be_nil
      editor.is_camera_dragging.should be_false
    end
  end

  describe "#find_object_at_position" do
    it "finds hotspots at position" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Create a test scene with hotspots
      scene = PointClickEngine::Scene.new("test_scene")
      hotspot1 = PointClickEngine::Hotspot.new("hotspot1", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 50, y: 50))
      hotspot2 = PointClickEngine::Hotspot.new("hotspot2", RL::Vector2.new(x: 200, y: 200), RL::Vector2.new(x: 50, y: 50))

      scene.add_hotspot(hotspot1)
      scene.add_hotspot(hotspot2)

      # Mock the current scene
      allow(state).to receive(:current_scene).and_return(scene)

      # Test finding objects
      result = editor.find_object_at_position(RL::Vector2.new(x: 120, y: 120))
      result.should eq("hotspot1")

      result = editor.find_object_at_position(RL::Vector2.new(x: 220, y: 220))
      result.should eq("hotspot2")

      result = editor.find_object_at_position(RL::Vector2.new(x: 50, y: 50))
      result.should be_nil
    end

    it "finds characters at position" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Create a test scene with characters
      scene = PointClickEngine::Scene.new("test_scene")
      character = PointClickEngine::Characters::Character.new("hero", RL::Vector2.new(x: 300, y: 300), RL::Vector2.new(x: 32, y: 64))
      scene.add_character(character)

      allow(state).to receive(:current_scene).and_return(scene)

      result = editor.find_object_at_position(RL::Vector2.new(x: 310, y: 330))
      result.should eq("hero")

      result = editor.find_object_at_position(RL::Vector2.new(x: 400, y: 400))
      result.should be_nil
    end

    it "prioritizes hotspots over characters" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Create overlapping hotspot and character
      scene = PointClickEngine::Scene.new("test_scene")
      character = PointClickEngine::Characters::Character.new("hero", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 50, y: 50))
      hotspot = PointClickEngine::Hotspot.new("hotspot", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 50, y: 50))

      scene.add_character(character)
      scene.add_hotspot(hotspot)

      allow(state).to receive(:current_scene).and_return(scene)

      # Should return hotspot (higher priority)
      result = editor.find_object_at_position(RL::Vector2.new(x: 120, y: 120))
      result.should eq("hotspot")
    end
  end

  describe "#point_in_rect?" do
    it "detects point inside rectangle" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      point = RL::Vector2.new(x: 25, y: 35)
      rect_pos = RL::Vector2.new(x: 10, y: 20)
      rect_size = RL::Vector2.new(x: 50, y: 40)

      result = editor.point_in_rect?(point, rect_pos, rect_size)
      result.should be_true
    end

    it "detects point outside rectangle" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      point = RL::Vector2.new(x: 5, y: 5)
      rect_pos = RL::Vector2.new(x: 10, y: 20)
      rect_size = RL::Vector2.new(x: 50, y: 40)

      result = editor.point_in_rect?(point, rect_pos, rect_size)
      result.should be_false
    end

    it "handles edge cases correctly" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      rect_pos = RL::Vector2.new(x: 10, y: 20)
      rect_size = RL::Vector2.new(x: 50, y: 40)

      # Point on left edge
      point = RL::Vector2.new(x: 10, y: 30)
      editor.point_in_rect?(point, rect_pos, rect_size).should be_true

      # Point on right edge
      point = RL::Vector2.new(x: 60, y: 30)
      editor.point_in_rect?(point, rect_pos, rect_size).should be_true

      # Point on top edge
      point = RL::Vector2.new(x: 30, y: 20)
      editor.point_in_rect?(point, rect_pos, rect_size).should be_true

      # Point on bottom edge
      point = RL::Vector2.new(x: 30, y: 60)
      editor.point_in_rect?(point, rect_pos, rect_size).should be_true

      # Point just outside
      point = RL::Vector2.new(x: 61, y: 30)
      editor.point_in_rect?(point, rect_pos, rect_size).should be_false
    end
  end

  describe "#mouse_in_viewport?" do
    it "detects mouse inside viewport" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      # Mouse inside viewport
      mouse_pos = RL::Vector2.new(x: 200, y: 100)
      result = editor.mouse_in_viewport?(mouse_pos)
      result.should be_true

      # Mouse at viewport edges
      mouse_pos = RL::Vector2.new(x: 100, y: 50)
      result = editor.mouse_in_viewport?(mouse_pos)
      result.should be_true

      mouse_pos = RL::Vector2.new(x: 900, y: 650)
      result = editor.mouse_in_viewport?(mouse_pos)
      result.should be_true
    end

    it "detects mouse outside viewport" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      # Mouse left of viewport
      mouse_pos = RL::Vector2.new(x: 50, y: 100)
      result = editor.mouse_in_viewport?(mouse_pos)
      result.should be_false

      # Mouse above viewport
      mouse_pos = RL::Vector2.new(x: 200, y: 25)
      result = editor.mouse_in_viewport?(mouse_pos)
      result.should be_false

      # Mouse right of viewport
      mouse_pos = RL::Vector2.new(x: 950, y: 100)
      result = editor.mouse_in_viewport?(mouse_pos)
      result.should be_false

      # Mouse below viewport
      mouse_pos = RL::Vector2.new(x: 200, y: 700)
      result = editor.mouse_in_viewport?(mouse_pos)
      result.should be_false
    end
  end

  describe "tool modes" do
    it "handles select tool state correctly" do
      state = PaceEditor::Core::EditorState.new
      state.current_tool = PaceEditor::Tool::Select
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Create test scene
      scene = PointClickEngine::Scene.new("test_scene")
      hotspot = PointClickEngine::Hotspot.new("test_hotspot", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 50, y: 50))
      scene.add_hotspot(hotspot)

      allow(state).to receive(:current_scene).and_return(scene)

      # Simulate tool behavior
      state.current_tool.should eq(PaceEditor::Tool::Select)
    end

    it "handles move tool state correctly" do
      state = PaceEditor::Core::EditorState.new
      state.current_tool = PaceEditor::Tool::Move
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      state.current_tool.should eq(PaceEditor::Tool::Move)
    end

    it "handles place tool state correctly" do
      state = PaceEditor::Core::EditorState.new
      state.current_tool = PaceEditor::Tool::Place
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      state.current_tool.should eq(PaceEditor::Tool::Place)
    end

    it "handles delete tool state correctly" do
      state = PaceEditor::Core::EditorState.new
      state.current_tool = PaceEditor::Tool::Delete
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      state.current_tool.should eq(PaceEditor::Tool::Delete)
    end
  end

  describe "drag operations" do
    it "tracks drag start position" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      start_pos = RL::Vector2.new(x: 100, y: 200)
      editor.drag_start = start_pos

      editor.drag_start.should eq(start_pos)
    end

    it "tracks dragging object" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      editor.dragging_object = "test_object"
      editor.dragging_object.should eq("test_object")
    end

    it "resets drag state correctly" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Set drag state
      editor.drag_start = RL::Vector2.new(x: 100, y: 200)
      editor.dragging_object = "test_object"

      # Reset
      editor.drag_start = nil
      editor.dragging_object = nil

      editor.drag_start.should be_nil
      editor.dragging_object.should be_nil
    end
  end
end

# Helper method to allow mocking in specs
private def allow(object)
  object
end

private class MockObject
  def receive(method_name)
    self
  end

  def and_return(value)
    value
  end
end

private def allow(object)
  MockObject.new
end
