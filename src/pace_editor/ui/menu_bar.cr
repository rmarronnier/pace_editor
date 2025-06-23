module PaceEditor::UI
  # Menu bar with file operations and mode switching
  class MenuBar
    def initialize(@state : Core::EditorState)
      @show_new_dialog = false
      @show_open_dialog = false
      @show_about_dialog = false
      @show_scene_dialog = false
      @show_file_menu = false
      @show_edit_menu = false
      @show_view_menu = false
      @new_project_name = ""
      @new_project_path = ""
    end

    def update
      # Close menus when clicking elsewhere (but not on the menus themselves)
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        mouse_pos = RL.get_mouse_position

        # Don't close if clicking on a dropdown menu
        in_file_dropdown = @show_file_menu && mouse_pos.x >= 10 && mouse_pos.x <= 150 &&
                           mouse_pos.y >= Core::EditorWindow::MENU_HEIGHT && mouse_pos.y <= Core::EditorWindow::MENU_HEIGHT + 120
        in_edit_dropdown = @show_edit_menu && mouse_pos.x >= 60 && mouse_pos.x <= 180 &&
                           mouse_pos.y >= Core::EditorWindow::MENU_HEIGHT && mouse_pos.y <= Core::EditorWindow::MENU_HEIGHT + 96
        in_view_dropdown = @show_view_menu && mouse_pos.x >= 110 && mouse_pos.x <= 250 &&
                           mouse_pos.y >= Core::EditorWindow::MENU_HEIGHT && mouse_pos.y <= Core::EditorWindow::MENU_HEIGHT + 72

        # Only close if clicking outside menu area and not in any dropdown
        if mouse_pos.y > Core::EditorWindow::MENU_HEIGHT && !in_file_dropdown && !in_edit_dropdown && !in_view_dropdown
          @show_file_menu = false
          @show_edit_menu = false
          @show_view_menu = false
        end
      end
    end

    def draw_background
      # Draw menu bar background
      RL.draw_rectangle(0, 0, Core::EditorWindow::WINDOW_WIDTH, Core::EditorWindow::MENU_HEIGHT,
        RL::Color.new(r: 60, g: 60, b: 60, a: 255))
    end

    def draw_content
      x = 10

      # File menu
      if draw_menu_item("File", x, 5, @show_file_menu)
        @show_file_menu = !@show_file_menu
        @show_edit_menu = false
        @show_view_menu = false
      end
      x += 50

      # Edit menu
      if draw_menu_item("Edit", x, 5, @show_edit_menu)
        @show_edit_menu = !@show_edit_menu
        @show_file_menu = false
        @show_view_menu = false
      end
      x += 50

      # View menu
      if draw_menu_item("View", x, 5, @show_view_menu)
        @show_view_menu = !@show_view_menu
        @show_file_menu = false
        @show_edit_menu = false
      end
      x += 50

      # Mode buttons
      x += 30
      draw_mode_buttons(x)

      # Help menu (right-aligned)
      help_x = Core::EditorWindow::WINDOW_WIDTH - 60
      if draw_menu_item("Help", help_x, 5)
        @show_about_dialog = true
      end

      # Draw dropdowns LAST (on top)
      x = 10
      if @show_file_menu
        draw_file_dropdown(x, Core::EditorWindow::MENU_HEIGHT)
      end
      x += 50
      if @show_edit_menu
        draw_edit_dropdown(x, Core::EditorWindow::MENU_HEIGHT)
      end
      x += 50
      if @show_view_menu
        draw_view_dropdown(x, Core::EditorWindow::MENU_HEIGHT)
      end

      # Draw dialogs LAST
      draw_dialogs
    end

    def draw
      draw_background
      draw_content
    end

    private def draw_mode_buttons(start_x : Int32)
      modes = [
        {EditorMode::Scene, "Scene"},
        {EditorMode::Character, "Character"},
        {EditorMode::Hotspot, "Hotspot"},
        {EditorMode::Dialog, "Dialog"},
        {EditorMode::Assets, "Assets"},
        {EditorMode::Project, "Project"},
      ]

      x = start_x
      modes.each do |mode, label|
        is_active = @state.current_mode == mode
        color = is_active ? RL::YELLOW : RL::LIGHTGRAY

        if draw_button(label, x, 2, color)
          @state.current_mode = mode
        end

        x += RL.measure_text(label, 16) + 20
      end
    end

    private def draw_menu_item(text : String, x : Int32, y : Int32, is_open : Bool = false) : Bool
      width = RL.measure_text(text, 16) + 10
      height = 20

      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      if is_open || is_hover
        RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 80, g: 80, b: 80, a: 255))
      end

      RL.draw_text(text, x + 5, y + 2, 16, RL::WHITE)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def draw_file_dropdown(x : Int32, y : Int32)
      dropdown_width = 140
      dropdown_height = 216  # Increased for scene menu items

      # Dropdown background
      RL.draw_rectangle(x, y, dropdown_width, dropdown_height, RL::Color.new(r: 70, g: 70, b: 70, a: 255))
      RL.draw_rectangle_lines(x, y, dropdown_width, dropdown_height, RL::LIGHTGRAY)

      item_height = 24
      current_y = y + 4

      # New Project
      if draw_dropdown_item("New Project", x, current_y, dropdown_width, item_height, "Ctrl+N")
        @show_new_dialog = true
        @show_file_menu = false
      end
      current_y += item_height

      # Open Project
      if draw_dropdown_item("Open Project", x, current_y, dropdown_width, item_height, "Ctrl+O")
        @show_open_dialog = true
        @show_file_menu = false
      end
      current_y += item_height

      # Save Project
      if draw_dropdown_item("Save Project", x, current_y, dropdown_width, item_height, "Ctrl+S")
        @state.save_project
        @show_file_menu = false
      end
      current_y += item_height

      # Separator
      RL.draw_line(x + 5, current_y + 8, x + dropdown_width - 5, current_y + 8, RL::GRAY)
      current_y += 16

      # New Scene (only enabled if project is loaded)
      project_loaded = !@state.current_project.nil?
      if draw_dropdown_item("New Scene", x, current_y, dropdown_width, item_height, "", project_loaded)
        create_new_scene
        @show_file_menu = false
      end
      current_y += item_height

      # Load Scene (only enabled if project is loaded)
      if draw_dropdown_item("Load Scene", x, current_y, dropdown_width, item_height, "", project_loaded)
        @show_scene_dialog = true
        @show_file_menu = false
      end
      current_y += item_height

      # Save Scene (only enabled if scene is loaded)
      scene_loaded = !@state.current_scene.nil?
      if draw_dropdown_item("Save Scene", x, current_y, dropdown_width, item_height, "Ctrl+S", scene_loaded)
        save_current_scene
        @show_file_menu = false
      end
      current_y += item_height

      # Separator
      RL.draw_line(x + 5, current_y + 8, x + dropdown_width - 5, current_y + 8, RL::GRAY)
      current_y += 16

      # Exit
      if draw_dropdown_item("Exit", x, current_y, dropdown_width, item_height, "Alt+F4")
        # Actually exit the application
        exit(0)
      end
    end

    private def draw_edit_dropdown(x : Int32, y : Int32)
      dropdown_width = 120
      dropdown_height = 96

      RL.draw_rectangle(x, y, dropdown_width, dropdown_height, RL::Color.new(r: 70, g: 70, b: 70, a: 255))
      RL.draw_rectangle_lines(x, y, dropdown_width, dropdown_height, RL::LIGHTGRAY)

      item_height = 24
      current_y = y + 4

      # Undo
      enabled = @state.can_undo?
      if draw_dropdown_item("Undo", x, current_y, dropdown_width, item_height, "Ctrl+Z", enabled)
        @state.undo
        @show_edit_menu = false
      end
      current_y += item_height

      # Redo
      enabled = @state.can_redo?
      if draw_dropdown_item("Redo", x, current_y, dropdown_width, item_height, "Ctrl+Y", enabled)
        @state.redo
        @show_edit_menu = false
      end
      current_y += item_height

      # Separator
      RL.draw_line(x + 5, current_y + 8, x + dropdown_width - 5, current_y + 8, RL::GRAY)
      current_y += 16

      # Delete
      if draw_dropdown_item("Delete", x, current_y, dropdown_width, item_height, "Del")
        # Delete selected objects
        @show_edit_menu = false
      end
    end

    private def draw_view_dropdown(x : Int32, y : Int32)
      dropdown_width = 140
      dropdown_height = 72

      RL.draw_rectangle(x, y, dropdown_width, dropdown_height, RL::Color.new(r: 70, g: 70, b: 70, a: 255))
      RL.draw_rectangle_lines(x, y, dropdown_width, dropdown_height, RL::LIGHTGRAY)

      item_height = 24
      current_y = y + 4

      # Show Grid
      checkbox_text = @state.show_grid ? "✓ Show Grid" : "  Show Grid"
      if draw_dropdown_item(checkbox_text, x, current_y, dropdown_width, item_height, "G")
        @state.show_grid = !@state.show_grid
        @show_view_menu = false
      end
      current_y += item_height

      # Show Hotspots
      checkbox_text = @state.show_hotspots ? "✓ Show Hotspots" : "  Show Hotspots"
      if draw_dropdown_item(checkbox_text, x, current_y, dropdown_width, item_height, "H")
        @state.show_hotspots = !@state.show_hotspots
        @show_view_menu = false
      end
      current_y += item_height

      # Reset Camera
      if draw_dropdown_item("Reset Camera", x, current_y, dropdown_width, item_height, "R")
        @state.reset_camera
        @show_view_menu = false
      end
    end

    private def draw_dropdown_item(text : String, x : Int32, y : Int32, width : Int32, height : Int32, shortcut : String = "", enabled : Bool = true) : Bool
      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      if is_hover && enabled
        RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 100, g: 100, b: 100, a: 255))
      end

      text_color = enabled ? RL::WHITE : RL::GRAY
      RL.draw_text(text, x + 8, y + 4, 14, text_color)

      # Draw shortcut if provided
      if !shortcut.empty?
        shortcut_width = RL.measure_text(shortcut, 12)
        RL.draw_text(shortcut, x + width - shortcut_width - 8, y + 6, 12, RL::LIGHTGRAY)
      end

      is_hover && enabled && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def create_new_scene
      return unless project = @state.current_project

      # Generate unique scene name
      scene_count = 1
      scene_name = "scene_#{scene_count}"
      while project.scenes.includes?("#{scene_name}.yml")
        scene_count += 1
        scene_name = "scene_#{scene_count}"
      end

      # Create a simple default scene
      scene = PointClickEngine::Scenes::Scene.new(scene_name)
      scene.hotspots = [] of PointClickEngine::Scenes::Hotspot
      scene.characters = [] of PointClickEngine::Characters::Character
      scene.scale = 1.0_f32
      scene.enable_pathfinding = true
      scene.navigation_cell_size = 16
      
      # Set it as the current scene
      @state.current_scene = scene
      
      # Save scene to file
      scene_path = File.join(project.scenes_path, "#{scene_name}.yml")
      if PaceEditor::IO::SceneIO.save_scene(scene, scene_path)
        # Add scene to project
        project.add_scene("#{scene_name}.yml")
        
        # Save project to persist scene list
        project.save
        
        # Switch to scene mode
        @state.current_mode = EditorMode::Scene
        
        puts "Created and saved new scene: #{scene_name}"
      else
        puts "Failed to save new scene"
      end
    end

    private def save_current_scene
      return unless project = @state.current_project
      return unless scene = @state.current_scene
      
      # Build scene file path
      scene_filename = "#{scene.name}.yml"
      scene_path = File.join(project.scenes_path, scene_filename)
      
      # Save the scene
      if PaceEditor::IO::SceneIO.save_scene(scene, scene_path)
        puts "Saved scene: #{scene.name}"
        @state.is_dirty = false
      else
        puts "Failed to save scene: #{scene.name}"
      end
    end

    private def draw_button(text : String, x : Int32, y : Int32, color : RL::Color) : Bool
      width = RL.measure_text(text, 16) + 10
      height = 25

      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      bg_color = is_hover ? RL::Color.new(r: 80, g: 80, b: 80, a: 255) : RL::Color.new(r: 70, g: 70, b: 70, a: 255)

      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)
      RL.draw_text(text, x + 5, y + 4, 16, color)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def draw_dialogs
      if @show_new_dialog
        draw_new_project_dialog
      elsif @show_open_dialog
        draw_open_project_dialog
      elsif @show_scene_dialog
        draw_scene_dialog
      elsif @show_about_dialog
        draw_about_dialog
      end
    end

    private def draw_new_project_dialog
      # Simple modal dialog for new project
      dialog_width = 500
      dialog_height = 250
      dialog_x = (Core::EditorWindow::WINDOW_WIDTH - dialog_width) // 2
      dialog_y = (Core::EditorWindow::WINDOW_HEIGHT - dialog_height) // 2

      # Modal overlay
      RL.draw_rectangle(0, 0, Core::EditorWindow::WINDOW_WIDTH, Core::EditorWindow::WINDOW_HEIGHT,
        RL::Color.new(r: 0, g: 0, b: 0, a: 128))

      # Dialog background
      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height,
        RL::Color.new(r: 80, g: 80, b: 80, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      # Title
      RL.draw_text("New Project", dialog_x + 20, dialog_y + 20, 20, RL::WHITE)

      # Project name input
      RL.draw_text("Name:", dialog_x + 20, dialog_y + 60, 16, RL::WHITE)
      name_input_rect = RL::Rectangle.new(
        x: (dialog_x + 100).to_f, y: (dialog_y + 58).to_f,
        width: 350.0f32, height: 25.0f32
      )
      draw_text_input(name_input_rect, @new_project_name)

      # Handle name input
      @new_project_name = handle_text_input(@new_project_name)

      # Show where project will be created
      sanitized_name = @new_project_name.downcase.gsub(/[^a-z0-9_\s]/, "").gsub(/\s+/, "_")
      preview_path = sanitized_name.empty? ? "project_name" : sanitized_name

      RL.draw_text("Location:", dialog_x + 20, dialog_y + 100, 16, RL::WHITE)
      RL.draw_text("./projects/#{preview_path}/", dialog_x + 100, dialog_y + 102, 14, RL::LIGHTGRAY)

      # Instructions
      RL.draw_text("Project will be created in the projects folder with its own directory.",
        dialog_x + 20, dialog_y + 130, 12, RL::LIGHTGRAY)
      RL.draw_text("This includes subfolders for assets, scenes, scripts, dialogs, and exports.",
        dialog_x + 20, dialog_y + 150, 12, RL::LIGHTGRAY)

      # Buttons
      create_enabled = !@new_project_name.strip.empty?
      create_color = create_enabled ? RL::GREEN : RL::GRAY

      if draw_button("Create", dialog_x + dialog_width - 180, dialog_y + dialog_height - 40, create_color) && create_enabled
        create_new_project
      end

      if draw_button("Cancel", dialog_x + dialog_width - 80, dialog_y + dialog_height - 40, RL::RED)
        @show_new_dialog = false
      end

      # Handle Escape key
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        @show_new_dialog = false
      end
    end

    private def draw_text_input(rect : RL::Rectangle, text : String)
      # Input field background
      RL.draw_rectangle_rec(rect, RL::Color.new(r: 60, g: 60, b: 60, a: 255))
      RL.draw_rectangle_lines_ex(rect, 1, RL::LIGHTGRAY)

      # Text
      if !text.empty?
        RL.draw_text(text, rect.x.to_i + 5, rect.y.to_i + 5, 14, RL::WHITE)
      end

      # Cursor (simple blinking)
      if (RL.get_time * 2).to_i % 2 == 0
        cursor_x = rect.x.to_i + 5 + RL.measure_text(text, 14)
        RL.draw_line(cursor_x, rect.y.to_i + 3, cursor_x, rect.y.to_i + rect.height.to_i - 3, RL::WHITE)
      end
    end

    private def handle_text_input(text : String) : String
      # Very basic text input handling
      # In a real implementation, you'd want more sophisticated input handling

      # Get character input
      key = RL.get_char_pressed
      while key > 0
        if key >= 32 && key <= 126 && text.size < 50 # Printable ASCII characters
          text += key.chr
        end
        key = RL.get_char_pressed
      end

      # Handle backspace
      if RL.key_pressed?(RL::KeyboardKey::Backspace) && !text.empty?
        text = text[0..-2]
      end

      text
    end

    private def draw_open_project_dialog
      dialog_width = 600
      dialog_height = 400
      dialog_x = (Core::EditorWindow::WINDOW_WIDTH - dialog_width) // 2
      dialog_y = (Core::EditorWindow::WINDOW_HEIGHT - dialog_height) // 2

      # Modal overlay
      RL.draw_rectangle(0, 0, Core::EditorWindow::WINDOW_WIDTH, Core::EditorWindow::WINDOW_HEIGHT,
        RL::Color.new(r: 0, g: 0, b: 0, a: 128))

      # Dialog background
      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height,
        RL::Color.new(r: 80, g: 80, b: 80, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      # Title
      RL.draw_text("Open Project", dialog_x + 20, dialog_y + 20, 20, RL::WHITE)

      # Simple file list (look for .pace files in projects directory)
      y = dialog_y + 60
      RL.draw_text("Available Projects:", dialog_x + 20, y, 16, RL::WHITE)
      y += 30

      # List project files from projects directory
      project_files = find_pace_files_in_projects

      if project_files.empty?
        RL.draw_text("No projects found in the projects folder.", dialog_x + 20, y, 14, RL::LIGHTGRAY)
        y += 25
        RL.draw_text("Create a new project to get started!", dialog_x + 20, y, 12, RL::LIGHTGRAY)
      else
        project_files.each do |file|
          if draw_file_item(file, dialog_x + 20, y, dialog_width - 40)
            # Load this project
            if @state.load_project(file)
              @show_open_dialog = false
            end
          end
          y += 25
        end
      end

      # Buttons
      if draw_button("Cancel", dialog_x + dialog_width - 80, dialog_y + dialog_height - 40, RL::RED)
        @show_open_dialog = false
      end

      # Handle Escape key
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        @show_open_dialog = false
      end
    end

    private def find_pace_files : Array(String)
      files = [] of String
      begin
        Dir.glob("*.pace").each do |file|
          files << file
        end
        # Also check common subdirectories
        Dir.glob("*/*.pace").each do |file|
          files << file
        end
      rescue
        # If there's an error reading directory, just return empty array
      end
      files[0..4] # Limit to first 5 files
    end

    private def find_pace_files_in_projects : Array(String)
      files = [] of String
      projects_dir = "./projects"

      begin
        return files unless Dir.exists?(projects_dir)

        # Look for .pace files in project subdirectories
        Dir.glob(File.join(projects_dir, "**", "*.pace")).each do |file|
          files << file
        end
      rescue
        # If there's an error reading directory, just return empty array
      end
      files[0..10] # Limit to first 10 files
    end

    private def draw_file_item(filename : String, x : Int32, y : Int32, width : Int32) : Bool
      height = 20

      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      if is_hover
        RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 100, g: 100, b: 100, a: 255))
      end

      # File icon
      RL.draw_text("📁", x + 5, y + 2, 14, RL::YELLOW)

      # File name
      display_name = filename.size > 50 ? "..." + filename[-47..-1] : filename
      RL.draw_text(display_name, x + 25, y + 3, 14, RL::WHITE)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def draw_about_dialog
      dialog_width = 400
      dialog_height = 200
      dialog_x = (Core::EditorWindow::WINDOW_WIDTH - dialog_width) // 2
      dialog_y = (Core::EditorWindow::WINDOW_HEIGHT - dialog_height) // 2

      # Modal overlay
      RL.draw_rectangle(0, 0, Core::EditorWindow::WINDOW_WIDTH, Core::EditorWindow::WINDOW_HEIGHT,
        RL::Color.new(r: 0, g: 0, b: 0, a: 128))

      # Dialog background
      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height,
        RL::Color.new(r: 80, g: 80, b: 80, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      # Content
      RL.draw_text("PACE Editor", dialog_x + 20, dialog_y + 20, 20, RL::WHITE)
      RL.draw_text("Point & Click Adventure Creator", dialog_x + 20, dialog_y + 50, 14, RL::LIGHTGRAY)
      RL.draw_text("Version #{PaceEditor::VERSION}", dialog_x + 20, dialog_y + 70, 14, RL::LIGHTGRAY)

      RL.draw_text("Built with Crystal and Raylib", dialog_x + 20, dialog_y + 100, 12, RL::LIGHTGRAY)
      RL.draw_text("Create point-and-click adventure games", dialog_x + 20, dialog_y + 120, 12, RL::LIGHTGRAY)

      # Close button
      if draw_button("Close", dialog_x + dialog_width - 80, dialog_y + dialog_height - 40, RL::WHITE)
        @show_about_dialog = false
      end

      # Handle Escape key
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        @show_about_dialog = false
      end
    end

    def show_new_project_dialog
      @show_new_dialog = true
      @new_project_name = ""
      @new_project_path = "" # Not used anymore but kept for compatibility
    end

    def show_open_project_dialog
      @show_open_dialog = true
    end

    private def draw_scene_dialog
      return unless project = @state.current_project
      
      dialog_width = 600
      dialog_height = 400
      dialog_x = (Core::EditorWindow::WINDOW_WIDTH - dialog_width) // 2
      dialog_y = (Core::EditorWindow::WINDOW_HEIGHT - dialog_height) // 2

      # Modal overlay
      RL.draw_rectangle(0, 0, Core::EditorWindow::WINDOW_WIDTH, Core::EditorWindow::WINDOW_HEIGHT,
        RL::Color.new(r: 0, g: 0, b: 0, a: 128))

      # Dialog background
      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height,
        RL::Color.new(r: 80, g: 80, b: 80, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      # Title
      RL.draw_text("Load Scene", dialog_x + 20, dialog_y + 20, 20, RL::WHITE)

      # List scenes
      y = dialog_y + 60
      
      # Get scene files
      scene_files = project.scenes.select { |f| f.ends_with?(".yml") }
      
      if scene_files.empty?
        RL.draw_text("No scenes found. Create a new scene from the File menu.", dialog_x + 20, y, 14, RL::LIGHTGRAY)
      else
        scene_files.each do |scene_file|
          scene_name = scene_file.chomp(".yml")
          
          # Highlight current scene
          is_current = @state.current_scene && @state.current_scene.not_nil!.name == scene_name
          text_color = is_current ? RL::GREEN : RL::WHITE
          
          if draw_file_item(scene_name, dialog_x + 20, y, dialog_width - 40)
            # Load this scene
            load_scene(scene_file)
            @show_scene_dialog = false
          end
          
          # Show current indicator
          if is_current
            RL.draw_text("(current)", dialog_x + dialog_width - 100, y + 2, 12, RL::GREEN)
          end
          
          y += 25
        end
      end

      # Cancel button
      if draw_button("Cancel", dialog_x + dialog_width - 80, dialog_y + dialog_height - 40, RL::RED)
        @show_scene_dialog = false
      end

      # Handle Escape key
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        @show_scene_dialog = false
      end
    end

    private def load_scene(scene_filename : String)
      return unless project = @state.current_project
      
      scene_path = File.join(project.scenes_path, scene_filename)
      
      if scene = PaceEditor::IO::SceneIO.load_scene(scene_path)
        @state.current_scene = scene
        @state.current_mode = EditorMode::Scene
        puts "Loaded scene: #{scene.name}"
      else
        puts "Failed to load scene: #{scene_filename}"
      end
    end

    private def create_new_project
      # Create project in proper projects folder structure
      name = @new_project_name.empty? ? "New Game" : @new_project_name

      # Create projects directory if it doesn't exist
      projects_dir = "./projects"
      Dir.mkdir_p(projects_dir) unless Dir.exists?(projects_dir)

      # Create project folder inside projects directory
      sanitized_name = name.downcase.gsub(/[^a-z0-9_\s]/, "").gsub(/\s+/, "_")
      project_path = File.join(projects_dir, sanitized_name)

      # Handle case where project already exists
      if Dir.exists?(project_path)
        counter = 1
        original_path = project_path
        while Dir.exists?(project_path)
          project_path = "#{original_path}_#{counter}"
          counter += 1
        end
      end

      if @state.create_new_project(name, project_path)
        @show_new_dialog = false
      end
    end
  end
end
