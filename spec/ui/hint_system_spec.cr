require "../spec_helper"

describe "Hint System Extensions" do
  describe "UIHint" do
    it "creates hint with all properties" do
      hint = PaceEditor::UI::UIHint.new(
        "test_id",
        "Test hint message",
        PaceEditor::UI::UIHintType::Info,
        priority: 5,
        expires_in: 30.seconds
      )

      hint.id.should eq("test_id")
      hint.text.should eq("Test hint message")
      hint.type.should eq(PaceEditor::UI::UIHintType::Info)
      hint.priority.should eq(5)
      hint.expires_at.should_not be_nil
    end

    it "creates hint without expiration" do
      hint = PaceEditor::UI::UIHint.new(
        "test_id",
        "Test hint message",
        PaceEditor::UI::UIHintType::Warning
      )

      hint.expires_at.should be_nil
      hint.expired?.should be_false
    end

    it "detects expired hints" do
      hint = PaceEditor::UI::UIHint.new(
        "test_id",
        "Test hint message",
        PaceEditor::UI::UIHintType::Error,
        expires_in: -1.seconds  # Already expired
      )

      hint.expired?.should be_true
    end

    it "handles different hint types" do
      types = [
        PaceEditor::UI::UIHintType::Info,
        PaceEditor::UI::UIHintType::Warning,
        PaceEditor::UI::UIHintType::Success,
        PaceEditor::UI::UIHintType::Error,
        PaceEditor::UI::UIHintType::Suggestion,
        PaceEditor::UI::UIHintType::Feature,
        PaceEditor::UI::UIHintType::Tutorial
      ]

      types.each do |type|
        hint = PaceEditor::UI::UIHint.new("test", "Test", type)
        hint.type.should eq(type)
      end
    end
  end

  describe "ProjectProgress" do
    it "starts with no progress" do
      progress = PaceEditor::UI::ProjectProgress.new
      
      progress.has_project.should be_false
      progress.has_scenes.should be_false
      progress.has_characters.should be_false
      progress.has_npcs.should be_false
      progress.has_hotspots.should be_false
      progress.has_dialogs.should be_false
      progress.has_assets.should be_false
      progress.has_scripts.should be_false
    end

    it "calculates completion percentage correctly" do
      progress = PaceEditor::UI::ProjectProgress.new
      
      # No progress initially
      progress.completion_percentage.should eq(0.0_f32)

      # Set some progress
      progress.has_project = true
      progress.has_scenes = true
      
      # Should be 2/8 = 25%
      progress.completion_percentage.should eq(25.0_f32)

      # Full progress
      progress.has_project = true
      progress.has_scenes = true
      progress.has_characters = true
      progress.has_npcs = true
      progress.has_hotspots = true
      progress.has_dialogs = true
      progress.has_assets = true
      progress.has_scripts = true

      progress.completion_percentage.should eq(100.0_f32)
    end

    it "provides next action suggestions" do
      progress = PaceEditor::UI::ProjectProgress.new
      editor_state = test_editor_state(has_project: false)

      action = progress.get_next_action(editor_state)
      action.should eq("Create or open a project")

      progress.has_project = true
      action = progress.get_next_action(editor_state)
      action.should eq("Create your first scene")

      progress.has_scenes = true
      action = progress.get_next_action(editor_state)
      action.should eq("Add characters to your scene")

      progress.has_characters = true
      action = progress.get_next_action(editor_state)
      action.should eq("Import or create assets")

      progress.has_assets = true
      action = progress.get_next_action(editor_state)
      action.should eq("Add interactive hotspots")

      progress.has_hotspots = true
      action = progress.get_next_action(editor_state)
      action.should eq("Create NPCs for dialogs")

      progress.has_npcs = true
      action = progress.get_next_action(editor_state)
      action.should eq("Write character dialogs")

      progress.has_dialogs = true
      action = progress.get_next_action(editor_state)
      action.should eq("Add custom scripts")

      progress.has_scripts = true
      action = progress.get_next_action(editor_state)
      action.should eq("Your project is ready to export!")
    end
  end

  describe "Contextual Hints" do
    it "adds contextual hints for project creation" do
      ui_state = PaceEditor::UI::UIState.new
      ui_state.show_hints = true
      
      ui_state.track_action("project_created")

      hint = ui_state.get_next_hint
      hint.should_not be_nil
      hint.not_nil!.id.should eq("create_scene")
      hint.not_nil!.text.should contain("scene")
      hint.not_nil!.type.should eq(PaceEditor::UI::UIHintType::Suggestion)
    end

    it "adds contextual hints for scene creation" do
      ui_state = PaceEditor::UI::UIState.new
      ui_state.show_hints = true
      
      ui_state.track_action("scene_created")

      hint = ui_state.get_next_hint
      hint.should_not be_nil
      hint.not_nil!.id.should eq("add_character")
      hint.not_nil!.text.should contain("character")
    end

    it "adds contextual hints for character addition" do
      ui_state = PaceEditor::UI::UIState.new
      ui_state.show_hints = true
      
      ui_state.track_action("character_added")

      hint = ui_state.get_next_hint
      hint.should_not be_nil
      hint.not_nil!.id.should eq("add_hotspots")
      hint.not_nil!.text.should contain("hotspot")
    end

    it "adds contextual hints for NPC addition" do
      ui_state = PaceEditor::UI::UIState.new
      ui_state.show_hints = true
      
      ui_state.track_action("npc_added")

      hint = ui_state.get_next_hint
      hint.should_not be_nil
      hint.not_nil!.id.should eq("create_dialog")
      hint.not_nil!.text.should contain("dialog")
      hint.not_nil!.type.should eq(PaceEditor::UI::UIHintType::Feature)
    end

    it "ignores contextual hints when hints are disabled" do
      ui_state = PaceEditor::UI::UIState.new
      ui_state.show_hints = false

      ui_state.track_action("project_created")
      ui_state.track_action("scene_created")
      ui_state.track_action("character_added")

      hint = ui_state.get_next_hint
      hint.should be_nil
    end
  end

  describe "Tutorial System" do
    describe "Tutorial" do
      it "creates tutorial with steps" do
        steps = [
          PaceEditor::UI::WorkflowStep.new("Step 1", "Description 1"),
          PaceEditor::UI::WorkflowStep.new("Step 2", "Description 2")
        ]

        tutorial = PaceEditor::UI::Tutorial.new("test_tutorial", steps)

        tutorial.name.should eq("test_tutorial")
        tutorial.steps.size.should eq(2)
        tutorial.current_step_index.should eq(0)
      end

      it "advances through steps" do
        steps = [
          PaceEditor::UI::WorkflowStep.new("Step 1", "Description 1"),
          PaceEditor::UI::WorkflowStep.new("Step 2", "Description 2")
        ]

        tutorial = PaceEditor::UI::Tutorial.new("test_tutorial", steps)

        tutorial.current_step.not_nil!.title.should eq("Step 1")
        tutorial.completed?.should be_false

        tutorial.advance_step
        tutorial.current_step.not_nil!.title.should eq("Step 2")
        tutorial.completed?.should be_false

        tutorial.advance_step
        tutorial.current_step.should be_nil
        tutorial.completed?.should be_true
      end
    end

    describe "WorkflowStep" do
      it "creates step with completion condition" do
        condition = ->(state : PaceEditor::Core::EditorState, ui : PaceEditor::UI::UIState) {
          state.has_project?
        }

        step = PaceEditor::UI::WorkflowStep.new(
          "Create Project",
          "Create a new project",
          completion_condition: condition
        )

        step.title.should eq("Create Project")
        step.description.should eq("Create a new project")
        step.completion_condition.should_not be_nil
      end

      it "evaluates completion condition correctly" do
        condition = ->(state : PaceEditor::Core::EditorState, ui : PaceEditor::UI::UIState) {
          state.has_project?
        }

        step = PaceEditor::UI::WorkflowStep.new(
          "Create Project",
          "Create a new project",
          completion_condition: condition
        )

        editor_state = test_editor_state(has_project: false)
        ui_state = PaceEditor::UI::UIState.new

        step.completed?(editor_state, ui_state).should be_false

        # Update state to have project
        editor_state_with_project = test_editor_state(has_project: true)
        step.completed?(editor_state_with_project, ui_state).should be_true
      end

      it "handles step without completion condition" do
        step = PaceEditor::UI::WorkflowStep.new("Manual Step", "Complete manually")

        editor_state = test_editor_state(has_project: true)
        ui_state = PaceEditor::UI::UIState.new

        # Should return false when no condition is set
        step.completed?(editor_state, ui_state).should be_false
      end

      it "can include target area for highlighting" do
        target_area = RL::Rectangle.new(x: 10.0_f32, y: 10.0_f32, width: 100.0_f32, height: 50.0_f32)

        step = PaceEditor::UI::WorkflowStep.new(
          "Click Here",
          "Click on the highlighted area",
          target_area: target_area
        )

        step.target_area.should eq(target_area)
      end
    end
  end
end