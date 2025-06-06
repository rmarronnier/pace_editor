require "raylib-cr/rlgl"

module PaceEditor::Editors
  # Dialog editor for creating and editing dialog trees
  class DialogEditor
    property current_dialog : PointClickEngine::DialogTree? = nil
    property selected_node : String? = nil
    property camera_offset : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)
    property node_positions : Hash(String, RL::Vector2) = {} of String => RL::Vector2
    property dragging_node : String? = nil
    property drag_start : RL::Vector2? = nil

    def initialize(@state : Core::EditorState)
    end

    def update
      handle_node_interaction
    end

    def draw
      editor_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      editor_y = Core::EditorWindow::MENU_HEIGHT
      editor_width = Core::EditorWindow::WINDOW_WIDTH - Core::EditorWindow::TOOL_PALETTE_WIDTH - Core::EditorWindow::PROPERTY_PANEL_WIDTH
      editor_height = Core::EditorWindow::WINDOW_HEIGHT - Core::EditorWindow::MENU_HEIGHT

      # Draw background
      RL.draw_rectangle(editor_x, editor_y, editor_width, editor_height,
        RL::Color.new(r: 40, g: 40, b: 40, a: 255))

      if dialog = get_current_dialog
        draw_dialog_workspace(dialog, editor_x, editor_y, editor_width, editor_height)
      else
        draw_no_dialog_message(editor_x, editor_y, editor_width, editor_height)
      end
    end

    private def get_current_dialog : PointClickEngine::DialogTree?
      return @current_dialog if @current_dialog

      # Try to load a dialog from the current project
      if project = @state.current_project
        dialog_files = Dir.glob(File.join(project.dialogs_path, "*.yml"))
        if !dialog_files.empty?
          @current_dialog = PointClickEngine::DialogTree.load_from_file(dialog_files.first)
          initialize_node_positions(@current_dialog.not_nil!)
        end
      end

      @current_dialog
    end

    private def draw_dialog_workspace(dialog : PointClickEngine::DialogTree, x : Int32, y : Int32, width : Int32, height : Int32)
      # Draw dialog canvas background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 35, g: 35, b: 35, a: 255))

      # Draw grid
      draw_dialog_grid(x, y, width, height)

      # Apply camera transform for node drawing
      RLGL.push_matrix
      RLGL.translate_f(@camera_offset.x, @camera_offset.y, 0)

      # Draw connections between nodes
      draw_node_connections(dialog, x, y)

      # Draw dialog nodes
      draw_dialog_nodes(dialog, x, y)

      RLGL.pop_matrix

      # Draw UI overlay (not affected by camera)
      draw_dialog_toolbar(x, y, width)
    end

    private def draw_dialog_grid(x : Int32, y : Int32, width : Int32, height : Int32)
      grid_size = 50
      grid_color = RL::Color.new(r: 60, g: 60, b: 60, a: 255)

      # Draw vertical lines
      grid_x = (@camera_offset.x % grid_size).to_i
      while grid_x < width
        RL.draw_line(x + grid_x, y, x + grid_x, y + height, grid_color)
        grid_x += grid_size
      end

      # Draw horizontal lines
      grid_y = (@camera_offset.y % grid_size).to_i
      while grid_y < height
        RL.draw_line(x, y + grid_y, x + width, y + grid_y, grid_color)
        grid_y += grid_size
      end
    end

    private def draw_node_connections(dialog : PointClickEngine::DialogTree, offset_x : Int32, offset_y : Int32)
      dialog.nodes.each do |node_id, node|
        start_pos = @node_positions[node_id]? || RL::Vector2.new(x: 100, y: 100)
        start_center = RL::Vector2.new(
          x: start_pos.x + 75, # Half node width
          y: start_pos.y + 40  # Half node height
        )

        node.choices.each do |choice|
          if target_pos = @node_positions[choice.target_node_id]?
            end_center = RL::Vector2.new(
              x: target_pos.x + 75,
              y: target_pos.y + 40
            )

            # Draw connection line
            RL.draw_line_ex(start_center, end_center, 2, RL::LIGHTGRAY)

            # Draw arrow head
            direction = RL::Vector2.new(
              x: end_center.x - start_center.x,
              y: end_center.y - start_center.y
            )
            length = Math.sqrt(direction.x * direction.x + direction.y * direction.y)
            if length > 0
              direction = RL::Vector2.new(x: direction.x / length, y: direction.y / length)
              arrow_size = 10
              arrow_pos = RL::Vector2.new(
                x: end_center.x - direction.x * 15,
                y: end_center.y - direction.y * 15
              )

              # Simple arrow (triangle)
              RL.draw_circle(arrow_pos.x.to_i, arrow_pos.y.to_i, 3, RL::LIGHTGRAY)
            end
          end
        end
      end
    end

    private def draw_dialog_nodes(dialog : PointClickEngine::DialogTree, offset_x : Int32, offset_y : Int32)
      dialog.nodes.each do |node_id, node|
        position = @node_positions[node_id]? || RL::Vector2.new(x: 100, y: 100)
        draw_dialog_node(node, position, node_id == @selected_node)
      end
    end

    private def draw_dialog_node(node : PointClickEngine::DialogNode, position : RL::Vector2, selected : Bool)
      node_width = 150
      node_height = 80

      # Node background
      bg_color = if selected
                   RL::Color.new(r: 100, g: 150, b: 200, a: 255)
                 elsif node.is_end
                   RL::Color.new(r: 150, g: 100, b: 100, a: 255)
                 else
                   RL::Color.new(r: 80, g: 80, b: 80, a: 255)
                 end

      RL.draw_rectangle(position.x.to_i, position.y.to_i, node_width, node_height, bg_color)
      RL.draw_rectangle_lines(position.x.to_i, position.y.to_i, node_width, node_height, RL::WHITE)

      # Node title
      title_text = node.id.size > 15 ? node.id[0...12] + "..." : node.id
      RL.draw_text(title_text, position.x.to_i + 5, position.y.to_i + 5, 12, RL::WHITE)

      # Node text preview
      preview_text = node.text.size > 40 ? node.text[0...37] + "..." : node.text
      lines = wrap_text(preview_text, 16)
      lines.each_with_index do |line, index|
        break if index >= 3 # Max 3 lines
        RL.draw_text(line, position.x.to_i + 5, position.y.to_i + 20 + index * 15, 10, RL::LIGHTGRAY)
      end

      # Choice count indicator
      if node.choices.size > 0
        choice_text = "#{node.choices.size} choice#{node.choices.size > 1 ? "s" : ""}"
        RL.draw_text(choice_text, position.x.to_i + 5, position.y.to_i + node_height - 15, 10, RL::YELLOW)
      end

      # End node indicator
      if node.is_end
        RL.draw_text("END", position.x.to_i + node_width - 25, position.y.to_i + 5, 10, RL::RED)
      end
    end

    private def draw_dialog_toolbar(x : Int32, y : Int32, width : Int32)
      toolbar_height = 40
      RL.draw_rectangle(x, y, width, toolbar_height, RL::Color.new(r: 70, g: 70, b: 70, a: 255))
      RL.draw_line(x, y + toolbar_height, x + width, y + toolbar_height, RL::GRAY)

      # Toolbar buttons
      button_x = x + 10

      if draw_toolbar_button("New Node", button_x, y + 5)
        create_new_node
      end
      button_x += 80

      if draw_toolbar_button("Delete", button_x, y + 5)
        delete_selected_node
      end
      button_x += 70

      if draw_toolbar_button("Connect", button_x, y + 5)
        # Start connection mode
      end
      button_x += 70

      if draw_toolbar_button("Test", button_x, y + 5)
        test_dialog_tree
      end

      # Dialog info (right side)
      if dialog = @current_dialog
        info_text = "Nodes: #{dialog.nodes.size}"
        info_width = RL.measure_text(info_text, 12)
        RL.draw_text(info_text, x + width - info_width - 10, y + 15, 12, RL::WHITE)
      end
    end

    private def draw_no_dialog_message(x : Int32, y : Int32, width : Int32, height : Int32)
      message = "No Dialog Tree Loaded"
      message_width = RL.measure_text(message, 24)
      message_x = x + (width - message_width) // 2
      message_y = y + height // 2 - 60

      RL.draw_text(message, message_x, message_y, 24, RL::LIGHTGRAY)

      instruction = "Create a new dialog tree or load an existing one"
      instruction_width = RL.measure_text(instruction, 16)
      instruction_x = x + (width - instruction_width) // 2
      RL.draw_text(instruction, instruction_x, message_y + 40, 16, RL::GRAY)

      # Create dialog button
      button_width = 150
      button_x = x + (width - button_width) // 2
      if draw_button("Create Dialog Tree", button_x, message_y + 80, button_width, 30)
        create_new_dialog
      end
    end

    private def handle_node_interaction
      mouse_pos = RL.get_mouse_position
      editor_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      editor_y = Core::EditorWindow::MENU_HEIGHT + 40 # Account for toolbar

      # Convert mouse position to dialog canvas coordinates
      canvas_pos = RL::Vector2.new(
        x: mouse_pos.x - editor_x - @camera_offset.x,
        y: mouse_pos.y - editor_y - @camera_offset.y
      )

      # Handle node selection and dragging
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        clicked_node = find_node_at_position(canvas_pos)
        if clicked_node
          @selected_node = clicked_node
          @dragging_node = clicked_node
          @drag_start = canvas_pos
        else
          @selected_node = nil
        end
      elsif RL.mouse_button_down?(RL::MouseButton::Left) && @dragging_node && @drag_start
        # Update node position while dragging
        if node_pos = @node_positions[@dragging_node.not_nil!]?
          delta = RL::Vector2.new(
            x: canvas_pos.x - @drag_start.not_nil!.x,
            y: canvas_pos.y - @drag_start.not_nil!.y
          )
          @node_positions[@dragging_node.not_nil!] = RL::Vector2.new(
            x: node_pos.x + delta.x,
            y: node_pos.y + delta.y
          )
          @drag_start = canvas_pos
        end
      elsif RL.mouse_button_released?(RL::MouseButton::Left)
        @dragging_node = nil
        @drag_start = nil
      end

      # Handle camera panning with middle mouse or space+drag
      if RL.mouse_button_down?(RL::MouseButton::Middle) ||
         (RL.key_down?(RL::KeyboardKey::Space) && RL.mouse_button_down?(RL::MouseButton::Left))
        delta = RL.get_mouse_delta
        @camera_offset = RL::Vector2.new(
          x: @camera_offset.x + delta.x,
          y: @camera_offset.y + delta.y
        )
      end
    end

    private def find_node_at_position(position : RL::Vector2) : String?
      @node_positions.each do |node_id, node_pos|
        if position.x >= node_pos.x && position.x <= node_pos.x + 150 &&
           position.y >= node_pos.y && position.y <= node_pos.y + 80
          return node_id
        end
      end
      nil
    end

    private def initialize_node_positions(dialog : PointClickEngine::DialogTree)
      @node_positions.clear

      # Simple layout: arrange nodes in a grid
      x = 50
      y = 50
      cols = 3
      col = 0

      dialog.nodes.each do |node_id, node|
        @node_positions[node_id] = RL::Vector2.new(x: x.to_f, y: y.to_f)

        col += 1
        if col >= cols
          col = 0
          x = 50
          y += 120
        else
          x += 200
        end
      end
    end

    private def wrap_text(text : String, chars_per_line : Int32) : Array(String)
      words = text.split(" ")
      lines = [] of String
      current_line = ""

      words.each do |word|
        if current_line.empty?
          current_line = word
        elsif (current_line + " " + word).size <= chars_per_line
          current_line += " " + word
        else
          lines << current_line
          current_line = word
        end
      end

      lines << current_line unless current_line.empty?
      lines
    end

    private def draw_toolbar_button(text : String, x : Int32, y : Int32) : Bool
      width = 70
      height = 30

      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      bg_color = is_hover ? RL::Color.new(r: 100, g: 100, b: 100, a: 255) : RL::Color.new(r: 80, g: 80, b: 80, a: 255)

      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, RL::LIGHTGRAY)

      text_width = RL.measure_text(text, 12)
      text_x = x + (width - text_width) // 2
      RL.draw_text(text, text_x, y + 9, 12, RL::WHITE)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def draw_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32) : Bool
      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      bg_color = is_hover ? RL::Color.new(r: 80, g: 80, b: 80, a: 255) : RL::Color.new(r: 60, g: 60, b: 60, a: 255)

      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, RL::WHITE)

      text_width = RL.measure_text(text, 14)
      text_x = x + (width - text_width) // 2
      RL.draw_text(text, text_x, y + (height - 14) // 2, 14, RL::WHITE)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def create_new_node
      return unless dialog = @current_dialog

      # Create new dialog node
      node_id = "node_#{Time.utc.to_unix_ms}"
      new_node = PointClickEngine::DialogNode.new(node_id, "New dialog text")

      dialog.nodes[node_id] = new_node

      # Position new node
      @node_positions[node_id] = RL::Vector2.new(x: 100, y: 100)
      @selected_node = node_id

      save_current_dialog
    end

    private def delete_selected_node
      return unless node_id = @selected_node
      return unless dialog = @current_dialog

      # Remove node
      dialog.nodes.delete(node_id)
      @node_positions.delete(node_id)
      @selected_node = nil

      # Remove references to this node in choices
      dialog.nodes.each do |_, node|
        node.choices.reject! { |choice| choice.target_node_id == node_id }
      end

      save_current_dialog
    end

    private def create_new_dialog
      return unless project = @state.current_project

      # Create new dialog tree
      @current_dialog = PointClickEngine::DialogTree.new
      @current_dialog.not_nil!.name = "New Dialog"

      # Create initial node
      start_node = PointClickEngine::DialogNode.new("start", "Hello! This is the start of a new dialog.")
      @current_dialog.not_nil!.nodes["start"] = start_node

      initialize_node_positions(@current_dialog.not_nil!)
      save_current_dialog
    end

    private def test_dialog_tree
      return unless dialog = @current_dialog
      puts "Testing dialog tree: #{dialog.name}"
      puts "Nodes: #{dialog.nodes.size}"
    end

    private def save_current_dialog
      return unless dialog = @current_dialog
      return unless project = @state.current_project

      # Save dialog to project
      dialog_file = File.join(project.dialogs_path, "#{dialog.name.downcase.gsub(" ", "_")}.yml")
      dialog.save_to_file(dialog_file)
    end
  end
end
