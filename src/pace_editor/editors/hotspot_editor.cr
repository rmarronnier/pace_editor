module PaceEditor::Editors
  # Hotspot editor for creating and configuring interactive areas
  class HotspotEditor
    property current_hotspot : PointClickEngine::Hotspot? = nil
    property creating_hotspot : Bool = false
    property hotspot_start : RL::Vector2? = nil

    def initialize(@state : Core::EditorState)
    end

    def update
      handle_hotspot_creation
    end

    def draw
      editor_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      editor_y = Core::EditorWindow::MENU_HEIGHT
      editor_width = Core::EditorWindow::WINDOW_WIDTH - Core::EditorWindow::TOOL_PALETTE_WIDTH - Core::EditorWindow::PROPERTY_PANEL_WIDTH
      editor_height = Core::EditorWindow::WINDOW_HEIGHT - Core::EditorWindow::MENU_HEIGHT

      # Draw background
      RL.draw_rectangle(editor_x, editor_y, editor_width, editor_height,
        RL::Color.new(r: 40, g: 40, b: 40, a: 255))

      if hotspot = get_current_hotspot
        draw_hotspot_workspace(hotspot, editor_x, editor_y, editor_width, editor_height)
      else
        draw_no_hotspot_message(editor_x, editor_y, editor_width, editor_height)
      end

      # Draw creation overlay if creating
      if @creating_hotspot
        draw_creation_overlay(editor_x, editor_y, editor_width, editor_height)
      end
    end

    private def get_current_hotspot : PointClickEngine::Hotspot?
      return @current_hotspot if @current_hotspot

      # Try to get hotspot from selection
      if selected = @state.selected_object
        if scene = @state.current_scene
          @current_hotspot = scene.hotspots.find { |h| h.name == selected }
        end
      end

      @current_hotspot
    end

    private def draw_hotspot_workspace(hotspot : PointClickEngine::Hotspot, x : Int32, y : Int32, width : Int32, height : Int32)
      # Split workspace
      preview_width = width // 2
      controls_width = width - preview_width

      # Draw hotspot preview
      draw_hotspot_preview(hotspot, x, y, preview_width, height)

      # Draw hotspot controls
      draw_hotspot_controls(hotspot, x + preview_width, y, controls_width, height)
    end

    private def draw_hotspot_preview(hotspot : PointClickEngine::Hotspot, x : Int32, y : Int32, width : Int32, height : Int32)
      # Preview section background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 50, g: 50, b: 50, a: 255))
      RL.draw_line(x + width, y, x + width, y + height, RL::GRAY)

      # Preview title
      RL.draw_text("Hotspot Preview", x + 10, y + 10, 18, RL::WHITE)

      # Hotspot visualization
      preview_x = x + width // 2
      preview_y = y + height // 2

      # Scale hotspot to fit preview
      scale = [200.0f32 / hotspot.size.x, 150.0f32 / hotspot.size.y].min
      scale = [scale, 1.0f32].min

      preview_width = (hotspot.size.x * scale).to_i
      preview_height = (hotspot.size.y * scale).to_i

      # Draw hotspot shape
      RL.draw_rectangle(preview_x - preview_width//2, preview_y - preview_height//2,
        preview_width, preview_height, RL::Color.new(r: 100, g: 200, b: 100, a: 100))
      RL.draw_rectangle_lines(preview_x - preview_width//2, preview_y - preview_height//2,
        preview_width, preview_height, RL::GREEN)

      # Draw hotspot name
      name_width = RL.measure_text(hotspot.name, 16)
      RL.draw_text(hotspot.name, preview_x - name_width//2, preview_y - preview_height//2 - 25, 16, RL::WHITE)

      # Draw coordinates
      coord_text = "(#{hotspot.position.x.to_i}, #{hotspot.position.y.to_i})"
      coord_width = RL.measure_text(coord_text, 12)
      RL.draw_text(coord_text, preview_x - coord_width//2, preview_y + preview_height//2 + 10, 12, RL::LIGHTGRAY)

      # Draw size info
      size_text = "#{hotspot.size.x.to_i} x #{hotspot.size.y.to_i}"
      size_width = RL.measure_text(size_text, 12)
      RL.draw_text(size_text, preview_x - size_width//2, preview_y + preview_height//2 + 25, 12, RL::LIGHTGRAY)

      # Interaction test button
      if draw_button("Test Interaction", x + 10, y + height - 60, 120, 25)
        test_hotspot_interaction(hotspot)
      end
    end

    private def draw_hotspot_controls(hotspot : PointClickEngine::Hotspot, x : Int32, y : Int32, width : Int32, height : Int32)
      # Controls section background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 45, g: 45, b: 45, a: 255))

      # Controls title
      RL.draw_text("Hotspot Properties", x + 10, y + 10, 18, RL::WHITE)

      current_y = y + 40

      # Basic properties
      draw_section_header("Basic Properties", x, current_y, width)
      current_y += 30

      current_y = draw_property_field("Name:", hotspot.name, x, current_y, width)
      current_y = draw_property_field("Description:", hotspot.description, x, current_y, width)
      current_y = draw_property_field("X:", hotspot.position.x.to_s, x, current_y, width)
      current_y = draw_property_field("Y:", hotspot.position.y.to_s, x, current_y, width)
      current_y = draw_property_field("Width:", hotspot.size.x.to_s, x, current_y, width)
      current_y = draw_property_field("Height:", hotspot.size.y.to_s, x, current_y, width)

      current_y += 20

      # Interaction properties
      draw_section_header("Interaction", x, current_y, width)
      current_y += 30

      current_y = draw_property_field("Active:", hotspot.active.to_s, x, current_y, width)
      current_y = draw_property_field("Cursor:", "default", x, current_y, width)

      # Action buttons
      current_y += 10
      if draw_button("Edit Look Action", x + 10, current_y, 120, 25)
        edit_action("look")
      end

      if draw_button("Edit Use Action", x + 140, current_y, 120, 25)
        edit_action("use")
      end
      current_y += 35

      # Scripts section
      draw_section_header("Scripts", x, current_y, width)
      current_y += 30

      current_y = draw_property_field("On Enter:", "None", x, current_y, width)
      current_y = draw_property_field("On Exit:", "None", x, current_y, width)
      current_y = draw_property_field("On Click:", "None", x, current_y, width)

      # Script editing
      if draw_button("Edit Scripts", x + 10, current_y, 100, 25)
        edit_hotspot_scripts
      end
      current_y += 35

      # Advanced properties
      draw_section_header("Advanced", x, current_y, width)
      current_y += 30

      current_y = draw_property_field("Z-Order:", "0", x, current_y, width)
      current_y = draw_property_field("Tags:", "None", x, current_y, width)

      # Delete button
      current_y += 20
      if draw_button("Delete Hotspot", x + 10, current_y, 120, 25, RL::RED)
        delete_current_hotspot
      end
    end

    private def draw_no_hotspot_message(x : Int32, y : Int32, width : Int32, height : Int32)
      message = "No Hotspot Selected"
      message_width = RL.measure_text(message, 24)
      message_x = x + (width - message_width) // 2
      message_y = y + height // 2 - 80

      RL.draw_text(message, message_x, message_y, 24, RL::LIGHTGRAY)

      instruction = "Select a hotspot from the scene or create a new one"
      instruction_width = RL.measure_text(instruction, 16)
      instruction_x = x + (width - instruction_width) // 2
      RL.draw_text(instruction, instruction_x, message_y + 40, 16, RL::GRAY)

      # Create hotspot button
      button_width = 150
      button_x = x + (width - button_width) // 2
      if draw_button("Create Rectangle", button_x, message_y + 80, button_width, 30)
        start_hotspot_creation("rectangle")
      end

      if draw_button("Create Circle", button_x, message_y + 120, button_width, 30)
        start_hotspot_creation("circle")
      end
    end

    private def draw_creation_overlay(x : Int32, y : Int32, width : Int32, height : Int32)
      # Draw instructions for hotspot creation
      overlay_color = RL::Color.new(r: 0, g: 0, b: 0, a: 150)
      RL.draw_rectangle(x, y, width, height, overlay_color)

      message = "Click and drag to create hotspot"
      message_width = RL.measure_text(message, 20)
      message_x = x + (width - message_width) // 2
      message_y = y + height // 2

      RL.draw_text(message, message_x, message_y, 20, RL::WHITE)

      instruction = "Press ESC to cancel"
      instruction_width = RL.measure_text(instruction, 14)
      instruction_x = x + (width - instruction_width) // 2
      RL.draw_text(instruction, instruction_x, message_y + 30, 14, RL::LIGHTGRAY)
    end

    private def handle_hotspot_creation
      return unless @creating_hotspot

      mouse_pos = RL.get_mouse_position

      # Convert to world coordinates
      viewport_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      viewport_y = Core::EditorWindow::MENU_HEIGHT
      world_pos = @state.screen_to_world(RL::Vector2.new(
        x: mouse_pos.x - viewport_x,
        y: mouse_pos.y - viewport_y
      ))

      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        @hotspot_start = world_pos
      elsif RL.mouse_button_down?(RL::MouseButton::Left) && @hotspot_start
        # Draw preview of hotspot being created
        start_pos = @hotspot_start.not_nil!
        end_pos = world_pos

        min_x = [start_pos.x, end_pos.x].min
        min_y = [start_pos.y, end_pos.y].min
        width = (end_pos.x - start_pos.x).abs
        height = (end_pos.y - start_pos.y).abs

        # This would be drawn in the scene editor, not here
      elsif RL.mouse_button_released?(RL::MouseButton::Left) && @hotspot_start
        # Create the hotspot
        create_hotspot_from_drag(@hotspot_start.not_nil!, world_pos)
        @creating_hotspot = false
        @hotspot_start = nil
      elsif RL.key_pressed?(RL::KeyboardKey::Escape)
        # Cancel creation
        @creating_hotspot = false
        @hotspot_start = nil
      end
    end

    private def draw_section_header(title : String, x : Int32, y : Int32, width : Int32)
      RL.draw_text(title, x + 10, y, 16, RL::WHITE)
      RL.draw_line(x + 10, y + 20, x + width - 10, y + 20, RL::GRAY)
    end

    private def draw_property_field(label : String, value : String, x : Int32, y : Int32, width : Int32) : Int32
      label_width = 100

      RL.draw_text(label, x + 10, y, 12, RL::LIGHTGRAY)

      field_x = x + 10 + label_width
      field_width = width - label_width - 30
      field_height = 18

      RL.draw_rectangle(field_x, y - 2, field_width, field_height,
        RL::Color.new(r: 30, g: 30, b: 30, a: 255))
      RL.draw_rectangle_lines(field_x, y - 2, field_width, field_height, RL::GRAY)

      value_to_draw = value.size > 20 ? value[0...17] + "..." : value
      RL.draw_text(value_to_draw, field_x + 5, y, 12, RL::WHITE)

      y + 25
    end

    private def draw_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32, color : RL::Color = RL::WHITE) : Bool
      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      bg_color = if color == RL::RED
                   is_hover ? RL::Color.new(r: 150, g: 50, b: 50, a: 255) : RL::Color.new(r: 120, g: 40, b: 40, a: 255)
                 else
                   is_hover ? RL::Color.new(r: 80, g: 80, b: 80, a: 255) : RL::Color.new(r: 60, g: 60, b: 60, a: 255)
                 end

      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, color)

      text_width = RL.measure_text(text, 14)
      text_x = x + (width - text_width) // 2
      RL.draw_text(text, text_x, y + (height - 14) // 2, 14, color)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def start_hotspot_creation(shape : String)
      @creating_hotspot = true
      @state.current_mode = EditorMode::Scene # Switch back to scene to create
    end

    private def create_hotspot_from_drag(start_pos : RL::Vector2, end_pos : RL::Vector2)
      min_x = [start_pos.x, end_pos.x].min
      min_y = [start_pos.y, end_pos.y].min
      width = [(end_pos.x - start_pos.x).abs, 10].max # Minimum size
      height = [(end_pos.y - start_pos.y).abs, 10].max

      # Create new hotspot
      if scene = @state.current_scene
        new_hotspot = PointClickEngine::Hotspot.new(
          "hotspot_#{Time.utc.to_unix_ms}",
          RL::Vector2.new(x: min_x, y: min_y),
          RL::Vector2.new(x: width, y: height)
        )
        new_hotspot.description = "New hotspot"

        scene.add_hotspot(new_hotspot)
        @current_hotspot = new_hotspot
        @state.select_object(new_hotspot.name)
        @state.save_current_scene(scene)
      end
    end

    private def test_hotspot_interaction(hotspot : PointClickEngine::Hotspot)
      puts "Testing interaction with hotspot: #{hotspot.name}"
      puts "Description: #{hotspot.description}"
    end

    private def edit_action(action_type : String)
      puts "Would edit #{action_type} action for hotspot"
    end

    private def edit_hotspot_scripts
      puts "Would open script editor for hotspot"
    end

    private def delete_current_hotspot
      if hotspot = @current_hotspot
        if scene = @state.current_scene
          scene.hotspots.delete(hotspot)
          @current_hotspot = nil
          @state.clear_selection
          @state.save_current_scene(scene)
        end
      end
    end
  end
end
