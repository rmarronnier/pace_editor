require "raylib-cr"

module PaceEditor::UI
  # Script editor for editing Lua scripts with syntax highlighting
  class ScriptEditor
    property visible : Bool = false

    @script_path : String? = nil
    @script_content : String = ""
    @original_content : String = ""
    @is_modified : Bool = false
    @cursor_line : Int32 = 0
    @cursor_column : Int32 = 0
    @scroll_offset : Int32 = 0
    @font_size : Int32 = 14
    @line_height : Int32 = 18
    @tab_size : Int32 = 2
    @lines : Array(String) = [] of String
    @syntax_tokens : Array(SyntaxToken) = [] of SyntaxToken
    @error_messages : Array(String) = [] of String

    # Syntax highlighting
    struct SyntaxToken
      property type : TokenType
      property line : Int32
      property start_col : Int32
      property end_col : Int32
      property text : String

      def initialize(@type : TokenType, @line : Int32, @start_col : Int32, @end_col : Int32, @text : String)
      end
    end

    enum TokenType
      Keyword
      Function
      String
      Comment
      Number
      Identifier
      Operator
      Normal
    end

    def initialize(@state : Core::EditorState)
      @lines = ["-- New Lua script", "-- Add your code here", ""]
      update_syntax_highlighting
    end

    def show(script_path : String? = nil)
      @script_path = script_path
      @visible = true
      @cursor_line = 0
      @cursor_column = 0
      @scroll_offset = 0
      @error_messages.clear

      if script_path && File.exists?(script_path)
        load_script(script_path)
      else
        # New script
        @script_content = "-- New Lua script\n-- Add your code here\n\nfunction main()\n    -- Your code here\nend\n"
        @original_content = @script_content
        @lines = @script_content.split('\n')
        @is_modified = false
      end

      update_syntax_highlighting
    end

    def hide
      if @is_modified
        # TODO: Show save dialog
        puts "Warning: Unsaved changes in script editor"
      end
      @visible = false
      @script_path = nil
    end

    # Public getters for testing
    def line_count
      @lines.size
    end

    def current_line
      @lines[@cursor_line]? || ""
    end

    def cursor_position
      {@cursor_line, @cursor_column}
    end

    def modified?
      @is_modified
    end

    def error_count
      @error_messages.size
    end

    def token_count
      @syntax_tokens.size
    end

    def update
      return unless @visible

      # Handle keyboard input
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        hide
      elsif RL.key_pressed?(RL::KeyboardKey::S) && (RL.key_down?(RL::KeyboardKey::LeftControl) || RL.key_down?(RL::KeyboardKey::RightControl))
        save_script
      elsif RL.key_pressed?(RL::KeyboardKey::F5)
        validate_syntax
      end

      # Handle text editing
      handle_text_input
      handle_cursor_movement
      handle_scrolling
    end

    def draw
      return unless @visible

      # Dialog window dimensions
      window_width = 900
      window_height = 700
      window_x = (Core::EditorWindow::WINDOW_WIDTH - window_width) // 2
      window_y = (Core::EditorWindow::WINDOW_HEIGHT - window_height) // 2

      # Draw backdrop
      RL.draw_rectangle(0, 0, Core::EditorWindow::WINDOW_WIDTH, Core::EditorWindow::WINDOW_HEIGHT,
        RL::Color.new(r: 0, g: 0, b: 0, a: 150))

      # Draw editor window
      RL.draw_rectangle(window_x, window_y, window_width, window_height, RL::Color.new(r: 30, g: 30, b: 30, a: 255))
      RL.draw_rectangle_lines(window_x, window_y, window_width, window_height, RL::GRAY)

      # Title bar
      title_height = 35
      RL.draw_rectangle(window_x, window_y, window_width, title_height, RL::Color.new(r: 50, g: 50, b: 50, a: 255))

      title_text = "Script Editor"
      if path = @script_path
        title_text += " - #{File.basename(path)}"
      else
        title_text += " - New Script"
      end
      if @is_modified
        title_text += " *"
      end

      RL.draw_text(title_text, window_x + 10, window_y + 8, 16, RL::WHITE)

      # Toolbar
      toolbar_y = window_y + title_height
      toolbar_height = 40
      draw_toolbar(window_x, toolbar_y, window_width, toolbar_height)

      # Editor content area
      content_y = toolbar_y + toolbar_height
      content_height = window_height - title_height - toolbar_height - 30

      # Draw editor content
      draw_editor_content(window_x + 5, content_y + 5, window_width - 10, content_height)

      # Status bar
      status_y = window_y + window_height - 25
      draw_status_bar(window_x, status_y, window_width, 25)
    end

    private def draw_toolbar(x : Int32, y : Int32, width : Int32, height : Int32)
      # Toolbar background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 40, g: 40, b: 40, a: 255))
      RL.draw_line(x, y + height, x + width, y + height, RL::GRAY)

      button_x = x + 10
      button_y = y + 8
      button_width = 60
      button_height = 24

      # Save button
      save_color = @is_modified ? RL::Color.new(r: 100, g: 150, b: 100, a: 255) : RL::Color.new(r: 60, g: 60, b: 60, a: 255)
      if draw_button("Save", button_x, button_y, button_width, button_height, save_color)
        save_script
      end

      # Validate button
      button_x += button_width + 10
      if draw_button("Check", button_x, button_y, button_width, button_height)
        validate_syntax
      end

      # Functions dropdown
      button_x += button_width + 20
      RL.draw_text("Functions:", button_x, button_y + 5, 12, RL::LIGHTGRAY)
      button_x += 70

      functions = extract_functions
      if functions.any?
        # Simple function list (could be enhanced with dropdown)
        function_text = functions.first
        RL.draw_text(function_text, button_x, button_y + 5, 12, RL::YELLOW)
      end
    end

    private def draw_editor_content(x : Int32, y : Int32, width : Int32, height : Int32)
      # Editor background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 25, g: 25, b: 25, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Line numbers area
      line_number_width = 50
      RL.draw_rectangle(x, y, line_number_width, height, RL::Color.new(r: 35, g: 35, b: 35, a: 255))
      RL.draw_line(x + line_number_width, y, x + line_number_width, y + height, RL::GRAY)

      # Calculate visible lines
      visible_lines = height // @line_height
      editor_text_x = x + line_number_width + 10
      editor_text_width = width - line_number_width - 15

      # Draw lines
      (@scroll_offset...[@scroll_offset + visible_lines, @lines.size].min).each_with_index do |line_index, display_index|
        line_y = y + 5 + display_index * @line_height

        # Draw line number
        line_num_text = (line_index + 1).to_s
        line_num_x = x + line_number_width - RL.measure_text(line_num_text, 12) - 5
        RL.draw_text(line_num_text, line_num_x, line_y, 12, RL::DARKGRAY)

        # Highlight current line
        if line_index == @cursor_line
          RL.draw_rectangle(editor_text_x - 5, line_y - 2, editor_text_width, @line_height,
            RL::Color.new(r: 40, g: 40, b: 50, a: 255))
        end

        # Draw line text with syntax highlighting
        draw_line_with_highlighting(@lines[line_index], editor_text_x, line_y, line_index)

        # Draw cursor
        if line_index == @cursor_line
          cursor_x = editor_text_x + get_text_width(@lines[line_index][0...[@cursor_column, @lines[line_index].size].min])
          RL.draw_line(cursor_x, line_y, cursor_x, line_y + @font_size, RL::WHITE)
        end
      end

      # Draw error highlights
      draw_error_highlights(x, y, width, height, line_number_width)
    end

    private def draw_line_with_highlighting(line : String, x : Int32, y : Int32, line_index : Int32)
      return if line.empty?

      # Find tokens for this line
      line_tokens = @syntax_tokens.select { |token| token.line == line_index }

      if line_tokens.empty?
        # No highlighting, draw as normal text
        RL.draw_text(line, x, y, @font_size, RL::LIGHTGRAY)
      else
        # Draw with syntax highlighting
        current_x = x
        last_end = 0

        line_tokens.each do |token|
          # Draw any unhighlighted text before this token
          if token.start_col > last_end
            text_before = line[last_end...token.start_col]
            RL.draw_text(text_before, current_x, y, @font_size, RL::LIGHTGRAY)
            current_x += get_text_width(text_before)
          end

          # Draw the highlighted token
          color = get_token_color(token.type)
          RL.draw_text(token.text, current_x, y, @font_size, color)
          current_x += get_text_width(token.text)
          last_end = token.end_col
        end

        # Draw any remaining text
        if last_end < line.size
          remaining_text = line[last_end..-1]
          RL.draw_text(remaining_text, current_x, y, @font_size, RL::LIGHTGRAY)
        end
      end
    end

    private def draw_status_bar(x : Int32, y : Int32, width : Int32, height : Int32)
      # Status bar background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 40, g: 40, b: 40, a: 255))
      RL.draw_line(x, y, x + width, y, RL::GRAY)

      # Line/column info
      status_text = "Line #{@cursor_line + 1}, Column #{@cursor_column + 1}"
      RL.draw_text(status_text, x + 10, y + 5, 12, RL::LIGHTGRAY)

      # File info
      if path = @script_path
        file_info = "File: #{File.basename(path)}"
      else
        file_info = "File: Unsaved"
      end
      file_info_width = RL.measure_text(file_info, 12)
      RL.draw_text(file_info, x + width - file_info_width - 10, y + 5, 12, RL::LIGHTGRAY)

      # Error count
      if @error_messages.any?
        error_text = "#{@error_messages.size} error(s)"
        error_width = RL.measure_text(error_text, 12)
        RL.draw_text(error_text, x + width // 2 - error_width // 2, y + 5, 12, RL::RED)
      end
    end

    private def draw_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32, color : RL::Color = RL::GRAY) : Bool
      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      bg_color = is_hover ? RL::Color.new(r: color.r + 20, g: color.g + 20, b: color.b + 20, a: 255) : color

      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, RL::LIGHTGRAY)

      text_width = RL.measure_text(text, 12)
      text_x = x + (width - text_width) // 2
      RL.draw_text(text, text_x, y + 6, 12, RL::WHITE)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def handle_text_input
      # Handle character input
      while (char = RL.get_char_pressed) != 0
        if char >= 32 && char < 127 # Printable ASCII
          insert_character(char.chr)
        end
      end

      # Handle special keys
      if RL.key_pressed?(RL::KeyboardKey::Enter)
        insert_newline
      elsif RL.key_pressed?(RL::KeyboardKey::Backspace)
        delete_character
      elsif RL.key_pressed?(RL::KeyboardKey::Tab)
        insert_tab
      end
    end

    private def handle_cursor_movement
      if RL.key_pressed?(RL::KeyboardKey::Up)
        move_cursor_up
      elsif RL.key_pressed?(RL::KeyboardKey::Down)
        move_cursor_down
      elsif RL.key_pressed?(RL::KeyboardKey::Left)
        move_cursor_left
      elsif RL.key_pressed?(RL::KeyboardKey::Right)
        move_cursor_right
      elsif RL.key_pressed?(RL::KeyboardKey::Home)
        @cursor_column = 0
      elsif RL.key_pressed?(RL::KeyboardKey::End)
        @cursor_column = @lines[@cursor_line].size
      end
    end

    private def handle_scrolling
      # Mouse wheel scrolling
      wheel = RL.get_mouse_wheel_move
      if wheel != 0
        @scroll_offset = [@scroll_offset - wheel.to_i, 0].max
        max_scroll = [@lines.size - 10, 0].max
        @scroll_offset = [@scroll_offset, max_scroll].min
      end
    end

    private def insert_character(char : Char)
      line = @lines[@cursor_line]
      @lines[@cursor_line] = line[0...@cursor_column] + char + line[@cursor_column..-1]
      @cursor_column += 1
      @is_modified = true
      update_syntax_highlighting
    end

    private def insert_newline
      line = @lines[@cursor_line]
      current_part = line[0...@cursor_column]
      next_part = line[@cursor_column..-1]

      @lines[@cursor_line] = current_part
      @lines.insert(@cursor_line + 1, next_part)
      @cursor_line += 1
      @cursor_column = 0
      @is_modified = true
      update_syntax_highlighting
    end

    private def delete_character
      if @cursor_column > 0
        line = @lines[@cursor_line]
        @lines[@cursor_line] = line[0...@cursor_column - 1] + line[@cursor_column..-1]
        @cursor_column -= 1
        @is_modified = true
        update_syntax_highlighting
      elsif @cursor_line > 0
        # Join with previous line
        prev_line = @lines[@cursor_line - 1]
        current_line = @lines[@cursor_line]
        @lines[@cursor_line - 1] = prev_line + current_line
        @lines.delete_at(@cursor_line)
        @cursor_line -= 1
        @cursor_column = prev_line.size
        @is_modified = true
        update_syntax_highlighting
      end
    end

    private def insert_tab
      spaces = " " * @tab_size
      @tab_size.times { insert_character(' ') }
      @cursor_column -= @tab_size - 1 # Adjust because insert_character increments
    end

    private def move_cursor_up
      if @cursor_line > 0
        @cursor_line -= 1
        @cursor_column = [@cursor_column, @lines[@cursor_line].size].min
        ensure_cursor_visible
      end
    end

    private def move_cursor_down
      if @cursor_line < @lines.size - 1
        @cursor_line += 1
        @cursor_column = [@cursor_column, @lines[@cursor_line].size].min
        ensure_cursor_visible
      end
    end

    private def move_cursor_left
      if @cursor_column > 0
        @cursor_column -= 1
      elsif @cursor_line > 0
        @cursor_line -= 1
        @cursor_column = @lines[@cursor_line].size
        ensure_cursor_visible
      end
    end

    private def move_cursor_right
      if @cursor_column < @lines[@cursor_line].size
        @cursor_column += 1
      elsif @cursor_line < @lines.size - 1
        @cursor_line += 1
        @cursor_column = 0
        ensure_cursor_visible
      end
    end

    private def ensure_cursor_visible
      if @cursor_line < @scroll_offset
        @scroll_offset = @cursor_line
      elsif @cursor_line >= @scroll_offset + 30 # Assuming ~30 visible lines
        @scroll_offset = @cursor_line - 29
      end
    end

    private def update_syntax_highlighting
      @syntax_tokens.clear

      @lines.each_with_index do |line, line_index|
        tokenize_line(line, line_index)
      end
    end

    private def tokenize_line(line : String, line_index : Int32)
      return if line.empty?

      keywords = %w[and break do else elseif end false for function if in local nil not or repeat return then true until while]

      i = 0
      while i < line.size
        char = line[i]

        case char
        when '-'
          # Check for comment
          if i + 1 < line.size && line[i + 1] == '-'
            @syntax_tokens << SyntaxToken.new(TokenType::Comment, line_index, i, line.size, line[i..-1])
            break
          else
            i += 1
          end
        when '"', '\''
          # String literal
          quote = char
          start = i
          i += 1
          while i < line.size && line[i] != quote
            i += 1
          end
          i += 1 if i < line.size # Include closing quote
          @syntax_tokens << SyntaxToken.new(TokenType::String, line_index, start, i, line[start...i])
        when ' ', '\t'
          i += 1
        else
          if char.ascii_letter? || char == '_'
            # Identifier or keyword
            start = i
            while i < line.size && (line[i].ascii_alphanumeric? || line[i] == '_')
              i += 1
            end
            word = line[start...i]

            token_type = if keywords.includes?(word)
                           TokenType::Keyword
                         elsif word == "function" || (i < line.size && line[i] == '(')
                           TokenType::Function
                         else
                           TokenType::Identifier
                         end

            @syntax_tokens << SyntaxToken.new(token_type, line_index, start, i, word)
          elsif char.ascii_number?
            # Number
            start = i
            while i < line.size && (line[i].ascii_number? || line[i] == '.')
              i += 1
            end
            @syntax_tokens << SyntaxToken.new(TokenType::Number, line_index, start, i, line[start...i])
          else
            # Operator or other
            if "+-*/=<>(){}[],.;:".includes?(char)
              @syntax_tokens << SyntaxToken.new(TokenType::Operator, line_index, i, i + 1, char.to_s)
            end
            i += 1
          end
        end
      end
    end

    private def get_token_color(token_type : TokenType) : RL::Color
      case token_type
      when .keyword?
        RL::Color.new(r: 86, g: 156, b: 214, a: 255) # Blue
      when .function?
        RL::Color.new(r: 220, g: 220, b: 170, a: 255) # Yellow
      when .string?
        RL::Color.new(r: 206, g: 145, b: 120, a: 255) # Orange
      when .comment?
        RL::Color.new(r: 106, g: 153, b: 85, a: 255) # Green
      when .number?
        RL::Color.new(r: 181, g: 206, b: 168, a: 255) # Light green
      when .operator?
        RL::Color.new(r: 212, g: 212, b: 212, a: 255) # Light gray
      else
        RL::LIGHTGRAY
      end
    end

    private def get_text_width(text : String) : Int32
      RL.measure_text(text, @font_size)
    end

    private def load_script(path : String)
      begin
        @script_content = File.read(path)
        @original_content = @script_content
        @lines = @script_content.split('\n')
        @is_modified = false
        puts "Loaded script: #{path}"
      rescue ex
        @error_messages << "Failed to load script: #{ex.message}"
        puts "Error loading script: #{ex.message}"
      end
    end

    private def save_script
      unless path = @script_path
        # TODO: Show save-as dialog
        puts "Save-as dialog not implemented yet"
        return
      end

      begin
        content = @lines.join('\n')
        File.write(path, content)
        @original_content = content
        @is_modified = false
        @error_messages.clear
        puts "Saved script: #{path}"
      rescue ex
        @error_messages << "Failed to save script: #{ex.message}"
        puts "Error saving script: #{ex.message}"
      end
    end

    private def validate_syntax
      @error_messages.clear

      # Basic Lua syntax validation
      lua_content = @lines.join('\n')

      # Check for balanced parentheses, brackets, etc.
      stack = [] of Char
      lua_content.each_char_with_index do |char, index|
        case char
        when '(', '[', '{'
          stack << char
        when ')', ']', '}'
          if stack.empty?
            @error_messages << "Unmatched closing '#{char}' at position #{index}"
          else
            opening = stack.pop
            expected = case char
                       when ')' then '('
                       when ']' then '['
                       when '}' then '{'
                       else          '?'
                       end
            if opening != expected
              @error_messages << "Mismatched brackets: expected '#{expected}' but found '#{opening}'"
            end
          end
        end
      end

      stack.each do |opening|
        @error_messages << "Unmatched opening '#{opening}'"
      end

      # Check for basic Lua syntax errors
      validate_lua_keywords

      if @error_messages.empty?
        @error_messages << "Syntax validation passed!"
      end

      puts "Syntax validation completed: #{@error_messages.size} issues found"
    end

    private def validate_lua_keywords
      @lines.each_with_index do |line, line_index|
        # Check for function definitions without 'end'
        if line.strip.starts_with?("function") && !line.includes?("end")
          # Look for matching 'end' in subsequent lines
          found_end = false
          (line_index + 1...@lines.size).each do |check_index|
            if @lines[check_index].strip == "end"
              found_end = true
              break
            end
          end
          unless found_end
            @error_messages << "Function on line #{line_index + 1} missing 'end'"
          end
        end

        # Check for 'if' without 'then'
        if line.includes?("if ") && !line.includes?(" then")
          @error_messages << "Line #{line_index + 1}: 'if' statement missing 'then'"
        end
      end
    end

    private def extract_functions : Array(String)
      functions = [] of String
      @lines.each do |line|
        if match = line.match(/function\s+(\w+)\s*\(/)
          functions << match[1]
        end
      end
      functions
    end

    private def draw_error_highlights(x : Int32, y : Int32, width : Int32, height : Int32, line_number_width : Int32)
      # This would highlight lines with errors - simplified for now
      if @error_messages.any? { |msg| msg.includes?("line") }
        # Could parse error messages and highlight specific lines
        # For now, just indicate errors exist
      end
    end

    # Testing support methods
    def set_lines(lines : Array(String))
      @lines = lines.dup
      update_syntax_highlighting
    end

    def set_cursor_position(line : Int32, column : Int32)
      @cursor_line = line.clamp(0, [@lines.size - 1, 0].max)
      @cursor_column = column.clamp(0, @lines[@cursor_line]?.try(&.size) || 0)
    end

    def cursor_position : Tuple(Int32, Int32)
      {@cursor_line, @cursor_column}
    end

    def line_count : Int32
      @lines.size
    end

    def current_line : String
      @lines[@cursor_line]? || ""
    end

    def modified? : Bool
      @is_modified
    end

    def error_count : Int32
      @error_messages.size
    end

    def token_count : Int32
      @syntax_tokens.size
    end

    def reset_editor_state
      @cursor_line = 0
      @cursor_column = 0
      @scroll_offset = 0
      @is_modified = false
      @error_messages.clear
      @syntax_tokens.clear
    end
  end
end
