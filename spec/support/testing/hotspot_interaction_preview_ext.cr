# Test extensions for HotspotInteractionPreview
module PaceEditor::UI
  class HotspotInteractionPreview
    # Test-friendly update method that accepts an InputProvider
    def update_with_input(input : PaceEditor::Testing::SimulatedInputProvider)
      return unless @visible

      # Handle keyboard navigation
      if input.key_pressed?(RL::KeyboardKey::Escape)
        hide
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

      window_width = 700
      window_height = 600
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

      # Check interaction buttons
      if hotspot = @hotspot
        content_y = window_y + 35
        controls_x = window_x + 10
        controls_width = window_width // 2 - 20
        current_y = content_y + 128 # After hotspot info

        interactions = ["on_click", "on_look", "on_use", "on_talk"]
        interactions.each do |interaction|
          button_width = controls_width - 40
          button_height = 25
          button_x = controls_x + 20

          if mouse_pos.x >= button_x && mouse_pos.x <= button_x + button_width &&
             mouse_pos.y >= current_y && mouse_pos.y <= current_y + button_height
            @selected_interaction = interaction
            simulate_interaction(interaction)
            return
          end

          current_y += button_height + 5
        end

        # Check clear log button
        current_y += 10
        clear_button_width = controls_width - 40
        clear_button_height = 30
        clear_button_x = controls_x + 20

        if mouse_pos.x >= clear_button_x && mouse_pos.x <= clear_button_x + clear_button_width &&
           mouse_pos.y >= current_y && mouse_pos.y <= current_y + clear_button_height
          @simulation_log.clear
          @simulation_log << "=== Log Cleared ==="
          return
        end
      end
    end

    # Testing getters
    def test_hotspot : PointClickEngine::Scenes::Hotspot?
      @hotspot
    end

    def test_hotspot_data : Models::HotspotData?
      @hotspot_data
    end

    def test_selected_interaction : String
      @selected_interaction
    end

    def test_simulation_log : Array(String)
      @simulation_log
    end

    def test_cursor_preview : PointClickEngine::Scenes::Hotspot::CursorType
      @cursor_preview
    end

    def test_variables : Hash(String, String)
      @test_variables
    end

    # Testing setters
    def test_set_selected_interaction(interaction : String)
      @selected_interaction = interaction
    end

    def test_clear_log
      @simulation_log.clear
    end

    def test_add_log_entry(entry : String)
      @simulation_log << entry
    end

    # Calculate button bounds for testing
    def test_close_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      window_width = 700
      window_height = 600
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - window_height) // 2

      {x: window_x + window_width - 25, y: window_y + 5, width: 20, height: 20}
    end

    def test_interaction_button_bounds(interaction : String) : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)?
      interactions = ["on_click", "on_look", "on_use", "on_talk"]
      index = interactions.index(interaction)
      return nil unless index

      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      window_width = 700
      window_height = 600
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - window_height) // 2

      content_y = window_y + 35
      controls_x = window_x + 10
      controls_width = window_width // 2 - 20
      button_width = controls_width - 40
      button_height = 25
      button_x = controls_x + 20

      current_y = content_y + 128 + index * (button_height + 5)

      {x: button_x, y: current_y, width: button_width, height: button_height}
    end

    def test_clear_log_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      window_width = 700
      window_height = 600
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - window_height) // 2

      content_y = window_y + 35
      controls_x = window_x + 10
      controls_width = window_width // 2 - 20

      # After 4 interaction buttons
      button_height = 25
      current_y = content_y + 128 + 4 * (button_height + 5) + 10
      clear_button_width = controls_width - 40
      clear_button_height = 30
      clear_button_x = controls_x + 20

      {x: clear_button_x, y: current_y, width: clear_button_width, height: clear_button_height}
    end

    # Expose simulate_interaction for testing
    def test_simulate_interaction(interaction_type : String)
      simulate_interaction(interaction_type)
    end
  end
end
