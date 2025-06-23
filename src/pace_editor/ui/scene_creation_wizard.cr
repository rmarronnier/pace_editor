require "raylib-cr"
require "../core/editor_state"

module PaceEditor::UI
  class SceneCreationWizard
    property visible : Bool = false

    @step : Int32 = 1
    @max_steps : Int32 = 4
    @scene_name : String = ""
    @scene_template : String = "empty"
    @selected_background : String? = nil
    @scene_width : Int32 = 1024
    @scene_height : Int32 = 768
    @background_list : Array(String) = [] of String
    @preview_texture : RL::Texture2D? = nil

    def initialize(@state : Core::EditorState)
      refresh_background_list
    end

    def show
      @visible = true
      @step = 1
      @scene_name = ""
      @scene_template = "empty"
      @selected_background = nil
      @scene_width = 1024
      @scene_height = 768
      refresh_background_list
    end

    def hide
      @visible = false
      unload_preview_texture
    end

    def update
      return unless @visible
      handle_input
    end

    def draw
      return unless @visible

      # Dialog background
      dialog_width = 800
      dialog_height = 600
      dialog_x = (Core::EditorWindow::WINDOW_WIDTH - dialog_width) // 2
      dialog_y = (Core::EditorWindow::WINDOW_HEIGHT - dialog_height) // 2

      # Modal background
      RL.draw_rectangle(0, 0, Core::EditorWindow::WINDOW_WIDTH, Core::EditorWindow::WINDOW_HEIGHT,
        RL::Color.new(r: 0, g: 0, b: 0, a: 128))

      # Dialog box
      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height,
        RL::Color.new(r: 50, g: 50, b: 50, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      # Title and progress
      draw_header(dialog_x, dialog_y, dialog_width)

      # Step content
      content_y = dialog_y + 80
      content_height = dialog_height - 160

      case @step
      when 1
        draw_step_1_scene_info(dialog_x, content_y, dialog_width, content_height)
      when 2
        draw_step_2_template_selection(dialog_x, content_y, dialog_width, content_height)
      when 3
        draw_step_3_background_selection(dialog_x, content_y, dialog_width, content_height)
      when 4
        draw_step_4_scene_settings(dialog_x, content_y, dialog_width, content_height)
      end

      # Navigation buttons
      button_y = dialog_y + dialog_height - 60
      draw_navigation_buttons(dialog_x, button_y, dialog_width)
    end

    private def draw_header(x : Int32, y : Int32, width : Int32)
      # Title
      title = "Create New Scene"
      RL.draw_text(title, x + 20, y + 20, 20, RL::WHITE)

      # Progress indicator
      progress_text = "Step #{@step} of #{@max_steps}"
      progress_width = RL.measure_text(progress_text, 14)
      RL.draw_text(progress_text, x + width - progress_width - 20, y + 25, 14, RL::LIGHTGRAY)

      # Progress bar
      bar_y = y + 50
      bar_width = width - 40
      bar_height = 6

      # Background
      RL.draw_rectangle(x + 20, bar_y, bar_width, bar_height,
        RL::Color.new(r: 80, g: 80, b: 80, a: 255))

      # Progress
      progress_fill = (bar_width * @step) // @max_steps
      RL.draw_rectangle(x + 20, bar_y, progress_fill, bar_height,
        RL::Color.new(r: 100, g: 150, b: 100, a: 255))

      # Step indicators
      (1..@max_steps).each do |step|
        indicator_x = x + 20 + ((bar_width * (step - 1)) // (@max_steps - 1)) - 4
        indicator_color = step <= @step ? RL::WHITE : RL::GRAY
        RL.draw_circle(indicator_x + 4, bar_y + 3, 4, indicator_color)
      end
    end

    private def draw_step_1_scene_info(x : Int32, y : Int32, width : Int32, height : Int32)
      # Step title
      RL.draw_text("Scene Information", x + 20, y + 20, 18, RL::WHITE)

      current_y = y + 60

      # Scene name input
      RL.draw_text("Scene Name:", x + 40, current_y, 14, RL::WHITE)
      current_y += 25

      # Name input field
      input_width = width - 80
      draw_text_input("scene_name", @scene_name, x + 40, current_y, input_width, 30)
      current_y += 50

      # Description
      RL.draw_text("Enter a name for your new scene. This will be used as the filename", x + 40, current_y, 12, RL::LIGHTGRAY)
      RL.draw_text("and internal identifier for the scene.", x + 40, current_y + 16, 12, RL::LIGHTGRAY)
      current_y += 50

      # Example names
      RL.draw_text("Examples:", x + 40, current_y, 14, RL::YELLOW)
      current_y += 25
      examples = ["main_menu", "forest_path", "castle_entrance", "wizard_tower", "final_boss"]
      examples.each_with_index do |example, index|
        if draw_clickable_text("• #{example}", x + 60, current_y + index * 20, 12, RL::LIGHTGRAY)
          @scene_name = example
        end
      end
    end

    private def draw_step_2_template_selection(x : Int32, y : Int32, width : Int32, height : Int32)
      # Step title
      RL.draw_text("Choose Scene Template", x + 20, y + 20, 18, RL::WHITE)

      current_y = y + 60

      templates = [
        {
          id:          "empty",
          name:        "Empty Scene",
          description: "Start with a blank scene and add objects manually",
        },
        {
          id:          "room",
          name:        "Room Template",
          description: "Indoor scene with door hotspot and basic lighting",
        },
        {
          id:          "outdoor",
          name:        "Outdoor Template",
          description: "Outdoor scene with path hotspots and natural elements",
        },
        {
          id:          "menu",
          name:        "Menu Template",
          description: "UI scene with buttons and navigation elements",
        },
      ]

      templates.each_with_index do |template, index|
        template_y = current_y + index * 80
        is_selected = @scene_template == template[:id]

        # Template card
        card_color = is_selected ? RL::Color.new(r: 70, g: 100, b: 70, a: 255) : RL::Color.new(r: 60, g: 60, b: 60, a: 255)
        border_color = is_selected ? RL::GREEN : RL::GRAY

        RL.draw_rectangle(x + 40, template_y, width - 80, 70, card_color)
        RL.draw_rectangle_lines(x + 40, template_y, width - 80, 70, border_color)

        # Template info
        RL.draw_text(template[:name], x + 60, template_y + 15, 16, RL::WHITE)
        RL.draw_text(template[:description], x + 60, template_y + 40, 12, RL::LIGHTGRAY)

        # Check for click
        mouse_pos = RL.get_mouse_position
        if mouse_pos.x >= x + 40 && mouse_pos.x <= x + width - 40 &&
           mouse_pos.y >= template_y && mouse_pos.y <= template_y + 70 &&
           RL.mouse_button_pressed?(RL::MouseButton::Left)
          @scene_template = template[:id]
        end
      end
    end

    private def draw_step_3_background_selection(x : Int32, y : Int32, width : Int32, height : Int32)
      # Step title
      RL.draw_text("Select Background", x + 20, y + 20, 18, RL::WHITE)

      current_y = y + 60

      # Option to skip
      if draw_clickable_text("○ No background (skip)", x + 40, current_y, 14, @selected_background.nil? ? RL::GREEN : RL::WHITE)
        @selected_background = nil
        unload_preview_texture
      end
      current_y += 30

      # Available backgrounds
      if @background_list.empty?
        RL.draw_text("No backgrounds available.", x + 40, current_y, 14, RL::LIGHTGRAY)
        current_y += 20

        # Import button
        if draw_button("Import Background...", x + 40, current_y, 200, 30)
          if window = @state.editor_window
            window.show_background_import_dialog
          end
        end
      else
        RL.draw_text("Available backgrounds:", x + 40, current_y, 14, RL::WHITE)
        current_y += 30

        # Background list
        list_height = 200
        draw_background_list(x + 40, current_y, width - 80, list_height)
        current_y += list_height + 20

        # Preview area
        if bg = @selected_background
          draw_background_preview(x + 40, current_y, width - 80, 120, bg)
        end
      end
    end

    private def draw_step_4_scene_settings(x : Int32, y : Int32, width : Int32, height : Int32)
      # Step title
      RL.draw_text("Scene Settings", x + 20, y + 20, 18, RL::WHITE)

      current_y = y + 60

      # Scene dimensions
      RL.draw_text("Scene Dimensions:", x + 40, current_y, 14, RL::WHITE)
      current_y += 30

      # Width
      RL.draw_text("Width:", x + 60, current_y, 12, RL::LIGHTGRAY)
      draw_number_input("width", @scene_width, x + 120, current_y, 100, 25)
      current_y += 35

      # Height
      RL.draw_text("Height:", x + 60, current_y, 12, RL::LIGHTGRAY)
      draw_number_input("height", @scene_height, x + 120, current_y, 100, 25)
      current_y += 50

      # Common presets
      RL.draw_text("Presets:", x + 60, current_y, 12, RL::LIGHTGRAY)
      current_y += 25

      presets = [
        {name: "1024x768 (4:3)", width: 1024, height: 768},
        {name: "1280x720 (16:9)", width: 1280, height: 720},
        {name: "1920x1080 (16:9)", width: 1920, height: 1080},
      ]

      presets.each_with_index do |preset, index|
        if draw_clickable_text("• #{preset[:name]}", x + 80, current_y + index * 20, 12, RL::LIGHTGRAY)
          @scene_width = preset[:width]
          @scene_height = preset[:height]
        end
      end
      current_y += 80

      # Summary
      RL.draw_text("Summary:", x + 40, current_y, 14, RL::YELLOW)
      current_y += 25
      RL.draw_text("Name: #{@scene_name}", x + 60, current_y, 12, RL::WHITE)
      current_y += 18
      RL.draw_text("Template: #{@scene_template.capitalize}", x + 60, current_y, 12, RL::WHITE)
      current_y += 18
      bg_text = @selected_background || "None"
      RL.draw_text("Background: #{bg_text}", x + 60, current_y, 12, RL::WHITE)
      current_y += 18
      RL.draw_text("Size: #{@scene_width}x#{@scene_height}", x + 60, current_y, 12, RL::WHITE)
    end

    private def draw_text_input(id : String, value : String, x : Int32, y : Int32, width : Int32, height : Int32)
      # Input background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 40, g: 40, b: 40, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Text
      RL.draw_text(value, x + 10, y + (height - 14) // 2, 14, RL::WHITE)

      # Cursor (simple implementation)
      if @step == 1 # Only show cursor on name input step
        cursor_x = x + 10 + RL.measure_text(value, 14)
        RL.draw_line(cursor_x, y + 5, cursor_x, y + height - 5, RL::WHITE)
      end
    end

    private def draw_number_input(id : String, value : Int32, x : Int32, y : Int32, width : Int32, height : Int32)
      # Input background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 40, g: 40, b: 40, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Text
      RL.draw_text(value.to_s, x + 10, y + (height - 12) // 2, 12, RL::WHITE)
    end

    private def draw_background_list(x : Int32, y : Int32, width : Int32, height : Int32)
      # List background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 30, g: 30, b: 30, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Draw backgrounds
      item_height = 25
      visible_items = height // item_height

      @background_list.each_with_index do |bg, index|
        break if index >= visible_items

        item_y = y + index * item_height
        is_selected = @selected_background == bg

        # Highlight selected
        if is_selected
          RL.draw_rectangle(x + 2, item_y, width - 4, item_height,
            RL::Color.new(r: 70, g: 130, b: 180, a: 255))
        end

        # Background name
        RL.draw_text("○ #{bg}", x + 10, item_y + 5, 12, RL::WHITE)

        # Check for click
        mouse_pos = RL.get_mouse_position
        if mouse_pos.x >= x && mouse_pos.x <= x + width &&
           mouse_pos.y >= item_y && mouse_pos.y <= item_y + item_height &&
           RL.mouse_button_pressed?(RL::MouseButton::Left)
          @selected_background = bg
          load_background_preview(bg)
        end
      end
    end

    private def draw_background_preview(x : Int32, y : Int32, width : Int32, height : Int32, background : String)
      # Preview background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 20, g: 20, b: 20, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      if preview = @preview_texture
        # Scale image to fit preview area
        scale = [width.to_f / preview.width, height.to_f / preview.height].min
        scaled_width = (preview.width * scale).to_i
        scaled_height = (preview.height * scale).to_i

        # Center the image
        preview_x = x + (width - scaled_width) // 2
        preview_y = y + (height - scaled_height) // 2

        dest_rect = RL::Rectangle.new(
          x: preview_x.to_f32,
          y: preview_y.to_f32,
          width: scaled_width.to_f32,
          height: scaled_height.to_f32
        )

        source_rect = RL::Rectangle.new(
          x: 0.0_f32,
          y: 0.0_f32,
          width: preview.width.to_f32,
          height: preview.height.to_f32
        )

        RL.draw_texture_pro(preview, source_rect, dest_rect, RL::Vector2.new(0.0_f32, 0.0_f32), 0.0_f32, RL::WHITE)

        # Image info
        info_text = "#{preview.width}x#{preview.height}"
        RL.draw_text(info_text, x + 10, y + height - 20, 12, RL::LIGHTGRAY)
      else
        RL.draw_text("Preview: #{background}", x + 10, y + 10, 14, RL::GRAY)
      end
    end

    private def draw_navigation_buttons(x : Int32, y : Int32, width : Int32)
      button_width = 100
      button_height = 30

      # Cancel button
      if draw_button("Cancel", x + 20, y, button_width, button_height, RL::LIGHTGRAY)
        hide
      end

      # Previous button (only if not on first step)
      if @step > 1
        prev_x = x + width // 2 - button_width - 10
        if draw_button("Previous", prev_x, y, button_width, button_height)
          @step -= 1
        end
      end

      # Next/Create button
      next_x = x + width // 2 + 10
      if @step < @max_steps
        next_enabled = can_proceed_to_next_step?
        next_color = next_enabled ? RL::WHITE : RL::GRAY
        if draw_button("Next", next_x, y, button_width, button_height, next_color) && next_enabled
          @step += 1
          if @step == 3
            refresh_background_list
          end
        end
      else
        create_enabled = can_create_scene?
        create_color = create_enabled ? RL::GREEN : RL::GRAY
        if draw_button("Create", next_x, y, button_width, button_height, create_color) && create_enabled
          create_scene
        end
      end
    end

    private def draw_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32, color : RL::Color = RL::WHITE) : Bool
      # Button background
      bg_color = RL::Color.new(r: 60, g: 60, b: 60, a: 255)
      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, color)

      # Button text
      text_width = RL.measure_text(text, 14)
      text_x = x + (width - text_width) // 2
      text_y = y + (height - 14) // 2
      RL.draw_text(text, text_x, text_y, 14, color)

      # Check if clicked
      mouse_pos = RL.get_mouse_position
      if mouse_pos.x >= x && mouse_pos.x <= x + width &&
         mouse_pos.y >= y && mouse_pos.y <= y + height
        if RL.mouse_button_pressed?(RL::MouseButton::Left)
          return true
        end
      end

      false
    end

    private def draw_clickable_text(text : String, x : Int32, y : Int32, size : Int32, color : RL::Color) : Bool
      RL.draw_text(text, x, y, size, color)

      text_width = RL.measure_text(text, size)
      mouse_pos = RL.get_mouse_position

      if mouse_pos.x >= x && mouse_pos.x <= x + text_width &&
         mouse_pos.y >= y && mouse_pos.y <= y + size
        if RL.mouse_button_pressed?(RL::MouseButton::Left)
          return true
        end
      end

      false
    end

    private def handle_input
      # Handle text input for scene name
      if @step == 1
        handle_scene_name_input
      elsif @step == 4
        handle_scene_settings_input
      end

      # Handle escape key
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        hide
      end
    end

    private def handle_scene_name_input
      # Handle character input
      key = RL.get_char_pressed
      while key > 0
        if key >= 32 && key <= 126 && @scene_name.size < 30
          char = key.chr
          # Only allow valid filename characters
          if char.ascii_alphanumeric? || char == '_' || char == '-'
            @scene_name += char
          end
        end
        key = RL.get_char_pressed
      end

      # Handle backspace
      if RL.key_pressed?(RL::KeyboardKey::Backspace) && !@scene_name.empty?
        @scene_name = @scene_name[0...-1]
      end
    end

    private def handle_scene_settings_input
      # Simple number input handling - in a full implementation you'd have better input fields
      if RL.key_pressed?(RL::KeyboardKey::Up)
        @scene_height += 16
      elsif RL.key_pressed?(RL::KeyboardKey::Down)
        @scene_height = [@scene_height - 16, 240].max
      end
    end

    private def can_proceed_to_next_step? : Bool
      case @step
      when 1
        !@scene_name.empty? && (@scene_name =~ /^[a-zA-Z0-9_-]+$/) != nil
      when 2
        !@scene_template.empty?
      when 3
        true # Background is optional
      else
        false
      end
    end

    private def can_create_scene? : Bool
      !@scene_name.empty? && @scene_width > 0 && @scene_height > 0
    end

    private def refresh_background_list
      return unless project = @state.current_project

      @background_list.clear
      bg_dir = File.join(project.project_path, "assets", "backgrounds")

      if Dir.exists?(bg_dir)
        Dir.glob(File.join(bg_dir, "*")).each do |file_path|
          if File.file?(file_path)
            ext = File.extname(file_path).downcase
            if [".png", ".jpg", ".jpeg", ".bmp", ".gif"].includes?(ext)
              @background_list << File.basename(file_path)
            end
          end
        end
      end
    end

    private def load_background_preview(background : String)
      return unless project = @state.current_project

      unload_preview_texture

      bg_path = File.join(project.project_path, "assets", "backgrounds", background)
      if File.exists?(bg_path)
        begin
          @preview_texture = RL.load_texture(bg_path)
        rescue
          @preview_texture = nil
        end
      end
    end

    private def unload_preview_texture
      if preview = @preview_texture
        RL.unload_texture(preview)
        @preview_texture = nil
      end
    end

    private def create_scene
      return unless project = @state.current_project
      return if @scene_name.empty?

      # Create new scene
      scene = PointClickEngine::Scenes::Scene.new(@scene_name)
      scene.scale = 1.0_f32

      # Set background if selected
      if bg = @selected_background
        scene.background_path = "backgrounds/#{bg}"
      end

      # Apply template
      apply_scene_template(scene)

      # Set as current scene
      @state.current_scene = scene
      @state.current_mode = PaceEditor::EditorMode::Scene

      # Save scene file
      scenes_dir = File.join(project.project_path, "scenes")
      Dir.mkdir_p(scenes_dir) unless Dir.exists?(scenes_dir)

      scene_file = File.join(scenes_dir, "#{@scene_name}.yml")
      File.write(scene_file, scene.to_yaml)

      # Add to project scenes list
      project.scenes << @scene_name unless project.scenes.includes?(@scene_name)

      # Close wizard
      hide

      puts "Scene '#{@scene_name}' created successfully!"
    end

    private def apply_scene_template(scene : PointClickEngine::Scenes::Scene)
      case @scene_template
      when "room"
        apply_room_template(scene)
      when "outdoor"
        apply_outdoor_template(scene)
      when "menu"
        apply_menu_template(scene)
        # "empty" template needs no additional setup
      end
    end

    private def apply_room_template(scene : PointClickEngine::Scenes::Scene)
      # Add a door hotspot
      door = PointClickEngine::Scenes::Hotspot.new(
        "door",
        RL::Vector2.new(100.0_f32, 200.0_f32),
        RL::Vector2.new(80.0_f32, 160.0_f32)
      )
      door.description = "A wooden door"
      door.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
      scene.add_hotspot(door)

      # Add window hotspot
      window = PointClickEngine::Scenes::Hotspot.new(
        "window",
        RL::Vector2.new(300.0_f32, 100.0_f32),
        RL::Vector2.new(120.0_f32, 80.0_f32)
      )
      window.description = "A bright window"
      window.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Look
      scene.add_hotspot(window)
    end

    private def apply_outdoor_template(scene : PointClickEngine::Scenes::Scene)
      # Add path hotspots
      left_path = PointClickEngine::Scenes::Hotspot.new(
        "left_path",
        RL::Vector2.new(50.0_f32, 400.0_f32),
        RL::Vector2.new(100.0_f32, 100.0_f32)
      )
      left_path.description = "Path to the left"
      left_path.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
      scene.add_hotspot(left_path)

      right_path = PointClickEngine::Scenes::Hotspot.new(
        "right_path",
        RL::Vector2.new(500.0_f32, 400.0_f32),
        RL::Vector2.new(100.0_f32, 100.0_f32)
      )
      right_path.description = "Path to the right"
      right_path.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
      scene.add_hotspot(right_path)

      # Add a tree or landmark
      tree = PointClickEngine::Scenes::Hotspot.new(
        "old_tree",
        RL::Vector2.new(250.0_f32, 150.0_f32),
        RL::Vector2.new(80.0_f32, 200.0_f32)
      )
      tree.description = "An ancient oak tree"
      tree.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Look
      scene.add_hotspot(tree)
    end

    private def apply_menu_template(scene : PointClickEngine::Scenes::Scene)
      # Add menu button hotspots
      start_button = PointClickEngine::Scenes::Hotspot.new(
        "start_button",
        RL::Vector2.new(350.0_f32, 200.0_f32),
        RL::Vector2.new(150.0_f32, 50.0_f32)
      )
      start_button.description = "Start New Game"
      start_button.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
      scene.add_hotspot(start_button)

      load_button = PointClickEngine::Scenes::Hotspot.new(
        "load_button",
        RL::Vector2.new(350.0_f32, 280.0_f32),
        RL::Vector2.new(150.0_f32, 50.0_f32)
      )
      load_button.description = "Load Game"
      load_button.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
      scene.add_hotspot(load_button)

      exit_button = PointClickEngine::Scenes::Hotspot.new(
        "exit_button",
        RL::Vector2.new(350.0_f32, 360.0_f32),
        RL::Vector2.new(150.0_f32, 50.0_f32)
      )
      exit_button.description = "Exit Game"
      exit_button.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
      scene.add_hotspot(exit_button)
    end
  end
end
