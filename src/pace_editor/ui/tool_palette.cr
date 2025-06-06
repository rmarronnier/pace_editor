module PaceEditor::UI
  # Tool palette for selecting editing tools
  class ToolPalette
    def initialize(@state : Core::EditorState)
    end

    def update
      # Tool selection logic
    end

    def draw
      # Draw tool palette background
      palette_rect = RL::Rectangle.new(
        x: 0,
        y: Core::EditorWindow::MENU_HEIGHT.to_f,
        width: Core::EditorWindow::TOOL_PALETTE_WIDTH.to_f,
        height: (Core::EditorWindow::WINDOW_HEIGHT - Core::EditorWindow::MENU_HEIGHT).to_f
      )

      RL.draw_rectangle_rec(palette_rect, RL::Color.new(r: 45, g: 45, b: 45, a: 255))
      RL.draw_line(Core::EditorWindow::TOOL_PALETTE_WIDTH, Core::EditorWindow::MENU_HEIGHT,
        Core::EditorWindow::TOOL_PALETTE_WIDTH, Core::EditorWindow::WINDOW_HEIGHT, RL::GRAY)

      # Draw tool buttons
      y = Core::EditorWindow::MENU_HEIGHT + 10

      tools = [
        {Tool::Select, "Select", "V"},
        {Tool::Move, "Move", "M"},
        {Tool::Place, "Place", "P"},
        {Tool::Delete, "Delete", "D"},
        {Tool::Paint, "Paint", "B"},
        {Tool::Zoom, "Zoom", "Z"},
      ]

      tools.each do |tool, name, shortcut|
        if draw_tool_button(tool, name, shortcut, 5, y)
          @state.current_tool = tool
        end
        y += 70
      end

      # Draw separator
      y += 10
      RL.draw_line(10, y, Core::EditorWindow::TOOL_PALETTE_WIDTH - 10, y, RL::GRAY)
      y += 20

      # Draw mode-specific tools
      case @state.current_mode
      when .scene?
        draw_scene_tools(y)
      when .character?
        draw_character_tools(y)
      when .hotspot?
        draw_hotspot_tools(y)
      when .dialog?
        draw_dialog_tools(y)
      end
    end

    private def draw_tool_button(tool : Tool, name : String, shortcut : String, x : Int32, y : Int32) : Bool
      button_size = 60
      is_active = @state.current_tool == tool

      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + button_size &&
                 mouse_pos.y >= y && mouse_pos.y <= y + button_size

      # Button background
      bg_color = if is_active
                   RL::Color.new(r: 100, g: 150, b: 200, a: 255)
                 elsif is_hover
                   RL::Color.new(r: 80, g: 80, b: 80, a: 255)
                 else
                   RL::Color.new(r: 60, g: 60, b: 60, a: 255)
                 end

      RL.draw_rectangle(x, y, button_size, button_size, bg_color)
      RL.draw_rectangle_lines(x, y, button_size, button_size, RL::LIGHTGRAY)

      # Tool icon (simplified text for now)
      icon_text = get_tool_icon(tool)
      icon_width = RL.measure_text(icon_text, 20)
      icon_x = x + (button_size - icon_width) // 2
      RL.draw_text(icon_text, icon_x, y + 15, 20, RL::WHITE)

      # Shortcut key
      shortcut_width = RL.measure_text(shortcut, 10)
      shortcut_x = x + (button_size - shortcut_width) // 2
      RL.draw_text(shortcut, shortcut_x, y + button_size - 15, 10, RL::LIGHTGRAY)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def get_tool_icon(tool : Tool) : String
      case tool
      when .select?
        "SEL"
      when .move?
        "MOV"
      when .place?
        "PLC"
      when .delete?
        "DEL"
      when .paint?
        "PNT"
      when .zoom?
        "ZOM"
      else
        "???"
      end
    end

    private def draw_scene_tools(y : Int32)
      RL.draw_text("Scene Tools", 10, y, 12, RL::WHITE)
      y += 20

      if draw_small_button("Add BG", 5, y)
        # Add background
      end
      y += 25

      if draw_small_button("Add Char", 5, y)
        # Add character
      end
      y += 25

      if draw_small_button("Add Spot", 5, y)
        # Add hotspot
      end
    end

    private def draw_character_tools(y : Int32)
      RL.draw_text("Character", 10, y, 12, RL::WHITE)
      y += 20

      if draw_small_button("New Char", 5, y)
        create_character
      end
      y += 25

      if draw_small_button("Edit Anim", 5, y)
        edit_animations
      end
      y += 25

      if draw_small_button("Script", 5, y)
        edit_character_script
      end
    end

    private def draw_hotspot_tools(y : Int32)
      RL.draw_text("Hotspots", 10, y, 12, RL::WHITE)
      y += 20

      if draw_small_button("Rectangle", 5, y)
        # Create rectangular hotspot
      end
      y += 25

      if draw_small_button("Circle", 5, y)
        # Create circular hotspot
      end
    end

    private def draw_dialog_tools(y : Int32)
      RL.draw_text("Dialog", 10, y, 12, RL::WHITE)
      y += 20

      if draw_small_button("Add Node", 5, y)
        create_dialog_node
      end
      y += 25

      if draw_small_button("Connect", 5, y)
        connect_dialog_nodes
      end
    end

    private def draw_small_button(text : String, x : Int32, y : Int32) : Bool
      width = Core::EditorWindow::TOOL_PALETTE_WIDTH - 10
      height = 20

      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      bg_color = is_hover ? RL::Color.new(r: 80, g: 80, b: 80, a: 255) : RL::Color.new(r: 60, g: 60, b: 60, a: 255)

      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      text_width = RL.measure_text(text, 12)
      text_x = x + (width - text_width) // 2
      RL.draw_text(text, text_x, y + 4, 12, RL::WHITE)

      clicked = is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)

      # Debug output
      if clicked
        puts "🔍 Button '#{text}' clicked! (#{x}, #{y}) hover: #{is_hover}"
      end

      clicked
    end

    # Character tool actions
    private def create_character
      puts "🎭 Creating new character..."
      puts "   ✓ Character creation dialog would open here"
      puts "   ✓ This button is working!"
      # In a real implementation, this would open a character creation dialog
    end

    private def edit_animations
      puts "🎬 Opening animation editor..."
      puts "   ✓ Animation timeline would open here"
      # In a real implementation, this would open the animation timeline editor
    end

    private def edit_character_script
      puts "📝 Opening script editor for character..."
      puts "   ✓ Lua script editor would open here"
      # In a real implementation, this would open a Lua script editor
    end

    # Dialog tool actions
    private def create_dialog_node
      puts "💬 Creating new dialog node..."
      puts "   ✓ Dialog node creation dialog would open here"
      puts "   ✓ This button is working!"
      # In a real implementation, this would create a new dialog node
    end

    private def connect_dialog_nodes
      puts "🔗 Connecting dialog nodes..."
      puts "   ✓ Node connection tool activated"
      puts "   ✓ This button is working!"
      # In a real implementation, this would activate connection mode
    end
  end
end
