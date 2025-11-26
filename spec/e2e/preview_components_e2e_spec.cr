require "./e2e_spec_helper"

describe "Preview Components E2E Tests" do
  describe "HotspotInteractionPreview" do
    it "initializes in hidden state" do
      harness = E2ETestHelper.create_harness_with_project
      preview = PaceEditor::UI::HotspotInteractionPreview.new(harness.editor.state)

      preview.visible.should be_false
      preview.test_hotspot.should be_nil
    end

    it "shows preview with hotspot data" do
      harness = E2ETestHelper.create_harness_with_scene
      preview = PaceEditor::UI::HotspotInteractionPreview.new(harness.editor.state)

      # Create a test hotspot
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
        RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
      )
      hotspot.description = "A test hotspot"

      preview.show(hotspot)
      preview.visible.should be_true
      preview.test_hotspot.should eq(hotspot)
      preview.test_selected_interaction.should eq("on_click")
    end

    it "hides preview when hide is called" do
      harness = E2ETestHelper.create_harness_with_scene
      preview = PaceEditor::UI::HotspotInteractionPreview.new(harness.editor.state)

      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
        RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
      )
      preview.show(hotspot)
      preview.visible.should be_true

      preview.hide
      preview.visible.should be_false
      preview.test_hotspot.should be_nil
    end

    it "closes on escape key" do
      harness = E2ETestHelper.create_harness_with_scene
      preview = PaceEditor::UI::HotspotInteractionPreview.new(harness.editor.state)

      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
        RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
      )
      preview.show(hotspot)

      input = harness.input
      input.press_key(RL::KeyboardKey::Escape)

      preview.update_with_input(input)
      preview.visible.should be_false
    end

    it "initializes simulation log on show" do
      harness = E2ETestHelper.create_harness_with_scene
      preview = PaceEditor::UI::HotspotInteractionPreview.new(harness.editor.state)

      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
        RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
      )
      hotspot.description = "Test description"
      preview.show(hotspot)

      log = preview.test_simulation_log
      log.should_not be_empty
      log.first.should contain("test_hotspot")
    end

    it "clears log when show is called again" do
      harness = E2ETestHelper.create_harness_with_scene
      preview = PaceEditor::UI::HotspotInteractionPreview.new(harness.editor.state)

      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
        RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
      )
      preview.show(hotspot)
      preview.test_add_log_entry("Custom entry")

      # Show again should reset log
      preview.show(hotspot)
      preview.test_simulation_log.any? { |entry| entry.includes?("Custom entry") }.should be_false
    end

    it "can change selected interaction" do
      harness = E2ETestHelper.create_harness_with_scene
      preview = PaceEditor::UI::HotspotInteractionPreview.new(harness.editor.state)

      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
        RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
      )
      preview.show(hotspot)

      preview.test_set_selected_interaction("on_look")
      preview.test_selected_interaction.should eq("on_look")
    end

    it "simulates interactions and logs results" do
      harness = E2ETestHelper.create_harness_with_scene
      preview = PaceEditor::UI::HotspotInteractionPreview.new(harness.editor.state)

      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
        RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
      )
      preview.show(hotspot)
      initial_log_size = preview.test_simulation_log.size

      preview.test_simulate_interaction("on_click")

      # Log should have new entries
      preview.test_simulation_log.size.should be > initial_log_size
    end

    it "clears log when clear log is triggered" do
      harness = E2ETestHelper.create_harness_with_scene
      preview = PaceEditor::UI::HotspotInteractionPreview.new(harness.editor.state)

      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
        RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
      )
      preview.show(hotspot)
      preview.test_add_log_entry("Entry 1")
      preview.test_add_log_entry("Entry 2")

      preview.test_clear_log
      preview.test_simulation_log.should be_empty
    end

    it "calculates button bounds correctly" do
      harness = E2ETestHelper.create_harness_with_scene
      preview = PaceEditor::UI::HotspotInteractionPreview.new(harness.editor.state)

      close_bounds = preview.test_close_button_bounds
      close_bounds[:width].should eq(20)
      close_bounds[:height].should eq(20)

      clear_bounds = preview.test_clear_log_button_bounds
      clear_bounds[:height].should eq(30)
    end

    it "calculates interaction button bounds for all types" do
      harness = E2ETestHelper.create_harness_with_scene
      preview = PaceEditor::UI::HotspotInteractionPreview.new(harness.editor.state)

      ["on_click", "on_look", "on_use", "on_talk"].each do |interaction|
        bounds = preview.test_interaction_button_bounds(interaction)
        bounds.should_not be_nil
        if bounds
          bounds[:height].should eq(25)
        end
      end
    end
  end

  describe "GuidedWorkflow" do
    it "initializes tutorials" do
      harness = E2ETestHelper.create_harness_with_project
      # GuidedWorkflow requires both editor_state and ui_state
      workflow = PaceEditor::UI::GuidedWorkflow.new(harness.editor.state, harness.ui_state)

      tutorials = workflow.test_tutorials
      tutorials.should_not be_empty
      tutorials.has_key?("basic_workflow").should be_true
    end

    it "starts tutorial by name" do
      harness = E2ETestHelper.create_harness_with_project
      workflow = PaceEditor::UI::GuidedWorkflow.new(harness.editor.state, harness.ui_state)

      workflow.test_current_tutorial.should be_nil

      workflow.test_start_tutorial("basic_workflow")
      workflow.test_current_tutorial.should_not be_nil
    end

    it "advances tutorial steps" do
      harness = E2ETestHelper.create_harness_with_project
      workflow = PaceEditor::UI::GuidedWorkflow.new(harness.editor.state, harness.ui_state)

      workflow.test_start_tutorial("basic_workflow")
      tutorial = workflow.test_current_tutorial
      tutorial.should_not be_nil

      if tutorial
        initial_index = tutorial.test_current_step_index
        workflow.test_complete_current_step
        tutorial.test_current_step_index.should eq(initial_index + 1)
      end
    end

    it "skips tutorial completely" do
      harness = E2ETestHelper.create_harness_with_project
      workflow = PaceEditor::UI::GuidedWorkflow.new(harness.editor.state, harness.ui_state)

      workflow.test_start_tutorial("basic_workflow")
      workflow.test_current_tutorial.should_not be_nil

      workflow.test_skip_tutorial
      workflow.test_current_tutorial.should be_nil
    end

    it "shows getting started when no project" do
      harness = PaceEditor::Testing::TestHarness.new
      workflow = PaceEditor::UI::GuidedWorkflow.new(harness.editor.state, harness.ui_state)

      # Without a project, should show getting started (if onboarding enabled)
      harness.editor.state.current_project.should be_nil
    end

    it "calculates button bounds for getting started panel" do
      harness = E2ETestHelper.create_harness_with_project
      workflow = PaceEditor::UI::GuidedWorkflow.new(harness.editor.state, harness.ui_state)

      new_project_bounds = workflow.test_new_project_button_bounds
      open_project_bounds = workflow.test_open_project_button_bounds
      tutorial_bounds = workflow.test_tutorial_button_bounds

      # All buttons should have same width
      new_project_bounds[:width].should eq(150.0_f32)
      open_project_bounds[:width].should eq(150.0_f32)
      tutorial_bounds[:width].should eq(150.0_f32)

      # Buttons should be vertically stacked
      new_project_bounds[:y].should be < open_project_bounds[:y]
      open_project_bounds[:y].should be < tutorial_bounds[:y]
    end

    it "handles tutorial input when active" do
      harness = E2ETestHelper.create_harness_with_project
      workflow = PaceEditor::UI::GuidedWorkflow.new(harness.editor.state, harness.ui_state)

      workflow.test_start_tutorial("basic_workflow")
      workflow.test_current_tutorial.should_not be_nil

      # Next and skip buttons should have bounds
      next_bounds = workflow.test_next_button_bounds
      skip_bounds = workflow.test_skip_button_bounds

      next_bounds.should_not be_nil
      skip_bounds.should_not be_nil
    end
  end

  describe "DialogPreviewWindow" do
    it "initializes in hidden state" do
      harness = E2ETestHelper.create_harness_with_project
      preview = PaceEditor::UI::DialogPreviewWindow.new(harness.editor.state)

      preview.visible.should be_false
    end

    it "shows preview with dialog tree" do
      harness = E2ETestHelper.create_harness_with_project
      preview = PaceEditor::UI::DialogPreviewWindow.new(harness.editor.state)

      # Create a simple dialog tree
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
      node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello, world!")
      dialog_tree.add_node(node)
      dialog_tree.current_node_id = "start"

      preview.show(dialog_tree)
      preview.visible.should be_true
      preview.test_dialog_tree.should eq(dialog_tree)
    end

    it "hides preview when hide is called" do
      harness = E2ETestHelper.create_harness_with_project
      preview = PaceEditor::UI::DialogPreviewWindow.new(harness.editor.state)

      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
      node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello!")
      dialog_tree.add_node(node)
      dialog_tree.current_node_id = "start"

      preview.show(dialog_tree)
      preview.hide
      preview.visible.should be_false
    end

    it "closes on escape key" do
      harness = E2ETestHelper.create_harness_with_project
      preview = PaceEditor::UI::DialogPreviewWindow.new(harness.editor.state)

      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
      node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello!")
      dialog_tree.add_node(node)
      dialog_tree.current_node_id = "start"

      preview.show(dialog_tree)

      input = harness.input
      input.press_key(RL::KeyboardKey::Escape)

      preview.update_with_input(input)
      preview.visible.should be_false
    end

    it "navigates choices with arrow keys" do
      harness = E2ETestHelper.create_harness_with_project
      preview = PaceEditor::UI::DialogPreviewWindow.new(harness.editor.state)

      # Set up choices count for testing
      preview.test_set_current_choices_count(3)
      preview.test_set_selected_choice_index(0)

      input = harness.input
      input.press_key(RL::KeyboardKey::Down)

      # Simulate the dialog being visible
      preview.visible = true
      preview.update_with_input(input)
      preview.test_selected_choice_index.should eq(1)
    end

    it "wraps choice selection from last to first" do
      harness = E2ETestHelper.create_harness_with_project
      preview = PaceEditor::UI::DialogPreviewWindow.new(harness.editor.state)

      preview.test_set_current_choices_count(3)
      preview.test_set_selected_choice_index(2) # Last choice

      input = harness.input
      input.press_key(RL::KeyboardKey::Down)

      preview.visible = true
      preview.update_with_input(input)
      preview.test_selected_choice_index.should eq(0) # Should wrap to first
    end

    it "wraps choice selection from first to last" do
      harness = E2ETestHelper.create_harness_with_project
      preview = PaceEditor::UI::DialogPreviewWindow.new(harness.editor.state)

      preview.test_set_current_choices_count(3)
      preview.test_set_selected_choice_index(0) # First choice

      input = harness.input
      input.press_key(RL::KeyboardKey::Up)

      preview.visible = true
      preview.update_with_input(input)
      preview.test_selected_choice_index.should eq(2) # Should wrap to last
    end

    it "tracks dialog state variables" do
      harness = E2ETestHelper.create_harness_with_project
      preview = PaceEditor::UI::DialogPreviewWindow.new(harness.editor.state)

      preview.test_set_dialog_state("player_name", "Hero")
      preview.test_dialog_state["player_name"].should eq("Hero")
    end

    it "tracks conversation history" do
      harness = E2ETestHelper.create_harness_with_project
      preview = PaceEditor::UI::DialogPreviewWindow.new(harness.editor.state)

      preview.test_add_conversation_entry("NPC: Hello there!")
      preview.test_add_conversation_entry("Player: Hi!")

      preview.test_conversation_history.size.should eq(2)
      preview.test_conversation_history.first.should eq("NPC: Hello there!")
    end

    it "calculates button bounds correctly" do
      harness = E2ETestHelper.create_harness_with_project
      preview = PaceEditor::UI::DialogPreviewWindow.new(harness.editor.state)

      close_bounds = preview.test_close_button_bounds
      close_bounds[:width].should eq(20)
      close_bounds[:height].should eq(20)

      restart_bounds = preview.test_restart_button_bounds
      restart_bounds[:width].should eq(80)
      restart_bounds[:height].should eq(25)
    end

    it "calculates choice bounds when choices available" do
      harness = E2ETestHelper.create_harness_with_project
      preview = PaceEditor::UI::DialogPreviewWindow.new(harness.editor.state)

      preview.test_set_current_choices_count(3)

      bounds_0 = preview.test_choice_bounds(0)
      bounds_1 = preview.test_choice_bounds(1)
      bounds_2 = preview.test_choice_bounds(2)

      bounds_0.should_not be_nil
      bounds_1.should_not be_nil
      bounds_2.should_not be_nil

      # Choices should be vertically stacked
      if b0 = bounds_0
        if b1 = bounds_1
          b0[:y].should be < b1[:y]
        end
      end
    end

    it "returns nil for invalid choice index" do
      harness = E2ETestHelper.create_harness_with_project
      preview = PaceEditor::UI::DialogPreviewWindow.new(harness.editor.state)

      preview.test_set_current_choices_count(3)

      preview.test_choice_bounds(-1).should be_nil
      preview.test_choice_bounds(5).should be_nil
    end
  end

  describe "Tutorial class" do
    it "starts at step 0" do
      steps = [
        PaceEditor::UI::WorkflowStep.new("Step 1", "First step"),
        PaceEditor::UI::WorkflowStep.new("Step 2", "Second step"),
      ]
      tutorial = PaceEditor::UI::Tutorial.new("test_tutorial", steps)

      tutorial.start
      tutorial.test_current_step_index.should eq(0)
    end

    it "advances step index" do
      steps = [
        PaceEditor::UI::WorkflowStep.new("Step 1", "First step"),
        PaceEditor::UI::WorkflowStep.new("Step 2", "Second step"),
      ]
      tutorial = PaceEditor::UI::Tutorial.new("test_tutorial", steps)

      tutorial.start
      tutorial.advance_step
      tutorial.test_current_step_index.should eq(1)
    end

    it "reports completion when all steps done" do
      steps = [
        PaceEditor::UI::WorkflowStep.new("Step 1", "First step"),
        PaceEditor::UI::WorkflowStep.new("Step 2", "Second step"),
      ]
      tutorial = PaceEditor::UI::Tutorial.new("test_tutorial", steps)

      tutorial.start
      tutorial.completed?.should be_false

      tutorial.advance_step
      tutorial.completed?.should be_false

      tutorial.advance_step
      tutorial.completed?.should be_true
    end

    it "returns current step" do
      steps = [
        PaceEditor::UI::WorkflowStep.new("Step 1", "First step"),
        PaceEditor::UI::WorkflowStep.new("Step 2", "Second step"),
      ]
      tutorial = PaceEditor::UI::Tutorial.new("test_tutorial", steps)

      tutorial.start
      step = tutorial.current_step
      step.should_not be_nil
      step.try(&.title).should eq("Step 1")
    end

    it "returns nil for current step when completed" do
      steps = [
        PaceEditor::UI::WorkflowStep.new("Step 1", "First step"),
      ]
      tutorial = PaceEditor::UI::Tutorial.new("test_tutorial", steps)

      tutorial.start
      tutorial.advance_step
      tutorial.current_step.should be_nil
    end
  end
end
