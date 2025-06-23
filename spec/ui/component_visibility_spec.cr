require "../spec_helper"

describe PaceEditor::UI::ComponentVisibility do
  describe "project-level visibility" do
    it "hides project tools when no project is loaded" do
      state = test_editor_state(has_project: false)
      PaceEditor::UI::ComponentVisibility.should_show_project_tools?(state).should be_false
    end

    it "shows project tools when project is loaded" do
      state = test_editor_state(has_project: true)
      PaceEditor::UI::ComponentVisibility.should_show_project_tools?(state).should be_true
    end
  end

  describe "scene editor visibility" do
    it "hides scene editor when no project exists" do
      state = test_editor_state(has_project: false)
      PaceEditor::UI::ComponentVisibility.should_show_scene_editor?(state).should be_false
    end

    it "hides scene editor when project exists but no scene is loaded" do
      state = test_editor_state(has_project: true, current_scene: nil)
      PaceEditor::UI::ComponentVisibility.should_show_scene_editor?(state).should be_false
    end

    it "shows scene editor when project and scene exist" do
      state = test_editor_state(has_project: true, current_scene: test_scene)
      PaceEditor::UI::ComponentVisibility.should_show_scene_editor?(state).should be_true
    end
  end

  describe "character editor visibility" do
    it "hides character editor when no project exists" do
      state = test_editor_state(has_project: false)
      PaceEditor::UI::ComponentVisibility.should_show_character_editor?(state).should be_false
    end

    it "hides character editor when no scene is loaded" do
      state = test_editor_state(has_project: true, current_scene: nil)
      PaceEditor::UI::ComponentVisibility.should_show_character_editor?(state).should be_false
    end

    it "shows character editor when scene is loaded" do
      state = test_editor_state(has_project: true, current_scene: test_scene)
      PaceEditor::UI::ComponentVisibility.should_show_character_editor?(state).should be_true
    end
  end

  describe "hotspot editor visibility" do
    it "hides hotspot editor when no project exists" do
      state = test_editor_state(has_project: false)
      PaceEditor::UI::ComponentVisibility.should_show_hotspot_editor?(state).should be_false
    end

    it "shows hotspot editor when project has scenes" do
      state = test_editor_state(has_project: true)

      # Mock the has_any_scenes? method
      allow(PaceEditor::UI::ComponentVisibility).to receive(:has_any_scenes?).and_return(true)

      PaceEditor::UI::ComponentVisibility.should_show_hotspot_editor?(state).should be_true
    end

    it "hides hotspot editor when project has no scenes" do
      state = test_editor_state(has_project: true)

      # Mock the has_any_scenes? method
      allow(PaceEditor::UI::ComponentVisibility).to receive(:has_any_scenes?).and_return(false)

      PaceEditor::UI::ComponentVisibility.should_show_hotspot_editor?(state).should be_false
    end
  end

  describe "dialog editor visibility" do
    it "hides dialog editor when no project exists" do
      state = test_editor_state(has_project: false)
      PaceEditor::UI::ComponentVisibility.should_show_dialog_editor?(state).should be_false
    end

    it "shows dialog editor when project has NPCs" do
      state = test_editor_state(has_project: true)

      # Mock the has_npcs_in_project? method
      allow(PaceEditor::UI::ComponentVisibility).to receive(:has_npcs_in_project?).and_return(true)

      PaceEditor::UI::ComponentVisibility.should_show_dialog_editor?(state).should be_true
    end

    it "hides dialog editor when project has no NPCs" do
      state = test_editor_state(has_project: true)

      # Mock the has_npcs_in_project? method
      allow(PaceEditor::UI::ComponentVisibility).to receive(:has_npcs_in_project?).and_return(false)

      PaceEditor::UI::ComponentVisibility.should_show_dialog_editor?(state).should be_false
    end
  end

  describe "mode availability" do
    it "always includes project mode" do
      state = test_editor_state(has_project: false)
      modes = PaceEditor::UI::ComponentVisibility.get_available_modes(state)
      modes.should contain(PaceEditor::EditorMode::Project)
    end

    it "includes basic modes when project exists" do
      state = test_editor_state(has_project: true)
      modes = PaceEditor::UI::ComponentVisibility.get_available_modes(state)

      modes.should contain(PaceEditor::EditorMode::Project)
      modes.should contain(PaceEditor::EditorMode::Assets)
    end

    it "includes scene and character modes when scene exists" do
      state = test_editor_state(has_project: true, current_scene: test_scene)
      modes = PaceEditor::UI::ComponentVisibility.get_available_modes(state)

      modes.should contain(PaceEditor::EditorMode::Scene)
      modes.should contain(PaceEditor::EditorMode::Character)
    end

    it "includes hotspot mode when project has scenes" do
      state = test_editor_state(has_project: true)

      # Mock the has_any_scenes? method
      allow(PaceEditor::UI::ComponentVisibility).to receive(:has_any_scenes?).and_return(true)

      modes = PaceEditor::UI::ComponentVisibility.get_available_modes(state)
      modes.should contain(PaceEditor::EditorMode::Hotspot)
    end

    it "includes dialog mode when project has NPCs" do
      state = test_editor_state(has_project: true)

      # Mock the has_npcs_in_project? method
      allow(PaceEditor::UI::ComponentVisibility).to receive(:has_npcs_in_project?).and_return(true)

      modes = PaceEditor::UI::ComponentVisibility.get_available_modes(state)
      modes.should contain(PaceEditor::EditorMode::Dialog)
    end
  end

  describe "fallback mode selection" do
    it "keeps current mode if still available" do
      state = test_editor_state(has_project: true, current_scene: test_scene)
      current_mode = PaceEditor::EditorMode::Scene

      fallback = PaceEditor::UI::ComponentVisibility.get_fallback_mode(state, current_mode)
      fallback.should eq(current_mode)
    end

    it "falls back to project mode when nothing else is available" do
      state = test_editor_state(has_project: false)
      current_mode = PaceEditor::EditorMode::Scene

      fallback = PaceEditor::UI::ComponentVisibility.get_fallback_mode(state, current_mode)
      fallback.should eq(PaceEditor::EditorMode::Project)
    end

    it "prefers scene mode as fallback when available" do
      state = test_editor_state(has_project: true, current_scene: test_scene)
      current_mode = PaceEditor::EditorMode::Dialog # Assume dialog mode becomes unavailable

      # Mock dialog mode as unavailable
      allow(PaceEditor::UI::ComponentVisibility).to receive(:has_npcs_in_project?).and_return(false)

      fallback = PaceEditor::UI::ComponentVisibility.get_fallback_mode(state, current_mode)
      fallback.should eq(PaceEditor::EditorMode::Scene)
    end
  end

  describe "visibility reasons" do
    it "provides helpful reasons for hidden components" do
      state = test_editor_state(has_project: false)

      reason = PaceEditor::UI::ComponentVisibility.get_visibility_reason("scene_editor", state)
      reason.should eq("Create or open a project first")
    end

    it "provides specific reasons for character editor" do
      state = test_editor_state(has_project: true, current_scene: nil)

      reason = PaceEditor::UI::ComponentVisibility.get_visibility_reason("character_editor", state)
      reason.should eq("Create a scene to enable character editing")
    end

    it "provides specific reasons for dialog editor" do
      state = test_editor_state(has_project: true)

      # Mock no NPCs in project
      allow(PaceEditor::UI::ComponentVisibility).to receive(:has_npcs_in_project?).and_return(false)

      reason = PaceEditor::UI::ComponentVisibility.get_visibility_reason("dialog_editor", state)
      reason.should eq("Add NPC characters to enable dialog editing")
    end

    it "returns nil for available components" do
      state = test_editor_state(has_project: true, current_scene: test_scene)

      reason = PaceEditor::UI::ComponentVisibility.get_visibility_reason("scene_editor", state)
      reason.should be_nil
    end
  end

  describe "component state" do
    it "returns visible state for available components" do
      state = test_editor_state(has_project: true, current_scene: test_scene)

      component_state = PaceEditor::UI::ComponentVisibility.get_component_state("scene_editor", state)
      component_state.should eq(PaceEditor::UI::ComponentState::Visible)
    end

    it "returns hidden state for unavailable components" do
      state = test_editor_state(has_project: false)

      component_state = PaceEditor::UI::ComponentVisibility.get_component_state("scene_editor", state)
      component_state.should eq(PaceEditor::UI::ComponentState::Hidden)
    end

    it "defaults to visible for unknown components" do
      state = test_editor_state(has_project: false)

      component_state = PaceEditor::UI::ComponentVisibility.get_component_state("unknown_component", state)
      component_state.should eq(PaceEditor::UI::ComponentState::Visible)
    end
  end

  describe "power user mode" do
    it "shows most components in power mode" do
      result = PaceEditor::UI::ComponentVisibility.should_show_in_power_mode?("scene_editor")
      result.should be_true
    end

    it "still hides project tools in power mode when no project" do
      result = PaceEditor::UI::ComponentVisibility.should_show_in_power_mode?("project_tools")
      result.should be_false
    end
  end
end
