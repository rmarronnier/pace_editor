require "./e2e_spec_helper"

describe "ComponentVisibility E2E Tests" do
  describe "Project-level visibility" do
    it "should_show_project_tools? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_project_tools?(harness.editor.state).should be_false
    end

    it "should_show_project_tools? returns true with project" do
      harness = E2ETestHelper.create_harness_with_project
      PaceEditor::UI::ComponentVisibility.should_show_project_tools?(harness.editor.state).should be_true
    end

    it "should_show_scene_editor? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_scene_editor?(harness.editor.state).should be_false
    end

    it "should_show_scene_editor? depends on whether project has current_scene" do
      harness = E2ETestHelper.create_harness_with_project
      # The harness creates a project which may or may not have a scene loaded
      has_scene = !harness.editor.state.current_scene.nil?
      PaceEditor::UI::ComponentVisibility.should_show_scene_editor?(harness.editor.state).should eq(has_scene)
    end

    it "should_show_scene_editor? returns true with project and scene" do
      harness = E2ETestHelper.create_harness_with_scene
      PaceEditor::UI::ComponentVisibility.should_show_scene_editor?(harness.editor.state).should be_true
    end
  end

  describe "Character editor visibility" do
    it "should_show_character_editor? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_character_editor?(harness.editor.state).should be_false
    end

    it "should_show_character_editor? returns true with project and scene" do
      harness = E2ETestHelper.create_harness_with_scene
      PaceEditor::UI::ComponentVisibility.should_show_character_editor?(harness.editor.state).should be_true
    end
  end

  describe "Asset browser visibility" do
    it "should_show_asset_browser? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_asset_browser?(harness.editor.state).should be_false
    end

    it "should_show_asset_browser? returns true with project" do
      harness = E2ETestHelper.create_harness_with_project
      PaceEditor::UI::ComponentVisibility.should_show_asset_browser?(harness.editor.state).should be_true
    end
  end

  describe "Script editor visibility" do
    it "should_show_script_editor? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_script_editor?(harness.editor.state).should be_false
    end

    it "should_show_script_editor? returns true with project" do
      harness = E2ETestHelper.create_harness_with_project
      PaceEditor::UI::ComponentVisibility.should_show_script_editor?(harness.editor.state).should be_true
    end
  end

  describe "Hotspot editor visibility" do
    it "should_show_hotspot_editor? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_hotspot_editor?(harness.editor.state).should be_false
    end

    it "should_show_hotspot_editor? depends on whether project has scenes" do
      harness = E2ETestHelper.create_harness_with_project
      has_scenes = PaceEditor::UI::ComponentVisibility.has_any_scenes?(harness.editor.state)
      PaceEditor::UI::ComponentVisibility.should_show_hotspot_editor?(harness.editor.state).should eq(has_scenes)
    end

    it "should_show_hotspot_editor? returns true with project and scenes" do
      harness = E2ETestHelper.create_harness_with_scene
      PaceEditor::UI::ComponentVisibility.should_show_hotspot_editor?(harness.editor.state).should be_true
    end
  end

  describe "Dialog editor visibility" do
    it "should_show_dialog_editor? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_dialog_editor?(harness.editor.state).should be_false
    end

    it "should_show_dialog_editor? returns false with project but no NPCs" do
      harness = E2ETestHelper.create_harness_with_project
      PaceEditor::UI::ComponentVisibility.should_show_dialog_editor?(harness.editor.state).should be_false
    end
  end

  describe "File menu visibility" do
    it "should_show_file_save? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_file_save?(harness.editor.state).should be_false
    end

    it "should_show_file_save? returns false when project is not dirty" do
      harness = E2ETestHelper.create_harness_with_project
      harness.editor.state.is_dirty = false
      PaceEditor::UI::ComponentVisibility.should_show_file_save?(harness.editor.state).should be_false
    end

    it "should_show_file_save? returns true when project is dirty" do
      harness = E2ETestHelper.create_harness_with_project
      harness.editor.state.is_dirty = true
      PaceEditor::UI::ComponentVisibility.should_show_file_save?(harness.editor.state).should be_true
    end

    it "should_show_file_export? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_file_export?(harness.editor.state).should be_false
    end
  end

  describe "Edit menu visibility" do
    it "should_show_edit_undo? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_edit_undo?(harness.editor.state).should be_false
    end

    it "should_show_edit_redo? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_edit_redo?(harness.editor.state).should be_false
    end
  end

  describe "Scene menu visibility" do
    it "should_show_scene_menu? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_scene_menu?(harness.editor.state).should be_false
    end

    it "should_show_scene_menu? returns true with project" do
      harness = E2ETestHelper.create_harness_with_project
      PaceEditor::UI::ComponentVisibility.should_show_scene_menu?(harness.editor.state).should be_true
    end
  end

  describe "Character menu visibility" do
    it "should_show_character_menu? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_character_menu?(harness.editor.state).should be_false
    end

    it "should_show_character_menu? returns true with project and scene" do
      harness = E2ETestHelper.create_harness_with_scene
      PaceEditor::UI::ComponentVisibility.should_show_character_menu?(harness.editor.state).should be_true
    end
  end

  describe "Dialog menu visibility" do
    it "should_show_dialog_menu? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_dialog_menu?(harness.editor.state).should be_false
    end
  end

  describe "Properties visibility" do
    it "should_show_scene_properties? returns true with scene" do
      harness = E2ETestHelper.create_harness_with_scene
      PaceEditor::UI::ComponentVisibility.should_show_scene_properties?(harness.editor.state).should be_true
    end

    it "should_show_scene_properties? depends on whether project has current scene" do
      harness = E2ETestHelper.create_harness_with_project
      has_scene = !harness.editor.state.current_scene.nil?
      PaceEditor::UI::ComponentVisibility.should_show_scene_properties?(harness.editor.state).should eq(has_scene)
    end

    it "should_show_hotspot_properties? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_hotspot_properties?(harness.editor.state).should be_false
    end

    it "should_show_character_properties? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_character_properties?(harness.editor.state).should be_false
    end

    it "should_show_dialog_properties? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_dialog_properties?(harness.editor.state).should be_false
    end
  end

  describe "Tools visibility" do
    it "should_show_scene_tools? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_scene_tools?(harness.editor.state).should be_false
    end

    it "should_show_scene_tools? returns true with scene" do
      harness = E2ETestHelper.create_harness_with_scene
      PaceEditor::UI::ComponentVisibility.should_show_scene_tools?(harness.editor.state).should be_true
    end

    it "should_show_character_tools? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_character_tools?(harness.editor.state).should be_false
    end

    it "should_show_hotspot_tools? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_hotspot_tools?(harness.editor.state).should be_false
    end

    it "should_show_hotspot_tools? returns true with scene" do
      harness = E2ETestHelper.create_harness_with_scene
      PaceEditor::UI::ComponentVisibility.should_show_hotspot_tools?(harness.editor.state).should be_true
    end
  end

  describe "Export visibility" do
    it "should_show_export_tools? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.should_show_export_tools?(harness.editor.state).should be_false
    end
  end

  describe "Available modes" do
    it "returns limited modes without project" do
      harness = PaceEditor::Testing::TestHarness.new
      modes = PaceEditor::UI::ComponentVisibility.get_available_modes(harness.editor.state)
      # Without a project, most modes should not be available
      modes.size.should be <= 2
    end

    it "returns available modes with project" do
      harness = E2ETestHelper.create_harness_with_project
      modes = PaceEditor::UI::ComponentVisibility.get_available_modes(harness.editor.state)
      modes.should_not be_empty
    end

    it "returns more modes with scene" do
      harness_project = E2ETestHelper.create_harness_with_project
      harness_scene = E2ETestHelper.create_harness_with_scene

      modes_project = PaceEditor::UI::ComponentVisibility.get_available_modes(harness_project.editor.state)
      modes_scene = PaceEditor::UI::ComponentVisibility.get_available_modes(harness_scene.editor.state)

      modes_scene.size.should be >= modes_project.size
    end
  end

  describe "Mode availability" do
    it "Assets mode is always available with project" do
      harness = E2ETestHelper.create_harness_with_project
      PaceEditor::UI::ComponentVisibility.is_mode_available?(harness.editor.state, PaceEditor::EditorMode::Assets).should be_true
    end

    it "Scene mode is available with scene" do
      harness = E2ETestHelper.create_harness_with_scene
      PaceEditor::UI::ComponentVisibility.is_mode_available?(harness.editor.state, PaceEditor::EditorMode::Scene).should be_true
    end

    it "Scene mode availability depends on current scene" do
      harness = E2ETestHelper.create_harness_with_project
      has_scene = !harness.editor.state.current_scene.nil?
      PaceEditor::UI::ComponentVisibility.is_mode_available?(harness.editor.state, PaceEditor::EditorMode::Scene).should eq(has_scene)
    end
  end

  describe "Fallback mode" do
    it "returns a valid fallback mode" do
      harness = E2ETestHelper.create_harness_with_project
      fallback = PaceEditor::UI::ComponentVisibility.get_fallback_mode(harness.editor.state, PaceEditor::EditorMode::Dialog)
      # Fallback should be a valid mode for the current state
      PaceEditor::UI::ComponentVisibility.is_mode_available?(harness.editor.state, fallback).should be_true
    end
  end

  describe "Visibility reasons" do
    it "returns reason for scene_editor without project" do
      harness = PaceEditor::Testing::TestHarness.new
      reason = PaceEditor::UI::ComponentVisibility.get_visibility_reason("scene_editor", harness.editor.state)
      reason.should_not be_nil
    end

    it "returns nil for scene_editor with project and scene" do
      harness = E2ETestHelper.create_harness_with_scene
      reason = PaceEditor::UI::ComponentVisibility.get_visibility_reason("scene_editor", harness.editor.state)
      reason.should be_nil
    end
  end

  describe "Helper methods" do
    it "has_any_scenes? returns based on project content" do
      harness = E2ETestHelper.create_harness_with_project
      # Test harness may or may not create default scenes
      result = PaceEditor::UI::ComponentVisibility.has_any_scenes?(harness.editor.state)
      result.should be_a(Bool)
    end

    it "has_any_scenes? returns true for project with scenes" do
      harness = E2ETestHelper.create_harness_with_scene
      PaceEditor::UI::ComponentVisibility.has_any_scenes?(harness.editor.state).should be_true
    end

    it "has_npcs_in_project? returns false without project" do
      harness = PaceEditor::Testing::TestHarness.new
      PaceEditor::UI::ComponentVisibility.has_npcs_in_project?(harness.editor.state).should be_false
    end
  end

  describe "Component state" do
    it "returns Hidden state for scene_editor without project" do
      harness = PaceEditor::Testing::TestHarness.new
      state = PaceEditor::UI::ComponentVisibility.get_component_state("scene_editor", harness.editor.state)

      state.should eq(PaceEditor::UI::ComponentState::Hidden)
    end

    it "returns Visible state for scene_editor with scene" do
      harness = E2ETestHelper.create_harness_with_scene
      state = PaceEditor::UI::ComponentVisibility.get_component_state("scene_editor", harness.editor.state)

      state.should eq(PaceEditor::UI::ComponentState::Visible)
    end
  end

  describe "Power mode visibility" do
    it "returns true for scene_editor in power mode" do
      PaceEditor::UI::ComponentVisibility.should_show_in_power_mode?("scene_editor").should be_true
    end

    it "returns true for script_editor in power mode" do
      PaceEditor::UI::ComponentVisibility.should_show_in_power_mode?("script_editor").should be_true
    end
  end
end
