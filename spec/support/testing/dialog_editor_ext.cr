# Testing extensions for DialogEditor
# Reopens the class to add e2e testing support methods

module PaceEditor::Editors
  class DialogEditor
    # Update with a specific input provider (for testing)
    def update_with_input(input : Testing::InputProvider)
      @node_dialog.update
      @preview_window.update

      unless @node_dialog.visible || @preview_window.visible
        handle_node_interaction_with_input(input)
        handle_toolbar_input_with_input(input)

        # Update connection preview if in connection mode
        if @connecting_mode
          mouse_pos = input.get_mouse_position
          editor_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
          editor_y = Core::EditorWindow::MENU_HEIGHT + 40
          canvas_pos = RL::Vector2.new(
            x: mouse_pos.x - editor_x - @camera_offset.x,
            y: mouse_pos.y - editor_y - @camera_offset.y
          )
          update_connection_preview(canvas_pos)
        end
      end
    end

    # Handle toolbar button clicks in update instead of draw
    private def handle_toolbar_input_with_input(input : Testing::InputProvider)
      return unless @current_dialog # Only handle toolbar when dialog exists

      mouse_pos = input.get_mouse_position
      editor_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      editor_y = Core::EditorWindow::MENU_HEIGHT

      # Toolbar button positions
      button_y = editor_y + 5
      button_height = 30
      button_width = 70

      # "New Node" button at x=90
      new_node_x = editor_x + 10
      if button_clicked?(mouse_pos, input, new_node_x, button_y, button_width, button_height)
        create_new_node
      end

      # "Delete" button at x=170
      delete_x = editor_x + 10 + 80
      if button_clicked?(mouse_pos, input, delete_x, button_y, button_width, button_height)
        delete_selected_node
      end

      # "Connect" button at x=240
      connect_x = editor_x + 10 + 150
      if button_clicked?(mouse_pos, input, connect_x, button_y, button_width, button_height)
        toggle_connection_mode
      end

      # "Test" button at x=310
      test_x = editor_x + 10 + 220
      if button_clicked?(mouse_pos, input, test_x, button_y, button_width, button_height)
        test_dialog_tree
      end
    end

    # Handle the "Create Dialog Tree" button when no dialog is loaded
    private def handle_create_dialog_button_with_input(input : Testing::InputProvider)
      return if @current_dialog # Button only visible when no dialog

      mouse_pos = input.get_mouse_position
      screen_width = input.get_screen_width
      screen_height = input.get_screen_height

      editor_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      editor_y = Core::EditorWindow::MENU_HEIGHT
      editor_width = screen_width - Core::EditorWindow::TOOL_PALETTE_WIDTH - Core::EditorWindow::PROPERTY_PANEL_WIDTH
      editor_height = screen_height - Core::EditorWindow::MENU_HEIGHT

      button_width = 150
      button_height = 30
      button_x = editor_x + (editor_width - button_width) // 2
      message_y = editor_y + editor_height // 2 - 60
      button_y = message_y + 80

      if button_clicked?(mouse_pos, input, button_x, button_y, button_width, button_height)
        create_new_dialog
      end
    end

    private def button_clicked?(mouse_pos : RL::Vector2, input : Testing::InputProvider, x : Int32, y : Int32, width : Int32, height : Int32) : Bool
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height
      is_hover && input.mouse_button_pressed?(RL::MouseButton::Left)
    end

    # Node interaction with test input provider
    private def handle_node_interaction_with_input(input : Testing::InputProvider)
      mouse_pos = input.get_mouse_position
      editor_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      editor_y = Core::EditorWindow::MENU_HEIGHT + 40 # Account for toolbar
      toolbar_y = Core::EditorWindow::MENU_HEIGHT
      toolbar_height = 40

      # Skip node interaction if clicking in toolbar area
      if mouse_pos.y >= toolbar_y && mouse_pos.y < editor_y &&
         mouse_pos.x >= editor_x
        return
      end

      # Check for "Create Dialog Tree" button if no dialog
      unless @current_dialog
        handle_create_dialog_button_with_input(input)
        return
      end

      # Convert mouse position to dialog canvas coordinates
      canvas_pos = RL::Vector2.new(
        x: mouse_pos.x - editor_x - @camera_offset.x,
        y: mouse_pos.y - editor_y - @camera_offset.y
      )

      # Handle double click to edit node
      if input.mouse_button_pressed?(RL::MouseButton::Left) && @selected_node
        # Check for double click
        current_time = Time.utc.to_unix_ms
        if last_time = @last_click_time
          if (current_time - last_time) < 500
            # Double click detected
            if selected_node = @selected_node
              if node = @current_dialog.try(&.nodes[selected_node]?)
                @node_dialog.show(node)
              end
            end
          end
        end
        @last_click_time = current_time
      end

      # Handle node selection and dragging (or connection)
      if input.mouse_button_pressed?(RL::MouseButton::Left)
        clicked_node = find_node_at_position(canvas_pos)
        if clicked_node
          if @connecting_mode
            if @source_node
              # Complete connection to target node
              complete_connection_to_node(clicked_node)
            else
              # Start connection from source node
              start_connection_from_node(clicked_node)
            end
          else
            # Normal selection and dragging
            @selected_node = clicked_node
            @dragging_node = clicked_node
            @drag_start = canvas_pos
          end
        else
          if @connecting_mode
            # Cancel connection if clicking on empty space
            @source_node = nil
            @connection_preview_pos = nil
          else
            @selected_node = nil
          end
        end
      elsif input.mouse_button_down?(RL::MouseButton::Left) && @dragging_node && @drag_start
        # Update node position while dragging
        if dragging_node = @dragging_node
          if drag_start = @drag_start
            if node_pos = @node_positions[dragging_node]?
              delta = RL::Vector2.new(
                x: canvas_pos.x - drag_start.x,
                y: canvas_pos.y - drag_start.y
              )
              @node_positions[dragging_node] = RL::Vector2.new(
                x: node_pos.x + delta.x,
                y: node_pos.y + delta.y
              )
            end
          end
        end
        @drag_start = canvas_pos
      elsif input.mouse_button_released?(RL::MouseButton::Left)
        @dragging_node = nil
        @drag_start = nil
      end

      # Handle camera panning with middle mouse or space+drag
      if input.mouse_button_down?(RL::MouseButton::Middle) ||
         (input.key_down?(RL::KeyboardKey::Space) && input.mouse_button_down?(RL::MouseButton::Left))
        delta = input.get_mouse_delta
        @camera_offset = RL::Vector2.new(
          x: @camera_offset.x + delta.x,
          y: @camera_offset.y + delta.y
        )
      end
    end

    # Testing helper: directly trigger node deletion
    def delete_selected_node_for_test
      delete_selected_node
    end

    # Testing helper: get node dialog visibility
    def node_dialog_visible? : Bool
      @node_dialog.visible
    end

    # Testing helper: get current dialog (creating one if needed)
    def dialog_tree : PointClickEngine::Characters::Dialogue::DialogTree
      if dialog = @current_dialog
        dialog
      else
        # Create a new dialog
        create_new_dialog
        @current_dialog.not_nil!
      end
    end

    # Testing helper: check if connection mode is active
    def connection_mode? : Bool
      @connecting_mode
    end

    # Testing helper: select a node by ID
    def select_node_for_test(node_id : String)
      @selected_node = node_id
    end

    # Testing helper: get toolbar button position
    def get_toolbar_button_position(button_name : String) : {Int32, Int32}
      editor_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      editor_y = Core::EditorWindow::MENU_HEIGHT
      button_y = editor_y + 5 + 15 # Center of button height

      case button_name
      when "new_node"
        {editor_x + 10 + 35, button_y}
      when "delete"
        {editor_x + 10 + 80 + 35, button_y}
      when "connect"
        {editor_x + 10 + 150 + 35, button_y}
      when "test"
        {editor_x + 10 + 220 + 35, button_y}
      else
        {editor_x + 10 + 35, button_y}
      end
    end

    # Testing helper: get node screen position (for clicking)
    def get_node_position(node_id : String) : {Int32, Int32}?
      if pos = @node_positions[node_id]?
        editor_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
        editor_y = Core::EditorWindow::MENU_HEIGHT + 40
        screen_x = (pos.x + @camera_offset.x + editor_x + 60).to_i # center of node
        screen_y = (pos.y + @camera_offset.y + editor_y + 30).to_i # center of node
        {screen_x, screen_y}
      else
        nil
      end
    end

    # Testing helper: ensure a dialog exists
    def ensure_dialog_for_test
      unless @current_dialog
        create_new_dialog
      end
    end

    # Testing helper: create a new node directly (bypasses dialog)
    def create_node_for_test(id : String, text : String) : Bool
      return false unless dialog = @current_dialog

      node = PointClickEngine::Characters::Dialogue::DialogNode.new(id, text)
      dialog.add_node(node)

      # Position the new node
      x = 100.0_f32 + (dialog.nodes.size * 50)
      y = 100.0_f32 + (dialog.nodes.size * 30)
      @node_positions[id] = RL::Vector2.new(x: x, y: y)

      true
    end

    # Testing helper: create new node via button (shows dialog, doesn't create immediately)
    def click_new_node_button_for_test
      create_new_node
    end

    # Testing helper: check if node dialog is visible
    def node_dialog_showing? : Bool
      @node_dialog.visible
    end
  end
end
