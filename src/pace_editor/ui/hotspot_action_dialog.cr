require "../models/hotspot_action"

module PaceEditor::UI
  # Dialog for editing hotspot actions
  class HotspotActionDialog
    @visible : Bool
    @hotspot_name : String?
    @hotspot_data : Models::HotspotData?
    @selected_event : String
    @selected_action_index : Int32?
    @new_action_type : Models::HotspotAction::ActionType?
    @edit_parameters : Hash(String, String)
    @active_field : String?
    @edit_buffer : String
    @cursor_position : Int32
    @cursor_blink_timer : Float32

    def initialize(@state : Core::EditorState)
      @visible = false
      @hotspot_name = nil
      @hotspot_data = nil
      @selected_event = "on_click"
      @selected_action_index = nil
      @new_action_type = nil
      @edit_parameters = {} of String => String
      @active_field = nil
      @edit_buffer = ""
      @cursor_position = 0
      @cursor_blink_timer = 0.0f32
    end

    def show(hotspot_name : String)
      @visible = true
      @hotspot_name = hotspot_name

      # Load or create hotspot data
      @hotspot_data = load_hotspot_data(hotspot_name)
    end

    def hide
      @visible = false
    end

    def update
      return unless @visible

      # Handle text input for active field
      if field = @active_field
        handle_text_input
      end

      # Update cursor blink
      @cursor_blink_timer += RL.get_frame_time
      if @cursor_blink_timer > 1.0f32
        @cursor_blink_timer = 0.0f32
      end

      # Close on Escape
      if RL.key_pressed?(RL::KeyboardKey::Escape) && @active_field.nil?
        save_hotspot_data
        hide
      end
    end

    def draw
      return unless @visible
      return unless hotspot_name = @hotspot_name
      return unless hotspot_data = @hotspot_data

      # Get screen dimensions
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height

      # Draw modal background
      RL.draw_rectangle(0, 0, screen_width, screen_height,
        RL::Color.new(r: 0, g: 0, b: 0, a: 180))

      # Dialog dimensions
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      # Draw dialog background
      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height,
        RL::Color.new(r: 50, g: 50, b: 50, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      # Dialog title
      title = "Edit Actions: #{hotspot_name}"
      title_width = RL.measure_text(title, 20)
      RL.draw_text(title, dialog_x + (dialog_width - title_width) // 2, dialog_y + 10, 20, RL::WHITE)

      # Event tabs
      draw_event_tabs(dialog_x + 10, dialog_y + 40, dialog_width - 20)

      # Action list
      y = dialog_y + 80
      draw_action_list(dialog_x + 10, y, dialog_width - 20, 200)

      # Add/Edit action section
      y = dialog_y + 290
      if @new_action_type
        draw_action_editor(dialog_x + 10, y, dialog_width - 20)
      else
        draw_add_action_button(dialog_x + 10, y)
      end

      # Close button
      draw_close_button(dialog_x + dialog_width - 100, dialog_y + dialog_height - 40)
    end

    private def draw_event_tabs(x : Int32, y : Int32, width : Int32)
      events = ["on_click", "on_look", "on_use", "on_talk"]
      tab_width = width // events.size

      events.each_with_index do |event, index|
        tab_x = x + index * tab_width
        is_active = @selected_event == event

        # Tab background
        bg_color = is_active ? RL::Color.new(r: 70, g: 70, b: 70, a: 255) : RL::Color.new(r: 40, g: 40, b: 40, a: 255)
        RL.draw_rectangle(tab_x, y, tab_width, 30, bg_color)
        RL.draw_rectangle_lines(tab_x, y, tab_width, 30, RL::GRAY)

        # Tab text
        text = event.gsub("_", " ").capitalize
        text_width = RL.measure_text(text, 14)
        text_color = is_active ? RL::WHITE : RL::LIGHTGRAY
        RL.draw_text(text, tab_x + (tab_width - text_width) // 2, y + 8, 14, text_color)

        # Check for click
        mouse_pos = RL.get_mouse_position
        if RL.mouse_button_pressed?(RL::MouseButton::Left) &&
           mouse_pos.x >= tab_x && mouse_pos.x <= tab_x + tab_width &&
           mouse_pos.y >= y && mouse_pos.y <= y + 30
          @selected_event = event
          @selected_action_index = nil.as(Int32?)
        end
      end
    end

    private def draw_action_list(x : Int32, y : Int32, width : Int32, height : Int32)
      return unless hotspot_data = @hotspot_data

      # Background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 30, g: 30, b: 30, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Draw actions
      actions = hotspot_data.get_actions(@selected_event)

      if actions.empty?
        text = "No actions defined"
        text_width = RL.measure_text(text, 14)
        RL.draw_text(text, x + (width - text_width) // 2, y + height // 2 - 7, 14, RL::GRAY)
      else
        current_y = y + 5
        actions.each_with_index do |action, index|
          is_selected = @selected_action_index == index

          # Selection background
          if is_selected
            RL.draw_rectangle(x + 5, current_y, width - 10, 25,
              RL::Color.new(r: 70, g: 70, b: 70, a: 255))
          end

          # Action description
          RL.draw_text(action.description, x + 10, current_y + 5, 14, RL::WHITE)

          # Delete button
          delete_x = x + width - 60
          if draw_small_button("Delete", delete_x, current_y + 2, 50, 20)
            hotspot_data.remove_action(@selected_event, index)
            @selected_action_index = nil.as(Int32?)
            save_hotspot_data
          end

          # Check for selection
          mouse_pos = RL.get_mouse_position
          if RL.mouse_button_pressed?(RL::MouseButton::Left) &&
             mouse_pos.x >= x + 5 && mouse_pos.x <= delete_x - 5 &&
             mouse_pos.y >= current_y && mouse_pos.y <= current_y + 25
            @selected_action_index = index
          end

          current_y += 30
        end
      end
    end

    private def draw_add_action_button(x : Int32, y : Int32)
      if draw_button("Add Action", x, y, 100, 30)
        @new_action_type = Models::HotspotAction::ActionType::ShowMessage
        @edit_parameters.clear
      end
    end

    private def draw_action_editor(x : Int32, y : Int32, width : Int32)
      return unless action_type = @new_action_type

      # Action type selector
      RL.draw_text("Action Type:", x, y, 14, RL::LIGHTGRAY)

      # Type dropdown (simplified - just show current type and allow cycling)
      type_y = y + 20
      type_text = action_type.to_s.gsub("_", " ")

      if draw_dropdown(type_text, x, type_y, 200, 25)
        # Cycle to next action type
        types = Models::HotspotAction::ActionType.values
        current_index = types.index(action_type) || 0
        next_index = (current_index + 1) % types.size
        @new_action_type = types[next_index]
        @edit_parameters.clear
      end

      # Parameter fields
      param_y = type_y + 35
      parameters = Models::HotspotAction.parameters_for(action_type)

      parameters.each do |param|
        RL.draw_text("#{param.capitalize}:", x, param_y, 14, RL::LIGHTGRAY)
        value = @edit_parameters[param]? || ""

        field_y = param_y + 18
        new_value = draw_text_field("param_#{param}", value, x, field_y, 300, 25)
        if new_value != value
          @edit_parameters[param] = new_value
        end

        param_y = field_y + 35
      end

      # Save/Cancel buttons
      button_y = y + 150
      if draw_button("Save", x, button_y, 80, 30)
        if hotspot_data = @hotspot_data
          action = Models::HotspotAction.new(action_type)
          action.parameters = @edit_parameters.dup
          hotspot_data.add_action(@selected_event, action)
          save_hotspot_data
          @new_action_type = nil.as(Models::HotspotAction::ActionType?)
          @edit_parameters.clear
        end
      end

      if draw_button("Cancel", x + 90, button_y, 80, 30)
        @new_action_type = nil.as(Models::HotspotAction::ActionType?)
        @edit_parameters.clear
      end
    end

    private def draw_close_button(x : Int32, y : Int32)
      if draw_button("Close", x, y, 80, 30)
        save_hotspot_data
        hide
      end
    end

    private def draw_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32) : Bool
      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      bg_color = is_hover ? RL::Color.new(r: 80, g: 80, b: 80, a: 255) : RL::Color.new(r: 60, g: 60, b: 60, a: 255)

      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, RL::WHITE)

      text_width = RL.measure_text(text, 14)
      text_x = x + (width - text_width) // 2
      text_y = y + (height - 14) // 2
      RL.draw_text(text, text_x, text_y, 14, RL::WHITE)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def draw_small_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32) : Bool
      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      bg_color = is_hover ? RL::Color.new(r: 120, g: 60, b: 60, a: 255) : RL::Color.new(r: 100, g: 40, b: 40, a: 255)

      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      text_width = RL.measure_text(text, 12)
      text_x = x + (width - text_width) // 2
      text_y = y + (height - 12) // 2
      RL.draw_text(text, text_x, text_y, 12, RL::WHITE)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def draw_dropdown(text : String, x : Int32, y : Int32, width : Int32, height : Int32) : Bool
      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      bg_color = is_hover ? RL::Color.new(r: 50, g: 50, b: 50, a: 255) : RL::Color.new(r: 40, g: 40, b: 40, a: 255)

      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Draw text
      RL.draw_text(text, x + 5, y + (height - 14) // 2, 14, RL::WHITE)

      # Draw dropdown arrow
      RL.draw_text("▼", x + width - 20, y + (height - 14) // 2, 14, RL::GRAY)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def draw_text_field(field_id : String, value : String, x : Int32, y : Int32, width : Int32, height : Int32) : String
      is_active = @active_field == field_id

      # Handle click to activate field
      mouse_pos = RL.get_mouse_position
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        if mouse_pos.x >= x && mouse_pos.x <= x + width &&
           mouse_pos.y >= y && mouse_pos.y <= y + height
          @active_field = field_id
          @edit_buffer = value
          @cursor_position = value.size
        elsif is_active
          # Apply changes when clicking outside
          @active_field = nil.as(String?)
          return @edit_buffer
        end
      end

      # Draw field background
      bg_color = is_active ? RL::Color.new(r: 50, g: 50, b: 50, a: 255) : RL::Color.new(r: 30, g: 30, b: 30, a: 255)
      border_color = is_active ? RL::WHITE : RL::GRAY

      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, border_color)

      # Draw value text
      display_value = is_active ? @edit_buffer : value
      RL.draw_text(display_value, x + 5, y + (height - 14) // 2, 14, RL::WHITE)

      # Draw cursor if active
      if is_active && @cursor_blink_timer < 0.5f32
        cursor_x = x + 5 + RL.measure_text(display_value[0...@cursor_position], 14)
        cursor_y = y + (height - 14) // 2
        RL.draw_line(cursor_x, cursor_y, cursor_x, cursor_y + 14, RL::WHITE)
      end

      # Return the edited value if Enter pressed
      if is_active && RL.key_pressed?(RL::KeyboardKey::Enter)
        @active_field = nil.as(String?)
        return @edit_buffer
      end

      value
    end

    private def handle_text_input
      # Handle character input
      key = RL.get_char_pressed
      while key > 0
        if key >= 32 && key <= 126
          @edit_buffer = @edit_buffer.insert(@cursor_position, key.chr.to_s)
          @cursor_position += 1
        end
        key = RL.get_char_pressed
      end

      # Handle special keys
      if RL.key_pressed?(RL::KeyboardKey::Backspace) && @cursor_position > 0
        @edit_buffer = @edit_buffer.delete_at(@cursor_position - 1)
        @cursor_position -= 1
      end

      if RL.key_pressed?(RL::KeyboardKey::Delete) && @cursor_position < @edit_buffer.size
        @edit_buffer = @edit_buffer.delete_at(@cursor_position)
      end

      if RL.key_pressed?(RL::KeyboardKey::Left) && @cursor_position > 0
        @cursor_position -= 1
      end

      if RL.key_pressed?(RL::KeyboardKey::Right) && @cursor_position < @edit_buffer.size
        @cursor_position += 1
      end

      if RL.key_pressed?(RL::KeyboardKey::Home)
        @cursor_position = 0
      end

      if RL.key_pressed?(RL::KeyboardKey::End)
        @cursor_position = @edit_buffer.size
      end
    end

    private def load_hotspot_data(hotspot_name : String) : Models::HotspotData
      # For now, create a new data object
      # In a real implementation, this would load from a file
      Models::HotspotData.new
    end

    private def save_hotspot_data
      # In a real implementation, this would save the action data to a file
      # For now, just mark the project as dirty
      @state.is_dirty = true
    end

    def visible? : Bool
      @visible
    end
  end
end
