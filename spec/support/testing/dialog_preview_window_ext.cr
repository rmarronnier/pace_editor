# Test extensions for DialogPreviewWindow
module PaceEditor::UI
  class DialogPreviewWindow
    # Test-friendly update method that accepts an InputProvider
    def update_with_input(input : PaceEditor::Testing::SimulatedInputProvider)
      return unless @visible

      # Handle keyboard
      if input.key_pressed?(RL::KeyboardKey::Escape)
        hide
        return
      end

      # Handle choice navigation when choices are displayed
      if choice_count = @current_choices_count
        if choice_count > 0
          if input.key_pressed?(RL::KeyboardKey::Up)
            # Use explicit wrap-around to avoid negative modulo issues in Crystal
            @selected_choice_index = (@selected_choice_index - 1 + choice_count) % choice_count
          elsif input.key_pressed?(RL::KeyboardKey::Down)
            @selected_choice_index = (@selected_choice_index + 1) % choice_count
          elsif input.key_pressed?(RL::KeyboardKey::Enter)
            select_choice(@selected_choice_index)
          end
        end
      end
    end

    # Draw with input handling for testing
    def draw_with_input(input : PaceEditor::Testing::SimulatedInputProvider)
      return unless @visible

      if input.mouse_button_pressed?(RL::MouseButton::Left)
        handle_click_with_input(input)
      end
    end

    private def handle_click_with_input(input : PaceEditor::Testing::SimulatedInputProvider)
      mouse_pos = input.get_mouse_position
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height

      window_width = 600
      window_height = 500
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - window_height) // 2

      # Check close button
      close_button_x = window_x + window_width - 25
      close_button_y = window_y + 5
      if mouse_pos.x >= close_button_x && mouse_pos.x <= close_button_x + 20 &&
         mouse_pos.y >= close_button_y && mouse_pos.y <= close_button_y + 20
        hide
        return
      end

      # Check restart button
      restart_button_x = window_x + 10
      restart_button_y = window_y + window_height - 35
      restart_button_width = 80
      restart_button_height = 25
      if mouse_pos.x >= restart_button_x && mouse_pos.x <= restart_button_x + restart_button_width &&
         mouse_pos.y >= restart_button_y && mouse_pos.y <= restart_button_y + restart_button_height
        restart_preview
        return
      end

      # Check choice clicks if in choice mode
      if choice_count = @current_choices_count
        if choice_count > 0
          choice_y = window_y + 200
          choice_height = 30

          choice_count.times do |i|
            if mouse_pos.x >= window_x + 20 && mouse_pos.x <= window_x + window_width - 40 &&
               mouse_pos.y >= choice_y + i * (choice_height + 5) &&
               mouse_pos.y <= choice_y + i * (choice_height + 5) + choice_height
              select_choice(i)
              return
            end
          end
        end
      end
    end

    # Testing getters
    def test_dialog_tree : PointClickEngine::Characters::Dialogue::DialogTree?
      @dialog_tree
    end

    def test_current_node : PointClickEngine::Characters::Dialogue::DialogNode?
      @current_node
    end

    def test_dialog_state : Hash(String, String)
      @dialog_state
    end

    def test_conversation_history : Array(String)
      @conversation_history
    end

    def test_selected_choice_index : Int32
      @selected_choice_index
    end

    def test_current_choices_count : Int32?
      @current_choices_count
    end

    # Testing setters
    def test_set_selected_choice_index(index : Int32)
      @selected_choice_index = index
    end

    def test_set_dialog_state(key : String, value : String)
      @dialog_state[key] = value
    end

    def test_add_conversation_entry(entry : String)
      @conversation_history << entry
    end

    def test_set_current_choices_count(count : Int32?)
      @current_choices_count = count
    end

    # Calculate button bounds for testing
    def test_close_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      window_width = 600
      window_height = 500
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - window_height) // 2

      {x: window_x + window_width - 25, y: window_y + 5, width: 20, height: 20}
    end

    def test_restart_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      window_width = 600
      window_height = 500
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - window_height) // 2

      {x: window_x + 10, y: window_y + window_height - 35, width: 80, height: 25}
    end

    def test_choice_bounds(index : Int32) : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)?
      return nil unless @current_choices_count
      return nil if index < 0 || index >= (@current_choices_count || 0)

      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      window_width = 600
      window_height = 500
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - window_height) // 2

      choice_y = window_y + 200
      choice_height = 30

      {
        x: window_x + 20,
        y: choice_y + index * (choice_height + 5),
        width: window_width - 40,
        height: choice_height,
      }
    end

    # Expose methods for testing
    def test_select_choice(index : Int32)
      select_choice(index)
    end

    def test_restart_preview
      restart_preview
    end
  end
end
