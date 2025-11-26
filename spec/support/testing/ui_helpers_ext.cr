# Testing extensions for UIHelpers
# Provides versions of UI helpers that accept an InputProvider

module PaceEditor::UI
  module UIHelpers
    # Button that works with test input provider
    def self.button_with_input(x : Int32, y : Int32, width : Int32, height : Int32, text : String,
                               input : Testing::InputProvider) : Bool
      bounds = RL::Rectangle.new(x: x.to_f32, y: y.to_f32, width: width.to_f32, height: height.to_f32)
      mouse_pos = input.get_mouse_position

      # Check mouse state
      is_hover = mouse_pos.x >= bounds.x && mouse_pos.x <= bounds.x + bounds.width &&
                 mouse_pos.y >= bounds.y && mouse_pos.y <= bounds.y + bounds.height
      is_clicked = is_hover && input.mouse_button_released?(RL::MouseButton::Left)

      is_clicked
    end

    # Toggle button that works with test input provider
    def self.toggle_button_with_input(x : Int32, y : Int32, width : Int32, height : Int32,
                                      text : String, active : Bool, input : Testing::InputProvider) : Bool
      bounds = RL::Rectangle.new(x: x.to_f32, y: y.to_f32, width: width.to_f32, height: height.to_f32)
      mouse_pos = input.get_mouse_position

      # Check mouse state
      is_hover = mouse_pos.x >= bounds.x && mouse_pos.x <= bounds.x + bounds.width &&
                 mouse_pos.y >= bounds.y && mouse_pos.y <= bounds.y + bounds.height
      is_clicked = is_hover && input.mouse_button_released?(RL::MouseButton::Left)

      is_clicked
    end

    # Text input that works with test input provider
    def self.text_input_with_input(x : Int32, y : Int32, width : Int32, height : Int32,
                                   text : String, active : Bool, input : Testing::InputProvider) : {String, Bool}
      bounds = RL::Rectangle.new(x: x.to_f32, y: y.to_f32, width: width.to_f32, height: height.to_f32)
      mouse_pos = input.get_mouse_position

      # Check if clicked
      if input.mouse_button_pressed?(RL::MouseButton::Left)
        active = mouse_pos.x >= bounds.x && mouse_pos.x <= bounds.x + bounds.width &&
                 mouse_pos.y >= bounds.y && mouse_pos.y <= bounds.y + bounds.height
      end

      # Handle text input if active
      new_text = text
      if active
        chars = input.get_typed_chars
        chars.each do |key|
          if key >= 32 && key <= 125
            new_text += key.chr
          end
        end

        # Handle backspace
        if input.key_pressed?(RL::KeyboardKey::Backspace) && !new_text.empty?
          new_text = new_text[0...-1]
        end

        # Handle enter
        if input.key_pressed?(RL::KeyboardKey::Enter)
          active = false
        end
      end

      {new_text, active}
    end

    # Slider that works with test input provider
    def self.slider_with_input(x : Int32, y : Int32, width : Int32, height : Int32,
                               value : Float32, min : Float32, max : Float32,
                               input : Testing::InputProvider) : Float32
      # Calculate handle position
      normalized = (value - min) / (max - min)
      handle_x = x + (normalized * width).to_i
      handle_radius = 8

      handle_bounds = RL::Rectangle.new(
        x: (handle_x - handle_radius).to_f32,
        y: (y + height // 2 - handle_radius).to_f32,
        width: (handle_radius * 2).to_f32,
        height: (handle_radius * 2).to_f32
      )

      mouse_pos = input.get_mouse_position
      is_hover = mouse_pos.x >= handle_bounds.x && mouse_pos.x <= handle_bounds.x + handle_bounds.width &&
                 mouse_pos.y >= handle_bounds.y && mouse_pos.y <= handle_bounds.y + handle_bounds.height

      # Handle dragging
      if is_hover && input.mouse_button_down?(RL::MouseButton::Left)
        new_x = (mouse_pos.x - x).clamp(0, width.to_f32)
        normalized = new_x / width
        value = min + normalized * (max - min)
      end

      value
    end

    # Check if point is in rectangle (utility)
    def self.point_in_rect?(point : RL::Vector2, rect : RL::Rectangle) : Bool
      point.x >= rect.x && point.x <= rect.x + rect.width &&
        point.y >= rect.y && point.y <= rect.y + rect.height
    end
  end
end
