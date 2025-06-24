require "raylib-cr"
require "../models/hotspot_action"

module PaceEditor::UI
  # Hotspot interaction preview window for testing hotspot behavior
  class HotspotInteractionPreview
    property visible : Bool = false

    @hotspot : PointClickEngine::Scenes::Hotspot? = nil
    @hotspot_data : Models::HotspotData? = nil
    @selected_interaction : String = "on_click"
    @simulation_log : Array(String) = [] of String
    @cursor_preview : PointClickEngine::Scenes::Hotspot::CursorType = PointClickEngine::Scenes::Hotspot::CursorType::Default
    @test_variables : Hash(String, String) = {} of String => String

    def initialize(@state : Core::EditorState)
    end

    def show(hotspot : PointClickEngine::Scenes::Hotspot, hotspot_data : Models::HotspotData? = nil)
      @hotspot = hotspot
      @hotspot_data = hotspot_data
      @visible = true
      @selected_interaction = "on_click"
      @simulation_log.clear
      @cursor_preview = hotspot.cursor_type
      @test_variables.clear

      # Add initial log entry
      @simulation_log << "=== Hotspot Interaction Test: #{hotspot.name} ==="
      @simulation_log << "Description: #{hotspot.description}"
      @simulation_log << "Cursor Type: #{hotspot.cursor_type}"
      @simulation_log << "Visible: #{hotspot.visible}"
      @simulation_log << ""
    end

    def hide
      @visible = false
      @hotspot = nil
      @hotspot_data = nil
    end

    def update
      return unless @visible

      # Handle keyboard navigation
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        hide
      end
    end

    def draw
      return unless @visible

      # Get screen dimensions
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height

      # Dialog window dimensions
      window_width = 700
      window_height = 600
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - window_height) // 2

      # Draw backdrop
      RL.draw_rectangle(0, 0, screen_width, screen_height,
        RL::Color.new(r: 0, g: 0, b: 0, a: 150))

      # Draw dialog window
      RL.draw_rectangle(window_x, window_y, window_width, window_height, RL::WHITE)
      RL.draw_rectangle_lines(window_x, window_y, window_width, window_height, RL::BLACK)

      # Title bar
      RL.draw_rectangle(window_x, window_y, window_width, 30, RL::DARKBLUE)
      title_text = "Hotspot Interaction Preview"
      if hotspot = @hotspot
        title_text = "Hotspot Preview: #{hotspot.name}"
      end
      RL.draw_text(title_text, window_x + 10, window_y + 8, 16, RL::WHITE)

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

      # Left side: Interaction controls
      controls_width = window_width // 2
      draw_interaction_controls(window_x + 10, content_y, controls_width - 20, content_height - 10)

      # Right side: Simulation log
      log_x = window_x + controls_width + 10
      log_width = window_width - controls_width - 30
      draw_simulation_log(log_x, content_y, log_width, content_height - 10)
    end

    private def draw_interaction_controls(x : Int32, y : Int32, width : Int32, height : Int32)
      # Background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 240, g: 240, b: 240, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Title
      RL.draw_text("Interaction Controls", x + 5, y + 5, 14, RL::BLACK)

      current_y = y + 30

      # Hotspot info
      if hotspot = @hotspot
        RL.draw_text("Hotspot: #{hotspot.name}", x + 10, current_y, 12, RL::DARKBLUE)
        current_y += 18
        RL.draw_text("Position: (#{hotspot.position.x.to_i}, #{hotspot.position.y.to_i})", x + 10, current_y, 10, RL::GRAY)
        current_y += 15
        RL.draw_text("Size: #{hotspot.size.x.to_i}x#{hotspot.size.y.to_i}", x + 10, current_y, 10, RL::GRAY)
        current_y += 20

        # Cursor preview
        RL.draw_text("Cursor Type:", x + 10, current_y, 12, RL::BLACK)
        current_y += 18
        cursor_text = get_cursor_description(@cursor_preview)
        RL.draw_text(cursor_text, x + 20, current_y, 11, RL::DARKGREEN)
        current_y += 25

        # Interaction types
        RL.draw_text("Test Interactions:", x + 10, current_y, 12, RL::BLACK)
        current_y += 20

        interactions = ["on_click", "on_look", "on_use", "on_talk"]
        interactions.each do |interaction|
          is_selected = interaction == @selected_interaction
          bg_color = is_selected ? RL::Color.new(r: 200, g: 200, b: 255, a: 255) : RL::Color.new(r: 250, g: 250, b: 250, a: 255)

          button_width = width - 40
          button_height = 25
          RL.draw_rectangle(x + 20, current_y, button_width, button_height, bg_color)
          RL.draw_rectangle_lines(x + 20, current_y, button_width, button_height, RL::GRAY)

          interaction_text = get_interaction_display_name(interaction)
          RL.draw_text(interaction_text, x + 25, current_y + 5, 11, RL::BLACK)

          # Handle interaction button click
          if RL.mouse_button_pressed?(RL::MouseButton::Left)
            mouse_pos = RL.get_mouse_position
            if mouse_pos.x >= x + 20 && mouse_pos.x <= x + 20 + button_width &&
               mouse_pos.y >= current_y && mouse_pos.y <= current_y + button_height
              @selected_interaction = interaction
              simulate_interaction(interaction)
            end
          end

          current_y += button_height + 5
        end

        # Clear log button
        current_y += 10
        clear_button_width = width - 40
        clear_button_height = 30
        RL.draw_rectangle(x + 20, current_y, clear_button_width, clear_button_height, RL::Color.new(r: 255, g: 200, b: 200, a: 255))
        RL.draw_rectangle_lines(x + 20, current_y, clear_button_width, clear_button_height, RL::BLACK)
        RL.draw_text("Clear Log", x + 25 + (clear_button_width - 70) // 2, current_y + 8, 12, RL::BLACK)

        # Handle clear log button click
        if RL.mouse_button_pressed?(RL::MouseButton::Left)
          mouse_pos = RL.get_mouse_position
          if mouse_pos.x >= x + 20 && mouse_pos.x <= x + 20 + clear_button_width &&
             mouse_pos.y >= current_y && mouse_pos.y <= current_y + clear_button_height
            @simulation_log.clear
            @simulation_log << "=== Log Cleared ==="
          end
        end
      end
    end

    private def draw_simulation_log(x : Int32, y : Int32, width : Int32, height : Int32)
      # Background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 250, g: 250, b: 250, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Title
      RL.draw_text("Simulation Log", x + 5, y + 5, 14, RL::BLACK)

      # Log content
      text_y = y + 25
      line_height = 14
      @simulation_log.each do |line|
        if text_y + line_height < y + height
          # Wrap text if needed
          wrapped_lines = wrap_text(line, width - 10, 10)
          wrapped_lines.each do |wrapped_line|
            if text_y + line_height < y + height
              color = get_log_line_color(wrapped_line)
              RL.draw_text(wrapped_line, x + 5, text_y, 10, color)
              text_y += line_height
            end
          end
        end
      end
    end

    private def simulate_interaction(interaction_type : String)
      return unless hotspot = @hotspot

      @simulation_log << ""
      @simulation_log << "> #{get_interaction_display_name(interaction_type)} on #{hotspot.name}"

      # Check if hotspot has actions for this interaction
      if hotspot_data = @hotspot_data
        actions = hotspot_data.get_actions(interaction_type)
        if actions.empty?
          @simulation_log << "  No actions defined for this interaction"
        else
          @simulation_log << "  Found #{actions.size} action(s):"
          actions.each_with_index do |action, index|
            @simulation_log << "    #{index + 1}. #{action.description}"
            simulate_action(action)
          end
        end
      else
        @simulation_log << "  No action data available for this hotspot"
      end

      @simulation_log << "  Interaction completed"
    end

    private def simulate_action(action : Models::HotspotAction)
      case action.action_type
      when Models::HotspotAction::ActionType::ShowMessage
        if message = action.parameters["message"]?
          @simulation_log << "    → Message: \"#{message}\""
        else
          @simulation_log << "    → Message: (no message text)"
        end
      when Models::HotspotAction::ActionType::ChangeScene
        if scene = action.parameters["scene"]?
          @simulation_log << "    → Change to scene: #{scene}"
          if entry_point = action.parameters["entry_point"]?
            @simulation_log << "      Entry point: #{entry_point}"
          end
        else
          @simulation_log << "    → Change scene: (no scene specified)"
        end
      when Models::HotspotAction::ActionType::PlaySound
        if sound = action.parameters["sound"]?
          volume = action.parameters["volume"]? || "100"
          @simulation_log << "    → Play sound: #{File.basename(sound)} (volume: #{volume}%)"
        else
          @simulation_log << "    → Play sound: (no sound file specified)"
        end
      when Models::HotspotAction::ActionType::GiveItem
        if item = action.parameters["item"]?
          quantity = action.parameters["quantity"]? || "1"
          @simulation_log << "    → Give item: #{item} (quantity: #{quantity})"
        else
          @simulation_log << "    → Give item: (no item specified)"
        end
      when Models::HotspotAction::ActionType::RunScript
        if script = action.parameters["script"]?
          function = action.parameters["function"]? || "main"
          @simulation_log << "    → Run script: #{File.basename(script)}.#{function}()"
        else
          @simulation_log << "    → Run script: (no script specified)"
        end
      when Models::HotspotAction::ActionType::SetVariable
        if variable = action.parameters["variable"]?
          value = action.parameters["value"]? || ""
          operation = action.parameters["operation"]? || "set"
          @simulation_log << "    → #{operation.capitalize} variable: #{variable} = #{value}"
          @test_variables[variable] = value
        else
          @simulation_log << "    → Set variable: (no variable specified)"
        end
      when Models::HotspotAction::ActionType::StartDialog
        if dialog = action.parameters["dialog"]?
          node = action.parameters["node"]? || "start"
          @simulation_log << "    → Start dialog: #{dialog} (node: #{node})"
        else
          @simulation_log << "    → Start dialog: (no dialog specified)"
        end
      else
        @simulation_log << "    → Unknown action type: #{action.action_type}"
      end
    end

    private def get_interaction_display_name(interaction : String) : String
      case interaction
      when "on_click"
        "Click/Use"
      when "on_look"
        "Look At"
      when "on_use"
        "Use With"
      when "on_talk"
        "Talk To"
      else
        interaction.capitalize
      end
    end

    private def get_cursor_description(cursor_type : PointClickEngine::Scenes::Hotspot::CursorType) : String
      case cursor_type
      when PointClickEngine::Scenes::Hotspot::CursorType::Default
        "Default (arrow)"
      when PointClickEngine::Scenes::Hotspot::CursorType::Hand
        "Hand (interactive)"
      when PointClickEngine::Scenes::Hotspot::CursorType::Look
        "Look (examine)"
      when PointClickEngine::Scenes::Hotspot::CursorType::Talk
        "Talk (conversation)"
      when PointClickEngine::Scenes::Hotspot::CursorType::Use
        "Use (action)"
      else
        cursor_type.to_s
      end
    end

    private def get_log_line_color(line : String) : RL::Color
      if line.starts_with?(">")
        RL::DARKBLUE # User actions
      elsif line.starts_with?("  →")
        RL::DARKGREEN # Action results
      elsif line.starts_with?("===")
        RL::PURPLE # Section headers
      elsif line.starts_with?("  No") || line.starts_with?("    → (no")
        RL::RED # Warnings/missing data
      else
        RL::BLACK # Normal text
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
