require "../spec_helper"

describe PaceEditor::UI::UIState do
  ui_state : PaceEditor::UI::UIState?
  
  before_each do
    @ui_state = PaceEditor::UI::UIState.new
  end
  
  def ui_state
    @ui_state.not_nil!
  end

  describe "power mode" do
    it "starts in normal mode" do
      ui_state.power_mode.should be_false
      ui_state.show_advanced_tools.should be_false
    end

    it "enables advanced tools when power mode is enabled" do
      ui_state.enable_power_mode
      
      ui_state.power_mode.should be_true
      ui_state.show_advanced_tools.should be_true
    end

    it "disables advanced tools when power mode is disabled" do
      ui_state.enable_power_mode
      ui_state.disable_power_mode
      
      ui_state.power_mode.should be_false
      ui_state.show_advanced_tools.should be_false
    end

    it "toggles power mode correctly" do
      ui_state.power_mode.should be_false
      
      ui_state.toggle_power_mode
      ui_state.power_mode.should be_true
      
      ui_state.toggle_power_mode
      ui_state.power_mode.should be_false
    end
  end

  describe "component visibility" do
    it "uses override when present" do
      state = test_editor_state(has_project: false)
      
      ui_state.override_component_visibility("scene_editor", PaceEditor::UI::ComponentState::Visible)
      result = ui_state.get_component_visibility("scene_editor", state)
      
      result.should eq(PaceEditor::UI::ComponentState::Visible)
    end

    it "falls back to standard rules when no override" do
      state = test_editor_state(has_project: false)
      
      result = ui_state.get_component_visibility("scene_editor", state)
      result.should eq(PaceEditor::UI::ComponentState::Hidden)
    end

    it "shows everything in power mode" do
      state = test_editor_state(has_project: false)
      ui_state.enable_power_mode
      
      # Mock power mode check
      allow(PaceEditor::UI::ComponentVisibility).to receive(:should_show_in_power_mode?).and_return(true)
      
      result = ui_state.get_component_visibility("scene_editor", state)
      result.should eq(PaceEditor::UI::ComponentState::Visible)
    end

    it "can clear individual overrides" do
      state = test_editor_state(has_project: false)
      
      ui_state.override_component_visibility("scene_editor", PaceEditor::UI::ComponentState::Visible)
      ui_state.clear_visibility_override("scene_editor")
      
      result = ui_state.get_component_visibility("scene_editor", state)
      result.should eq(PaceEditor::UI::ComponentState::Hidden)
    end

    it "can clear all overrides" do
      state = test_editor_state(has_project: false)
      
      ui_state.override_component_visibility("scene_editor", PaceEditor::UI::ComponentState::Visible)
      ui_state.override_component_visibility("character_editor", PaceEditor::UI::ComponentState::Visible)
      ui_state.clear_all_overrides
      
      result1 = ui_state.get_component_visibility("scene_editor", state)
      result2 = ui_state.get_component_visibility("character_editor", state)
      
      result1.should eq(PaceEditor::UI::ComponentState::Hidden)
      result2.should eq(PaceEditor::UI::ComponentState::Hidden)
    end
  end

  describe "hint system" do
    it "adds hints when hints are enabled" do
      ui_state.show_hints = true
      hint = PaceEditor::UI::UIHint.new("test", "Test hint", PaceEditor::UI::UIHintType::Info)
      
      ui_state.add_hint(hint)
      result = ui_state.get_next_hint
      
      result.should_not be_nil
      result.not_nil!.text.should eq("Test hint")
    end

    it "ignores hints when hints are disabled" do
      ui_state.show_hints = false
      hint = PaceEditor::UI::UIHint.new("test", "Test hint", PaceEditor::UI::UIHintType::Info)
      
      ui_state.add_hint(hint)
      result = ui_state.get_next_hint
      
      result.should be_nil
    end

    it "prevents duplicate hints" do
      ui_state.show_hints = true
      hint1 = PaceEditor::UI::UIHint.new("test", "Test hint 1", PaceEditor::UI::UIHintType::Info)
      hint2 = PaceEditor::UI::UIHint.new("test", "Test hint 2", PaceEditor::UI::UIHintType::Info)
      
      ui_state.add_hint(hint1)
      ui_state.add_hint(hint2)  # Should be ignored due to same ID
      
      result1 = ui_state.get_next_hint
      result2 = ui_state.get_next_hint
      
      result1.should_not be_nil
      result1.not_nil!.text.should eq("Test hint 1")
      result2.should be_nil
    end

    it "limits queue size" do
      ui_state.show_hints = true
      
      # Add more hints than the max queue size
      (1..10).each do |i|
        hint = PaceEditor::UI::UIHint.new("test#{i}", "Test hint #{i}", PaceEditor::UI::UIHintType::Info)
        ui_state.add_hint(hint)
      end
      
      # Should only have MAX_HINT_QUEUE_SIZE hints
      count = 0
      while hint = ui_state.get_next_hint
        count += 1
      end
      
      count.should eq(PaceEditor::UI::MAX_HINT_QUEUE_SIZE)
    end

    it "can dismiss specific hints" do
      ui_state.show_hints = true
      hint1 = PaceEditor::UI::UIHint.new("test1", "Test hint 1", PaceEditor::UI::UIHintType::Info)
      hint2 = PaceEditor::UI::UIHint.new("test2", "Test hint 2", PaceEditor::UI::UIHintType::Info)
      
      ui_state.add_hint(hint1)
      ui_state.add_hint(hint2)
      ui_state.dismiss_hint("test1")
      
      result = ui_state.get_next_hint
      result.should_not be_nil
      result.not_nil!.id.should eq("test2")
    end

    it "can clear all hints" do
      ui_state.show_hints = true
      hint1 = PaceEditor::UI::UIHint.new("test1", "Test hint 1", PaceEditor::UI::UIHintType::Info)
      hint2 = PaceEditor::UI::UIHint.new("test2", "Test hint 2", PaceEditor::UI::UIHintType::Info)
      
      ui_state.add_hint(hint1)
      ui_state.add_hint(hint2)
      ui_state.clear_hints
      
      result = ui_state.get_next_hint
      result.should be_nil
    end
  end

  describe "action tracking" do
    it "tracks recent actions" do
      ui_state.track_action("test_action")
      
      ui_state.has_recent_action?("test_action").should be_true
      ui_state.has_recent_action?("other_action").should be_false
    end

    it "limits recent actions count" do
      # Add more actions than the max
      (1..30).each do |i|
        ui_state.track_action("action#{i}")
      end
      
      # Should only keep the most recent MAX_RECENT_ACTIONS
      ui_state.has_recent_action?("action1").should be_false  # Should be dropped
      ui_state.has_recent_action?("action30").should be_true  # Should be kept
    end

    it "triggers contextual hints for specific actions" do
      ui_state.show_hints = true
      
      ui_state.track_action("project_created")
      
      hint = ui_state.get_next_hint
      hint.should_not be_nil
      hint.not_nil!.text.should contain("scene")
    end
  end

  describe "tutorial and onboarding" do
    it "starts as first run" do
      ui_state.first_run.should be_true
    end

    it "tracks completed tutorials" do
      ui_state.mark_tutorial_completed("basic_workflow")
      
      ui_state.is_tutorial_completed?("basic_workflow").should be_true
      ui_state.is_tutorial_completed?("advanced_workflow").should be_false
    end

    it "should show onboarding for first run" do
      ui_state.first_run = true
      
      ui_state.should_show_onboarding?.should be_true
    end

    it "should not show onboarding after basic tutorial" do
      ui_state.first_run = true
      ui_state.mark_tutorial_completed("basic_workflow")
      
      ui_state.should_show_onboarding?.should be_false
    end
  end

  describe "mode management" do
    it "tracks mode switches" do
      ui_state.track_mode_switch(PaceEditor::EditorMode::Scene)
      
      ui_state.has_recent_action?("mode_switch_scene").should be_true
    end

    it "gets available modes in normal mode" do
      state = test_editor_state(has_project: true, current_scene: test_scene)
      
      # Mock ComponentVisibility
      expected_modes = [PaceEditor::EditorMode::Project, PaceEditor::EditorMode::Scene]
      allow(PaceEditor::UI::ComponentVisibility).to receive(:get_available_modes).and_return(expected_modes)
      
      modes = ui_state.get_available_modes(state)
      modes.should eq(expected_modes)
    end

    it "gets all modes in power mode" do
      ui_state.enable_power_mode
      state = test_editor_state(has_project: false)
      
      modes = ui_state.get_available_modes(state)
      modes.should eq(PaceEditor::EditorMode.values)
    end
  end

  describe "tooltip management" do
    it "manages tooltip visibility" do
      ui_state.has_active_tooltip?.should be_false
      
      ui_state.show_tooltip("Test tooltip", RL::Vector2.new(100.0_f32, 200.0_f32))
      ui_state.has_active_tooltip?.should be_true
      
      ui_state.hide_tooltip
      ui_state.has_active_tooltip?.should be_false
    end

    it "stores tooltip text and position" do
      position = RL::Vector2.new(100.0_f32, 200.0_f32)
      ui_state.show_tooltip("Test tooltip", position)
      
      ui_state.active_tooltip.should eq("Test tooltip")
      ui_state.tooltip_position.should eq(position)
    end
  end

  describe "progress tracking" do
    it "updates project progress" do
      state = test_editor_state(has_project: true)
      
      ui_state.update_project_progress(state)
      
      # Progress should be calculated based on project state
      percentage = ui_state.get_completion_percentage
      percentage.should be >= 0.0_f32
      percentage.should be <= 100.0_f32
    end

    it "provides next suggested action" do
      state = test_editor_state(has_project: false)
      
      ui_state.update_project_progress(state)
      suggestion = ui_state.get_next_suggested_action(state)
      
      suggestion.should_not be_nil
      suggestion.not_nil!.should contain("project")
    end
  end
end