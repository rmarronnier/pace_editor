require "../spec_helper"

describe "Progressive Workflow Integration" do
  describe "Complete workflow progression" do
    editor_state : PaceEditor::Core::EditorState?
    ui_state : PaceEditor::UI::UIState?
    component_visibility : PaceEditor::UI::ComponentVisibility.class?

    before_each do
      @editor_state = test_editor_state(has_project: false)
      @ui_state = PaceEditor::UI::UIState.new
      @component_visibility = PaceEditor::UI::ComponentVisibility
    end

    def editor_state
      @editor_state.not_nil!
    end

    def ui_state
      @ui_state.not_nil!
    end

    def component_visibility
      @component_visibility.not_nil!
    end

    it "follows complete progressive disclosure workflow" do
      # Step 1: Initial state - only Project mode available
      modes = component_visibility.get_available_modes(editor_state)
      modes.should eq([PaceEditor::EditorMode::Project])

      component_visibility.should_show_scene_editor?(editor_state).should be_false
      component_visibility.should_show_character_editor?(editor_state).should be_false
      component_visibility.should_show_hotspot_editor?(editor_state).should be_false
      component_visibility.should_show_dialog_editor?(editor_state).should be_false

      # Step 2: Create project - unlocks basic tools
      project = MockProject.new("Test Game", "/tmp/test_project")
      editor_state.current_project = project

      modes = component_visibility.get_available_modes(editor_state)
      modes.should contain(PaceEditor::EditorMode::Project)
      modes.should contain(PaceEditor::EditorMode::Assets)
      modes.should contain(PaceEditor::EditorMode::Script)

      component_visibility.should_show_project_tools?(editor_state).should be_true
      component_visibility.should_show_asset_browser?(editor_state).should be_true
      component_visibility.should_show_script_editor?(editor_state).should be_true

      # Still no scene-dependent features
      component_visibility.should_show_scene_editor?(editor_state).should be_false
      component_visibility.should_show_character_editor?(editor_state).should be_false

      # Step 3: Create scene - unlocks scene and character editing
      scene = MockScene.new("Main Scene")
      editor_state.current_scene = scene

      modes = component_visibility.get_available_modes(editor_state)
      modes.should contain(PaceEditor::EditorMode::Scene)
      modes.should contain(PaceEditor::EditorMode::Character)

      component_visibility.should_show_scene_editor?(editor_state).should be_true
      component_visibility.should_show_character_editor?(editor_state).should be_true

      # Mock has_any_scenes? to return true
      allow(component_visibility).to receive(:has_any_scenes?).and_return(true)
      modes = component_visibility.get_available_modes(editor_state)
      modes.should contain(PaceEditor::EditorMode::Hotspot)

      # Step 4: Add NPCs - unlocks dialog editing
      npc = MockNPC.new("Test NPC")
      scene.characters << npc

      # Mock has_npcs_in_project? to return true
      allow(component_visibility).to receive(:has_npcs_in_project?).and_return(true)

      modes = component_visibility.get_available_modes(editor_state)
      modes.should contain(PaceEditor::EditorMode::Dialog)

      component_visibility.should_show_dialog_editor?(editor_state).should be_true
    end

    it "provides appropriate fallback modes" do
      # Set up state with project and scene
      project = MockProject.new("Test Game", "/tmp/test_project")
      scene = MockScene.new("Main Scene")
      editor_state.current_project = project
      editor_state.current_scene = scene

      # Current mode is Scene - should stay Scene
      fallback = component_visibility.get_fallback_mode(editor_state, PaceEditor::EditorMode::Scene)
      fallback.should eq(PaceEditor::EditorMode::Scene)

      # Dialog mode not available (no NPCs) - should fall back to Scene
      allow(component_visibility).to receive(:has_npcs_in_project?).and_return(false)
      fallback = component_visibility.get_fallback_mode(editor_state, PaceEditor::EditorMode::Dialog)
      fallback.should eq(PaceEditor::EditorMode::Scene)

      # No scene available - should fall back to Assets
      editor_state.current_scene = nil
      fallback = component_visibility.get_fallback_mode(editor_state, PaceEditor::EditorMode::Scene)
      fallback.should eq(PaceEditor::EditorMode::Assets)

      # No project - should fall back to Project
      editor_state.current_project = nil
      fallback = component_visibility.get_fallback_mode(editor_state, PaceEditor::EditorMode::Assets)
      fallback.should eq(PaceEditor::EditorMode::Project)
    end

    it "provides helpful visibility reasons" do
      # No project
      reason = component_visibility.get_visibility_reason("scene_editor", editor_state)
      reason.should eq("Create or open a project first")

      # Project but no scene
      project = MockProject.new("Test Game", "/tmp/test_project")
      editor_state.current_project = project

      reason = component_visibility.get_visibility_reason("scene_editor", editor_state)
      reason.should eq("Create a scene to enable the scene editor")

      reason = component_visibility.get_visibility_reason("character_editor", editor_state)
      reason.should eq("Create a scene to enable character editing")

      # Mock no scenes for hotspot editor
      allow(component_visibility).to receive(:has_any_scenes?).and_return(false)
      reason = component_visibility.get_visibility_reason("hotspot_editor", editor_state)
      reason.should eq("Create at least one scene to enable hotspot editing")

      # Mock no NPCs for dialog editor  
      allow(component_visibility).to receive(:has_npcs_in_project?).and_return(false)
      reason = component_visibility.get_visibility_reason("dialog_editor", editor_state)
      reason.should eq("Add NPC characters to enable dialog editing")

      # Available component should return nil
      scene = MockScene.new("Main Scene")
      editor_state.current_scene = scene
      reason = component_visibility.get_visibility_reason("scene_editor", editor_state)
      reason.should be_nil
    end

    it "integrates with UI state for power mode" do
      # Normal mode - follows progressive rules
      ui_state.power_mode = false
      
      visibility = ui_state.get_component_visibility("scene_editor", editor_state)
      visibility.should eq(PaceEditor::UI::ComponentState::Hidden)

      # Power mode - shows everything available in power mode
      ui_state.enable_power_mode

      # Mock power mode check
      allow(component_visibility).to receive(:should_show_in_power_mode?).with("scene_editor").and_return(true)

      visibility = ui_state.get_component_visibility("scene_editor", editor_state)
      visibility.should eq(PaceEditor::UI::ComponentState::Visible)

      # Power mode shows all editor modes
      modes = ui_state.get_available_modes(editor_state)
      modes.should eq(PaceEditor::EditorMode.values)
    end

    it "tracks progress and provides suggestions" do
      ui_state.update_project_progress(editor_state)

      # No project - 0% complete, suggest creating project
      percentage = ui_state.get_completion_percentage
      percentage.should eq(0.0_f32)

      suggestion = ui_state.get_next_suggested_action(editor_state)
      suggestion.should eq("Create or open a project")

      # Add project
      project = MockProject.new("Test Game", "/tmp/test_project")
      editor_state.current_project = project

      # Mock progress tracking
      allow(component_visibility).to receive(:has_any_scenes?).and_return(false)
      allow(component_visibility).to receive(:has_any_assets?).and_return(false)
      allow(component_visibility).to receive(:has_npcs_in_project?).and_return(false)

      ui_state.update_project_progress(editor_state)

      # Should have some progress now
      percentage = ui_state.get_completion_percentage
      percentage.should be > 0.0_f32
      percentage.should be < 100.0_f32

      suggestion = ui_state.get_next_suggested_action(editor_state)
      suggestion.should eq("Create your first scene")
    end

    it "handles contextual hints throughout workflow" do
      ui_state.show_hints = true

      # Track project creation - should suggest creating scene
      ui_state.track_action("project_created")
      hint = ui_state.get_next_hint
      hint.should_not be_nil
      hint.not_nil!.text.should contain("scene")

      # Track scene creation - should suggest adding characters
      ui_state.track_action("scene_created")
      hint = ui_state.get_next_hint
      hint.should_not be_nil
      hint.not_nil!.text.should contain("character")

      # Track character addition - should suggest adding hotspots
      ui_state.track_action("character_added")
      hint = ui_state.get_next_hint
      hint.should_not be_nil
      hint.not_nil!.text.should contain("hotspot")

      # Track NPC addition - should suggest creating dialogs
      ui_state.track_action("npc_added")
      hint = ui_state.get_next_hint
      hint.should_not be_nil
      hint.not_nil!.text.should contain("dialog")
    end

    it "supports component visibility overrides" do
      # Scene editor normally hidden without project
      visibility = ui_state.get_component_visibility("scene_editor", editor_state)
      visibility.should eq(PaceEditor::UI::ComponentState::Hidden)

      # Override to show scene editor
      ui_state.override_component_visibility("scene_editor", PaceEditor::UI::ComponentState::Visible)
      visibility = ui_state.get_component_visibility("scene_editor", editor_state)
      visibility.should eq(PaceEditor::UI::ComponentState::Visible)

      # Clear override - back to normal rules
      ui_state.clear_visibility_override("scene_editor")
      visibility = ui_state.get_component_visibility("scene_editor", editor_state)
      visibility.should eq(PaceEditor::UI::ComponentState::Hidden)

      # Set multiple overrides and clear all
      ui_state.override_component_visibility("scene_editor", PaceEditor::UI::ComponentState::Visible)
      ui_state.override_component_visibility("character_editor", PaceEditor::UI::ComponentState::Disabled)

      ui_state.clear_all_overrides

      visibility1 = ui_state.get_component_visibility("scene_editor", editor_state)
      visibility2 = ui_state.get_component_visibility("character_editor", editor_state)

      visibility1.should eq(PaceEditor::UI::ComponentState::Hidden)
      visibility2.should eq(PaceEditor::UI::ComponentState::Hidden)
    end
  end
end