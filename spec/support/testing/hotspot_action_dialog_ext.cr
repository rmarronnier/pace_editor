# Testing extensions for HotspotActionDialog
# Reopens the class to add e2e testing support methods

module PaceEditor::UI
  class HotspotActionDialog
    # Expose internal state for testing
    getter selected_event : String
    getter selected_action_index : Int32?
    getter new_action_type : Models::HotspotAction::ActionType?
    getter edit_parameters : Hash(String, String)
    getter active_field : String?
    getter edit_buffer : String

    # Update with a specific input provider (for testing)
    def update_with_input(input : Testing::InputProvider)
      return unless @visible

      # Handle text input for active field
      if field = @active_field
        handle_text_input_with_input(input)
      end

      # Update cursor blink
      @cursor_blink_timer += input.get_frame_time
      if @cursor_blink_timer > 1.0f32
        @cursor_blink_timer = 0.0f32
      end

      # Process clicks on UI elements
      handle_dialog_input(input)

      # Close on Escape
      if input.key_pressed?(RL::KeyboardKey::Escape) && @active_field.nil?
        save_hotspot_data
        hide
      end
    end

    private def handle_dialog_input(input : Testing::InputProvider)
      return unless hotspot_data = @hotspot_data

      screen_width = input.get_screen_width
      screen_height = input.get_screen_height

      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      mouse_pos = input.get_mouse_position
      mouse_clicked = input.mouse_button_pressed?(RL::MouseButton::Left)

      # Handle event tab clicks
      handle_event_tabs_input(dialog_x + 10, dialog_y + 40, dialog_width - 20, input)

      # Handle action list clicks
      handle_action_list_input(dialog_x + 10, dialog_y + 80, dialog_width - 20, 200, input)

      # Handle add action section
      y = dialog_y + 290
      if @new_action_type
        handle_action_editor_input(dialog_x + 10, y, dialog_width - 20, input)
      else
        if add_action_button_clicked?(dialog_x + 10, y, input)
          @new_action_type = Models::HotspotAction::ActionType::ShowMessage
          @edit_parameters.clear
        end
      end

      # Handle close button
      if close_button_clicked?(dialog_x + dialog_width - 100, dialog_y + dialog_height - 40, input)
        save_hotspot_data
        hide
      end
    end

    private def handle_event_tabs_input(x : Int32, y : Int32, width : Int32, input : Testing::InputProvider)
      events = ["on_click", "on_look", "on_use", "on_talk"]
      tab_width = width // events.size

      mouse_pos = input.get_mouse_position

      events.each_with_index do |event, index|
        tab_x = x + index * tab_width

        if input.mouse_button_pressed?(RL::MouseButton::Left) &&
           mouse_pos.x >= tab_x && mouse_pos.x <= tab_x + tab_width &&
           mouse_pos.y >= y && mouse_pos.y <= y + 30
          @selected_event = event
          @selected_action_index = nil.as(Int32?)
        end
      end
    end

    private def handle_action_list_input(x : Int32, y : Int32, width : Int32, height : Int32, input : Testing::InputProvider)
      return unless hotspot_data = @hotspot_data

      mouse_pos = input.get_mouse_position
      actions = hotspot_data.get_actions(@selected_event)
      return if actions.empty?

      current_y = y + 5
      actions.each_with_index do |action, index|
        delete_x = x + width - 60

        # Check for delete button click
        if button_clicked_at?(delete_x, current_y + 2, 50, 20, input)
          hotspot_data.remove_action(@selected_event, index)
          @selected_action_index = nil.as(Int32?)
          save_hotspot_data
          return
        end

        # Check for action selection click
        if input.mouse_button_pressed?(RL::MouseButton::Left) &&
           mouse_pos.x >= x + 5 && mouse_pos.x <= delete_x - 5 &&
           mouse_pos.y >= current_y && mouse_pos.y <= current_y + 25
          @selected_action_index = index
        end

        current_y += 30
      end
    end

    private def handle_action_editor_input(x : Int32, y : Int32, width : Int32, input : Testing::InputProvider)
      return unless action_type = @new_action_type

      # Handle type dropdown click (cycles through types)
      type_y = y + 20
      if dropdown_clicked_at?(x, type_y, 200, 25, input)
        types = Models::HotspotAction::ActionType.values
        current_index = types.index(action_type) || 0
        next_index = (current_index + 1) % types.size
        @new_action_type = types[next_index]
        @edit_parameters.clear
      end

      # Handle parameter field clicks
      param_y = type_y + 35
      parameters = Models::HotspotAction.parameters_for(action_type)

      parameters.each do |param|
        field_y = param_y + 18
        field_id = "param_#{param}"

        handle_text_field_click(field_id, @edit_parameters[param]? || "", x, field_y, 300, 25, input)

        param_y = field_y + 35
      end

      # Handle Save/Cancel buttons
      button_y = y + 150
      if button_clicked_at?(x, button_y, 80, 30, input)
        # Save action
        if hotspot_data = @hotspot_data
          action = Models::HotspotAction.new(action_type)
          action.parameters = @edit_parameters.dup
          hotspot_data.add_action(@selected_event, action)
          save_hotspot_data
          @new_action_type = nil.as(Models::HotspotAction::ActionType?)
          @edit_parameters.clear
        end
      end

      if button_clicked_at?(x + 90, button_y, 80, 30, input)
        # Cancel
        @new_action_type = nil.as(Models::HotspotAction::ActionType?)
        @edit_parameters.clear
      end
    end

    private def handle_text_field_click(field_id : String, value : String, x : Int32, y : Int32, width : Int32, height : Int32, input : Testing::InputProvider)
      mouse_pos = input.get_mouse_position

      if input.mouse_button_pressed?(RL::MouseButton::Left)
        if mouse_pos.x >= x && mouse_pos.x <= x + width &&
           mouse_pos.y >= y && mouse_pos.y <= y + height
          @active_field = field_id
          @edit_buffer = value
          @cursor_position = value.size
        elsif @active_field == field_id
          # Apply changes when clicking outside
          if field_id.starts_with?("param_")
            param_name = field_id[6..]
            @edit_parameters[param_name] = @edit_buffer
          end
          @active_field = nil.as(String?)
        end
      end

      # Handle Enter to apply
      if @active_field == field_id && input.key_pressed?(RL::KeyboardKey::Enter)
        if field_id.starts_with?("param_")
          param_name = field_id[6..]
          @edit_parameters[param_name] = @edit_buffer
        end
        @active_field = nil.as(String?)
      end
    end

    private def handle_text_input_with_input(input : Testing::InputProvider)
      # Handle character input
      chars = input.get_typed_chars
      chars.each do |key|
        if key >= 32 && key <= 126
          @edit_buffer = @edit_buffer.insert(@cursor_position, key.chr.to_s)
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
    end

    private def button_clicked_at?(x : Int32, y : Int32, width : Int32, height : Int32, input : Testing::InputProvider) : Bool
      mouse_pos = input.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height
      is_hover && input.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def dropdown_clicked_at?(x : Int32, y : Int32, width : Int32, height : Int32, input : Testing::InputProvider) : Bool
      button_clicked_at?(x, y, width, height, input)
    end

    private def add_action_button_clicked?(x : Int32, y : Int32, input : Testing::InputProvider) : Bool
      button_clicked_at?(x, y, 100, 30, input)
    end

    private def close_button_clicked?(x : Int32, y : Int32, input : Testing::InputProvider) : Bool
      button_clicked_at?(x, y, 80, 30, input)
    end

    # Testing helper: get event tab position
    def get_event_tab_position(event : String, screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      events = ["on_click", "on_look", "on_use", "on_talk"]
      index = events.index(event) || 0

      dialog_width = 600
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - 500) // 2

      tab_width = (dialog_width - 20) // events.size
      {dialog_x + 10 + index * tab_width + tab_width // 2, dialog_y + 40 + 15}
    end

    # Testing helper: get add action button position
    def get_add_action_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_x = (screen_width - 600) // 2
      dialog_y = (screen_height - 500) // 2
      {dialog_x + 10 + 50, dialog_y + 290 + 15}
    end

    # Testing helper: get close button position
    def get_close_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      {dialog_x + dialog_width - 100 + 40, dialog_y + dialog_height - 40 + 15}
    end

    # Testing helper: get save action button position
    def get_save_action_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_x = (screen_width - 600) // 2
      dialog_y = (screen_height - 500) // 2
      {dialog_x + 10 + 40, dialog_y + 290 + 150 + 15}
    end

    # Testing helper: get cancel action button position
    def get_cancel_action_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_x = (screen_width - 600) // 2
      dialog_y = (screen_height - 500) // 2
      {dialog_x + 10 + 90 + 40, dialog_y + 290 + 150 + 15}
    end

    # Testing helper: set active field for text input
    def set_active_field_for_test(field_id : String, initial_value : String = "")
      @active_field = field_id
      @edit_buffer = initial_value
      @cursor_position = initial_value.size
    end

    # Testing helper: apply current edit
    def apply_edit_for_test
      if field = @active_field
        if field.starts_with?("param_")
          param_name = field[6..]
          @edit_parameters[param_name] = @edit_buffer
        end
        @active_field = nil.as(String?)
      end
    end

    # Testing helper: show dialog programmatically
    def show_for_test(hotspot_name : String)
      show(hotspot_name)
    end

    # Testing helper: check if dialog is visible
    def visible_for_test? : Bool
      @visible
    end

    # Testing helper: set action type
    def set_action_type_for_test(action_type : Models::HotspotAction::ActionType)
      @new_action_type = action_type
      @edit_parameters.clear
    end
  end
end
