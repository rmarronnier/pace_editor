module PaceEditor::UI
  # Asset browser for managing and previewing game assets
  class AssetBrowser
    def initialize(@state : Core::EditorState)
      @current_category = "backgrounds"
      @scroll_y = 0.0f32
    end

    def update
      # Handle scrolling and selection
    end

    def draw
      return unless @state.current_mode.assets?

      # Asset browser takes over the main viewport when in assets mode
      browser_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      browser_y = Core::EditorWindow::MENU_HEIGHT
      browser_width = Core::EditorWindow::WINDOW_WIDTH - Core::EditorWindow::TOOL_PALETTE_WIDTH - Core::EditorWindow::PROPERTY_PANEL_WIDTH
      browser_height = Core::EditorWindow::WINDOW_HEIGHT - Core::EditorWindow::MENU_HEIGHT

      # Draw background
      RL.draw_rectangle(browser_x, browser_y, browser_width, browser_height,
        RL::Color.new(r: 40, g: 40, b: 40, a: 255))

      # Draw category tabs
      draw_category_tabs(browser_x, browser_y, browser_width)

      # Draw asset grid
      draw_asset_grid(browser_x, browser_y + 40, browser_width, browser_height - 40)
    end

    private def draw_category_tabs(x : Int32, y : Int32, width : Int32)
      categories = ["backgrounds", "characters", "sounds", "music", "scripts"]
      tab_width = width // categories.size

      categories.each_with_index do |category, index|
        tab_x = x + index * tab_width
        is_active = @current_category == category

        # Tab background
        bg_color = is_active ? RL::Color.new(r: 70, g: 70, b: 70, a: 255) : RL::Color.new(r: 50, g: 50, b: 50, a: 255)

        RL.draw_rectangle(tab_x, y, tab_width, 40, bg_color)
        RL.draw_rectangle_lines(tab_x, y, tab_width, 40, RL::GRAY)

        # Tab text
        text_color = is_active ? RL::WHITE : RL::LIGHTGRAY
        text_width = RL.measure_text(category.capitalize, 14)
        text_x = tab_x + (tab_width - text_width) // 2
        RL.draw_text(category.capitalize, text_x, y + 13, 14, text_color)

        # Check for tab click
        mouse_pos = RL.get_mouse_position
        if mouse_pos.x >= tab_x && mouse_pos.x <= tab_x + tab_width &&
           mouse_pos.y >= y && mouse_pos.y <= y + 40 &&
           RL.mouse_button_pressed?(RL::MouseButton::Left)
          @current_category = category
        end
      end
    end

    private def draw_asset_grid(x : Int32, y : Int32, width : Int32, height : Int32)
      return unless project = @state.current_project

      assets = get_current_assets(project)

      if assets.empty?
        draw_empty_state(x, y, width, height)
        return
      end

      # Grid parameters
      item_size = 120
      items_per_row = (width - 20) // (item_size + 10)

      # Draw assets
      assets.each_with_index do |asset, index|
        row = index // items_per_row
        col = index % items_per_row

        item_x = x + 10 + col * (item_size + 10)
        item_y = y + 10 + row * (item_size + 30) - @scroll_y.to_i

        # Skip if out of view
        next if item_y + item_size < y || item_y > y + height

        draw_asset_item(asset, item_x, item_y, item_size)
      end

      # Draw import button
      import_button_y = y + height - 50
      if draw_import_button(x + 10, import_button_y)
        import_asset
      end
    end

    private def get_current_assets(project : Core::Project) : Array(String)
      case @current_category
      when "backgrounds"
        project.backgrounds
      when "characters"
        project.characters
      when "sounds"
        project.sounds
      when "music"
        project.music
      when "scripts"
        project.scripts
      else
        [] of String
      end
    end

    private def draw_asset_item(asset : String, x : Int32, y : Int32, size : Int32)
      # Asset thumbnail background
      RL.draw_rectangle(x, y, size, size, RL::Color.new(r: 60, g: 60, b: 60, a: 255))
      RL.draw_rectangle_lines(x, y, size, size, RL::GRAY)

      # Asset preview (simplified)
      case @current_category
      when "backgrounds", "characters"
        # Try to load and display image preview
        draw_image_preview(asset, x, y, size)
      when "sounds", "music"
        # Show audio icon
        RL.draw_text("♪", x + size//2 - 10, y + size//2 - 10, 20, RL::WHITE)
      when "scripts"
        # Show script icon
        RL.draw_text("{}", x + size//2 - 10, y + size//2 - 10, 20, RL::WHITE)
      end

      # Asset name
      asset_name = File.basename(asset, File.extname(asset))
      name_to_show = asset_name.size > 15 ? asset_name[0...12] + "..." : asset_name
      name_width = RL.measure_text(name_to_show, 12)
      name_x = x + (size - name_width) // 2

      # Name background
      RL.draw_rectangle(x, y + size - 20, size, 20, RL::Color.new(r: 0, g: 0, b: 0, a: 150))
      RL.draw_text(name_to_show, name_x, y + size - 15, 12, RL::WHITE)

      # Handle click
      mouse_pos = RL.get_mouse_position
      if mouse_pos.x >= x && mouse_pos.x <= x + size &&
         mouse_pos.y >= y && mouse_pos.y <= y + size &&
         RL.mouse_button_pressed?(RL::MouseButton::Left)
        @state.select_object(asset)
      end
    end

    private def draw_image_preview(asset : String, x : Int32, y : Int32, size : Int32)
      # For now, just show a placeholder
      # In a real implementation, we'd load and scale the actual image
      RL.draw_rectangle(x + 10, y + 10, size - 20, size - 40, RL::Color.new(r: 100, g: 100, b: 100, a: 255))
      RL.draw_text("IMG", x + size//2 - 15, y + size//2 - 10, 14, RL::WHITE)
    end

    private def draw_empty_state(x : Int32, y : Int32, width : Int32, height : Int32)
      message = "No #{@current_category} assets"
      message_width = RL.measure_text(message, 18)
      message_x = x + (width - message_width) // 2
      message_y = y + height // 2 - 40

      RL.draw_text(message, message_x, message_y, 18, RL::LIGHTGRAY)

      hint = "Click Import to add assets"
      hint_width = RL.measure_text(hint, 14)
      hint_x = x + (width - hint_width) // 2
      RL.draw_text(hint, hint_x, message_y + 30, 14, RL::GRAY)
    end

    private def draw_import_button(x : Int32, y : Int32) : Bool
      button_width = 100
      button_height = 30

      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + button_width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + button_height

      bg_color = is_hover ? RL::Color.new(r: 80, g: 120, b: 80, a: 255) : RL::Color.new(r: 60, g: 100, b: 60, a: 255)

      RL.draw_rectangle(x, y, button_width, button_height, bg_color)
      RL.draw_rectangle_lines(x, y, button_width, button_height, RL::WHITE)

      text = "Import"
      text_width = RL.measure_text(text, 14)
      text_x = x + (button_width - text_width) // 2
      RL.draw_text(text, text_x, y + 8, 14, RL::WHITE)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def import_asset
      return unless project = @state.current_project

      # Define supported file extensions by category
      supported_extensions = case @current_category
                             when "backgrounds", "characters"
                               [".png", ".jpg", ".jpeg", ".bmp", ".tga"]
                             when "sounds", "music"
                               [".wav", ".ogg", ".mp3"]
                             when "scripts"
                               [".lua", ".cr"]
                             else
                               [] of String
                             end

      if supported_extensions.empty?
        puts "No supported file types for category: #{@current_category}"
        return
      end

      # Simple file import dialog using system commands
      # This is a basic implementation - a full implementation would use native file dialogs
      puts "Opening file dialog for #{@current_category}..."
      puts "Supported formats: #{supported_extensions.join(", ")}"

      # For now, implement a basic file finder that looks in common directories
      import_from_common_directories(project, supported_extensions)
    end

    private def import_from_common_directories(project : Core::Project, extensions : Array(String))
      # Look for assets in common directories relative to the project
      search_paths = [
        File.join(project.project_path, "assets"),
        File.join(project.project_path, "resources"),
        File.join(project.project_path, @current_category),
        File.join(Dir.current, "assets"),
        File.join(Dir.current, "sample_assets"),
      ]

      found_files = [] of String

      search_paths.each do |search_path|
        next unless Dir.exists?(search_path)

        Dir.glob(File.join(search_path, "**/*")).each do |file_path|
          next unless File.file?(file_path)

          extension = File.extname(file_path).downcase
          if extensions.includes?(extension)
            found_files << file_path
          end
        end
      end

      if found_files.empty?
        puts "No #{@current_category} assets found in common directories."
        puts "Try placing assets in: #{File.join(project.project_path, "assets")}"
        return
      end

      # Show found files and import the first few
      puts "Found #{found_files.size} potential assets:"
      found_files[0, 5].each_with_index do |file, index|
        filename = File.basename(file)
        puts "  #{index + 1}. #{filename}"

        # Import this file
        import_file_to_project(file, project)
      end

      if found_files.size > 5
        puts "  ... and #{found_files.size - 5} more files"
      end
    end

    private def import_file_to_project(source_path : String, project : Core::Project)
      filename = File.basename(source_path)

      # Determine target directory based on category
      target_dir = case @current_category
                   when "backgrounds"
                     project.backgrounds_path
                   when "characters"
                     project.characters_path
                   when "sounds"
                     project.sounds_path
                   when "music"
                     project.music_path
                   when "scripts"
                     project.scripts_path
                   else
                     File.join(project.project_path, @current_category)
                   end

      # Create target directory if it doesn't exist
      Dir.mkdir_p(target_dir) unless Dir.exists?(target_dir)

      target_path = File.join(target_dir, filename)

      # Check if file already exists
      if File.exists?(target_path)
        puts "Asset already exists: #{filename}"
        return
      end

      begin
        # Copy file to project
        File.copy(source_path, target_path)
        puts "Imported asset: #{filename} -> #{File.basename(target_dir)}"

        # Add to project's asset list
        case @current_category
        when "backgrounds"
          project.backgrounds << target_path unless project.backgrounds.includes?(target_path)
        when "characters"
          project.characters << target_path unless project.characters.includes?(target_path)
        when "sounds"
          project.sounds << target_path unless project.sounds.includes?(target_path)
        when "music"
          project.music << target_path unless project.music.includes?(target_path)
        when "scripts"
          project.scripts << target_path unless project.scripts.includes?(target_path)
        end

        # Mark project as dirty to trigger save
        @state.is_dirty = true
      rescue ex
        puts "Error importing asset #{filename}: #{ex.message}"
      end
    end
  end
end
