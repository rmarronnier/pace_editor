require "../spec_helper"

describe "Progressive Disclosure Integration" do
  editor_window : PaceEditor::Core::EditorWindow?

  before_each do
    @editor_window = PaceEditor::Core::EditorWindow.new
  end

  def editor_window
    @editor_window.not_nil!
  end

  describe "initial state" do
    it "starts with no project and minimal UI" do
      state = editor_window.state
      ui_state = editor_window.ui_state

      state.has_project?.should be_false
      ui_state.first_run.should be_true
      ui_state.power_mode.should be_false
    end

    it "shows getting started workflow" do
      guided_workflow = editor_window.guided_workflow

      guided_workflow.show_getting_started.should be_true
    end

    it "hides project-dependent components" do
      state = editor_window.state
      ui_state = editor_window.ui_state

      ui_state.get_component_visibility("scene_hierarchy", state).should eq(PaceEditor::UI::ComponentState::Hidden)
      ui_state.get_component_visibility("property_panel", state).should eq(PaceEditor::UI::ComponentState::Hidden)
    end

    it "shows only basic menu items" do
      progressive_menu = editor_window.progressive_menu
      state = editor_window.state
      ui_state = editor_window.ui_state

      # File menu should be visible
      file_section = progressive_menu.menu_items["File"]
      file_section.visible?(state, ui_state).should be_true

      # Edit menu should be hidden (no project)
      edit_section = progressive_menu.menu_items["Edit"]
      edit_section.visible?(state, ui_state).should be_false

      # Scene menu should be hidden (no project)
      scene_section = progressive_menu.menu_items["Scene"]
      scene_section.visible?(state, ui_state).should be_false
    end
  end

  describe "project creation workflow" do
    it "enables project tools after project creation" do
      state = editor_window.state
      ui_state = editor_window.ui_state

      # Simulate project creation
      state.current_project = test_project
      ui_state.track_action("project_created")

      # Project tools should now be available
      PaceEditor::UI::ComponentVisibility.should_show_project_tools?(state).should be_true

      # Scene hierarchy and property panel should become visible
      ui_state.get_component_visibility("scene_hierarchy", state).should eq(PaceEditor::UI::ComponentState::Visible)
      ui_state.get_component_visibility("property_panel", state).should eq(PaceEditor::UI::ComponentState::Visible)

      # Edit menu should become visible
      progressive_menu = editor_window.progressive_menu
      edit_section = progressive_menu.menu_items["Edit"]
      edit_section.visible?(state, ui_state).should be_true
    end

    it "shows contextual hints after project creation" do
      state = editor_window.state
      ui_state = editor_window.ui_state
      ui_state.show_hints = true

      # Simulate project creation
      state.current_project = test_project
      ui_state.track_action("project_created")

      # Should get hint about creating first scene
      hint = ui_state.get_next_hint
      hint.should_not be_nil
      hint.not_nil!.text.should contain("scene")
      hint.not_nil!.type.should eq(PaceEditor::UI::UIHintType::Suggestion)
    end

    it "updates available editor modes" do
      state = editor_window.state
      ui_state = editor_window.ui_state

      # Initially only Project mode should be available
      initial_modes = ui_state.get_available_modes(state)
      initial_modes.should contain(PaceEditor::EditorMode::Project)
      initial_modes.should_not contain(PaceEditor::EditorMode::Scene)

      # After project creation, more modes become available
      state.current_project = test_project
      updated_modes = ui_state.get_available_modes(state)
      updated_modes.should contain(PaceEditor::EditorMode::Project)
      updated_modes.should contain(PaceEditor::EditorMode::Assets)
    end
  end

  describe "scene creation workflow" do
    it "enables scene editor after scene creation" do
      state = editor_window.state
      ui_state = editor_window.ui_state

      # Set up project and scene
      state.current_project = test_project
      state.current_scene = test_scene
      ui_state.track_action("scene_created")

      # Scene editor should be available
      PaceEditor::UI::ComponentVisibility.should_show_scene_editor?(state).should be_true

      # Scene and Character modes should be available
      modes = ui_state.get_available_modes(state)
      modes.should contain(PaceEditor::EditorMode::Scene)
      modes.should contain(PaceEditor::EditorMode::Character)
    end

    it "shows scene-specific menu items" do
      state = editor_window.state
      ui_state = editor_window.ui_state
      progressive_menu = editor_window.progressive_menu

      # Set up project and scene
      state.current_project = test_project
      state.current_scene = test_scene

      # Scene menu should be visible
      scene_section = progressive_menu.menu_items["Scene"]
      scene_section.visible?(state, ui_state).should be_true

      # Character menu should be visible (scene exists)
      character_section = progressive_menu.menu_items["Character"]
      character_section.visible?(state, ui_state).should be_true
    end

    it "provides contextual hints for next steps" do
      state = editor_window.state
      ui_state = editor_window.ui_state
      ui_state.show_hints = true

      # Set up project and track scene creation
      state.current_project = test_project
      state.current_scene = test_scene
      ui_state.track_action("scene_created")

      # Should get hint about adding characters
      hint = ui_state.get_next_hint
      hint.should_not be_nil
      hint.not_nil!.text.should contain("character")
    end
  end

  describe "character and dialog workflow" do
    it "enables dialog editor after NPC creation" do
      state = editor_window.state
      ui_state = editor_window.ui_state

      # Set up project with NPC
      state.current_project = test_project
      state.current_scene = test_scene_with_npc
      ui_state.track_action("npc_added")

      # Mock NPC detection
      allow(PaceEditor::UI::ComponentVisibility).to receive(:has_npcs_in_project?).and_return(true)

      # Dialog editor should be available
      PaceEditor::UI::ComponentVisibility.should_show_dialog_editor?(state).should be_true

      # Dialog mode should be available
      modes = ui_state.get_available_modes(state)
      modes.should contain(PaceEditor::EditorMode::Dialog)
    end

    it "shows dialog menu when NPCs exist" do
      state = editor_window.state
      ui_state = editor_window.ui_state
      progressive_menu = editor_window.progressive_menu

      # Set up project with NPCs
      state.current_project = test_project

      # Mock NPC detection
      allow(PaceEditor::UI::ComponentVisibility).to receive(:has_npcs_in_project?).and_return(true)

      # Dialog menu should be visible
      dialog_section = progressive_menu.menu_items["Dialog"]
      dialog_section.visible?(state, ui_state).should be_true
    end

    it "provides hints for dialog creation" do
      state = editor_window.state
      ui_state = editor_window.ui_state
      ui_state.show_hints = true

      # Track NPC addition
      ui_state.track_action("npc_added")

      # Should get hint about creating dialogs
      hint = ui_state.get_next_hint
      hint.should_not be_nil
      hint.not_nil!.text.should contain("dialog")
      hint.not_nil!.type.should eq(PaceEditor::UI::UIHintType::Feature)
    end
  end

  describe "mode switching with validation" do
    it "prevents switching to unavailable modes" do
      state = editor_window.state
      ui_state = editor_window.ui_state

      # Try to switch to scene mode without a project
      editor_window.switch_mode(PaceEditor::EditorMode::Scene)

      # Mode should not change
      state.current_mode.should_not eq(PaceEditor::EditorMode::Scene)

      # Should get a warning hint
      hint = ui_state.get_next_hint
      hint.should_not be_nil
      hint.not_nil!.type.should eq(PaceEditor::UI::UIHintType::Warning)
    end

    it "allows switching to available modes" do
      state = editor_window.state
      ui_state = editor_window.ui_state

      # Set up project and scene
      state.current_project = test_project
      state.current_scene = test_scene

      # Switch to scene mode should work
      editor_window.switch_mode(PaceEditor::EditorMode::Scene)

      # Mode should change
      state.current_mode.should eq(PaceEditor::EditorMode::Scene)

      # Should track the mode switch
      ui_state.has_recent_action?("mode_switch_scene").should be_true
    end

    it "provides fallback modes when current mode becomes unavailable" do
      state = editor_window.state
      ui_state = editor_window.ui_state

      # Set up scene mode
      state.current_project = test_project
      state.current_scene = test_scene
      state.current_mode = PaceEditor::EditorMode::Scene

      # Remove scene (simulate scene deletion)
      state.current_scene = nil

      # Get fallback mode
      fallback = PaceEditor::UI::ComponentVisibility.get_fallback_mode(state, PaceEditor::EditorMode::Scene)

      # Should fall back to Project or Assets mode
      [PaceEditor::EditorMode::Project, PaceEditor::EditorMode::Assets].should contain(fallback)
    end
  end

  describe "power user mode" do
    it "shows all components in power mode" do
      state = editor_window.state
      ui_state = editor_window.ui_state

      # Enable power mode
      ui_state.enable_power_mode

      # Most components should be visible even without project
      ui_state.get_component_visibility("tool_palette", state).should eq(PaceEditor::UI::ComponentState::Visible)

      # All modes should be available
      modes = ui_state.get_available_modes(state)
      modes.should eq(PaceEditor::EditorMode.values)
    end

    it "shows all menu items in power mode" do
      state = editor_window.state
      ui_state = editor_window.ui_state
      progressive_menu = editor_window.progressive_menu

      # Enable power mode
      ui_state.enable_power_mode

      # All menu sections should show all items
      edit_section = progressive_menu.menu_items["Edit"]
      visible_items = edit_section.visible_items(state, ui_state)

      # Should include all items in power mode
      visible_items.size.should eq(edit_section.items.size)
    end
  end

  describe "progress tracking" do
    it "calculates project completion percentage" do
      state = editor_window.state
      ui_state = editor_window.ui_state

      # Start with no project
      ui_state.update_project_progress(state)
      initial_progress = ui_state.get_completion_percentage
      initial_progress.should be < 20.0_f32 # Minimal progress

      # Add project
      state.current_project = test_project
      ui_state.update_project_progress(state)
      project_progress = ui_state.get_completion_percentage
      project_progress.should be > initial_progress

      # Add scene
      state.current_scene = test_scene
      ui_state.update_project_progress(state)
      scene_progress = ui_state.get_completion_percentage
      scene_progress.should be > project_progress
    end

    it "provides next action suggestions" do
      state = editor_window.state
      ui_state = editor_window.ui_state

      # Without project
      ui_state.update_project_progress(state)
      suggestion = ui_state.get_next_suggested_action(state)
      suggestion.should_not be_nil
      suggestion.not_nil!.should contain("project")

      # With project but no scenes
      state.current_project = test_project
      ui_state.update_project_progress(state)
      suggestion = ui_state.get_next_suggested_action(state)
      suggestion.should_not be_nil
      suggestion.not_nil!.should contain("scene")
    end
  end

  describe "onboarding flow" do
    it "guides new users through initial setup" do
      state = editor_window.state
      ui_state = editor_window.ui_state
      guided_workflow = editor_window.guided_workflow

      # Should show getting started for first-time users
      ui_state.first_run = true
      guided_workflow.update
      guided_workflow.show_getting_started.should be_true

      # After completing basic tutorial, should not show onboarding
      ui_state.mark_tutorial_completed("basic_workflow")
      ui_state.should_show_onboarding?.should be_false
    end

    it "provides tutorials for complex features" do
      guided_workflow = editor_window.guided_workflow
      ui_state = editor_window.ui_state

      # Should be able to start tutorials
      # Mock tutorial system
      tutorial = PaceEditor::UI::Tutorial.new("test_tutorial", [] of PaceEditor::UI::WorkflowStep)
      allow(guided_workflow).to receive(:get_tutorial).and_return(tutorial)

      guided_workflow.start_tutorial("test_tutorial")
      guided_workflow.current_tutorial.should_not be_nil
      ui_state.has_recent_action?("tutorial_started_test_tutorial").should be_true
    end
  end
end
