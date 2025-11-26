# Testing extensions for ScriptEditor
# Reopens the class to add e2e testing support methods

module PaceEditor::UI
  class ScriptEditor
    # Update with a specific input provider (for testing)
    def update_with_input(input : Testing::InputProvider)
      return unless @visible

      # Handle keyboard input
      if input.key_pressed?(RL::KeyboardKey::Escape)
        hide
      elsif input.key_pressed?(RL::KeyboardKey::S) && (input.key_down?(RL::KeyboardKey::LeftControl) || input.key_down?(RL::KeyboardKey::RightControl))
        save_script
      elsif input.key_pressed?(RL::KeyboardKey::F5)
        validate_syntax
      end

      # Handle text editing with test input
      handle_text_input_with_test(input)
      handle_cursor_movement_with_test(input)
      handle_scrolling_with_test(input)
    end

    private def handle_text_input_with_test(input : Testing::InputProvider)
      # Handle character input
      input.get_typed_chars.each do |char|
        if char >= 32 && char < 127
          insert_character(char.chr)
        end
      end

      # Handle special keys
      if input.key_pressed?(RL::KeyboardKey::Enter)
        insert_newline
      elsif input.key_pressed?(RL::KeyboardKey::Backspace)
        delete_character
      elsif input.key_pressed?(RL::KeyboardKey::Tab)
        insert_tab
      end
    end

    private def handle_cursor_movement_with_test(input : Testing::InputProvider)
      if input.key_pressed?(RL::KeyboardKey::Up)
        move_cursor_up
      elsif input.key_pressed?(RL::KeyboardKey::Down)
        move_cursor_down
      elsif input.key_pressed?(RL::KeyboardKey::Left)
        move_cursor_left
      elsif input.key_pressed?(RL::KeyboardKey::Right)
        move_cursor_right
      elsif input.key_pressed?(RL::KeyboardKey::Home)
        @cursor_column = 0
      elsif input.key_pressed?(RL::KeyboardKey::End)
        @cursor_column = @lines[@cursor_line].size
      end
    end

    private def handle_scrolling_with_test(input : Testing::InputProvider)
      wheel = input.get_mouse_wheel_move
      if wheel != 0
        @scroll_offset = [@scroll_offset - wheel.to_i, 0].max
        max_scroll = [@lines.size - 10, 0].max
        @scroll_offset = [@scroll_offset, max_scroll].min
      end
    end

    # Testing getters
    def script_path_for_test : String?
      @script_path
    end

    def lines_for_test : Array(String)
      @lines.dup
    end

    def line_at_for_test(index : Int32) : String
      @lines[index]? || ""
    end

    def cursor_line_for_test : Int32
      @cursor_line
    end

    def cursor_column_for_test : Int32
      @cursor_column
    end

    def scroll_offset_for_test : Int32
      @scroll_offset
    end

    def is_modified_for_test : Bool
      @is_modified
    end

    def error_messages_for_test : Array(String)
      @error_messages.dup
    end

    def syntax_token_count_for_test : Int32
      @syntax_tokens.size
    end

    # Testing setters
    def set_lines_for_test(lines : Array(String))
      @lines = lines.dup
      update_syntax_highlighting
    end

    def set_cursor_for_test(line : Int32, column : Int32)
      @cursor_line = line.clamp(0, [@lines.size - 1, 0].max)
      @cursor_column = column.clamp(0, @lines[@cursor_line]?.try(&.size) || 0)
    end

    def set_scroll_offset_for_test(offset : Int32)
      @scroll_offset = offset.clamp(0, [@lines.size - 10, 0].max)
    end

    def mark_modified_for_test
      @is_modified = true
    end

    def clear_modified_for_test
      @is_modified = false
    end

    # Testing actions
    def insert_text_for_test(text : String)
      text.each_char do |char|
        if char == '\n'
          insert_newline
        else
          insert_character(char)
        end
      end
    end

    def validate_syntax_for_test
      validate_syntax
    end

    def clear_errors_for_test
      @error_messages.clear
    end

    def show_for_test(script_path : String? = nil)
      show(script_path)
    end

    # Get button positions for click testing
    def get_save_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      window_width = 900
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - 700) // 2
      toolbar_y = window_y + 35
      {window_x + 40, toolbar_y + 20}
    end

    def get_check_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      window_width = 900
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - 700) // 2
      toolbar_y = window_y + 35
      {window_x + 110, toolbar_y + 20}
    end

    def get_editor_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      window_width = 900
      window_height = 700
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - window_height) // 2
      content_y = window_y + 35 + 40
      {window_x + 60, content_y + 50}
    end

    def get_line_position(line_index : Int32, screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      window_width = 900
      window_height = 700
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - window_height) // 2
      content_y = window_y + 35 + 40
      line_y = content_y + 5 + (line_index - @scroll_offset) * @line_height
      {window_x + 60, line_y + 9}
    end
  end
end
