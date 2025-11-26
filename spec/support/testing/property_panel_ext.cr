# Testing extensions for PropertyPanel
# Reopens the class to add e2e testing support methods

module PaceEditor::UI
  class PropertyPanel
    # Update with a specific input provider (for testing)
    def update_with_input(input : Testing::InputProvider)
      # Handle text input for active field
      if field = @active_field
        handle_text_input_with_input(input)
      end

      # Update cursor blink
      @cursor_blink_timer += 0.016f32
      if @cursor_blink_timer > 1.0f32
        @cursor_blink_timer = 0.0f32
      end

      # Handle scrolling
      wheel = input.get_mouse_wheel_move
      if wheel != 0
        mouse_pos = input.get_mouse_position
        screen_width = input.get_screen_width
        panel_x = screen_width - Core::EditorWindow::PROPERTY_PANEL_WIDTH
        if mouse_pos.x >= panel_x
          @scroll_y -= wheel * 20
          @scroll_y = @scroll_y.clamp(0.0_f32, Float32::MAX)
        end
      end

      # Handle property field clicks
      handle_property_clicks_with_input(input)
    end

    private def handle_text_input_with_input(input : Testing::InputProvider)
      # Handle character input from typed text queue
      input.get_typed_chars.each do |char|
        if char >= 32 && char <= 126
          @edit_buffer = @edit_buffer.insert(@cursor_position, char.chr.to_s)
          @cursor_position += 1
        end
      end

      # Handle special keys
      if input.key_pressed?(RL::KeyboardKey::Backspace) && @cursor_position > 0
        @edit_buffer = @edit_buffer.delete_at(@cursor_position - 1)
        @cursor_position -= 1
      end

      if input.key_pressed?(RL::KeyboardKey::Delete) && @cursor_position < @edit_buffer.size
        @edit_buffer = @edit_buffer.delete_at(@cursor_position)
      end

      if input.key_pressed?(RL::KeyboardKey::Left) && @cursor_position > 0
        @cursor_position -= 1
      end

      if input.key_pressed?(RL::KeyboardKey::Right) && @cursor_position < @edit_buffer.size
        @cursor_position += 1
      end

      if input.key_pressed?(RL::KeyboardKey::Home)
        @cursor_position = 0
      end

      if input.key_pressed?(RL::KeyboardKey::End)
        @cursor_position = @edit_buffer.size
      end

      # Apply changes on Enter
      if input.key_pressed?(RL::KeyboardKey::Enter)
        if active = @active_field
          apply_property_change(active, @edit_buffer)
        end
        @active_field = nil
      end

      # Cancel on Escape
      if input.key_pressed?(RL::KeyboardKey::Escape)
        @active_field = nil
      end
    end

    private def handle_property_clicks_with_input(input : Testing::InputProvider)
      return unless scene = @state.current_scene
      return unless obj_name = @state.selected_object

      mouse_pos = input.get_mouse_position
      screen_width = input.get_screen_width

      panel_x = screen_width - Core::EditorWindow::PROPERTY_PANEL_WIDTH
      label_width = 80
      field_width = Core::EditorWindow::PROPERTY_PANEL_WIDTH - label_width - 30

      # Calculate field positions based on property panel layout
      y_start = Core::EditorWindow::MENU_HEIGHT + 45

      if hotspot = scene.hotspots.find { |h| h.name == obj_name }
        # Hotspot properties - check editable field clicks
        y = y_start + 25 # After "Hotspot: name" header and section header

        check_field_click_with_input("hotspot_x", hotspot.position.x.to_s, panel_x + 10 + label_width, y + 25, field_width, input)
        check_field_click_with_input("hotspot_y", hotspot.position.y.to_s, panel_x + 10 + label_width, y + 50, field_width, input)
        check_field_click_with_input("hotspot_width", hotspot.size.x.to_s, panel_x + 10 + label_width, y + 75, field_width, input)
        check_field_click_with_input("hotspot_height", hotspot.size.y.to_s, panel_x + 10 + label_width, y + 100, field_width, input)

        # Description field
        check_field_click_with_input("hotspot_desc", hotspot.description, panel_x + 10 + label_width, y + 140, field_width, input)

      elsif character = scene.characters.find { |c| c.name == obj_name }
        # Character properties
        y = y_start + 25

        check_field_click_with_input("char_x", character.position.x.to_s, panel_x + 10 + label_width, y + 25, field_width, input)
        check_field_click_with_input("char_y", character.position.y.to_s, panel_x + 10 + label_width, y + 50, field_width, input)
        check_field_click_with_input("char_width", character.size.x.to_s, panel_x + 10 + label_width, y + 75, field_width, input)
        check_field_click_with_input("char_height", character.size.y.to_s, panel_x + 10 + label_width, y + 100, field_width, input)

        # Description and speed
        check_field_click_with_input("char_desc", character.description, panel_x + 10 + label_width, y + 140, field_width, input)
        check_field_click_with_input("char_speed", character.walking_speed.to_s, panel_x + 10 + label_width, y + 165, field_width, input)
      end
    end

    private def check_field_click_with_input(field_id : String, current_value : String, x : Int32, y : Int32, width : Int32, input : Testing::InputProvider)
      mouse_pos = input.get_mouse_position
      height = 18

      if input.mouse_button_pressed?(RL::MouseButton::Left)
        if mouse_pos.x >= x && mouse_pos.x <= x + width &&
           mouse_pos.y >= y - 2 && mouse_pos.y <= y - 2 + height
          @active_field = field_id
          @edit_buffer = current_value
          @cursor_position = current_value.size
        elsif @active_field == field_id
          # Clicking outside - apply changes
          apply_property_change(field_id, @edit_buffer)
          @active_field = nil
        end
      end
    end

    # Testing helper: set active field directly
    def set_active_field_for_test(field_id : String, initial_value : String)
      @active_field = field_id
      @edit_buffer = initial_value
      @cursor_position = initial_value.size
    end

    # Testing helper: get active field
    def active_field_for_test : String?
      @active_field
    end

    # Testing helper: get edit buffer
    def edit_buffer_for_test : String
      @edit_buffer
    end

    # Testing helper: apply current edit
    def apply_edit_for_test
      if active = @active_field
        apply_property_change(active, @edit_buffer)
        @active_field = nil
      end
    end
  end
end
