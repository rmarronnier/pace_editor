require "./ui_helpers"

module PaceEditor::UI
  # Dialog for creating and editing dialog nodes
  class DialogNodeDialog
    property visible : Bool = false
    property node_id : String = ""
    property text : String = ""
    property character_name : String = ""
    property is_end : Bool = false

    # Text input fields
    @id_field : String = ""
    @text_field : String = ""
    @character_field : String = ""
    @editing_mode : Bool = false

    def initialize(@state : Core::EditorState)
    end

    def show(node : PointClickEngine::Characters::Dialogue::DialogNode? = nil)
      @visible = true

      if node
        # Edit existing node
        @editing_mode = true
        @node_id = node.id
        @id_field = node.id
        @text_field = node.text
        @character_field = node.character_name || ""
        @is_end = node.is_end

        # Update public properties
        @text = node.text
        @character_name = node.character_name || ""
      else
        # Create new node
        @editing_mode = false
        @node_id = "node_#{Time.utc.to_unix_ms}"
        @id_field = @node_id
        @text_field = ""
        @character_field = ""
        @is_end = false

        # Update public properties
        @text = ""
        @character_name = ""
      end
    end

    def hide
      @visible = false
    end

    def update
      return unless @visible

      # Handle escape key
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        hide
      end
    end

    def draw
      return unless @visible

      # Draw modal background
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      RL.draw_rectangle(0, 0, screen_width, screen_height,
        RL::Color.new(r: 0, g: 0, b: 0, a: 180))

      # Dialog window
      dialog_width = 500
      dialog_height = 400
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      # Window background
      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height,
        RL::Color.new(r: 60, g: 60, b: 60, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      # Title
      title = @editing_mode ? "Edit Dialog Node" : "Create Dialog Node"
      title_width = RL.measure_text(title, 20)
      RL.draw_text(title, dialog_x + (dialog_width - title_width) // 2, dialog_y + 20, 20, RL::WHITE)

      y = dialog_y + 60

      # Node ID field
      RL.draw_text("Node ID:", dialog_x + 20, y, 16, RL::WHITE)
      y += 25
      # ID field is only editable when creating new node
      id_result = UIHelpers.text_input(
        dialog_x + 20, y, dialog_width - 40, 25,
        @id_field, !@editing_mode, "Enter node ID"
      )
      @id_field = id_result[0]
      y += 40

      # Character name field
      RL.draw_text("Character Name (optional):", dialog_x + 20, y, 16, RL::WHITE)
      y += 25
      char_result = UIHelpers.text_input(
        dialog_x + 20, y, dialog_width - 40, 25,
        @character_field, true, "Enter character name"
      )
      @character_field = char_result[0]
      y += 40

      # Dialog text field (multiline)
      RL.draw_text("Dialog Text:", dialog_x + 20, y, 16, RL::WHITE)
      y += 25

      # Draw text area background
      text_area_height = 100
      RL.draw_rectangle(dialog_x + 20, y, dialog_width - 40, text_area_height,
        RL::Color.new(r: 40, g: 40, b: 40, a: 255))
      RL.draw_rectangle_lines(dialog_x + 20, y, dialog_width - 40, text_area_height, RL::LIGHTGRAY)

      # Simple multiline text editing
      # Use regular text input for now (multiline not implemented)
      text_result = UIHelpers.text_input(
        dialog_x + 20, y + 5, dialog_width - 50, 25,
        @text_field, true, "Enter dialog text"
      )
      @text_field = text_result[0]
      y += text_area_height + 20

      # Is End Node checkbox
      checkbox_size = 20
      is_checked = @is_end
      if UIHelpers.checkbox(dialog_x + 20, y, checkbox_size, is_checked, "end_node")
        @is_end = !@is_end
      end
      RL.draw_text("End Node", dialog_x + 20 + checkbox_size + 10, y + 2, 16, RL::WHITE)
      y += 40

      # Buttons
      button_width = 100
      button_height = 30
      button_spacing = 20

      # OK button
      ok_x = dialog_x + dialog_width - button_width * 2 - button_spacing - 20
      if UIHelpers.button(ok_x, y, button_width, button_height, "OK")
        if create_or_update_node
          hide
        end
      end

      # Cancel button
      cancel_x = dialog_x + dialog_width - button_width - 20
      if UIHelpers.button(cancel_x, y, button_width, button_height, "Cancel")
        hide
      end
    end

    private def create_or_update_node : Bool
      # Validate inputs
      if @id_field.empty?
        puts "Error: Node ID cannot be empty"
        return false
      end

      if @text_field.empty?
        puts "Error: Dialog text cannot be empty"
        return false
      end

      # Get current dialog from editor
      if editor = @state.dialog_editor
        if dialog = editor.current_dialog
          if @editing_mode
            # Update existing node
            if node = dialog.nodes[@node_id]?
              node.id = @id_field
              node.text = @text_field
              node.character_name = @character_field.empty? ? nil : @character_field
              node.is_end = @is_end

              # If ID changed, update in dialog
              if @id_field != @node_id
                dialog.nodes.delete(@node_id)
                dialog.nodes[@id_field] = node

                # Update references in other nodes
                dialog.nodes.each do |_, other_node|
                  other_node.choices.each do |choice|
                    if choice.target_node_id == @node_id
                      choice.target_node_id = @id_field
                    end
                  end
                end
              end
            end
          else
            # Create new node
            new_node = PointClickEngine::Characters::Dialogue::DialogNode.new(@id_field, @text_field)
            new_node.character_name = @character_field.empty? ? nil : @character_field
            new_node.is_end = @is_end

            dialog.add_node(new_node)

            # Set initial position for the new node
            if positions = editor.node_positions
              # Find a good position for the new node
              x = 100_f32
              y = 100_f32

              # Try to place it to the right of the last node
              if positions.size > 0
                max_x = positions.values.max_by(&.x).x
                x = max_x + 200
              end

              positions[@id_field] = RL::Vector2.new(x: x, y: y)
            end

            # Select the new node
            editor.selected_node = @id_field
          end

          # Save the dialog
          editor.save_current_dialog
          @state.mark_dirty

          return true
        end
      end

      puts "Error: No dialog editor or current dialog available"
      return false
    end
  end

  # Helper for checkbox
  module UIHelpers
    def self.checkbox(x : Int32, y : Int32, size : Int32, checked : Bool, id : String) : Bool
      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + size &&
                 mouse_pos.y >= y && mouse_pos.y <= y + size

      # Draw checkbox
      bg_color = is_hover ? RL::LIGHTGRAY : RL::GRAY
      RL.draw_rectangle(x, y, size, size, bg_color)
      RL.draw_rectangle_lines(x, y, size, size, RL::WHITE)

      # Draw check mark if checked
      if checked
        check_margin = 4
        RL.draw_line(x + check_margin, y + size // 2,
          x + size // 2, y + size - check_margin, RL::GREEN)
        RL.draw_line(x + size // 2, y + size - check_margin,
          x + size - check_margin, y + check_margin, RL::GREEN)
      end

      # Return true if clicked
      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end
  end
end
