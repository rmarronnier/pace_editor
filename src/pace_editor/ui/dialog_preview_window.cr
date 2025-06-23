require "raylib-cr"

module PaceEditor::UI
  # Dialog preview window for testing dialog trees
  class DialogPreviewWindow
    property visible : Bool = false

    @dialog_tree : PointClickEngine::Characters::Dialogue::DialogTree? = nil
    @current_node : PointClickEngine::Characters::Dialogue::DialogNode? = nil
    @dialog_state : Hash(String, String) = {} of String => String
    @conversation_history : Array(String) = [] of String
    @selected_choice_index : Int32 = -1

    def initialize(@state : Core::EditorState)
    end

    def show(dialog_tree : PointClickEngine::Characters::Dialogue::DialogTree)
      @dialog_tree = dialog_tree
      # Find the first node or use current_node_id if set
      if current_id = dialog_tree.current_node_id
        @current_node = dialog_tree.nodes[current_id]?
      elsif !dialog_tree.nodes.empty?
        # Use the first node as starting point
        @current_node = dialog_tree.nodes.values.first
      else
        @current_node = nil
      end

      @conversation_history.clear
      @dialog_state.clear
      @selected_choice_index = -1
      @visible = true

      # Add initial node to history if it exists
      if node = @current_node
        @conversation_history << "#{node.character_name || "Narrator"}: #{node.text}"
      end
    end

    def hide
      @visible = false
      @dialog_tree = nil
      @current_node = nil
    end

    def update
      return unless @visible

      # Handle keyboard navigation
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        hide
      end

      # Handle choice selection
      if node = @current_node
        choice_count = node.choices.size
        if choice_count > 0
          if RL.key_pressed?(RL::KeyboardKey::Up)
            @selected_choice_index = (@selected_choice_index - 1) % choice_count
          elsif RL.key_pressed?(RL::KeyboardKey::Down)
            @selected_choice_index = (@selected_choice_index + 1) % choice_count
          elsif RL.key_pressed?(RL::KeyboardKey::Enter) && @selected_choice_index >= 0
            select_choice(@selected_choice_index)
          end
        end
      end
    end

    def draw
      return unless @visible

      # Dialog window dimensions
      window_width = 600
      window_height = 500
      window_x = (Core::EditorWindow::WINDOW_WIDTH - window_width) // 2
      window_y = (Core::EditorWindow::WINDOW_HEIGHT - window_height) // 2

      # Draw backdrop
      RL.draw_rectangle(0, 0, Core::EditorWindow::WINDOW_WIDTH, Core::EditorWindow::WINDOW_HEIGHT,
        RL::Color.new(r: 0, g: 0, b: 0, a: 150))

      # Draw dialog window
      RL.draw_rectangle(window_x, window_y, window_width, window_height, RL::WHITE)
      RL.draw_rectangle_lines(window_x, window_y, window_width, window_height, RL::BLACK)

      # Title bar
      RL.draw_rectangle(window_x, window_y, window_width, 30, RL::DARKBLUE)
      RL.draw_text("Dialog Preview", window_x + 10, window_y + 8, 16, RL::WHITE)

      # Close button
      close_button_x = window_x + window_width - 25
      close_button_y = window_y + 5
      RL.draw_rectangle(close_button_x, close_button_y, 20, 20, RL::RED)
      RL.draw_text("X", close_button_x + 6, close_button_y + 4, 12, RL::WHITE)

      # Handle close button click
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        mouse_pos = RL.get_mouse_position
        if mouse_pos.x >= close_button_x && mouse_pos.x <= close_button_x + 20 &&
           mouse_pos.y >= close_button_y && mouse_pos.y <= close_button_y + 20
          hide
          return
        end
      end

      # Content area
      content_y = window_y + 35
      content_height = window_height - 40

      # Draw conversation history
      history_height = content_height * 0.6
      draw_conversation_history(window_x + 10, content_y, window_width - 20, history_height.to_i)

      # Draw current choices
      choices_y = content_y + history_height.to_i + 10
      choices_height = content_height - history_height.to_i - 20
      draw_current_choices(window_x + 10, choices_y, window_width - 20, choices_height.to_i)

      # Instructions
      instructions_y = window_y + window_height - 20
      RL.draw_text("Use UP/DOWN to select, ENTER to choose, ESC to close", window_x + 10, instructions_y, 12, RL::DARKGRAY)
    end

    private def draw_conversation_history(x : Int32, y : Int32, width : Int32, height : Int32)
      # Background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 240, g: 240, b: 240, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Title
      RL.draw_text("Conversation:", x + 5, y + 5, 14, RL::BLACK)

      # History text
      text_y = y + 25
      line_height = 18
      @conversation_history.each_with_index do |line, index|
        if text_y + line_height < y + height
          # Wrap text if needed
          wrapped_lines = wrap_text(line, width - 10, 12)
          wrapped_lines.each do |wrapped_line|
            if text_y + line_height < y + height
              RL.draw_text(wrapped_line, x + 5, text_y, 12, RL::BLACK)
              text_y += line_height
            end
          end
          text_y += 5 # Extra spacing between entries
        end
      end
    end

    private def draw_current_choices(x : Int32, y : Int32, width : Int32, height : Int32)
      # Background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 250, g: 250, b: 250, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      node = @current_node
      return unless node

      if node.choices.empty?
        # End of dialog
        if node.is_end
          RL.draw_text("Dialog completed.", x + 5, y + 5, 14, RL::BLACK)
          RL.draw_text("Press ESC to close", x + 5, y + 25, 12, RL::DARKGRAY)
        else
          RL.draw_text("No choices available.", x + 5, y + 5, 14, RL::RED)
        end
      else
        # Current node text
        RL.draw_text("Current:", x + 5, y + 5, 14, RL::BLACK)
        current_text = "#{node.character_name || "Narrator"}: #{node.text}"
        wrapped_current = wrap_text(current_text, width - 10, 12)
        text_y = y + 25
        wrapped_current.each do |line|
          RL.draw_text(line, x + 5, text_y, 12, RL::DARKBLUE)
          text_y += 16
        end

        # Choices
        text_y += 10
        RL.draw_text("Choices:", x + 5, text_y, 14, RL::BLACK)
        text_y += 20

        node.choices.each_with_index do |choice, index|
          choice_color = (index == @selected_choice_index) ? RL::BLUE : RL::BLACK
          background_color = (index == @selected_choice_index) ? RL::Color.new(r: 200, g: 200, b: 255, a: 255) : RL::Color.new(r: 0, g: 0, b: 0, a: 0)

          if background_color.a > 0
            RL.draw_rectangle(x + 5, text_y - 2, width - 10, 18, background_color)
          end

          choice_text = "#{index + 1}. #{choice.text}"
          RL.draw_text(choice_text, x + 10, text_y, 12, choice_color)
          text_y += 18

          # Handle mouse click
          if RL.mouse_button_pressed?(RL::MouseButton::Left)
            mouse_pos = RL.get_mouse_position
            if mouse_pos.x >= x + 5 && mouse_pos.x <= x + width - 5 &&
               mouse_pos.y >= text_y - 18 && mouse_pos.y <= text_y
              select_choice(index)
            end
          end
        end
      end
    end

    private def select_choice(index : Int32)
      return unless node = @current_node
      return unless dialog = @dialog_tree
      return if index < 0 || index >= node.choices.size

      choice = node.choices[index]

      # Add choice to history
      @conversation_history << "Player: #{choice.text}"

      # Process choice actions
      choice.actions.each do |action|
        case action
        when .starts_with?("set_variable:")
          parts = action.split(":")
          if parts.size >= 3
            var_name = parts[1].strip
            var_value = parts[2].strip
            @dialog_state[var_name] = var_value
            @conversation_history << "[Set #{var_name} = #{var_value}]"
          end
        when .starts_with?("end_dialog")
          @conversation_history << "[Dialog ended]"
          @current_node = nil
          return
        end
      end

      # Move to next node
      if target_node = dialog.nodes[choice.target_node_id]?
        @current_node = target_node
        @selected_choice_index = -1
        @conversation_history << "#{target_node.character_name || "Narrator"}: #{target_node.text}"
      else
        @conversation_history << "[Error: Target node '#{choice.target_node_id}' not found]"
        @current_node = nil
      end
    end

    private def wrap_text(text : String, max_width : Int32, font_size : Int32) : Array(String)
      words = text.split(" ")
      lines = [] of String
      current_line = ""

      words.each do |word|
        test_line = current_line.empty? ? word : "#{current_line} #{word}"
        text_width = RL.measure_text(test_line, font_size)

        if text_width <= max_width
          current_line = test_line
        else
          lines << current_line unless current_line.empty?
          current_line = word
        end
      end

      lines << current_line unless current_line.empty?
      lines
    end
  end
end
