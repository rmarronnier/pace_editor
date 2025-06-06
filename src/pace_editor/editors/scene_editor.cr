require "raylib-cr/rlgl"

module PaceEditor::Editors
  # Scene editor for visual scene editing with drag-and-drop
  class SceneEditor
    property drag_start : RL::Vector2? = nil
    property dragging_object : String? = nil
    property is_camera_dragging : Bool = false

    def initialize(@state : Core::EditorState, @viewport_x : Int32, @viewport_y : Int32, @viewport_width : Int32, @viewport_height : Int32)
    end

    def update
      handle_mouse_input
      handle_keyboard_input
    end

    def draw
      return unless scene = @state.current_scene

      # Draw grid
      draw_grid if @state.show_grid

      # Apply camera transform
      RLGL.push_matrix
      RLGL.translate_f(-@state.camera_x * @state.zoom, -@state.camera_y * @state.zoom, 0)
      RLGL.scale_f(@state.zoom, @state.zoom, 1)

      # Draw scene background
      if scene.background_path && scene.background
        RL.draw_texture(scene.background.not_nil!, 0, 0, RL::WHITE)
      else
        draw_background_placeholder
      end

      # Draw scene objects
      draw_hotspots(scene) if @state.show_hotspots
      draw_characters(scene) if @state.show_character_bounds
      draw_objects(scene)

      # Draw selection indicators
      draw_selection_indicators(scene)

      RLGL.pop_matrix

      # Draw UI overlays (not affected by camera)
      draw_tool_overlay
      draw_info_overlay
    end

    private def handle_mouse_input
      mouse_pos = RL.get_mouse_position

      # Check if mouse is in viewport
      return unless mouse_in_viewport?(mouse_pos)

      world_pos = @state.screen_to_world(RL::Vector2.new(
        x: mouse_pos.x - @viewport_x,
        y: mouse_pos.y - @viewport_y
      ))

      case @state.current_tool
      when .select?
        handle_select_tool(world_pos)
      when .move?
        handle_move_tool(world_pos)
      when .place?
        handle_place_tool(world_pos)
      when .delete?
        handle_delete_tool(world_pos)
      end
    end

    private def handle_select_tool(world_pos : RL::Vector2)
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        # Find object at position
        if object_name = find_object_at_position(world_pos)
          multi_select = RL.key_down?(RL::KeyboardKey::LeftControl) || RL.key_down?(RL::KeyboardKey::RightControl)
          @state.select_object(object_name, multi_select)
        else
          @state.clear_selection unless RL.key_down?(RL::KeyboardKey::LeftControl) || RL.key_down?(RL::KeyboardKey::RightControl)
        end
      end

      # Handle selection rectangle
      if RL.mouse_button_down?(RL::MouseButton::Left) && @drag_start
        draw_selection_rectangle
      elsif RL.mouse_button_pressed?(RL::MouseButton::Left)
        @drag_start = world_pos
      elsif RL.mouse_button_released?(RL::MouseButton::Left)
        @drag_start = nil
      end
    end

    private def handle_move_tool(world_pos : RL::Vector2)
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        if object_name = find_object_at_position(world_pos)
          @dragging_object = object_name
          @drag_start = world_pos
          @state.select_object(object_name)
        end
      elsif RL.mouse_button_down?(RL::MouseButton::Left) && @dragging_object && @drag_start
        # Calculate movement delta
        delta = RL::Vector2.new(
          x: world_pos.x - @drag_start.not_nil!.x,
          y: world_pos.y - @drag_start.not_nil!.y
        )

        # Apply snap to grid
        snapped_pos = @state.snap_to_grid(world_pos)

        # Move object (in a real implementation, this would update the actual object)
        # For now, just update the visual feedback

      elsif RL.mouse_button_released?(RL::MouseButton::Left)
        if @dragging_object && @drag_start
          # Complete the move operation
          # This would create an undo action and save the scene
        end
        @dragging_object = nil
        @drag_start = nil
      end
    end

    private def handle_place_tool(world_pos : RL::Vector2)
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        place_object_at_position(world_pos)
      end
    end

    private def handle_delete_tool(world_pos : RL::Vector2)
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        if object_name = find_object_at_position(world_pos)
          delete_object(object_name)
        end
      end
    end

    private def handle_keyboard_input
      # Camera movement with arrow keys
      camera_speed = 5.0f32 / @state.zoom

      if RL.key_down?(RL::KeyboardKey::Left)
        @state.camera_x -= camera_speed
      elsif RL.key_down?(RL::KeyboardKey::Right)
        @state.camera_x += camera_speed
      end

      if RL.key_down?(RL::KeyboardKey::Up)
        @state.camera_y -= camera_speed
      elsif RL.key_down?(RL::KeyboardKey::Down)
        @state.camera_y += camera_speed
      end

      # Delete selected objects
      if RL.key_pressed?(RL::KeyboardKey::Delete) && @state.selected_object
        delete_object(@state.selected_object.not_nil!)
      end
    end

    private def draw_grid
      grid_size = @state.grid_size

      # Calculate grid bounds based on camera and zoom
      start_x = (@state.camera_x / grid_size).floor.to_i * grid_size
      start_y = (@state.camera_y / grid_size).floor.to_i * grid_size
      end_x = start_x + (@viewport_width / @state.zoom).to_i + grid_size
      end_y = start_y + (@viewport_height / @state.zoom).to_i + grid_size

      # Draw vertical lines
      x = start_x
      while x <= end_x
        screen_x = @viewport_x + ((x - @state.camera_x) * @state.zoom).to_i
        if screen_x >= @viewport_x && screen_x <= @viewport_x + @viewport_width
          RL.draw_line(screen_x, @viewport_y, screen_x, @viewport_y + @viewport_height,
            RL::Color.new(r: 80, g: 80, b: 80, a: 255))
        end
        x += grid_size
      end

      # Draw horizontal lines
      y = start_y
      while y <= end_y
        screen_y = @viewport_y + ((y - @state.camera_y) * @state.zoom).to_i
        if screen_y >= @viewport_y && screen_y <= @viewport_y + @viewport_height
          RL.draw_line(@viewport_x, screen_y, @viewport_x + @viewport_width, screen_y,
            RL::Color.new(r: 80, g: 80, b: 80, a: 255))
        end
        y += grid_size
      end
    end

    private def draw_background_placeholder
      # Draw a checkerboard pattern to indicate no background
      checker_size = 32
      cols = ((800 / checker_size) + 1).to_i
      rows = ((600 / checker_size) + 1).to_i

      rows.times do |row|
        cols.times do |col|
          color = ((row + col) % 2 == 0) ? RL::Color.new(r: 100, g: 100, b: 100, a: 255) : RL::Color.new(r: 120, g: 120, b: 120, a: 255)
          RL.draw_rectangle(col * checker_size, row * checker_size, checker_size, checker_size, color)
        end
      end

      # Draw "No Background" text
      text = "No Background - Drop image here"
      text_width = RL.measure_text(text, 24)
      RL.draw_text(text, (800 - text_width) // 2, 300, 24, RL::Color.new(r: 200, g: 200, b: 200, a: 150))
    end

    private def draw_hotspots(scene : PointClickEngine::Scene)
      scene.hotspots.each do |hotspot|
        # Draw hotspot bounds
        color = @state.is_selected?(hotspot.name) ? RL::YELLOW : RL::GREEN
        alpha = 100u8
        fill_color = RL::Color.new(r: color.r, g: color.g, b: color.b, a: alpha)

        RL.draw_rectangle(hotspot.position.x.to_i, hotspot.position.y.to_i,
          hotspot.size.x.to_i, hotspot.size.y.to_i, fill_color)
        RL.draw_rectangle_lines(hotspot.position.x.to_i, hotspot.position.y.to_i,
          hotspot.size.x.to_i, hotspot.size.y.to_i, color)

        # Draw hotspot name
        RL.draw_text(hotspot.name, hotspot.position.x.to_i + 5, hotspot.position.y.to_i + 5, 12, color)
      end
    end

    private def draw_characters(scene : PointClickEngine::Scene)
      scene.characters.each do |character|
        # Draw character bounds
        color = @state.is_selected?(character.name) ? RL::YELLOW : RL::BLUE

        RL.draw_rectangle_lines(character.position.x.to_i, character.position.y.to_i,
          character.size.x.to_i, character.size.y.to_i, color)

        # Draw character sprite if available
        # For now, just draw a placeholder
        RL.draw_rectangle(character.position.x.to_i + 2, character.position.y.to_i + 2,
          character.size.x.to_i - 4, character.size.y.to_i - 4,
          RL::Color.new(r: 100, g: 100, b: 200, a: 150))

        # Draw character name
        RL.draw_text(character.name, character.position.x.to_i, character.position.y.to_i - 15, 12, color)
      end
    end

    private def draw_objects(scene : PointClickEngine::Scene)
      scene.objects.each do |object|
        # Skip objects that are already drawn as characters or hotspots
        next if scene.characters.any? { |c| c == object }
        next if scene.hotspots.any? { |h| h == object }

        # Draw generic object
        RL.draw_rectangle_lines(object.position.x.to_i, object.position.y.to_i,
          object.size.x.to_i, object.size.y.to_i, RL::WHITE)
      end
    end

    private def draw_selection_indicators(scene : PointClickEngine::Scene)
      if selected = @state.selected_object
        # Find and highlight selected object
        if hotspot = scene.hotspots.find { |h| h.name == selected }
          draw_selection_outline(hotspot.position, hotspot.size)
        elsif character = scene.characters.find { |c| c.name == selected }
          draw_selection_outline(character.position, character.size)
        end
      end
    end

    private def draw_selection_outline(position : RL::Vector2, size : RL::Vector2)
      # Draw animated selection outline
      time = RL.get_time
      alpha = (128 + 127 * Math.sin(time * 4)).to_u8

      outline_color = RL::Color.new(r: 255, g: 255, b: 0, a: alpha)
      RL.draw_rectangle_lines(position.x.to_i - 2, position.y.to_i - 2,
        size.x.to_i + 4, size.y.to_i + 4, outline_color)
    end

    private def draw_selection_rectangle
      return unless drag_start = @drag_start

      mouse_pos = RL.get_mouse_position
      world_pos = @state.screen_to_world(RL::Vector2.new(
        x: mouse_pos.x - @viewport_x,
        y: mouse_pos.y - @viewport_y
      ))

      min_x = [drag_start.x, world_pos.x].min
      min_y = [drag_start.y, world_pos.y].min
      width = (world_pos.x - drag_start.x).abs
      height = (world_pos.y - drag_start.y).abs

      RL.draw_rectangle(min_x.to_i, min_y.to_i, width.to_i, height.to_i,
        RL::Color.new(r: 100, g: 150, b: 200, a: 50))
      RL.draw_rectangle_lines(min_x.to_i, min_y.to_i, width.to_i, height.to_i, RL::BLUE)
    end

    private def draw_tool_overlay
      # Draw tool-specific overlay information
      mouse_pos = RL.get_mouse_position
      return unless mouse_in_viewport?(mouse_pos)

      world_pos = @state.screen_to_world(RL::Vector2.new(
        x: mouse_pos.x - @viewport_x,
        y: mouse_pos.y - @viewport_y
      ))

      case @state.current_tool
      when .place?
        # Show placement preview
        snapped_pos = @state.snap_to_grid(world_pos)
        screen_pos = @state.world_to_screen(snapped_pos)
        preview_size = 64

        RL.draw_rectangle_lines(
          @viewport_x + screen_pos.x.to_i - preview_size//2,
          @viewport_y + screen_pos.y.to_i - preview_size//2,
          preview_size, preview_size, RL::WHITE
        )
      end
    end

    private def draw_info_overlay
      # Draw coordinate information
      mouse_pos = RL.get_mouse_position
      return unless mouse_in_viewport?(mouse_pos)

      world_pos = @state.screen_to_world(RL::Vector2.new(
        x: mouse_pos.x - @viewport_x,
        y: mouse_pos.y - @viewport_y
      ))

      info_text = "X: #{world_pos.x.to_i} Y: #{world_pos.y.to_i}"
      RL.draw_text(info_text, @viewport_x + 10, @viewport_y + @viewport_height - 25, 12, RL::WHITE)
    end

    private def mouse_in_viewport?(mouse_pos : RL::Vector2) : Bool
      mouse_pos.x >= @viewport_x && mouse_pos.x <= @viewport_x + @viewport_width &&
        mouse_pos.y >= @viewport_y && mouse_pos.y <= @viewport_y + @viewport_height
    end

    private def find_object_at_position(world_pos : RL::Vector2) : String?
      return nil unless scene = @state.current_scene

      # Check hotspots first (they have priority)
      scene.hotspots.reverse_each do |hotspot|
        if point_in_rect?(world_pos, hotspot.position, hotspot.size)
          return hotspot.name
        end
      end

      # Check characters
      scene.characters.reverse_each do |character|
        if point_in_rect?(world_pos, character.position, character.size)
          return character.name
        end
      end

      nil
    end

    private def point_in_rect?(point : RL::Vector2, rect_pos : RL::Vector2, rect_size : RL::Vector2) : Bool
      point.x >= rect_pos.x && point.x <= rect_pos.x + rect_size.x &&
        point.y >= rect_pos.y && point.y <= rect_pos.y + rect_size.y
    end

    private def place_object_at_position(world_pos : RL::Vector2)
      snapped_pos = @state.snap_to_grid(world_pos)

      # Create a new hotspot at the position (example)
      new_hotspot_name = "hotspot_#{Time.utc.to_unix_ms}"

      # In a real implementation, this would create the hotspot and add it to the scene
      puts "Would place object at #{snapped_pos.x}, #{snapped_pos.y}"

      # Add undo action
      # @state.add_undo_action(CreateObjectAction.new(new_hotspot_name, "hotspot_data"))
    end

    private def delete_object(object_name : String)
      # In a real implementation, this would remove the object from the scene
      puts "Would delete object: #{object_name}"

      # Clear selection if deleted object was selected
      if @state.selected_object == object_name
        @state.clear_selection
      end

      # Add undo action
      # @state.add_undo_action(DeleteObjectAction.new(object_name, "object_data"))
    end
  end
end
