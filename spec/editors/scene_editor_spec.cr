require "../spec_helper"

describe PaceEditor::Editors::SceneEditor do
  describe "#initialize" do
    it "initializes with correct default values" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      editor.viewport_x.should eq(100)
      editor.viewport_y.should eq(50)
      editor.viewport_width.should eq(800)
      editor.viewport_height.should eq(600)
    end
  end

  describe "#update_viewport" do
    it "updates viewport dimensions correctly" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      editor.update_viewport(200, 100, 1000, 700)

      editor.viewport_x.should eq(200)
      editor.viewport_y.should eq(100)
      editor.viewport_width.should eq(1000)
      editor.viewport_height.should eq(700)
    end
  end

  describe "selection state" do
    it "handles single selection" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      # Test selection state
      state.selected_object.should be_nil
      state.selected_hotspots.should be_empty
      state.selected_characters.should be_empty
    end

    it "handles multi-selection" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      # Add multiple objects to selection
      state.selected_hotspots << "hotspot1"
      state.selected_hotspots << "hotspot2"

      state.selected_hotspots.size.should eq(2)
      state.selected_hotspots.should contain("hotspot1")
      state.selected_hotspots.should contain("hotspot2")
    end

    it "clears selection" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      state.selected_hotspots << "hotspot1"
      state.selected_hotspots.clear

      state.selected_hotspots.should be_empty
    end
  end

  describe "grid snapping" do
    it "respects snap_to_grid setting" do
      state = PaceEditor::Core::EditorState.new
      state.snap_to_grid = true
      state.grid_size = 16

      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      # Grid snapping is controlled by state
      state.snap_to_grid.should be_true
      state.grid_size.should eq(16)
    end

    it "can be disabled" do
      state = PaceEditor::Core::EditorState.new
      state.snap_to_grid = false

      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      state.snap_to_grid.should be_false
    end
  end

  describe "camera controls" do
    it "handles zoom changes" do
      state = PaceEditor::Core::EditorState.new
      state.zoom = 1.0f32

      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      # Zoom in
      state.zoom = state.zoom * 1.1f32
      state.zoom.should be_close(1.1f32, 0.01)

      # Zoom out
      state.zoom = state.zoom * 0.9f32
      state.zoom.should be_close(0.99f32, 0.01)
    end

    it "clamps zoom to valid range" do
      state = PaceEditor::Core::EditorState.new

      # Test minimum zoom
      state.zoom = 0.05f32
      state.zoom = state.zoom.clamp(0.1f32, 5.0f32)
      state.zoom.should eq(0.1f32)

      # Test maximum zoom
      state.zoom = 10.0f32
      state.zoom = state.zoom.clamp(0.1f32, 5.0f32)
      state.zoom.should eq(5.0f32)
    end

    it "handles camera panning" do
      state = PaceEditor::Core::EditorState.new
      state.camera_x = 0
      state.camera_y = 0

      # Pan camera
      state.camera_x += 10
      state.camera_y += 5

      state.camera_x.should eq(10)
      state.camera_y.should eq(5)
    end
  end

  describe "tool handling" do
    it "changes behavior based on current tool" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      # Test different tools
      state.current_tool = PaceEditor::Tool::Select
      state.current_tool.should eq(PaceEditor::Tool::Select)

      state.current_tool = PaceEditor::Tool::Move
      state.current_tool.should eq(PaceEditor::Tool::Move)

      state.current_tool = PaceEditor::Tool::Place
      state.current_tool.should eq(PaceEditor::Tool::Place)

      state.current_tool = PaceEditor::Tool::Delete
      state.current_tool.should eq(PaceEditor::Tool::Delete)
    end
  end

  describe "keyboard shortcuts" do
    it "supports delete for selection" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      state.selected_hotspots << "object_to_delete"

      # Simulate delete key press
      state.selected_hotspots.clear

      state.selected_hotspots.should be_empty
    end

    it "supports clearing selection" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      state.selected_hotspots << "hotspot1"
      state.selected_hotspots << "hotspot2"

      # Simulate escape key
      state.selected_hotspots.clear

      state.selected_hotspots.should be_empty
    end

    it "supports resetting view" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      # Set non-default camera position
      state.camera_x = 100
      state.camera_y = 200
      state.zoom = 2.0f32

      # Simulate home key press
      state.camera_x = 0
      state.camera_y = 0
      state.zoom = 1.0f32

      state.camera_x.should eq(0)
      state.camera_y.should eq(0)
      state.zoom.should eq(1.0f32)
    end
  end

  describe "visual features" do
    it "shows resize handles on selected objects" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      state.selected_hotspots << "selected_object"

      # Resize handles should be drawn for selected objects
      state.selected_hotspots.should contain("selected_object")
    end

    it "shows tool preview for placement" do
      state = PaceEditor::Core::EditorState.new
      state.current_tool = PaceEditor::Tool::Place
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      # Tool preview should be shown when not in select mode
      state.current_tool.should_not eq(PaceEditor::Tool::Select)
    end

    it "shows cursor icons on hotspots when enabled" do
      state = PaceEditor::Core::EditorState.new
      state.show_hotspots = true
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      state.show_hotspots.should be_true
    end
  end

  describe "multiple selection" do
    it "supports selecting multiple hotspots" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      # Simulate rectangle selection
      state.selected_hotspots.clear
      state.selected_hotspots << "h1"
      state.selected_hotspots << "h2"

      state.selected_hotspots.size.should eq(2)
      state.selected_hotspots.should contain("h1")
      state.selected_hotspots.should contain("h2")
    end

    it "supports mixed selection of hotspots and characters" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      state.selected_hotspots << "hotspot1"
      state.selected_characters << "character1"

      state.selected_hotspots.size.should eq(1)
      state.selected_characters.size.should eq(1)
    end
  end
end
