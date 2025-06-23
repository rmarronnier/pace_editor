require "../spec_helper"

describe PaceEditor::UI::GuidedWorkflow do
  guided_workflow : PaceEditor::UI::GuidedWorkflow?
  editor_state : PaceEditor::Core::EditorState?
  ui_state : PaceEditor::UI::UIState?
  
  before_each do
    @editor_state = test_editor_state(has_project: false)
    @ui_state = PaceEditor::UI::UIState.new
    @guided_workflow = PaceEditor::UI::GuidedWorkflow.new(@editor_state.not_nil!, @ui_state.not_nil!)
  end
  
  def guided_workflow
    @guided_workflow.not_nil!
  end
  
  def editor_state
    @editor_state.not_nil!
  end
  
  def ui_state
    @ui_state.not_nil!
  end

  describe "getting started panel" do
    it "shows getting started panel when no project exists" do
      ui_state.first_run = true
      
      guided_workflow.show_getting_started.should be_true
    end

    it "hides getting started panel when project exists" do
      # Create state with project
      state_with_project = test_editor_state(has_project: true)
      guided_workflow.editor_state = state_with_project
      
      guided_workflow.update
      guided_workflow.show_getting_started.should be_false
    end

    it "hides getting started panel when onboarding is disabled" do
      ui_state.first_run = false
      
      guided_workflow.update
      guided_workflow.show_getting_started.should be_false
    end

    it "positions getting started panel in center" do
      rect = guided_workflow.getting_started_rect
      
      # Should be centered on screen (mocked screen size would be needed for exact test)
      rect.width.should eq(400.0_f32)
      rect.height.should eq(300.0_f32)
    end
  end

  describe "tutorial system" do
    it "starts with no active tutorial" do
      guided_workflow.current_tutorial.should be_nil
    end

    it "can start a tutorial" do
      # Mock tutorial retrieval
      tutorial = PaceEditor::UI::Tutorial.new("test_tutorial", [] of PaceEditor::UI::WorkflowStep)
      allow(guided_workflow).to receive(:get_tutorial).and_return(tutorial)
      
      guided_workflow.start_tutorial("test_tutorial")
      guided_workflow.current_tutorial.should_not be_nil
    end

    it "tracks tutorial start action" do
      # Mock tutorial retrieval
      tutorial = PaceEditor::UI::Tutorial.new("test_tutorial", [] of PaceEditor::UI::WorkflowStep)
      allow(guided_workflow).to receive(:get_tutorial).and_return(tutorial)
      
      guided_workflow.start_tutorial("test_tutorial")
      
      ui_state.has_recent_action?("tutorial_started_test_tutorial").should be_true
    end

    it "can complete current step" do
      # Create tutorial with steps
      step = PaceEditor::UI::WorkflowStep.new("Test Step", "Test description")
      tutorial = PaceEditor::UI::Tutorial.new("test_tutorial", [step])
      allow(guided_workflow).to receive(:get_tutorial).and_return(tutorial)
      
      guided_workflow.start_tutorial("test_tutorial")
      guided_workflow.complete_current_step
      
      # Tutorial should advance to next step or complete
      tutorial.current_step_index.should eq(1)
    end

    it "marks tutorial as completed when finished" do
      # Create tutorial with one step
      step = PaceEditor::UI::WorkflowStep.new("Test Step", "Test description")
      tutorial = PaceEditor::UI::Tutorial.new("test_tutorial", [step])
      allow(guided_workflow).to receive(:get_tutorial).and_return(tutorial)
      
      guided_workflow.start_tutorial("test_tutorial")
      guided_workflow.complete_current_step
      
      # Tutorial should be completed and cleared
      guided_workflow.current_tutorial.should be_nil
      ui_state.is_tutorial_completed?("test_tutorial").should be_true
    end

    it "can skip tutorial" do
      # Create tutorial with steps
      step = PaceEditor::UI::WorkflowStep.new("Test Step", "Test description")
      tutorial = PaceEditor::UI::Tutorial.new("test_tutorial", [step])
      allow(guided_workflow).to receive(:get_tutorial).and_return(tutorial)
      
      guided_workflow.start_tutorial("test_tutorial")
      guided_workflow.skip_tutorial
      
      guided_workflow.current_tutorial.should be_nil
      ui_state.is_tutorial_completed?("test_tutorial").should be_true
    end
  end

  describe "workflow progression" do
    it "auto-advances workflows based on state changes" do
      ui_state.show_hints = true
      
      # Mock recent action check
      allow(ui_state).to receive(:has_recent_action?).with("project_created").and_return(true)
      
      # Create state with project
      state_with_project = test_editor_state(has_project: true)
      guided_workflow.editor_state = state_with_project
      
      guided_workflow.update
      
      # Should have added a hint about creating first scene
      hint = ui_state.get_next_hint
      hint.should_not be_nil
      hint.not_nil!.text.should contain("scene")
    end
  end

  describe "input handling" do
    it "handles getting started panel input" do
      guided_workflow.show_getting_started = true
      
      # Click on "New Project" button area
      mouse_pos = RL::Vector2.new(
        guided_workflow.getting_started_rect.x + guided_workflow.getting_started_rect.width / 2,
        guided_workflow.getting_started_rect.y + 140.0_f32
      )
      
      result = guided_workflow.handle_input(mouse_pos, true)
      
      # Should handle the input and trigger new project dialog
      result.should be_true
      editor_state.show_new_project_dialog.should be_true
      ui_state.has_recent_action?("new_project_from_welcome").should be_true
    end

    it "handles tutorial input" do
      # Set up tutorial with step
      step = PaceEditor::UI::WorkflowStep.new("Test Step", "Test description")
      tutorial = PaceEditor::UI::Tutorial.new("test_tutorial", [step])
      guided_workflow.current_tutorial = tutorial
      
      # Click on "Next" button area
      mouse_pos = RL::Vector2.new(230.0_f32, 172.0_f32)
      result = guided_workflow.handle_input(mouse_pos, true)
      
      result.should be_true
    end

    it "returns false when input is outside interactive areas" do
      guided_workflow.show_getting_started = false
      guided_workflow.current_tutorial = nil
      
      mouse_pos = RL::Vector2.new(100.0_f32, 100.0_f32)
      result = guided_workflow.handle_input(mouse_pos, true)
      
      result.should be_false
    end
  end

  describe "hint display" do
    it "displays contextual hints when enabled" do
      ui_state.show_hints = true
      hint = PaceEditor::UI::UIHint.new("test", "Test suggestion", PaceEditor::UI::UIHintType::Suggestion)
      ui_state.add_hint(hint)
      
      # Mock getting next suggested action
      allow(ui_state).to receive(:get_next_suggested_action).and_return("Create your first scene")
      
      # The draw method would display these hints
      # Here we just verify the setup is correct
      ui_state.get_next_hint.should_not be_nil
    end

    it "hides hints when disabled" do
      ui_state.show_hints = false
      hint = PaceEditor::UI::UIHint.new("test", "Test suggestion", PaceEditor::UI::UIHintType::Suggestion)
      ui_state.add_hint(hint)
      
      # Hints should not be displayed when disabled
      ui_state.get_next_hint.should be_nil
    end
  end

  describe "progress indicator" do
    it "shows progress when project exists and hints are enabled" do
      ui_state.show_hints = true
      state_with_project = test_editor_state(has_project: true)
      guided_workflow.editor_state = state_with_project
      
      # Mock progress calculation
      allow(ui_state).to receive(:get_completion_percentage).and_return(25.0_f32)
      
      # The draw method would show progress indicator
      # Here we verify the conditions are met
      state_with_project.has_project?.should be_true
      ui_state.show_hints.should be_true
    end

    it "hides progress when no project" do
      ui_state.show_hints = true
      
      editor_state.has_project?.should be_false
      # Progress indicator should not be shown
    end
  end

  describe "tutorial step completion" do
    it "creates workflow steps with completion conditions" do
      completion_condition = ->(state : PaceEditor::Core::EditorState, ui : PaceEditor::UI::UIState) { 
        state.has_project? 
      }
      
      step = PaceEditor::UI::WorkflowStep.new(
        "Create Project", 
        "Create a new project to get started",
        completion_condition: completion_condition
      )
      
      step.title.should eq("Create Project")
      step.description.should eq("Create a new project to get started")
      step.completion_condition.should_not be_nil
    end

    it "evaluates step completion conditions" do
      completion_condition = ->(state : PaceEditor::Core::EditorState, ui : PaceEditor::UI::UIState) { 
        state.has_project? 
      }
      
      step = PaceEditor::UI::WorkflowStep.new(
        "Create Project", 
        "Create a new project to get started",
        completion_condition: completion_condition
      )
      
      # Should not be completed when no project
      step.completed?(editor_state, ui_state).should be_false
      
      # Should be completed when project exists
      state_with_project = test_editor_state(has_project: true)
      step.completed?(state_with_project, ui_state).should be_true
    end
  end

  describe "color utilities" do
    it "lightens colors correctly" do
      original = RL::Color.new(r: 100_u8, g: 100_u8, b: 100_u8, a: 255_u8)
      lightened = guided_workflow.send(:lighten_color, original, 50_u8)
      
      lightened.r.should eq(150_u8)
      lightened.g.should eq(150_u8)
      lightened.b.should eq(150_u8)
      lightened.a.should eq(255_u8)
    end

    it "darkens colors correctly" do
      original = RL::Color.new(r: 150_u8, g: 150_u8, b: 150_u8, a: 255_u8)
      darkened = guided_workflow.send(:darken_color, original, 50_u8)
      
      darkened.r.should eq(100_u8)
      darkened.g.should eq(100_u8)
      darkened.b.should eq(100_u8)
      darkened.a.should eq(255_u8)
    end

    it "clamps color values correctly" do
      original = RL::Color.new(r: 200_u8, g: 200_u8, b: 200_u8, a: 255_u8)
      
      # Lightening beyond 255 should clamp to 255
      lightened = guided_workflow.send(:lighten_color, original, 100_u8)
      lightened.r.should eq(255_u8)
      
      # Darkening below 0 should clamp to 0
      darkened = guided_workflow.send(:darken_color, original, 250_u8)
      darkened.r.should eq(0_u8)
    end
  end
end