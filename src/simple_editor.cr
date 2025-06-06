# Simple PACE Editor
require "point_click_engine"

# Note: RL alias is already defined in point_click_engine

# Simple editor state
class EditorState
  property current_mode : String = "Scene"
  property project_name : String = "New Game"
  property show_grid : Bool = true
  property zoom : Float32 = 1.0f32
  property camera_x : Float32 = 0.0f32
  property camera_y : Float32 = 0.0f32
end

# Main editor
class SimpleEditor
  WINDOW_WIDTH   = 1200
  WINDOW_HEIGHT  =  800
  MENU_HEIGHT    =   30
  TOOLBAR_HEIGHT =   40

  def initialize
    @state = EditorState.new
    @show_about = false
  end

  def run
    RL.init_window(WINDOW_WIDTH, WINDOW_HEIGHT, "PACE - Point & Click Adventure Creator Editor")
    RL.set_target_fps(60)

    while !RL.close_window?
      update
      draw
    end

    RL.close_window
  end

  private def update
    # Handle keyboard shortcuts
    if RL::KeyboardKey::LeftControl.down? || RL::KeyboardKey::RightControl.down?
      if RL::KeyboardKey::N.pressed?
        puts "New project shortcut"
      elsif RL::KeyboardKey::O.pressed?
        puts "Open project shortcut"
      elsif RL::KeyboardKey::S.pressed?
        puts "Save project shortcut"
      end
    end

    # Tool shortcuts
    if RL::KeyboardKey::One.pressed?
      @state.current_mode = "Scene"
    elsif RL::KeyboardKey::Two.pressed?
      @state.current_mode = "Character"
    elsif RL::KeyboardKey::Three.pressed?
      @state.current_mode = "Hotspot"
    elsif RL::KeyboardKey::Four.pressed?
      @state.current_mode = "Dialog"
    end

    # View controls
    if RL::KeyboardKey::G.pressed?
      @state.show_grid = !@state.show_grid
    end
  end

  private def draw
    RL.begin_drawing
    RL.clear_background(RL::Color.new(r: 50, g: 50, b: 50, a: 255))

    # Draw menu bar
    draw_menu_bar

    # Draw toolbar
    draw_toolbar

    # Draw main content area
    draw_main_area

    # Draw status bar
    draw_status_bar

    # Draw about dialog if shown
    if @show_about
      draw_about_dialog
    end

    RL.end_drawing
  end

  private def draw_menu_bar
    # Menu bar background
    RL.draw_rectangle(0, 0, WINDOW_WIDTH, MENU_HEIGHT, RL::Color.new(r: 70, g: 70, b: 70, a: 255))

    mouse_pos = RL.get_mouse_position

    # File menu
    if draw_menu_button("File", 10, 5, 50, 20, mouse_pos)
      puts "File menu clicked"
    end

    # Edit menu
    if draw_menu_button("Edit", 70, 5, 50, 20, mouse_pos)
      puts "Edit menu clicked"
    end

    # View menu
    if draw_menu_button("View", 130, 5, 50, 20, mouse_pos)
      puts "View menu clicked"
    end

    # Help menu (right-aligned)
    if draw_menu_button("Help", WINDOW_WIDTH - 60, 5, 50, 20, mouse_pos)
      @show_about = true
    end
  end

  private def draw_toolbar
    toolbar_y = MENU_HEIGHT
    RL.draw_rectangle(0, toolbar_y, WINDOW_WIDTH, TOOLBAR_HEIGHT, RL::Color.new(r: 60, g: 60, b: 60, a: 255))

    # Mode buttons
    x = 10
    modes = ["Scene", "Character", "Hotspot", "Dialog", "Assets"]

    modes.each do |mode|
      if draw_toolbar_button(mode, x, toolbar_y + 5, 80, 30, @state.current_mode == mode)
        @state.current_mode = mode
        puts "Switched to #{mode} mode"
      end

      x += 90
    end

    # Tools section
    x += 50
    RL.draw_text("Tools:", x, toolbar_y + 15, 14, RL::WHITE)
    x += 60

    tools = ["Select", "Move", "Place", "Delete"]
    tools.each do |tool|
      if draw_toolbar_button(tool, x, toolbar_y + 5, 60, 30, false)
        puts "Selected #{tool} tool"
      end
      x += 70
    end
  end

  private def draw_main_area
    main_y = MENU_HEIGHT + TOOLBAR_HEIGHT
    main_height = WINDOW_HEIGHT - main_y - 25 # 25 for status bar

    # Left panel (Scene hierarchy / Asset browser)
    left_panel_width = 250
    RL.draw_rectangle(0, main_y, left_panel_width, main_height, RL::Color.new(r: 45, g: 45, b: 45, a: 255))
    RL.draw_text("#{@state.current_mode} Panel", 10, main_y + 10, 16, RL::WHITE)

    # Draw some example content
    case @state.current_mode
    when "Scene"
      draw_scene_panel(10, main_y + 40, left_panel_width - 20)
    when "Assets"
      draw_assets_panel(10, main_y + 40, left_panel_width - 20)
    end

    # Main viewport
    viewport_x = left_panel_width
    viewport_width = WINDOW_WIDTH - left_panel_width - 300 # 300 for right panel
    RL.draw_rectangle(viewport_x, main_y, viewport_width, main_height, RL::Color.new(r: 40, g: 40, b: 40, a: 255))

    # Draw viewport content
    draw_viewport_content(viewport_x, main_y, viewport_width, main_height)

    # Right panel (Properties)
    right_panel_x = viewport_x + viewport_width
    right_panel_width = 300
    RL.draw_rectangle(right_panel_x, main_y, right_panel_width, main_height, RL::Color.new(r: 45, g: 45, b: 45, a: 255))
    RL.draw_text("Properties", right_panel_x + 10, main_y + 10, 16, RL::WHITE)

    # Example property controls
    draw_properties_panel(right_panel_x + 10, main_y + 40, right_panel_width - 20)
  end

  private def draw_scene_panel(x : Int32, y : Int32, width : Int32)
    # Example scene hierarchy
    RL.draw_text("Scene: Main Room", x, y, 14, RL::WHITE)
    y += 25
    RL.draw_text("+ Hotspots", x, y, 12, RL::LIGHTGRAY)
    y += 20
    RL.draw_text("  - Door", x + 10, y, 12, RL::GRAY)
    y += 18
    RL.draw_text("  - Table", x + 10, y, 12, RL::GRAY)
    y += 25
    RL.draw_text("+ Characters", x, y, 12, RL::LIGHTGRAY)
    y += 20
    RL.draw_text("  - Player", x + 10, y, 12, RL::GRAY)
    y += 18
    RL.draw_text("  - NPC", x + 10, y, 12, RL::GRAY)
  end

  private def draw_assets_panel(x : Int32, y : Int32, width : Int32)
    # Example asset browser
    categories = ["Backgrounds", "Characters", "Sounds", "Scripts"]
    categories.each_with_index do |category, index|
      if draw_simple_button(category, x, y + index * 30, width, 25)
        puts "Selected #{category}"
      end
    end
  end

  private def draw_viewport_content(x : Int32, y : Int32, width : Int32, height : Int32)
    case @state.current_mode
    when "Scene"
      draw_scene_editor(x, y, width, height)
    when "Dialog"
      draw_dialog_editor(x, y, width, height)
    else
      # Default content
      RL.draw_text("#{@state.current_mode} Editor", x + 20, y + 20, 24, RL::WHITE)
      RL.draw_text("Content will go here", x + 20, y + 60, 16, RL::LIGHTGRAY)
    end
  end

  private def draw_scene_editor(x : Int32, y : Int32, width : Int32, height : Int32)
    # Draw grid if enabled
    if @state.show_grid
      grid_size = 32
      grid_color = RL::Color.new(r: 80, g: 80, b: 80, a: 255)

      # Vertical lines
      (0..width).step(grid_size) do |gx|
        RL.draw_line(x + gx, y, x + gx, y + height, grid_color)
      end

      # Horizontal lines
      (0..height).step(grid_size) do |gy|
        RL.draw_line(x, y + gy, x + width, y + gy, grid_color)
      end
    end

    # Draw some example objects
    RL.draw_rectangle(x + 100, y + 100, 80, 60, RL::Color.new(r: 100, g: 150, b: 100, a: 150))
    RL.draw_rectangle_lines(x + 100, y + 100, 80, 60, RL::GREEN)
    RL.draw_text("Hotspot", x + 110, y + 110, 12, RL::WHITE)

    RL.draw_rectangle(x + 200, y + 150, 40, 80, RL::Color.new(r: 100, g: 100, b: 200, a: 150))
    RL.draw_rectangle_lines(x + 200, y + 150, 40, 80, RL::BLUE)
    RL.draw_text("Character", x + 205, y + 180, 10, RL::WHITE)

    # Instructions
    RL.draw_text("Scene Editor - Press G to toggle grid", x + 10, y + height - 30, 12, RL::LIGHTGRAY)
  end

  private def draw_dialog_editor(x : Int32, y : Int32, width : Int32, height : Int32)
    # Draw dialog nodes
    node1_bounds = RL::Rectangle.new(x: (x + 50).to_f, y: (y + 50).to_f, width: 150, height: 80)
    RL.draw_rectangle_rec(node1_bounds, RL::Color.new(r: 80, g: 80, b: 80, a: 255))
    RL.draw_rectangle_lines_ex(node1_bounds, 2, RL::WHITE)
    RL.draw_text("Start Dialog", x + 60, y + 60, 12, RL::WHITE)
    RL.draw_text("Hello! Welcome to", x + 60, y + 80, 10, RL::LIGHTGRAY)
    RL.draw_text("the game.", x + 60, y + 95, 10, RL::LIGHTGRAY)

    node2_bounds = RL::Rectangle.new(x: (x + 250).to_f, y: (y + 150).to_f, width: 150, height: 80)
    RL.draw_rectangle_rec(node2_bounds, RL::Color.new(r: 80, g: 80, b: 80, a: 255))
    RL.draw_rectangle_lines_ex(node2_bounds, 2, RL::WHITE)
    RL.draw_text("Response", x + 260, y + 160, 12, RL::WHITE)
    RL.draw_text("That's great!", x + 260, y + 180, 10, RL::LIGHTGRAY)

    # Draw connection line
    RL.draw_line(x + 200, y + 90, x + 250, y + 190, RL::LIGHTGRAY)

    RL.draw_text("Dialog Editor - Visual dialog tree", x + 10, y + height - 30, 12, RL::LIGHTGRAY)
  end

  private def draw_properties_panel(x : Int32, y : Int32, width : Int32)
    # Example properties using simple drawing
    RL.draw_text("Properties Panel", x, y, 16, RL::WHITE)
    y += 30

    mouse_pos = RL.get_mouse_position

    # Project name
    RL.draw_text("Name: #{@state.project_name}", x, y, 12, RL::LIGHTGRAY)
    y += 25

    # Grid toggle (simple checkbox)
    checkbox_size = 15
    checkbox_bounds = RL::Rectangle.new(x: x.to_f, y: y.to_f, width: checkbox_size.to_f, height: checkbox_size.to_f)

    RL.draw_rectangle_rec(checkbox_bounds, RL::WHITE)
    RL.draw_rectangle_lines_ex(checkbox_bounds, 1, RL::BLACK)

    if @state.show_grid
      RL.draw_rectangle(x + 3, y + 3, checkbox_size - 6, checkbox_size - 6, RL::GREEN)
    end

    RL.draw_text("Show Grid", x + checkbox_size + 10, y + 2, 12, RL::LIGHTGRAY)

    # Handle click
    if RL.mouse_button_pressed?(RL::MouseButton::Left) &&
       mouse_pos.x >= x && mouse_pos.x <= x + checkbox_size &&
       mouse_pos.y >= y && mouse_pos.y <= y + checkbox_size
      @state.show_grid = !@state.show_grid
    end
    y += 30

    # Zoom display
    RL.draw_text("Zoom: #{(@state.zoom * 100).to_i}%", x, y, 12, RL::LIGHTGRAY)
    y += 25

    # Reset button (simple)
    button_width = 100
    button_height = 25
    button_bounds = RL::Rectangle.new(x: x.to_f, y: y.to_f, width: button_width.to_f, height: button_height.to_f)

    is_hover = mouse_pos.x >= x && mouse_pos.x <= x + button_width &&
               mouse_pos.y >= y && mouse_pos.y <= y + button_height

    button_color = is_hover ? RL::LIGHTGRAY : RL::GRAY
    RL.draw_rectangle_rec(button_bounds, button_color)
    RL.draw_rectangle_lines_ex(button_bounds, 1, RL::WHITE)

    text_width = RL.measure_text("Reset View", 12)
    text_x = x + (button_width - text_width) // 2
    RL.draw_text("Reset View", text_x, y + 6, 12, RL::BLACK)

    if is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
      @state.zoom = 1.0f32
      @state.camera_x = 0.0f32
      @state.camera_y = 0.0f32
    end
  end

  private def draw_status_bar
    status_y = WINDOW_HEIGHT - 25
    RL.draw_rectangle(0, status_y, WINDOW_WIDTH, 25, RL::Color.new(r: 30, g: 30, b: 30, a: 255))

    status_text = "Mode: #{@state.current_mode} | Project: #{@state.project_name} | Zoom: #{(@state.zoom * 100).to_i}%"
    RL.draw_text(status_text, 10, status_y + 5, 12, RL::LIGHTGRAY)

    # Version info (right-aligned)
    version_text = "PACE v0.1.0"
    version_width = RL.measure_text(version_text, 12)
    RL.draw_text(version_text, WINDOW_WIDTH - version_width - 10, status_y + 5, 12, RL::GRAY)
  end

  private def draw_about_dialog
    # Modal background
    RL.draw_rectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, RL::Color.new(r: 0, g: 0, b: 0, a: 150))

    # Dialog box
    dialog_width = 400
    dialog_height = 200
    dialog_x = (WINDOW_WIDTH - dialog_width) // 2
    dialog_y = (WINDOW_HEIGHT - dialog_height) // 2

    dialog_bounds = RL::Rectangle.new(x: dialog_x.to_f, y: dialog_y.to_f, width: dialog_width.to_f, height: dialog_height.to_f)
    RL.draw_rectangle_rec(dialog_bounds, RL::Color.new(r: 80, g: 80, b: 80, a: 255))
    RL.draw_rectangle_lines_ex(dialog_bounds, 2, RL::WHITE)

    # Dialog content
    RL.draw_text("About PACE Editor", dialog_x + 20, dialog_y + 20, 20, RL::WHITE)
    RL.draw_text("Point & Click Adventure Creator", dialog_x + 20, dialog_y + 50, 14, RL::LIGHTGRAY)
    RL.draw_text("A visual editor for creating adventure games", dialog_x + 20, dialog_y + 75, 12, RL::LIGHTGRAY)
    RL.draw_text("Built with Crystal and Raylib", dialog_x + 20, dialog_y + 100, 12, RL::LIGHTGRAY)

    # Close button
    if draw_simple_button("Close", dialog_x + dialog_width - 80, dialog_y + dialog_height - 40, 60, 25)
      @show_about = false
    end

    # Close with Escape
    if RL::KeyboardKey::Escape.pressed?
      @show_about = false
    end
  end

  # Helper methods for drawing buttons
  private def draw_menu_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32, mouse_pos : RL::Vector2) : Bool
    is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
               mouse_pos.y >= y && mouse_pos.y <= y + height

    if is_hover
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 100, g: 100, b: 100, a: 255))
    end

    text_width = RL.measure_text(text, 14)
    text_x = x + (width - text_width) // 2
    RL.draw_text(text, text_x, y + 3, 14, RL::WHITE)

    is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
  end

  private def draw_toolbar_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32, active : Bool) : Bool
    mouse_pos = RL.get_mouse_position
    is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
               mouse_pos.y >= y && mouse_pos.y <= y + height

    bg_color = if active
                 RL::Color.new(r: 100, g: 150, b: 200, a: 255)
               elsif is_hover
                 RL::Color.new(r: 80, g: 80, b: 80, a: 255)
               else
                 RL::Color.new(r: 60, g: 60, b: 60, a: 255)
               end

    RL.draw_rectangle(x, y, width, height, bg_color)
    RL.draw_rectangle_lines(x, y, width, height, RL::LIGHTGRAY)

    text_width = RL.measure_text(text, 12)
    text_x = x + (width - text_width) // 2
    RL.draw_text(text, text_x, y + 8, 12, RL::WHITE)

    is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
  end

  private def draw_simple_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32) : Bool
    mouse_pos = RL.get_mouse_position
    is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
               mouse_pos.y >= y && mouse_pos.y <= y + height

    bg_color = is_hover ? RL::LIGHTGRAY : RL::GRAY
    RL.draw_rectangle(x, y, width, height, bg_color)
    RL.draw_rectangle_lines(x, y, width, height, RL::WHITE)

    text_width = RL.measure_text(text, 12)
    text_x = x + (width - text_width) // 2
    text_color = is_hover ? RL::BLACK : RL::WHITE
    RL.draw_text(text, text_x, y + (height - 12) // 2, 12, text_color)

    is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
  end
end

# Run the editor
editor = SimpleEditor.new
editor.run
