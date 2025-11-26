# Testing extensions for AssetBrowser
# Reopens the class to add e2e testing support methods

module PaceEditor::UI
  class AssetBrowser
    # Expose current category for testing
    getter current_category : String

    # Update with a specific input provider (for testing)
    def update_with_input(input : Testing::InputProvider)
      return unless @state.current_mode.assets?

      screen_width = input.get_screen_width
      screen_height = input.get_screen_height

      browser_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      browser_y = Core::EditorWindow::MENU_HEIGHT
      browser_width = screen_width - Core::EditorWindow::TOOL_PALETTE_WIDTH - Core::EditorWindow::PROPERTY_PANEL_WIDTH
      browser_height = screen_height - Core::EditorWindow::MENU_HEIGHT

      # Handle category tab clicks
      handle_category_tabs_input(browser_x, browser_y, browser_width, input)

      # Handle asset grid clicks
      handle_asset_grid_input(browser_x, browser_y + 40, browser_width, browser_height - 40, input)

      # Handle import button
      import_button_y = browser_y + browser_height - 50
      if import_button_clicked?(browser_x + 10, import_button_y, input)
        import_asset
      end

      # Handle mouse wheel for scrolling
      wheel_move = input.get_mouse_wheel_move
      if wheel_move != 0
        @scroll_y = (@scroll_y - wheel_move * 30).clamp(0.0f32, 1000.0f32)
      end
    end

    private def handle_category_tabs_input(x : Int32, y : Int32, width : Int32, input : Testing::InputProvider)
      categories = ["backgrounds", "characters", "sounds", "music", "scripts"]
      tab_width = width // categories.size

      mouse_pos = input.get_mouse_position

      categories.each_with_index do |category, index|
        tab_x = x + index * tab_width

        if input.mouse_button_pressed?(RL::MouseButton::Left) &&
           mouse_pos.x >= tab_x && mouse_pos.x <= tab_x + tab_width &&
           mouse_pos.y >= y && mouse_pos.y <= y + 40
          @current_category = category
        end
      end
    end

    private def handle_asset_grid_input(x : Int32, y : Int32, width : Int32, height : Int32, input : Testing::InputProvider)
      return unless project = @state.current_project

      assets = get_current_assets(project)
      return if assets.empty?

      mouse_pos = input.get_mouse_position

      # Grid parameters
      item_size = 120
      items_per_row = (width - 20) // (item_size + 10)

      assets.each_with_index do |asset, index|
        row = index // items_per_row
        col = index % items_per_row

        item_x = x + 10 + col * (item_size + 10)
        item_y = y + 10 + row * (item_size + 30) - @scroll_y.to_i

        # Skip if out of view
        next if item_y + item_size < y || item_y > y + height

        # Check for click
        if input.mouse_button_pressed?(RL::MouseButton::Left) &&
           mouse_pos.x >= item_x && mouse_pos.x <= item_x + item_size &&
           mouse_pos.y >= item_y && mouse_pos.y <= item_y + item_size
          @state.select_object(asset)
        end
      end
    end

    private def import_button_clicked?(x : Int32, y : Int32, input : Testing::InputProvider) : Bool
      button_width = 100
      button_height = 30

      mouse_pos = input.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + button_width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + button_height

      is_hover && input.mouse_button_pressed?(RL::MouseButton::Left)
    end

    # Testing helper: get category tab position
    def get_category_tab_position(category : String) : {Int32, Int32}
      categories = ["backgrounds", "characters", "sounds", "music", "scripts"]
      index = categories.index(category) || 0

      screen_width = 1400 # Default test width
      browser_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      browser_width = screen_width - Core::EditorWindow::TOOL_PALETTE_WIDTH - Core::EditorWindow::PROPERTY_PANEL_WIDTH
      tab_width = browser_width // categories.size

      {browser_x + index * tab_width + tab_width // 2, Core::EditorWindow::MENU_HEIGHT + 20}
    end

    # Testing helper: get import button position
    def get_import_button_position(screen_height : Int32 = 900) : {Int32, Int32}
      browser_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      browser_height = screen_height - Core::EditorWindow::MENU_HEIGHT
      import_button_y = Core::EditorWindow::MENU_HEIGHT + browser_height - 50

      {browser_x + 10 + 50, import_button_y + 15}
    end

    # Testing helper: set current category directly
    def set_category_for_test(category : String)
      @current_category = category
    end

    # Testing helper: get asset item position by index
    def get_asset_item_position(index : Int32, screen_width : Int32 = 1400) : {Int32, Int32}
      browser_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      browser_y = Core::EditorWindow::MENU_HEIGHT + 40
      browser_width = screen_width - Core::EditorWindow::TOOL_PALETTE_WIDTH - Core::EditorWindow::PROPERTY_PANEL_WIDTH

      item_size = 120
      items_per_row = (browser_width - 20) // (item_size + 10)

      row = index // items_per_row
      col = index % items_per_row

      item_x = browser_x + 10 + col * (item_size + 10) + item_size // 2
      item_y = browser_y + 10 + row * (item_size + 30) - @scroll_y.to_i + item_size // 2

      {item_x, item_y}
    end
  end
end
