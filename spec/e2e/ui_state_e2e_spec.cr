require "./e2e_spec_helper"

describe "UIState E2E Tests" do
  describe "Power mode" do
    it "initializes with power mode disabled" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.power_mode.should be_false
    end

    it "enables power mode" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.enable_power_mode

      harness.ui_state.power_mode.should be_true
      harness.ui_state.show_advanced_tools.should be_true
    end

    it "disables power mode" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.enable_power_mode
      harness.ui_state.disable_power_mode

      harness.ui_state.power_mode.should be_false
      harness.ui_state.show_advanced_tools.should be_false
    end

    it "toggles power mode" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.power_mode.should be_false
      harness.ui_state.toggle_power_mode
      harness.ui_state.power_mode.should be_true
      harness.ui_state.toggle_power_mode
      harness.ui_state.power_mode.should be_false
    end
  end

  describe "Component visibility with overrides" do
    it "returns default visibility without override" do
      harness = E2ETestHelper.create_harness_with_scene
      visibility = harness.ui_state.get_component_visibility("scene_editor", harness.editor.state)

      visibility.should eq(PaceEditor::UI::ComponentState::Visible)
    end

    it "returns override when set" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.ui_state.override_component_visibility("scene_editor", PaceEditor::UI::ComponentState::Hidden)

      visibility = harness.ui_state.get_component_visibility("scene_editor", harness.editor.state)
      visibility.should eq(PaceEditor::UI::ComponentState::Hidden)
    end

    it "clears specific override" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.ui_state.override_component_visibility("scene_editor", PaceEditor::UI::ComponentState::Hidden)
      harness.ui_state.clear_visibility_override("scene_editor")

      visibility = harness.ui_state.get_component_visibility("scene_editor", harness.editor.state)
      visibility.should eq(PaceEditor::UI::ComponentState::Visible)
    end

    it "clears all overrides" do
      harness = E2ETestHelper.create_harness_with_scene
      harness.ui_state.override_component_visibility("scene_editor", PaceEditor::UI::ComponentState::Hidden)
      harness.ui_state.override_component_visibility("character_editor", PaceEditor::UI::ComponentState::Hidden)
      harness.ui_state.clear_all_overrides

      harness.ui_state.visibility_overrides.size.should eq(0)
    end

    it "power mode shows all components" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.enable_power_mode

      visibility = harness.ui_state.get_component_visibility("scene_editor", harness.editor.state)
      visibility.should eq(PaceEditor::UI::ComponentState::Visible)
    end
  end

  describe "Hint system" do
    it "adds hints when show_hints is true" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.show_hints = true

      hint = PaceEditor::UI::UIHint.new("test_hint", "Test message", PaceEditor::UI::UIHintType::Info)
      harness.ui_state.add_hint(hint)

      harness.ui_state.hint_queue.size.should eq(1)
    end

    it "does not add hints when show_hints is false" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.show_hints = false

      hint = PaceEditor::UI::UIHint.new("test_hint", "Test message", PaceEditor::UI::UIHintType::Info)
      harness.ui_state.add_hint(hint)

      harness.ui_state.hint_queue.size.should eq(0)
    end

    it "does not add duplicate hints" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.show_hints = true

      hint1 = PaceEditor::UI::UIHint.new("test_hint", "Test message", PaceEditor::UI::UIHintType::Info)
      hint2 = PaceEditor::UI::UIHint.new("test_hint", "Another message", PaceEditor::UI::UIHintType::Info)

      harness.ui_state.add_hint(hint1)
      harness.ui_state.add_hint(hint2)

      harness.ui_state.hint_queue.size.should eq(1)
    end

    it "gets next hint and removes from queue" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.show_hints = true

      hint = PaceEditor::UI::UIHint.new("test_hint", "Test message", PaceEditor::UI::UIHintType::Info)
      harness.ui_state.add_hint(hint)

      retrieved = harness.ui_state.get_next_hint
      retrieved.should_not be_nil
      retrieved.try(&.id).should eq("test_hint")

      harness.ui_state.hint_queue.size.should eq(0)
    end

    it "returns nil when no hints" do
      harness = E2ETestHelper.create_harness_with_project

      retrieved = harness.ui_state.get_next_hint
      retrieved.should be_nil
    end

    it "dismisses hint by id" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.show_hints = true

      hint1 = PaceEditor::UI::UIHint.new("hint1", "Message 1", PaceEditor::UI::UIHintType::Info)
      hint2 = PaceEditor::UI::UIHint.new("hint2", "Message 2", PaceEditor::UI::UIHintType::Info)

      harness.ui_state.add_hint(hint1)
      harness.ui_state.add_hint(hint2)

      harness.ui_state.dismiss_hint("hint1")

      harness.ui_state.hint_queue.size.should eq(1)
      harness.ui_state.hint_queue.first.id.should eq("hint2")
    end

    it "clears all hints" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.show_hints = true

      harness.ui_state.add_hint(PaceEditor::UI::UIHint.new("hint1", "M1", PaceEditor::UI::UIHintType::Info))
      harness.ui_state.add_hint(PaceEditor::UI::UIHint.new("hint2", "M2", PaceEditor::UI::UIHintType::Info))

      harness.ui_state.clear_hints

      harness.ui_state.hint_queue.size.should eq(0)
    end
  end

  describe "Recent actions tracking" do
    it "tracks actions" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.track_action("test_action")

      harness.ui_state.recent_actions.should contain("test_action")
    end

    it "has_recent_action? returns true for tracked action" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.track_action("test_action")

      harness.ui_state.has_recent_action?("test_action").should be_true
    end

    it "has_recent_action? returns false for untracked action" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.has_recent_action?("unknown_action").should be_false
    end

    it "has_recent_action? returns false when no actions" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.recent_actions.clear

      harness.ui_state.has_recent_action?("any_action").should be_false
    end
  end

  describe "Tutorial and onboarding" do
    it "marks tutorial as completed" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.mark_tutorial_completed("basic_workflow")

      harness.ui_state.is_tutorial_completed?("basic_workflow").should be_true
    end

    it "is_tutorial_completed? returns false for uncompleted tutorial" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.is_tutorial_completed?("advanced_workflow").should be_false
    end

    it "should_show_onboarding? returns true for first run without tutorial" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.first_run = true
      harness.ui_state.completed_tutorials.clear

      harness.ui_state.should_show_onboarding?.should be_true
    end

    it "should_show_onboarding? returns false after basic_workflow completed" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.first_run = true
      harness.ui_state.mark_tutorial_completed("basic_workflow")

      harness.ui_state.should_show_onboarding?.should be_false
    end

    it "should_show_onboarding? returns false when not first run" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.first_run = false

      harness.ui_state.should_show_onboarding?.should be_false
    end
  end

  describe "Mode management" do
    it "tracks mode switch" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.track_mode_switch(PaceEditor::EditorMode::Scene)

      harness.ui_state.last_mode_switch.should_not be_nil
      harness.ui_state.recent_actions.any? { |a| a.includes?("mode_switch") }.should be_true
    end

    it "get_available_modes returns all modes in power mode" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.enable_power_mode

      modes = harness.ui_state.get_available_modes(harness.editor.state)

      modes.size.should eq(PaceEditor::EditorMode.values.size)
    end

    it "get_available_modes uses ComponentVisibility when not in power mode" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.disable_power_mode

      modes = harness.ui_state.get_available_modes(harness.editor.state)

      # Should match ComponentVisibility result
      expected = PaceEditor::UI::ComponentVisibility.get_available_modes(harness.editor.state)
      modes.should eq(expected)
    end
  end

  describe "Tooltip management" do
    it "shows tooltip" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.show_tooltip("Test tooltip", RL::Vector2.new(x: 100.0_f32, y: 100.0_f32))

      harness.ui_state.active_tooltip.should eq("Test tooltip")
      harness.ui_state.tooltip_position.should_not be_nil
    end

    it "hides tooltip" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.show_tooltip("Test tooltip", RL::Vector2.new(x: 100.0_f32, y: 100.0_f32))
      harness.ui_state.hide_tooltip

      harness.ui_state.active_tooltip.should be_nil
      harness.ui_state.tooltip_position.should be_nil
    end

    it "has_active_tooltip? returns true when tooltip shown" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.show_tooltip("Test", RL::Vector2.new(x: 0.0_f32, y: 0.0_f32))

      harness.ui_state.has_active_tooltip?.should be_true
    end

    it "has_active_tooltip? returns false when no tooltip" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.has_active_tooltip?.should be_false
    end
  end

  describe "Progress tracking" do
    it "updates project progress" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.ui_state.update_project_progress(harness.editor.state)

      # Progress should be updated based on project state
      percentage = harness.ui_state.get_completion_percentage
      percentage.should be >= 0.0_f32
      percentage.should be <= 100.0_f32
    end

    it "gets completion percentage" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.update_project_progress(harness.editor.state)
      percentage = harness.ui_state.get_completion_percentage

      percentage.should be_a(Float32)
    end

    it "gets next suggested action" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.update_project_progress(harness.editor.state)
      action = harness.ui_state.get_next_suggested_action(harness.editor.state)

      # Should return either a suggestion or nil
      if action
        action.should be_a(String)
      end
    end
  end

  describe "UI preferences" do
    it "initializes with default panel layout" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.panel_layout.should eq(PaceEditor::UI::PanelLayout::Standard)
    end

    it "initializes with default theme" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.theme.should eq(PaceEditor::UI::UITheme::Default)
    end

    it "initializes with default font scale" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.font_scale.should eq(1.0_f32)
    end

    it "can change panel layout" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.panel_layout = PaceEditor::UI::PanelLayout::Compact

      harness.ui_state.panel_layout.should eq(PaceEditor::UI::PanelLayout::Compact)
    end
  end
end
