require "raylib-cr"

module PaceEditor::UI
  # Dialog for selecting object type when placing objects
  class ObjectTypeDialog
    property visible : Bool = false

    enum ObjectType
      Hotspot
      Character
      Item
      Trigger
    end

    @selected_type : ObjectType = ObjectType::Hotspot
    @on_confirm : Proc(ObjectType, Nil)? = nil

    def initialize(@state : Core::EditorState)
    end

    def show(&on_confirm : ObjectType -> Nil)
      @visible = true
      @on_confirm = on_confirm
      @selected_type = ObjectType::Hotspot
    end

    def hide
      @visible = false
      @on_confirm = nil
    end

    def update
      return unless @visible

      # Handle keyboard navigation
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        hide
      elsif RL.key_pressed?(RL::KeyboardKey::Enter)
        confirm_selection
      elsif RL.key_pressed?(RL::KeyboardKey::Up)
        cycle_selection(-1)
      elsif RL.key_pressed?(RL::KeyboardKey::Down)
        cycle_selection(1)
      end
    end

    def draw
      return unless @visible

      # Get screen dimensions
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height

      # Dialog window dimensions
      window_width = 300
      window_height = 250
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
      RL.draw_text("Select Object Type", window_x + 10, window_y + 8, 16, RL::WHITE)

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
      content_y = window_y + 40
      content_x = window_x + 20
      content_width = window_width - 40

      # Draw instructions
      RL.draw_text("Choose the type of object to place:", content_x, content_y, 14, RL::BLACK)

      # Draw object type options
      option_y = content_y + 30
      option_height = 30

      ObjectType.values.each_with_index do |object_type, index|
        is_selected = object_type == @selected_type

        # Option background
        bg_color = is_selected ? RL::Color.new(r: 200, g: 200, b: 255, a: 255) : RL::Color.new(r: 240, g: 240, b: 240, a: 255)
        RL.draw_rectangle(content_x, option_y, content_width, option_height, bg_color)
        RL.draw_rectangle_lines(content_x, option_y, content_width, option_height, RL::GRAY)

        # Option text
        text_color = is_selected ? RL::DARKBLUE : RL::BLACK
        option_text = get_object_type_text(object_type)
        RL.draw_text(option_text, content_x + 10, option_y + 8, 14, text_color)

        # Description
        description_text = get_object_type_description(object_type)
        RL.draw_text(description_text, content_x + 10, option_y + 24, 10, RL::DARKGRAY)

        # Handle mouse click
        if RL.mouse_button_pressed?(RL::MouseButton::Left)
          mouse_pos = RL.get_mouse_position
          if mouse_pos.x >= content_x && mouse_pos.x <= content_x + content_width &&
             mouse_pos.y >= option_y && mouse_pos.y <= option_y + option_height
            @selected_type = object_type
            confirm_selection
            return
          end
        end

        option_y += option_height + 5
      end

      # Buttons
      button_y = window_y + window_height - 50
      button_width = 80
      button_height = 30

      # OK button
      ok_button_x = content_x
      ok_bg_color = RL::Color.new(r: 100, g: 200, b: 100, a: 255)
      RL.draw_rectangle(ok_button_x, button_y, button_width, button_height, ok_bg_color)
      RL.draw_rectangle_lines(ok_button_x, button_y, button_width, button_height, RL::BLACK)
      RL.draw_text("OK", ok_button_x + 30, button_y + 8, 14, RL::WHITE)

      # Handle OK button click
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        mouse_pos = RL.get_mouse_position
        if mouse_pos.x >= ok_button_x && mouse_pos.x <= ok_button_x + button_width &&
           mouse_pos.y >= button_y && mouse_pos.y <= button_y + button_height
          confirm_selection
          return
        end
      end

      # Cancel button
      cancel_button_x = content_x + content_width - button_width
      cancel_bg_color = RL::Color.new(r: 200, g: 100, b: 100, a: 255)
      RL.draw_rectangle(cancel_button_x, button_y, button_width, button_height, cancel_bg_color)
      RL.draw_rectangle_lines(cancel_button_x, button_y, button_width, button_height, RL::BLACK)
      RL.draw_text("Cancel", cancel_button_x + 20, button_y + 8, 14, RL::WHITE)

      # Handle Cancel button click
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        mouse_pos = RL.get_mouse_position
        if mouse_pos.x >= cancel_button_x && mouse_pos.x <= cancel_button_x + button_width &&
           mouse_pos.y >= button_y && mouse_pos.y <= button_y + button_height
          hide
          return
        end
      end

      # Instructions
      instructions_y = button_y - 20
      RL.draw_text("Use UP/DOWN to select, ENTER to confirm, ESC to cancel", content_x, instructions_y, 10, RL::DARKGRAY)
    end

    private def get_object_type_text(object_type : ObjectType) : String
      case object_type
      when ObjectType::Hotspot
        "Hotspot"
      when ObjectType::Character
        "Character (NPC)"
      when ObjectType::Item
        "Item"
      when ObjectType::Trigger
        "Trigger Zone"
      else
        object_type.to_s
      end
    end

    private def get_object_type_description(object_type : ObjectType) : String
      case object_type
      when ObjectType::Hotspot
        "Interactive area with actions"
      when ObjectType::Character
        "Non-player character"
      when ObjectType::Item
        "Collectible item"
      when ObjectType::Trigger
        "Area that triggers events"
      else
        ""
      end
    end

    private def cycle_selection(direction : Int32)
      current_index = ObjectType.values.index(@selected_type) || 0
      new_index = (current_index + direction) % ObjectType.values.size
      new_index = ObjectType.values.size - 1 if new_index < 0
      @selected_type = ObjectType.values[new_index]
    end

    private def confirm_selection
      if callback = @on_confirm
        callback.call(@selected_type)
      end
      hide
    end
  end
end
