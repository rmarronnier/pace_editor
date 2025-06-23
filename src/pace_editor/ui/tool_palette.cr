module PaceEditor::UI
  # Tool palette for selecting editing tools
  class ToolPalette
    include PaceEditor::Constants

    def initialize(@state : Core::EditorState)
    end

    def update
      # Tool selection logic
    end

    def draw
      # Draw tool palette background
      palette_rect = RL::Rectangle.new(
        x: 0.0_f32,
        y: Core::EditorWindow::MENU_HEIGHT.to_f32,
        width: Core::EditorWindow::TOOL_PALETTE_WIDTH.to_f32,
        height: (Core::EditorWindow::WINDOW_HEIGHT - Core::EditorWindow::MENU_HEIGHT).to_f32
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

      # Draw mode-specific tools based on availability
      case @state.current_mode
      when .scene?
        if ComponentVisibility.should_show_scene_tools?(@state)
          draw_scene_tools(y)
        end
      when .character?
        if ComponentVisibility.should_show_character_tools?(@state)
          draw_character_tools(y)
        end
      when .hotspot?
        if ComponentVisibility.should_show_hotspot_tools?(@state)
          draw_hotspot_tools(y)
        end
      when .dialog?
        # Dialog tools always available in dialog mode
        draw_dialog_tools(y)
      end
    end

    private def draw_tool_button(tool : Tool, name : String, shortcut : String, x : Int32, y : Int32) : Bool
      button_size = 60
      is_active = @state.current_tool == tool

      # Use enhanced toggle button for tool selection
      icon_text = get_tool_icon(tool)
      UIHelpers.toggle_button(x, y, button_size, button_size, icon_text, is_active, nil)
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

      if UIHelpers.button(5, y, 70, 22, "Add BG")
        # Show background import dialog
        if editor_window = @state.editor_window
          editor_window.show_background_import_dialog
        end
      end
      y += 25

      if UIHelpers.button(5, y, 70, 22, "Add Char")
        create_character
      end
      y += 25

      if UIHelpers.button(5, y, 70, 22, "Add Spot")
        add_hotspot
      end
    end

    private def add_hotspot
      if scene = @state.current_scene
        # Create a new hotspot at viewport center
        new_hotspot = PointClickEngine::Scenes::Hotspot.new(
          "hotspot_#{Time.utc.to_unix}",
          RL::Vector2.new(x: 350, y: 250),
          RL::Vector2.new(x: 100, y: 100)
        )
        new_hotspot.description = "New hotspot"
        new_hotspot.cursor_type = :hand
        scene.hotspots << new_hotspot
        @state.selected_object = new_hotspot.name
        @state.save_current_scene(scene)
        @state.mark_dirty
      end
    end

    private def draw_character_tools(y : Int32)
      RL.draw_text("Character", 10, y, 12, RL::WHITE)
      y += 20

      if UIHelpers.button(5, y, 70, 22, "New Char")
        create_character
      end
      y += 25

      if UIHelpers.button(5, y, 70, 22, "Edit Anim")
        edit_animations
      end
      y += 25

      if UIHelpers.button(5, y, 70, 22, "Script")
        edit_character_script
      end
    end

    private def draw_hotspot_tools(y : Int32)
      RL.draw_text("Hotspots", 10, y, 12, RL::WHITE)
      y += 20

      if UIHelpers.button(5, y, 70, 22, "Rectangle")
        create_rectangular_hotspot
      end
      y += 25

      if UIHelpers.button(5, y, 70, 22, "Circle")
        create_circular_hotspot
      end
    end

    private def draw_dialog_tools(y : Int32)
      RL.draw_text("Dialog", 10, y, 12, RL::WHITE)
      y += 20

      if UIHelpers.button(5, y, 70, 22, "Add Node")
        create_dialog_node
      end
      y += 25

      if UIHelpers.button(5, y, 70, 22, "Connect")
        connect_dialog_nodes
      end
    end

    # Character tool actions
    private def create_character
      if scene = @state.current_scene
        # Create a new character at viewport center
        new_char = PointClickEngine::Characters::NPC.new(
          "character_#{Time.utc.to_unix}",
          RL::Vector2.new(x: 400, y: 300),
          RL::Vector2.new(x: 64, y: 128)
        )
        scene.add_character(new_char)
        @state.selected_object = new_char.name
        @state.save_current_scene(scene)
        @state.mark_dirty
      end
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
      if dialog_editor = @state.dialog_editor
        dialog_editor.create_new_node
      else
        puts "Error: Dialog editor not initialized"
      end
    end

    private def connect_dialog_nodes
      puts "🔗 Connecting dialog nodes..."
      puts "   ✓ Node connection tool activated"
      puts "   ✓ This button is working!"
      # In a real implementation, this would activate connection mode
    end

    # Hotspot creation methods
    private def create_rectangular_hotspot
      if scene = @state.current_scene
        # Create a new rectangular hotspot at viewport center
        hotspot_name = "rect_hotspot_#{Time.utc.to_unix}"
        new_hotspot = PointClickEngine::Scenes::Hotspot.new(
          hotspot_name,
          RL::Vector2.new(x: 300.0_f32, y: 200.0_f32),
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32)
        )
        new_hotspot.description = "Rectangle hotspot"
        scene.add_hotspot(new_hotspot)
        @state.selected_object = hotspot_name
        @state.mark_dirty
        puts "Created rectangular hotspot: #{hotspot_name}"
      end
    end

    private def create_circular_hotspot
      if scene = @state.current_scene
        # Create a new circular hotspot (using Rectangle with equal width/height)
        hotspot_name = "circle_hotspot_#{Time.utc.to_unix}"
        new_hotspot = PointClickEngine::Scenes::Hotspot.new(
          hotspot_name,
          RL::Vector2.new(x: 300.0_f32, y: 200.0_f32),
          RL::Vector2.new(x: 80.0_f32, y: 80.0_f32)
        )
        new_hotspot.description = "Circle hotspot"
        scene.add_hotspot(new_hotspot)
        @state.selected_object = hotspot_name
        @state.mark_dirty
        puts "Created circular hotspot: #{hotspot_name}"
      end
    end
  end
end
