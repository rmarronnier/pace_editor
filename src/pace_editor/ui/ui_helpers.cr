# Enhanced UI helpers combining best practices from both editors
module PaceEditor
  module UI
    module UIHelpers
      # UI styling constants from point_click_engine editor
      PANEL_COLOR          = RL::Color.new(r: 40, g: 40, b: 40, a: 255)
      PANEL_BORDER_COLOR   = RL::Color.new(r: 80, g: 80, b: 80, a: 255)
      BUTTON_COLOR         = RL::Color.new(r: 60, g: 60, b: 60, a: 255)
      BUTTON_HOVER_COLOR   = RL::Color.new(r: 80, g: 80, b: 80, a: 255)
      BUTTON_PRESSED_COLOR = RL::Color.new(r: 100, g: 100, b: 100, a: 255)
      TEXT_COLOR           = RL::Color.new(r: 220, g: 220, b: 220, a: 255)
      SELECTED_COLOR       = RL::Color.new(r: 100, g: 150, b: 200, a: 255)

      # Draw a panel with optional title (from point_click_engine)
      def self.draw_panel(x : Int32, y : Int32, width : Int32, height : Int32, title : String? = nil)
        # Draw panel background
        RL.draw_rectangle(x, y, width, height, PANEL_COLOR)
        RL.draw_rectangle_lines(x, y, width, height, PANEL_BORDER_COLOR)

        # Draw title if provided
        if title
          title_height = 25
          RL.draw_rectangle(x, y, width, title_height, PANEL_BORDER_COLOR)
          RL.draw_text(title, x + 5, y + 5, 16, TEXT_COLOR)
          return y + title_height
        end

        y
      end

      # Enhanced button with better visual feedback (merged from both)
      def self.button(x : Int32, y : Int32, width : Int32, height : Int32, text : String,
                      icon : String? = nil, tooltip : String? = nil) : Bool
        bounds = RL::Rectangle.new(x: x.to_f32, y: y.to_f32, width: width.to_f32, height: height.to_f32)
        mouse_pos = RL.get_mouse_position

        # Check mouse state
        is_hover = mouse_pos.x >= bounds.x && mouse_pos.x <= bounds.x + bounds.width &&
                   mouse_pos.y >= bounds.y && mouse_pos.y <= bounds.y + bounds.height
        is_pressed = is_hover && RL.mouse_button_down?(RL::MouseButton::Left)
        is_clicked = is_hover && RL.mouse_button_released?(RL::MouseButton::Left)

        # Draw button
        color = if is_pressed
                  BUTTON_PRESSED_COLOR
                elsif is_hover
                  BUTTON_HOVER_COLOR
                else
                  BUTTON_COLOR
                end

        RL.draw_rectangle_rec(bounds, color)
        RL.draw_rectangle_lines_ex(bounds, 1, PANEL_BORDER_COLOR)

        # Draw icon if provided
        icon_offset = 0
        if icon
          icon_size = 16
          icon_x = x + 5
          icon_y = y + (height - icon_size) // 2
          draw_icon(icon_x, icon_y, icon_size, icon, TEXT_COLOR)
          icon_offset = icon_size + 10
        end

        # Draw text centered
        text_width = RL.measure_text(text, 14)
        text_x = x + icon_offset + (width - icon_offset - text_width) // 2
        text_y = y + (height - 14) // 2
        RL.draw_text(text, text_x, text_y, 14, TEXT_COLOR)

        # Draw tooltip if hovering
        if is_hover && tooltip
          draw_tooltip(mouse_pos.x.to_i, mouse_pos.y.to_i + 20, tooltip)
        end

        is_clicked
      end

      # Toggle button with active state
      def self.toggle_button(x : Int32, y : Int32, width : Int32, height : Int32,
                             text : String, active : Bool, icon : String? = nil) : Bool
        bounds = RL::Rectangle.new(x: x.to_f32, y: y.to_f32, width: width.to_f32, height: height.to_f32)
        mouse_pos = RL.get_mouse_position

        # Check mouse state
        is_hover = mouse_pos.x >= bounds.x && mouse_pos.x <= bounds.x + bounds.width &&
                   mouse_pos.y >= bounds.y && mouse_pos.y <= bounds.y + bounds.height
        is_clicked = is_hover && RL.mouse_button_released?(RL::MouseButton::Left)

        # Draw button
        color = if active
                  SELECTED_COLOR
                elsif is_hover
                  BUTTON_HOVER_COLOR
                else
                  BUTTON_COLOR
                end

        RL.draw_rectangle_rec(bounds, color)
        RL.draw_rectangle_lines_ex(bounds, active ? 2 : 1, PANEL_BORDER_COLOR)

        # Draw icon if provided
        icon_offset = 0
        if icon
          icon_size = 16
          icon_x = x + 5
          icon_y = y + (height - icon_size) // 2
          draw_icon(icon_x, icon_y, icon_size, icon, TEXT_COLOR)
          icon_offset = icon_size + 10
        end

        # Draw text centered
        text_width = RL.measure_text(text, 14)
        text_x = x + icon_offset + (width - icon_offset - text_width) // 2
        text_y = y + (height - 14) // 2
        RL.draw_text(text, text_x, text_y, 14, TEXT_COLOR)

        is_clicked
      end

      # Enhanced text input with better visual feedback
      def self.text_input(x : Int32, y : Int32, width : Int32, height : Int32,
                          text : String, active : Bool, placeholder : String? = nil) : {String, Bool}
        bounds = RL::Rectangle.new(x: x.to_f32, y: y.to_f32, width: width.to_f32, height: height.to_f32)
        mouse_pos = RL.get_mouse_position

        # Check if clicked
        if RL.mouse_button_pressed?(RL::MouseButton::Left)
          active = mouse_pos.x >= bounds.x && mouse_pos.x <= bounds.x + bounds.width &&
                   mouse_pos.y >= bounds.y && mouse_pos.y <= bounds.y + bounds.height
        end

        # Draw background
        bg_color = active ? BUTTON_HOVER_COLOR : BUTTON_COLOR
        RL.draw_rectangle_rec(bounds, bg_color)
        RL.draw_rectangle_lines_ex(bounds, 1, active ? SELECTED_COLOR : PANEL_BORDER_COLOR)

        # Handle text input if active
        new_text = text
        if active
          key = RL.get_char_pressed
          while key > 0
            if key >= 32 && key <= 125
              new_text += key.chr
            end
            key = RL.get_char_pressed
          end

          # Handle backspace
          if RL.key_pressed?(RL::KeyboardKey::Backspace) && !new_text.empty?
            new_text = new_text[0...-1]
          end

          # Handle enter
          if RL.key_pressed?(RL::KeyboardKey::Enter)
            active = false
          end
        end

        # Draw text or placeholder
        display_text = if new_text.empty? && !active && placeholder
                         placeholder
                       else
                         active ? "#{new_text}_" : new_text
                       end

        text_color = new_text.empty? && !active && placeholder ? RL::Color.new(r: 150, g: 150, b: 150, a: 255) : TEXT_COLOR

        RL.draw_text(display_text, x + 5, y + (height - 14) // 2, 14, text_color)

        {new_text, active}
      end

      # Label helper
      def self.label(x : Int32, y : Int32, text : String, size : Int32 = 14, color : RL::Color = TEXT_COLOR)
        RL.draw_text(text, x, y, size, color)
      end

      # Separator line
      def self.separator(x : Int32, y : Int32, width : Int32)
        RL.draw_line(x, y, x + width, y, PANEL_BORDER_COLOR)
      end

      # Dropdown menu (enhanced from pace_editor)
      def self.dropdown(x : Int32, y : Int32, width : Int32, height : Int32,
                        selected : String, options : Array(String), open : Bool) : {String, Bool}
        # Draw main button
        if button(x, y, width, height, selected, nil, nil)
          open = !open
        end

        # Draw dropdown arrow
        arrow_x = x + width - 20
        arrow_y = y + height // 2
        draw_icon(arrow_x, arrow_y - 4, 8, open ? "▲" : "▼", TEXT_COLOR)

        # Draw options if open
        if open
          option_y = y + height
          options.each do |option|
            if button(x, option_y, width, height, option)
              selected = option
              open = false
            end
            option_y += height
          end
        end

        {selected, open}
      end

      # Slider control
      def self.slider(x : Int32, y : Int32, width : Int32, height : Int32,
                      value : Float32, min : Float32, max : Float32, label : String? = nil) : Float32
        # Draw track
        track_y = y + height // 2 - 2
        RL.draw_rectangle(x, track_y, width, 4, BUTTON_COLOR)

        # Calculate handle position
        normalized = (value - min) / (max - min)
        handle_x = x + (normalized * width).to_i

        # Draw handle
        handle_radius = 8
        handle_bounds = RL::Rectangle.new(
          x: (handle_x - handle_radius).to_f32,
          y: (y + height // 2 - handle_radius).to_f32,
          width: (handle_radius * 2).to_f32,
          height: (handle_radius * 2).to_f32
        )

        mouse_pos = RL.get_mouse_position
        is_hover = mouse_pos.x >= handle_bounds.x && mouse_pos.x <= handle_bounds.x + handle_bounds.width &&
                   mouse_pos.y >= handle_bounds.y && mouse_pos.y <= handle_bounds.y + handle_bounds.height

        # Handle dragging
        if is_hover && RL.mouse_button_down?(RL::MouseButton::Left)
          new_x = (mouse_pos.x - x).clamp(0, width.to_f32)
          normalized = new_x / width
          value = min + normalized * (max - min)
        end

        # Draw handle
        handle_color = is_hover ? BUTTON_HOVER_COLOR : SELECTED_COLOR
        RL.draw_circle(handle_x, y + height // 2, handle_radius.to_f32, handle_color)

        # Draw label if provided
        if label
          label_text = "#{label}: #{value.round(2)}"
          RL.draw_text(label_text, x, y - 20, 12, TEXT_COLOR)
        end

        value
      end

      # Draw grid (from point_click_engine)
      def self.draw_grid(camera_pos : RL::Vector2, zoom : Float32, grid_size : Int32,
                         screen_width : Int32, screen_height : Int32)
        grid_color = RL::Color.new(r: 50, g: 50, b: 50, a: 100)

        # Calculate visible grid range
        start_x = (camera_pos.x / grid_size).to_i * grid_size
        start_y = (camera_pos.y / grid_size).to_i * grid_size
        end_x = ((camera_pos.x + screen_width / zoom) / grid_size).to_i * grid_size + grid_size
        end_y = ((camera_pos.y + screen_height / zoom) / grid_size).to_i * grid_size + grid_size

        # Draw vertical lines
        x = start_x
        while x <= end_x
          screen_x = ((x - camera_pos.x) * zoom).to_i
          RL.draw_line(screen_x, 0, screen_x, screen_height, grid_color)
          x += grid_size
        end

        # Draw horizontal lines
        y = start_y
        while y <= end_y
          screen_y = ((y - camera_pos.y) * zoom).to_i
          RL.draw_line(0, screen_y, screen_width, screen_y, grid_color)
          y += grid_size
        end
      end

      # Draw tooltip
      private def self.draw_tooltip(x : Int32, y : Int32, text : String)
        padding = 5
        text_width = RL.measure_text(text, 12)
        width = text_width + padding * 2
        height = 12 + padding * 2

        # Ensure tooltip stays on screen
        screen_width = RL.get_screen_width
        screen_height = RL.get_screen_height
        x = (x + width > screen_width) ? screen_width - width : x
        y = (y + height > screen_height) ? screen_height - height : y

        # Draw background
        RL.draw_rectangle(x, y, width, height, PANEL_COLOR)
        RL.draw_rectangle_lines(x, y, width, height, PANEL_BORDER_COLOR)

        # Draw text
        RL.draw_text(text, x + padding, y + padding, 12, TEXT_COLOR)
      end

      # Simple icon drawing (can be extended with actual icons)
      private def self.draw_icon(x : Int32, y : Int32, size : Int32, icon : String, color : RL::Color)
        # For now, just draw the icon text
        # In a real implementation, this would draw actual icons
        RL.draw_text(icon, x, y, size, color)
      end
    end
  end
end
