module PaceEditor::UI
  # Menu bar with file operations and mode switching
  class MenuBar
    def initialize(@state : Core::EditorState)
      @show_new_dialog = false
      @show_open_dialog = false
      @show_about_dialog = false
      @new_project_name = ""
      @new_project_path = ""
    end

    def update
      # Dialog state management
    end

    def draw
      # Draw menu bar background
      RL.draw_rectangle(0, 0, Core::EditorWindow::WINDOW_WIDTH, Core::EditorWindow::MENU_HEIGHT,
        RL::Color.new(r: 60, g: 60, b: 60, a: 255))

      x = 10

      # File menu
      if draw_menu_item("File", x, 5)
        # File menu implementation would go here
      end
      x += 50

      # Edit menu
      if draw_menu_item("Edit", x, 5)
        # Edit menu implementation
      end
      x += 50

      # View menu
      if draw_menu_item("View", x, 5)
        # View menu implementation
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

      # Draw dialogs
      draw_dialogs
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

    private def draw_menu_item(text : String, x : Int32, y : Int32) : Bool
      width = RL.measure_text(text, 16) + 10
      height = 20

      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      if is_hover
        RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 80, g: 80, b: 80, a: 255))
      end

      RL.draw_text(text, x + 5, y + 2, 16, RL::WHITE)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
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
      elsif @show_about_dialog
        draw_about_dialog
      end
    end

    private def draw_new_project_dialog
      # Simple modal dialog for new project
      dialog_width = 400
      dialog_height = 200
      dialog_x = (Core::EditorWindow::WINDOW_WIDTH - dialog_width) // 2
      dialog_y = (Core::EditorWindow::WINDOW_HEIGHT - dialog_height) // 2

      # Dialog background
      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height,
        RL::Color.new(r: 80, g: 80, b: 80, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      # Title
      RL.draw_text("New Project", dialog_x + 20, dialog_y + 20, 20, RL::WHITE)

      # Project name input
      RL.draw_text("Name:", dialog_x + 20, dialog_y + 60, 16, RL::WHITE)

      # Project path input
      RL.draw_text("Path:", dialog_x + 20, dialog_y + 100, 16, RL::WHITE)

      # Buttons
      if draw_button("Create", dialog_x + dialog_width - 180, dialog_y + dialog_height - 40, RL::GREEN)
        create_new_project
      end

      if draw_button("Cancel", dialog_x + dialog_width - 80, dialog_y + dialog_height - 40, RL::RED)
        @show_new_dialog = false
      end
    end

    private def draw_open_project_dialog
      # File browser dialog would go here
      # For now, just a simple cancel button
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        @show_open_dialog = false
      end
    end

    private def draw_about_dialog
      dialog_width = 300
      dialog_height = 150
      dialog_x = (Core::EditorWindow::WINDOW_WIDTH - dialog_width) // 2
      dialog_y = (Core::EditorWindow::WINDOW_HEIGHT - dialog_height) // 2

      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height,
        RL::Color.new(r: 80, g: 80, b: 80, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      RL.draw_text("PACE Editor", dialog_x + 20, dialog_y + 20, 20, RL::WHITE)
      RL.draw_text("Point & Click Adventure Creator", dialog_x + 20, dialog_y + 50, 14, RL::LIGHTGRAY)
      RL.draw_text("Version #{PaceEditor::VERSION}", dialog_x + 20, dialog_y + 70, 14, RL::LIGHTGRAY)

      if draw_button("Close", dialog_x + dialog_width - 80, dialog_y + dialog_height - 40, RL::WHITE)
        @show_about_dialog = false
      end
    end

    def show_new_project_dialog
      @show_new_dialog = true
      @new_project_name = ""
      @new_project_path = ""
    end

    def show_open_project_dialog
      @show_open_dialog = true
    end

    private def create_new_project
      # For now, create with default values
      name = @new_project_name.empty? ? "New Game" : @new_project_name
      path = @new_project_path.empty? ? "./new_game" : @new_project_path

      if @state.create_new_project(name, path)
        @show_new_dialog = false
      end
    end
  end
end
