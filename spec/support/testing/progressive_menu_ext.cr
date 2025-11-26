# Testing extensions for ProgressiveMenu
# Reopens the class to add e2e testing support methods

module PaceEditor::UI
  class ProgressiveMenu
    # Handle input with a specific input provider (for testing)
    def handle_input_with_test(input : Testing::InputProvider) : Bool
      mouse_pos = input.get_mouse_position
      mouse_clicked = input.mouse_button_pressed?(RL::MouseButton::Left)

      # Ensure menu bar rect has proper width (normally set in draw)
      if @menu_bar_rect.width == 0
        @menu_bar_rect.width = input.get_screen_width.to_f32
      end

      # If we have an active menu and clicked outside both menu bar and dropdown, close it
      if active = @active_menu
        if mouse_clicked
          in_menu_bar = PaceEditor::Constants.point_in_rect?(mouse_pos, @menu_bar_rect)
          in_dropdown = in_dropdown_area?(mouse_pos, active)
          unless in_menu_bar || in_dropdown
            close_menu
            return true
          end
        end
      end

      # Check dropdown item clicks FIRST (dropdown is below menu bar)
      if active = @active_menu
        if section = @menu_items[active]?
          if handle_dropdown_click_with_input(section, mouse_pos, mouse_clicked)
            return true
          end
        end
      end

      # Check if mouse is over menu bar
      return false unless PaceEditor::Constants.point_in_rect?(mouse_pos, @menu_bar_rect)

      # Check menu section clicks
      x_offset = 10.0_f32
      @menu_items.each do |name, section|
        section_rect = RL::Rectangle.new(x: x_offset, y: 0.0_f32, width: section.calculate_width, height: MENU_HEIGHT.to_f32)

        if PaceEditor::Constants.point_in_rect?(mouse_pos, section_rect)
          @hover_item = name

          if mouse_clicked && section.visible?(@editor_state, @ui_state)
            toggle_menu(name)
            return true
          end
        end

        x_offset += section.calculate_width + 20.0_f32
      end

      # Close menu if clicked in menu bar but not on a section
      if mouse_clicked
        close_menu
      end

      false
    end

    private def handle_dropdown_click_with_input(section : MenuSection, mouse_pos : RL::Vector2, clicked : Bool) : Bool
      return false unless section.dropdown_visible && clicked

      # Check each visible item
      y_offset = MENU_HEIGHT.to_f32 + 5.0_f32
      section.visible_items(@editor_state, @ui_state).each do |item|
        item_rect = RL::Rectangle.new(x: section.x + 5.0_f32, y: y_offset, width: 190.0_f32, height: 20.0_f32)

        if PaceEditor::Constants.point_in_rect?(mouse_pos, item_rect)
          if item.is_a?(MenuItem)
            menu_item = item.as(MenuItem)
            if menu_item.visible?(@editor_state, @ui_state)
              menu_item.action.call
              close_menu
              return true
            end
          end
        end

        y_offset += 25.0_f32
      end

      false
    end

    # Helper: check if mouse is in dropdown area
    private def in_dropdown_area?(mouse_pos : RL::Vector2, menu_name : String) : Bool
      section = @menu_items[menu_name]?
      return false unless section
      return false unless section.dropdown_visible

      # Calculate dropdown rect
      dropdown_x = section.x
      dropdown_y = MENU_HEIGHT.to_f32
      dropdown_width = 200.0_f32
      visible_items_count = section.visible_items(@editor_state, @ui_state).size
      dropdown_height = visible_items_count * 25.0_f32 + 10.0_f32

      dropdown_rect = RL::Rectangle.new(
        x: dropdown_x,
        y: dropdown_y,
        width: dropdown_width,
        height: dropdown_height
      )

      PaceEditor::Constants.point_in_rect?(mouse_pos, dropdown_rect)
    end

    # Testing helper: get menu section position
    def get_menu_section_position(section_name : String) : {Float32, Float32}
      x_offset = 10.0_f32
      @menu_items.each do |name, section|
        if name == section_name
          return {x_offset + section.calculate_width / 2, MENU_HEIGHT.to_f32 / 2}
        end
        x_offset += section.calculate_width + 20.0_f32
      end
      {10.0_f32, 15.0_f32}
    end

    # Testing helper: get dropdown item position
    def get_dropdown_item_position(section_name : String, item_id : String) : {Float32, Float32}?
      section = @menu_items[section_name]?
      return nil unless section

      y_offset = MENU_HEIGHT.to_f32 + 5.0_f32
      section.visible_items(@editor_state, @ui_state).each do |item|
        if item.is_a?(MenuItem)
          menu_item = item.as(MenuItem)
          if menu_item.id == item_id
            return {section.x + 100.0_f32, y_offset + 10.0_f32}
          end
        end
        y_offset += 25.0_f32
      end

      nil
    end

    # Testing helper: check if menu is open
    def menu_open?(section_name : String) : Bool
      @active_menu == section_name
    end

    # Testing helper: open a specific menu
    def open_menu_for_test(section_name : String)
      @active_menu = section_name

      # Calculate and set x positions for all sections (normally done during draw)
      x_offset = 10.0_f32
      @menu_items.each do |name, section|
        section.update_layout(x_offset, 0.0_f32)
        if name == section_name
          section.dropdown_visible = true
        end
        x_offset += section.calculate_width + 20.0_f32
      end
    end

    # Testing helper: close any open menu
    def close_menu_for_test
      close_menu
    end

    # Testing helper: get list of menu sections
    def menu_section_names : Array(String)
      @menu_items.keys
    end

    # Testing helper: get list of items in a section
    def menu_items_for_section(section_name : String) : Array(String)
      section = @menu_items[section_name]?
      return [] of String unless section

      section.items.compact_map do |item|
        if item.is_a?(MenuItem)
          item.as(MenuItem).id
        else
          nil
        end
      end
    end
  end
end
