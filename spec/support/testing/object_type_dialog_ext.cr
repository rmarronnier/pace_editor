# Test extensions for ObjectTypeDialog
module PaceEditor::UI
  class ObjectTypeDialog
    # Test-friendly update method that accepts an InputProvider
    def update_with_input(input : PaceEditor::Testing::SimulatedInputProvider)
      return unless @visible

      # Handle keyboard navigation
      if input.key_pressed?(RL::KeyboardKey::Escape)
        hide
      elsif input.key_pressed?(RL::KeyboardKey::Enter)
        confirm_selection
      elsif input.key_pressed?(RL::KeyboardKey::Up)
        cycle_selection(-1)
      elsif input.key_pressed?(RL::KeyboardKey::Down)
        cycle_selection(1)
      end

      # Handle mouse clicks
      if input.mouse_button_pressed?(RL::MouseButton::Left)
        handle_mouse_click_with_input(input)
      end
    end

    private def handle_mouse_click_with_input(input : PaceEditor::Testing::SimulatedInputProvider)
      mouse_pos = input.get_mouse_position
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height

      window_width = 300
      window_height = 250
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

      # Content area
      content_y = window_y + 40
      content_x = window_x + 20
      content_width = window_width - 40
      option_y = content_y + 30
      option_height = 30

      # Check object type options
      ObjectType.values.each_with_index do |object_type, index|
        current_option_y = option_y + index * (option_height + 5)
        if mouse_pos.x >= content_x && mouse_pos.x <= content_x + content_width &&
           mouse_pos.y >= current_option_y && mouse_pos.y <= current_option_y + option_height
          @selected_type = object_type
          confirm_selection
          return
        end
      end

      # Buttons
      button_y = window_y + window_height - 50
      button_width = 80
      button_height = 30

      # OK button
      ok_button_x = content_x
      if mouse_pos.x >= ok_button_x && mouse_pos.x <= ok_button_x + button_width &&
         mouse_pos.y >= button_y && mouse_pos.y <= button_y + button_height
        confirm_selection
        return
      end

      # Cancel button
      cancel_button_x = content_x + content_width - button_width
      if mouse_pos.x >= cancel_button_x && mouse_pos.x <= cancel_button_x + button_width &&
         mouse_pos.y >= button_y && mouse_pos.y <= button_y + button_height
        hide
        return
      end
    end

    # Testing getters
    def test_selected_type : ObjectType
      @selected_type
    end

    def test_on_confirm : Proc(ObjectType, Nil)?
      @on_confirm
    end

    # Testing setters
    def test_set_selected_type(type : ObjectType)
      @selected_type = type
    end

    def test_set_on_confirm(&callback : ObjectType -> Nil)
      @on_confirm = callback
    end

    # Calculate dialog bounds
    def test_dialog_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      window_width = 300
      window_height = 250
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - window_height) // 2

      {x: window_x, y: window_y, width: window_width, height: window_height}
    end

    # Calculate close button bounds
    def test_close_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      bounds = test_dialog_bounds
      {x: bounds[:x] + bounds[:width] - 25, y: bounds[:y] + 5, width: 20, height: 20}
    end

    # Calculate OK button bounds
    def test_ok_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      bounds = test_dialog_bounds
      content_x = bounds[:x] + 20
      button_y = bounds[:y] + bounds[:height] - 50

      {x: content_x, y: button_y, width: 80, height: 30}
    end

    # Calculate Cancel button bounds
    def test_cancel_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      bounds = test_dialog_bounds
      content_x = bounds[:x] + 20
      content_width = bounds[:width] - 40
      button_y = bounds[:y] + bounds[:height] - 50
      button_width = 80

      {x: content_x + content_width - button_width, y: button_y, width: button_width, height: 30}
    end

    # Calculate object type option bounds
    def test_option_bounds(object_type : ObjectType) : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      bounds = test_dialog_bounds
      content_y = bounds[:y] + 40
      content_x = bounds[:x] + 20
      content_width = bounds[:width] - 40
      option_y = content_y + 30
      option_height = 30

      index = ObjectType.values.index(object_type) || 0
      current_option_y = option_y + index * (option_height + 5)

      {x: content_x, y: current_option_y, width: content_width, height: option_height}
    end

    # Expose cycle_selection for testing
    def test_cycle_selection(direction : Int32)
      cycle_selection(direction)
    end

    # Expose confirm_selection for testing
    def test_confirm_selection
      confirm_selection
    end
  end
end
