# Testing extensions for ToolPalette
# Reopens the class to add e2e testing support methods

module PaceEditor::UI
  class ToolPalette
    # Update with a specific input provider (for testing)
    def update_with_input(input : Testing::InputProvider)
      screen_height = input.get_screen_height

      # Process tool buttons (same layout as draw)
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
        if tool_button_clicked?(tool, 5, y, input)
          @state.current_tool = tool
        end
        y += 70
      end

      # Skip separator
      y += 30

      # Process mode-specific tools
      case @state.current_mode
      when .scene?
        if ComponentVisibility.should_show_scene_tools?(@state)
          handle_scene_tools_input(y, input)
        end
      when .character?
        if ComponentVisibility.should_show_character_tools?(@state)
          handle_character_tools_input(y, input)
        end
      when .hotspot?
        if ComponentVisibility.should_show_hotspot_tools?(@state)
          handle_hotspot_tools_input(y, input)
        end
      when .dialog?
        handle_dialog_tools_input(y, input)
      end
    end

    private def tool_button_clicked?(tool : Tool, x : Int32, y : Int32, input : Testing::InputProvider) : Bool
      button_size = 60
      UIHelpers.toggle_button_with_input(x, y, button_size, button_size, get_tool_icon(tool), @state.current_tool == tool, input)
    end

    private def handle_scene_tools_input(y : Int32, input : Testing::InputProvider)
      y += 20 # Skip "Scene Tools" label

      if UIHelpers.button_with_input(5, y, 70, 22, "Add BG", input)
        if editor_window = @state.editor_window
          editor_window.show_background_import_dialog
        end
      end
      y += 25

      if UIHelpers.button_with_input(5, y, 70, 22, "Add Char", input)
        create_character
      end
      y += 25

      if UIHelpers.button_with_input(5, y, 70, 22, "Add Spot", input)
        add_hotspot
      end
    end

    private def handle_character_tools_input(y : Int32, input : Testing::InputProvider)
      y += 20 # Skip "Character" label

      if UIHelpers.button_with_input(5, y, 70, 22, "New Char", input)
        create_character
      end
      y += 25

      if UIHelpers.button_with_input(5, y, 70, 22, "Edit Anim", input)
        edit_animations
      end
      y += 25

      if UIHelpers.button_with_input(5, y, 70, 22, "Script", input)
        edit_character_script
      end
    end

    private def handle_hotspot_tools_input(y : Int32, input : Testing::InputProvider)
      y += 20 # Skip "Hotspots" label

      if UIHelpers.button_with_input(5, y, 70, 22, "Rectangle", input)
        create_rectangular_hotspot
      end
      y += 25

      if UIHelpers.button_with_input(5, y, 70, 22, "Circle", input)
        create_circular_hotspot
      end
    end

    private def handle_dialog_tools_input(y : Int32, input : Testing::InputProvider)
      y += 20 # Skip "Dialog" label

      if UIHelpers.button_with_input(5, y, 70, 22, "Add Node", input)
        create_dialog_node
      end
      y += 25

      if UIHelpers.button_with_input(5, y, 70, 22, "Connect", input)
        connect_dialog_nodes
      end
    end

    # Testing helper: get button position for a tool
    def get_tool_button_position(tool : Tool) : {Int32, Int32}
      y = Core::EditorWindow::MENU_HEIGHT + 10
      tools = [Tool::Select, Tool::Move, Tool::Place, Tool::Delete, Tool::Paint, Tool::Zoom]

      tools.each_with_index do |t, index|
        if t == tool
          return {5, y + index * 70}
        end
      end

      {5, y} # Default to first tool
    end

    # Testing helper: get button position for scene tool
    def get_scene_tool_button_position(tool_name : String) : {Int32, Int32}
      base_y = Core::EditorWindow::MENU_HEIGHT + 10 + (6 * 70) + 30 + 20 # After main tools + separator + label

      case tool_name
      when "Add BG"
        {5, base_y}
      when "Add Char"
        {5, base_y + 25}
      when "Add Spot"
        {5, base_y + 50}
      else
        {5, base_y}
      end
    end

    # Testing helper: get button position for character tool
    def get_character_tool_button_position(tool_name : String) : {Int32, Int32}
      base_y = Core::EditorWindow::MENU_HEIGHT + 10 + (6 * 70) + 30 + 20

      case tool_name
      when "New Char"
        {5, base_y}
      when "Edit Anim"
        {5, base_y + 25}
      when "Script"
        {5, base_y + 50}
      else
        {5, base_y}
      end
    end

    # Testing helper: get button position for dialog tool
    def get_dialog_tool_button_position(tool_name : String) : {Int32, Int32}
      base_y = Core::EditorWindow::MENU_HEIGHT + 10 + (6 * 70) + 30 + 20

      case tool_name
      when "Add Node"
        {5, base_y}
      when "Connect"
        {5, base_y + 25}
      else
        {5, base_y}
      end
    end
  end
end
