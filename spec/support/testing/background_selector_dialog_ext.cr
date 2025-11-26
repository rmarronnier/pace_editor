# Test extensions for BackgroundSelectorDialog
module PaceEditor::UI
  class BackgroundSelectorDialog
    # Test-friendly update method that accepts an InputProvider
    def update_with_input(input : PaceEditor::Testing::SimulatedInputProvider)
      return unless @visible

      # Handle escape key
      if input.key_pressed?(RL::KeyboardKey::Escape)
        hide
      end

      # Handle scroll
      mouse_wheel = input.get_mouse_wheel_move
      @scroll_offset -= mouse_wheel * 30
      @scroll_offset = Math.max(0.0_f32, @scroll_offset)
    end

    # Draw with input provider for button handling
    def draw_with_input(input : PaceEditor::Testing::SimulatedInputProvider)
      return unless @visible

      # Check button clicks
      if input.mouse_button_pressed?(RL::MouseButton::Left)
        handle_button_clicks(input)
        handle_background_selection(input)
      end
    end

    private def handle_button_clicks(input : PaceEditor::Testing::SimulatedInputProvider)
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      button_width = 100
      button_height = 30
      button_y = dialog_y + dialog_height - 50
      button_spacing = 20

      mouse_pos = input.get_mouse_position

      # OK button
      ok_x = dialog_x + dialog_width - button_width * 2 - button_spacing - 20
      if !@selected_background.nil? &&
         mouse_pos.x >= ok_x && mouse_pos.x <= ok_x + button_width &&
         mouse_pos.y >= button_y && mouse_pos.y <= button_y + button_height
        assign_background
        hide
        return
      end

      # Cancel button
      cancel_x = dialog_x + dialog_width - button_width - 20
      if mouse_pos.x >= cancel_x && mouse_pos.x <= cancel_x + button_width &&
         mouse_pos.y >= button_y && mouse_pos.y <= button_y + button_height
        hide
        return
      end

      # Import button
      import_x = dialog_x + 20
      if mouse_pos.x >= import_x && mouse_pos.x <= import_x + button_width &&
         mouse_pos.y >= button_y && mouse_pos.y <= button_y + button_height
        @state.show_new_project_dialog = true
        hide
        return
      end
    end

    private def handle_background_selection(input : PaceEditor::Testing::SimulatedInputProvider)
      mouse_pos = input.get_mouse_position

      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      list_y = dialog_y + 60
      list_height = dialog_height - 120

      backgrounds = get_available_backgrounds
      return if backgrounds.empty?

      # Thumbnail settings
      thumb_size = 120
      padding = 10
      list_x = dialog_x + 20
      width = dialog_width - 40
      cols = (width + padding) // (thumb_size + padding)
      cols = [cols, 1].max

      row_height = thumb_size + padding + 30

      backgrounds.each_with_index do |bg_name, index|
        col = index % cols
        row = index // cols

        item_x = list_x + col * (thumb_size + padding)
        item_y = list_y + row * row_height - @scroll_offset.to_i

        # Skip if outside visible area
        next if item_y + row_height < list_y || item_y > list_y + list_height - 20

        if mouse_pos.x >= item_x && mouse_pos.x <= item_x + thumb_size &&
           mouse_pos.y >= item_y && mouse_pos.y <= item_y + thumb_size + 20
          @selected_background = bg_name
          return
        end
      end
    end

    # Testing getters
    def test_selected_background : String?
      @selected_background
    end

    def test_scroll_offset : Float32
      @scroll_offset
    end

    # Testing setters
    def test_set_selected_background(bg : String?)
      @selected_background = bg
    end

    def test_set_scroll_offset(offset : Float32)
      @scroll_offset = offset
    end

    # Calculate button positions for testing
    def test_ok_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      button_width = 100
      button_height = 30
      button_y = dialog_y + dialog_height - 50
      button_spacing = 20
      ok_x = dialog_x + dialog_width - button_width * 2 - button_spacing - 20

      {x: ok_x, y: button_y, width: button_width, height: button_height}
    end

    def test_cancel_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      button_width = 100
      button_height = 30
      button_y = dialog_y + dialog_height - 50
      cancel_x = dialog_x + dialog_width - button_width - 20

      {x: cancel_x, y: button_y, width: button_width, height: button_height}
    end

    def test_import_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      button_width = 100
      button_height = 30
      button_y = dialog_y + dialog_height - 50
      import_x = dialog_x + 20

      {x: import_x, y: button_y, width: button_width, height: button_height}
    end

    def test_list_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      list_y = dialog_y + 60
      list_height = dialog_height - 120

      {x: dialog_x + 20, y: list_y, width: dialog_width - 40, height: list_height}
    end

    # Expose get_available_backgrounds for testing
    def test_get_available_backgrounds : Array(String)
      get_available_backgrounds
    end

    # Calculate background item bounds
    def test_background_item_bounds(index : Int32) : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)?
      backgrounds = get_available_backgrounds
      return nil if index < 0 || index >= backgrounds.size

      list_bounds = test_list_bounds
      thumb_size = 120
      padding = 10
      cols = (list_bounds[:width] + padding) // (thumb_size + padding)
      cols = [cols, 1].max
      row_height = thumb_size + padding + 30

      col = index % cols
      row = index // cols

      item_x = list_bounds[:x] + col * (thumb_size + padding)
      item_y = list_bounds[:y] + row * row_height - @scroll_offset.to_i

      {x: item_x, y: item_y, width: thumb_size, height: thumb_size + 20}
    end
  end
end
