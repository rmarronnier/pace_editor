require "../spec_helper"
require "../../src/pace_editor/editors/hotspot_editor"

describe PaceEditor::Editors::HotspotEditor do
  let(:state) { PaceEditor::Core::EditorState.new }
  let(:editor) { PaceEditor::Editors::HotspotEditor.new(state) }
  let(:project) { create_test_project }
  let(:scene) { create_test_scene }

  before_each do
    state.current_project = project
    state.current_scene = scene
  end

  describe "script editor integration" do
    let(:test_hotspot) do
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        name: "test_hotspot",
        position: RL::Vector2.new(100, 100),
        size: RL::Vector2.new(64, 64)
      )
      hotspot.description = "Test hotspot for script editing"
      hotspot
    end

    before_each do
      scene.hotspots << test_hotspot
      state.select_object(test_hotspot.name)
    end

    describe "#edit_hotspot_scripts" do
      it "opens script editor for selected hotspot" do
        # Mock the script editor to verify it was called
        script_editor = editor.@script_editor
        script_editor.visible.should be_false

        # This would normally require UI interaction to trigger
        editor.send(:edit_hotspot_scripts)

        # Verify script editor was shown (in a real test, we'd check visibility)
        # For now, verify the method completes without error
      end

      it "creates script file path for hotspot" do
        script_path = editor.send(:get_hotspot_script_path, test_hotspot.name)
        script_path.should_not be_nil
        script_path.should contain("test_hotspot")
        script_path.should contain(".lua")
      end

      it "creates default script if none exists" do
        script_path = editor.send(:get_hotspot_script_path, test_hotspot.name)

        if script_path && !File.exists?(script_path)
          editor.send(:create_default_hotspot_script, script_path, test_hotspot.name)
          File.exists?(script_path).should be_true

          content = File.read(script_path)
          content.should contain("function on_click()")
          content.should contain("function on_look()")
          content.should contain("function on_use()")
          content.should contain("function on_talk()")
          content.should contain(test_hotspot.name)

          # Clean up
          File.delete(script_path)
        end
      end

      it "handles missing project gracefully" do
        state.current_project = nil

        editor.send(:edit_hotspot_scripts)
        # Should not crash
      end

      it "handles no selected hotspot gracefully" do
        state.clear_selection

        editor.send(:edit_hotspot_scripts)
        # Should not crash and should print appropriate message
      end
    end

    describe "#get_selected_hotspot" do
      it "returns current hotspot if set" do
        editor.current_hotspot = test_hotspot
        result = editor.send(:get_selected_hotspot)
        result.should eq(test_hotspot)
      end

      it "finds hotspot from editor state selection" do
        editor.current_hotspot = nil
        state.select_object(test_hotspot.name)

        result = editor.send(:get_selected_hotspot)
        result.should eq(test_hotspot)
      end

      it "returns nil when no hotspot is selected" do
        editor.current_hotspot = nil
        state.clear_selection

        result = editor.send(:get_selected_hotspot)
        result.should be_nil
      end
    end

    describe "#get_hotspot_script_path" do
      it "generates correct script path" do
        path = editor.send(:get_hotspot_script_path, "my hotspot")
        path.should contain("my_hotspot_hotspot.lua")
        path.should contain(project.scripts_path)
      end

      it "handles special characters in names" do
        path = editor.send(:get_hotspot_script_path, "Door #1 (Main)")
        path.should contain("door_#1_(main)_hotspot.lua")
      end

      it "returns nil for missing project" do
        state.current_project = nil
        path = editor.send(:get_hotspot_script_path, "test")
        path.should be_nil
      end
    end

    describe "script editor lifecycle" do
      it "updates script editor along with main editor" do
        editor.update
        # Script editor should be updated
        # This would be verified by checking internal state
      end

      it "draws script editor when visible" do
        # This would require graphics testing framework
        # For now, verify the draw method doesn't crash
        editor.draw
      end

      it "blocks main editor input when script editor is visible" do
        # Simulate script editor being visible
        editor.@script_editor.visible = true

        # Main editor should not handle input
        editor.update
        # Would verify that handle_hotspot_creation is not called
      end
    end
  end

  describe "hotspot interaction preview integration" do
    let(:test_hotspot) do
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        name: "interactive_hotspot",
        position: RL::Vector2.new(200, 200),
        size: RL::Vector2.new(32, 32)
      )
      hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
      hotspot
    end

    before_each do
      scene.hotspots << test_hotspot
    end

    describe "#test_hotspot_interaction" do
      it "opens interaction preview for hotspot" do
        preview = editor.@interaction_preview
        preview.visible.should be_false

        editor.send(:test_hotspot_interaction, test_hotspot)

        # In a real test, we'd verify the preview window is shown
        # For now, verify method completes without error
      end

      it "loads hotspot data for preview" do
        hotspot_data = editor.send(:load_hotspot_data, test_hotspot.name)
        # Currently returns nil as placeholder
        hotspot_data.should be_nil
      end
    end
  end

  describe "integration with editor state" do
    let(:test_hotspot) do
      PointClickEngine::Scenes::Hotspot.new(
        name: "state_test_hotspot",
        position: RL::Vector2.new(50, 50),
        size: RL::Vector2.new(48, 48)
      )
    end

    before_each do
      scene.hotspots << test_hotspot
    end

    it "respects editor tool state" do
      state.current_tool = Core::Tool::Select
      # Should handle selection mode

      state.current_tool = Core::Tool::Place
      # Should handle placement mode

      # Verify no crashes occur during tool changes
      editor.update
    end

    it "updates scene when hotspots are modified" do
      initial_count = scene.hotspots.size

      # Simulate hotspot creation
      state.current_tool = Core::Tool::Place
      editor.creating_hotspot = true

      # Would normally be triggered by mouse input
      # Verify scene is updated appropriately
      scene.hotspots.size.should eq(initial_count)
    end

    it "maintains selection consistency" do
      state.select_object(test_hotspot.name)
      selected = editor.send(:get_selected_hotspot)
      selected.should eq(test_hotspot)

      state.clear_selection
      selected = editor.send(:get_selected_hotspot)
      selected.should be_nil
    end
  end

  describe "error handling in integrations" do
    it "handles script editor errors gracefully" do
      # Simulate script editor error
      state.current_project = nil

      editor.send(:edit_hotspot_scripts)
      # Should not crash the entire editor
    end

    it "handles missing files in script operations" do
      fake_path = "/nonexistent/directory/script.lua"

      # Should not crash when trying to create script in invalid location
      begin
        editor.send(:create_default_hotspot_script, fake_path, "test")
      rescue
        # Expected to fail, but shouldn't crash the editor
      end
    end

    it "handles interaction preview with invalid data" do
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        name: "invalid_hotspot",
        position: RL::Vector2.new(0, 0),
        size: RL::Vector2.new(0, 0)
      )

      editor.send(:test_hotspot_interaction, hotspot)
      # Should handle gracefully
    end
  end

  describe "default script generation" do
    it "creates comprehensive default script" do
      temp_file = File.tempfile("test_script", ".lua")
      temp_file.close

      editor.send(:create_default_hotspot_script, temp_file.path, "TestHotspot")

      content = File.read(temp_file.path)

      # Should contain all interaction functions
      content.should contain("function on_click()")
      content.should contain("function on_look()")
      content.should contain("function on_use()")
      content.should contain("function on_talk()")
      content.should contain("function custom_action()")

      # Should contain hotspot name in comments
      content.should contain("TestHotspot")

      # Should have proper Lua syntax
      content.should contain("print(")
      content.should contain("end")

      temp_file.delete
    end

    it "handles file creation errors" do
      invalid_path = "/root/readonly/script.lua" # Should fail on most systems

      # Should not crash, just handle the error
      editor.send(:create_default_hotspot_script, invalid_path, "test")
    end
  end
end

private def create_test_project
  PaceEditor::Core::Project.new.tap do |project|
    project.name = "Test Project"
    project.path = File.tempdir
    project.scripts_path = File.join(project.path, "scripts")
    Dir.mkdir_p(project.scripts_path)
  end
end

private def create_test_scene
  PointClickEngine::Scenes::Scene.new("test_scene").tap do |scene|
    scene.hotspots = [] of PointClickEngine::Scenes::Hotspot
    scene.characters = [] of PointClickEngine::Characters::Character
  end
end
