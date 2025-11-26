# Test extensions for GuidedWorkflow
module PaceEditor::UI
  class GuidedWorkflow
    # Test-friendly handle_input that accepts InputProvider
    def handle_input_with_provider(input : PaceEditor::Testing::SimulatedInputProvider) : Bool
      mouse_pos = input.get_mouse_position
      mouse_clicked = input.mouse_button_pressed?(RL::MouseButton::Left)

      # Handle tutorial step input first (higher priority when active)
      if tutorial = @current_tutorial
        if step = tutorial.current_step
          return handle_tutorial_input_with_provider(step, mouse_pos, mouse_clicked, input)
        end
      end

      # Handle getting started panel
      if @show_getting_started && PaceEditor::Constants.point_in_rect?(mouse_pos, @getting_started_rect)
        return handle_getting_started_input_with_provider(mouse_pos, mouse_clicked, input)
      end

      false
    end

    private def handle_tutorial_input_with_provider(step : WorkflowStep, mouse_pos : RL::Vector2, clicked : Bool, input : PaceEditor::Testing::SimulatedInputProvider) : Bool
      return false unless clicked

      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      panel_width = 300.0_f32
      panel_height = 150.0_f32
      panel_x = (screen_width - panel_width) / 2
      panel_y = screen_height * 0.2_f32

      next_rect = RL::Rectangle.new(x: panel_x + 150.0_f32, y: panel_y + 110.0_f32, width: 60.0_f32, height: 25.0_f32)
      skip_rect = RL::Rectangle.new(x: panel_x + 220.0_f32, y: panel_y + 110.0_f32, width: 60.0_f32, height: 25.0_f32)

      if PaceEditor::Constants.point_in_rect?(mouse_pos, next_rect)
        complete_current_step
        return true
      elsif PaceEditor::Constants.point_in_rect?(mouse_pos, skip_rect)
        skip_tutorial
        return true
      end

      false
    end

    private def handle_getting_started_input_with_provider(mouse_pos : RL::Vector2, clicked : Bool, input : PaceEditor::Testing::SimulatedInputProvider) : Bool
      return false unless clicked

      button_width = 150.0_f32
      button_height = 35.0_f32
      button_spacing = 20.0_f32

      new_project_rect = RL::Rectangle.new(
        x: @getting_started_rect.x + (@getting_started_rect.width - button_width) / 2,
        y: @getting_started_rect.y + 120.0_f32,
        width: button_width, height: button_height
      )

      open_project_rect = RL::Rectangle.new(
        x: @getting_started_rect.x + (@getting_started_rect.width - button_width) / 2,
        y: @getting_started_rect.y + 120.0_f32 + button_height + button_spacing,
        width: button_width, height: button_height
      )

      tutorial_rect = RL::Rectangle.new(
        x: @getting_started_rect.x + (@getting_started_rect.width - button_width) / 2,
        y: @getting_started_rect.y + 120.0_f32 + (button_height + button_spacing) * 2,
        width: button_width, height: button_height
      )

      if PaceEditor::Constants.point_in_rect?(mouse_pos, new_project_rect)
        @editor_state.show_new_project_dialog = true
        @ui_state.track_action("new_project_from_welcome")
        return true
      elsif PaceEditor::Constants.point_in_rect?(mouse_pos, open_project_rect)
        @ui_state.track_action("open_project_from_welcome")
        return true
      elsif PaceEditor::Constants.point_in_rect?(mouse_pos, tutorial_rect)
        start_tutorial("basic_workflow")
        return true
      end

      false
    end

    # Testing getters
    def test_current_tutorial : Tutorial?
      @current_tutorial
    end

    def test_active_step : WorkflowStep?
      @active_step
    end

    def test_workflow_progress : Hash(String, Float32)
      @workflow_progress
    end

    def test_tutorials : Hash(String, Tutorial)
      @tutorials
    end

    def test_show_getting_started : Bool
      @show_getting_started
    end

    def test_getting_started_rect : RL::Rectangle
      @getting_started_rect
    end

    # Testing setters
    def test_set_show_getting_started(show : Bool)
      @show_getting_started = show
    end

    def test_set_current_tutorial(tutorial : Tutorial?)
      @current_tutorial = tutorial
    end

    # Calculate button bounds for testing
    def test_new_project_button_bounds : NamedTuple(x: Float32, y: Float32, width: Float32, height: Float32)
      button_width = 150.0_f32
      button_height = 35.0_f32

      {
        x: @getting_started_rect.x + (@getting_started_rect.width - button_width) / 2,
        y: @getting_started_rect.y + 120.0_f32,
        width: button_width,
        height: button_height,
      }
    end

    def test_open_project_button_bounds : NamedTuple(x: Float32, y: Float32, width: Float32, height: Float32)
      button_width = 150.0_f32
      button_height = 35.0_f32
      button_spacing = 20.0_f32

      {
        x: @getting_started_rect.x + (@getting_started_rect.width - button_width) / 2,
        y: @getting_started_rect.y + 120.0_f32 + button_height + button_spacing,
        width: button_width,
        height: button_height,
      }
    end

    def test_tutorial_button_bounds : NamedTuple(x: Float32, y: Float32, width: Float32, height: Float32)
      button_width = 150.0_f32
      button_height = 35.0_f32
      button_spacing = 20.0_f32

      {
        x: @getting_started_rect.x + (@getting_started_rect.width - button_width) / 2,
        y: @getting_started_rect.y + 120.0_f32 + (button_height + button_spacing) * 2,
        width: button_width,
        height: button_height,
      }
    end

    def test_next_button_bounds : NamedTuple(x: Float32, y: Float32, width: Float32, height: Float32)?
      return nil unless @current_tutorial

      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      panel_width = 300.0_f32
      panel_x = (screen_width - panel_width) / 2
      panel_y = screen_height * 0.2_f32

      {x: panel_x + 150.0_f32, y: panel_y + 110.0_f32, width: 60.0_f32, height: 25.0_f32}
    end

    def test_skip_button_bounds : NamedTuple(x: Float32, y: Float32, width: Float32, height: Float32)?
      return nil unless @current_tutorial

      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      panel_width = 300.0_f32
      panel_x = (screen_width - panel_width) / 2
      panel_y = screen_height * 0.2_f32

      {x: panel_x + 220.0_f32, y: panel_y + 110.0_f32, width: 60.0_f32, height: 25.0_f32}
    end

    # Expose methods for testing
    def test_start_tutorial(name : String)
      start_tutorial(name)
    end

    def test_complete_current_step
      complete_current_step
    end

    def test_skip_tutorial
      skip_tutorial
    end

    def test_check_workflow_progression
      check_workflow_progression
    end
  end

  # Extensions for Tutorial class
  class Tutorial
    def test_current_step_index : Int32
      @current_step_index
    end

    def test_set_current_step_index(index : Int32)
      @current_step_index = index
    end
  end
end
