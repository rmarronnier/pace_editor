# Test extensions for BackgroundImportDialog
module PaceEditor::UI
  class BackgroundImportDialog
    # Test-friendly update method that accepts an InputProvider
    def update_with_input(input : PaceEditor::Testing::SimulatedInputProvider)
      return unless @visible

      handle_input_with_provider(input)
      handle_file_selection
    end

    # Test helper to handle input with provider
    private def handle_input_with_provider(input : PaceEditor::Testing::SimulatedInputProvider)
      mouse_pos = input.get_mouse_position

      # Get screen dimensions
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height

      # Calculate file list area
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      list_x = dialog_x + 20
      list_y = dialog_y + 80
      list_width = dialog_width - 40
      list_height = 200

      if input.mouse_button_pressed?(RL::MouseButton::Left)
        if mouse_pos.x >= list_x && mouse_pos.x <= list_x + list_width &&
           mouse_pos.y >= list_y && mouse_pos.y <= list_y + list_height
          # Calculate clicked item
          item_height = 20
          clicked_index = @scroll_offset + ((mouse_pos.y - list_y) / item_height).to_i

          if clicked_index >= 0 && clicked_index < @file_list.size
            @selected_index = clicked_index
            handle_item_selection
          end
        end

        # Check button clicks
        button_y = dialog_y + dialog_height - 60
        check_button_clicks_with_input(input, dialog_x, button_y, dialog_width)
      end

      # Handle escape key
      if input.key_pressed?(RL::KeyboardKey::Escape)
        hide
      end
    end

    private def check_button_clicks_with_input(input : PaceEditor::Testing::SimulatedInputProvider, x : Int32, y : Int32, width : Int32)
      button_width = 100
      button_height = 30
      mouse_pos = input.get_mouse_position

      # Cancel button
      cancel_x = x + width - 220
      if mouse_pos.x >= cancel_x && mouse_pos.x <= cancel_x + button_width &&
         mouse_pos.y >= y && mouse_pos.y <= y + button_height
        hide
        return
      end

      # Import button
      import_x = x + width - 110
      if !@selected_file.nil? &&
         mouse_pos.x >= import_x && mouse_pos.x <= import_x + button_width &&
         mouse_pos.y >= y && mouse_pos.y <= y + button_height
        import_selected_file
        return
      end
    end

    # Testing getters
    def test_file_list : Array(String)
      @file_list
    end

    def test_current_directory : String
      @current_directory
    end

    def test_scroll_offset : Int32
      @scroll_offset
    end

    def test_selected_index : Int32
      @selected_index
    end

    def test_preview_texture : RL::Texture2D?
      @preview_texture
    end

    # Testing setters
    def test_set_current_directory(dir : String)
      @current_directory = dir
      refresh_file_list
    end

    def test_set_scroll_offset(offset : Int32)
      @scroll_offset = offset
    end

    def test_set_selected_index(index : Int32)
      @selected_index = index
    end

    def test_set_selected_file(file : String?)
      @selected_file = file
    end

    # Calculate button positions for testing
    def test_cancel_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      button_y = dialog_y + dialog_height - 60
      cancel_x = dialog_x + dialog_width - 220

      {x: cancel_x, y: button_y, width: 100, height: 30}
    end

    def test_import_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      button_y = dialog_y + dialog_height - 60
      import_x = dialog_x + dialog_width - 110

      {x: import_x, y: button_y, width: 100, height: 30}
    end

    def test_file_list_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      list_x = dialog_x + 20
      list_y = dialog_y + 80

      {x: list_x, y: list_y, width: dialog_width - 40, height: 200}
    end

    # Calculate item Y position in file list
    def test_file_item_y(index : Int32) : Int32
      bounds = test_file_list_bounds
      item_height = 20
      bounds[:y] + (index - @scroll_offset) * item_height
    end

    # Expose refresh method for testing
    def test_refresh_file_list
      refresh_file_list
    end
  end
end
