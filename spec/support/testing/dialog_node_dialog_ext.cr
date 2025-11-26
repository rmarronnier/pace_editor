# Testing extensions for DialogNodeDialog
# Reopens the class to add e2e testing support methods

module PaceEditor::UI
  class DialogNodeDialog
    # Update with a specific input provider (for testing)
    def update_with_input(input : Testing::InputProvider)
      return unless @visible

      mouse_pos = input.get_mouse_position
      mouse_clicked = input.mouse_button_pressed?(RL::MouseButton::Left)

      screen_width = input.get_screen_width
      screen_height = input.get_screen_height

      dialog_width = 500
      dialog_height = 400
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      # Handle field clicks
      handle_field_clicks_with_test(dialog_x, dialog_y, dialog_width, input)

      # Handle text input for active field
      if @active_field
        handle_text_input_with_test(input)
      end

      # Handle checkbox click
      handle_checkbox_with_test(dialog_x, dialog_y, input)

      # Handle buttons
      handle_buttons_with_test(dialog_x, dialog_y, dialog_width, dialog_height, input)

      # Handle Escape to close
      if input.key_pressed?(RL::KeyboardKey::Escape)
        hide
      end
    end

    private def handle_field_clicks_with_test(dialog_x : Int32, dialog_y : Int32, dialog_width : Int32, input : Testing::InputProvider)
      mouse_pos = input.get_mouse_position
      field_width = dialog_width - 40

      # ID field (y = dialog_y + 60)
      id_field_y = dialog_y + 60
      if input.mouse_button_pressed?(RL::MouseButton::Left) &&
         mouse_pos.x >= dialog_x + 20 && mouse_pos.x <= dialog_x + 20 + field_width &&
         mouse_pos.y >= id_field_y && mouse_pos.y <= id_field_y + 30
        unless @editing_node  # ID field disabled when editing
          @active_field = "id"
          @cursor_position = @id_field.size
        end
      end

      # Character field (y = dialog_y + 120)
      char_field_y = dialog_y + 120
      if input.mouse_button_pressed?(RL::MouseButton::Left) &&
         mouse_pos.x >= dialog_x + 20 && mouse_pos.x <= dialog_x + 20 + field_width &&
         mouse_pos.y >= char_field_y && mouse_pos.y <= char_field_y + 30
        @active_field = "character"
        @cursor_position = @character_field.size
      end

      # Text field (y = dialog_y + 180, larger multiline area)
      text_field_y = dialog_y + 180
      text_field_height = 120
      if input.mouse_button_pressed?(RL::MouseButton::Left) &&
         mouse_pos.x >= dialog_x + 20 && mouse_pos.x <= dialog_x + 20 + field_width &&
         mouse_pos.y >= text_field_y && mouse_pos.y <= text_field_y + text_field_height
        @active_field = "text"
        @cursor_position = @text_field.size
      end

      # Click outside fields deactivates
      if input.mouse_button_pressed?(RL::MouseButton::Left)
        in_any_field = false
        [{id_field_y, 30}, {char_field_y, 30}, {text_field_y, text_field_height}].each do |(y, h)|
          if mouse_pos.x >= dialog_x + 20 && mouse_pos.x <= dialog_x + 20 + field_width &&
             mouse_pos.y >= y && mouse_pos.y <= y + h
            in_any_field = true
            break
          end
        end
        unless in_any_field
          @active_field = nil
        end
      end
    end

    private def handle_checkbox_with_test(dialog_x : Int32, dialog_y : Int32, input : Testing::InputProvider)
      mouse_pos = input.get_mouse_position

      # "Is End Node" checkbox (y = dialog_y + 320)
      checkbox_x = dialog_x + 20
      checkbox_y = dialog_y + 320
      checkbox_size = 20

      if input.mouse_button_pressed?(RL::MouseButton::Left) &&
         mouse_pos.x >= checkbox_x && mouse_pos.x <= checkbox_x + checkbox_size &&
         mouse_pos.y >= checkbox_y && mouse_pos.y <= checkbox_y + checkbox_size
        @is_end = !@is_end
      end
    end

    private def handle_buttons_with_test(dialog_x : Int32, dialog_y : Int32, dialog_width : Int32, dialog_height : Int32, input : Testing::InputProvider)
      mouse_pos = input.get_mouse_position
      button_y = dialog_y + dialog_height - 50
      button_width = 80
      button_height = 30

      # OK button
      ok_x = dialog_x + dialog_width - button_width - 100
      if input.mouse_button_pressed?(RL::MouseButton::Left) &&
         mouse_pos.x >= ok_x && mouse_pos.x <= ok_x + button_width &&
         mouse_pos.y >= button_y && mouse_pos.y <= button_y + button_height
        if create_or_update_node
          hide
        end
      end

      # Cancel button
      cancel_x = dialog_x + dialog_width - button_width - 10
      if input.mouse_button_pressed?(RL::MouseButton::Left) &&
         mouse_pos.x >= cancel_x && mouse_pos.x <= cancel_x + button_width &&
         mouse_pos.y >= button_y && mouse_pos.y <= button_y + button_height
        hide
      end
    end

    private def handle_text_input_with_test(input : Testing::InputProvider)
      return unless field = @active_field

      # Get the current field text
      current_text = case field
                     when "id"        then @id_field
                     when "character" then @character_field
                     when "text"      then @text_field
                     else                  ""
                     end

      # Handle character input
      chars = input.get_typed_chars
      chars.each do |key|
        if key >= 32 && key <= 126
          current_text = current_text.insert(@cursor_position, key.chr.to_s)
          @cursor_position += 1
        end
      end

      # Handle special keys
      if input.key_pressed?(RL::KeyboardKey::Backspace) && @cursor_position > 0
        current_text = current_text.delete_at(@cursor_position - 1)
        @cursor_position -= 1
      end

      if input.key_pressed?(RL::KeyboardKey::Delete) && @cursor_position < current_text.size
        current_text = current_text.delete_at(@cursor_position)
      end

      if input.key_pressed?(RL::KeyboardKey::Left) && @cursor_position > 0
        @cursor_position -= 1
      end

      if input.key_pressed?(RL::KeyboardKey::Right) && @cursor_position < current_text.size
        @cursor_position += 1
      end

      if input.key_pressed?(RL::KeyboardKey::Home)
        @cursor_position = 0
      end

      if input.key_pressed?(RL::KeyboardKey::End)
        @cursor_position = current_text.size
      end

      # Tab to next field
      if input.key_pressed?(RL::KeyboardKey::Tab)
        @active_field = case field
                        when "id"        then "character"
                        when "character" then "text"
                        when "text"      then "id"
                        else                  nil
                        end
        @cursor_position = 0
      end

      # Enter deactivates field (except for text which is multiline)
      if input.key_pressed?(RL::KeyboardKey::Enter) && field != "text"
        @active_field = nil
      end

      # Update the field
      case field
      when "id"        then @id_field = current_text
      when "character" then @character_field = current_text
      when "text"      then @text_field = current_text
      end
    end

    # Testing helpers
    def id_field_for_test : String
      @id_field
    end

    def set_id_field_for_test(value : String)
      @id_field = value
    end

    def character_field_for_test : String
      @character_field
    end

    def set_character_field_for_test(value : String)
      @character_field = value
    end

    def text_field_for_test : String
      @text_field
    end

    def set_text_field_for_test(value : String)
      @text_field = value
    end

    def is_end_for_test : Bool
      @is_end
    end

    def set_is_end_for_test(value : Bool)
      @is_end = value
    end

    def active_field_for_test : String?
      @active_field
    end

    def set_active_field_for_test(field : String?)
      @active_field = field
      if field
        @cursor_position = case field
                           when "id"        then @id_field.size
                           when "character" then @character_field.size
                           when "text"      then @text_field.size
                           else                  0
                           end
      end
    end

    def editing_node_for_test? : Bool
      @editing_node != nil
    end

    def show_for_new_node_for_test
      show(nil)
    end

    def validation_error_for_test : String?
      @validation_error
    end

    # Get field positions for clicking
    def get_id_field_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_x = (screen_width - 500) // 2
      dialog_y = (screen_height - 400) // 2
      {dialog_x + 250, dialog_y + 75}
    end

    def get_character_field_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_x = (screen_width - 500) // 2
      dialog_y = (screen_height - 400) // 2
      {dialog_x + 250, dialog_y + 135}
    end

    def get_text_field_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_x = (screen_width - 500) // 2
      dialog_y = (screen_height - 400) // 2
      {dialog_x + 250, dialog_y + 240}
    end

    def get_is_end_checkbox_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_x = (screen_width - 500) // 2
      dialog_y = (screen_height - 400) // 2
      {dialog_x + 30, dialog_y + 330}
    end

    def get_ok_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_width = 500
      dialog_height = 400
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      {dialog_x + dialog_width - 140, dialog_y + dialog_height - 35}
    end

    def get_cancel_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_width = 500
      dialog_height = 400
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      {dialog_x + dialog_width - 50, dialog_y + dialog_height - 35}
    end
  end
end
