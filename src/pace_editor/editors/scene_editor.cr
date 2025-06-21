require "raylib-cr/rlgl"

module PaceEditor::Editors
  # Scene editor combining best features from both implementations
  class SceneEditor
    property viewport_x : Int32
    property viewport_y : Int32
    property viewport_width : Int32
    property viewport_height : Int32

    # Dragging state
    @dragging : Bool = false
    @drag_start : RL::Vector2
    @selection_rect : RL::Rectangle?
    @selecting : Bool = false
    @camera_dragging : Bool = false
    @last_mouse_pos : RL::Vector2

    def initialize(@state : Core::EditorState, @viewport_x : Int32, @viewport_y : Int32,
                   @viewport_width : Int32, @viewport_height : Int32)
      @drag_start = RL::Vector2.new(0, 0)
      @last_mouse_pos = RL::Vector2.new(0, 0)
    end

    def update_viewport(x : Int32, y : Int32, width : Int32, height : Int32)
      @viewport_x = x
      @viewport_y = y
      @viewport_width = width
      @viewport_height = height
    end

    def update
      mouse_pos = RL.get_mouse_position
      viewport_bounds = RL::Rectangle.new(
        x: @viewport_x.to_f32,
        y: @viewport_y.to_f32,
        width: @viewport_width.to_f32,
        height: @viewport_height.to_f32
      )

      # Only process input if mouse is in viewport
      if mouse_in_viewport?(mouse_pos)
        handle_camera_controls
        handle_tool_input
      end

      handle_keyboard_shortcuts
      @last_mouse_pos = mouse_pos
    end

    def draw
      return unless scene = @state.current_scene

      # Set up viewport clipping
      RL.begin_scissor_mode(@viewport_x, @viewport_y, @viewport_width, @viewport_height)

      # Clear viewport
      RL.draw_rectangle(@viewport_x, @viewport_y, @viewport_width, @viewport_height,
        RL::Color.new(r: 30, g: 30, b: 30, a: 255))

      # Draw grid using enhanced helpers
      if @state.show_grid
        UI::UIHelpers.draw_grid(
          RL::Vector2.new(@state.camera_x, @state.camera_y),
          @state.zoom,
          @state.grid_size,
          @viewport_width,
          @viewport_height
        )
      end

      # Apply camera transform
      RLGL.push_matrix
      RLGL.translate_f(@viewport_x - @state.camera_x * @state.zoom,
        @viewport_y - @state.camera_y * @state.zoom, 0)
      RLGL.scale_f(@state.zoom, @state.zoom, 1)

      # Draw scene background
      if scene.background_path && scene.background
        RL.draw_texture(scene.background.not_nil!, 0, 0, RL::WHITE)
      else
        draw_background_placeholder
      end

      # Draw scene objects with enhanced rendering
      draw_hotspots(scene) if @state.show_hotspots
      draw_characters(scene) if @state.show_character_bounds
      draw_objects(scene)

      # Draw selection indicators
      draw_selection_indicators(scene)

      # Draw current tool preview
      draw_tool_preview if @state.current_tool != :select

      RLGL.pop_matrix

      # Draw selection rectangle (screen space)
      if rect = @selection_rect
        RL.draw_rectangle_lines_ex(rect, 2, RL::Color.new(r: 100, g: 150, b: 200, a: 200))
        RL.draw_rectangle_rec(rect, RL::Color.new(r: 100, g: 150, b: 200, a: 50))
      end

      RL.end_scissor_mode

      # Draw viewport border
      RL.draw_rectangle_lines(@viewport_x, @viewport_y, @viewport_width, @viewport_height,
        UI::UIHelpers::PANEL_BORDER_COLOR)
    end

    private def handle_camera_controls
      # Mouse wheel zoom (enhanced with smooth zooming)
      wheel = RL.get_mouse_wheel_move
      if wheel != 0
        # Zoom towards mouse position
        mouse_world_before = screen_to_world(RL.get_mouse_position)

        zoom_factor = wheel > 0 ? 1.1f32 : 0.9f32
        @state.zoom *= zoom_factor
        @state.zoom = @state.zoom.clamp(0.1f32, 5.0f32)

        # Adjust camera to keep mouse position stable
        mouse_world_after = screen_to_world(RL.get_mouse_position)
        @state.camera_x -= (mouse_world_after.x - mouse_world_before.x)
        @state.camera_y -= (mouse_world_after.y - mouse_world_before.y)
      end

      # Middle mouse pan (or space + left mouse)
      if RL.mouse_button_down?(RL::MouseButton::Middle) ||
         (RL.key_down?(RL::KeyboardKey::Space) && RL.mouse_button_down?(RL::MouseButton::Left))
        if !@camera_dragging
          @camera_dragging = true
          @drag_start = RL.get_mouse_position
        end

        delta = RL.get_mouse_delta
        @state.camera_x -= delta.x / @state.zoom
        @state.camera_y -= delta.y / @state.zoom
      else
        @camera_dragging = false
      end

      # Keyboard pan with smooth movement
      pan_speed = 5.0f32 / @state.zoom
      pan_speed *= 3.0f32 if RL.key_down?(RL::KeyboardKey::LeftShift)

      @state.camera_x -= pan_speed if RL.key_down?(RL::KeyboardKey::A) || RL.key_down?(RL::KeyboardKey::Left)
      @state.camera_x += pan_speed if RL.key_down?(RL::KeyboardKey::D) || RL.key_down?(RL::KeyboardKey::Right)
      @state.camera_y -= pan_speed if RL.key_down?(RL::KeyboardKey::W) || RL.key_down?(RL::KeyboardKey::Up)
      @state.camera_y += pan_speed if RL.key_down?(RL::KeyboardKey::S) || RL.key_down?(RL::KeyboardKey::Down)
    end

    private def handle_tool_input
      return if @camera_dragging

      mouse_pos = RL.get_mouse_position
      world_pos = screen_to_world(mouse_pos)

      case @state.current_tool
      when Tool::Select
        handle_select_tool(mouse_pos, world_pos)
      when Tool::Move
        handle_move_tool(world_pos)
      when Tool::Place
        handle_place_tool(world_pos)
      when Tool::Delete
        handle_delete_tool(world_pos)
      when "hotspot"
        handle_hotspot_tool(world_pos)
      when "character"
        handle_character_tool(world_pos)
      end
    end

    private def handle_select_tool(screen_pos : RL::Vector2, world_pos : RL::Vector2)
      return unless scene = @state.current_scene

      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        @selecting = true
        @drag_start = screen_pos

        # Check if clicking on an object
        if obj = get_object_at(scene, world_pos)
          if RL.key_down?(RL::KeyboardKey::LeftControl)
            # Toggle selection
            if @state.selected_object == obj
              @state.selected_object = nil
            else
              @state.selected_object = obj
            end
          else
            # Single selection
            @state.selected_object = obj
          end

          # Start dragging if object selected
          if @state.selected_object == obj
            @dragging = true
            @state.current_tool = Tool::Move
          end
          @selecting = false
        else
          # Start selection rectangle
          @state.selected_object = nil unless RL.key_down?(RL::KeyboardKey::LeftControl)
        end
      end

      if @selecting && RL.mouse_button_down?(RL::MouseButton::Left)
        # Update selection rectangle
        current_pos = RL.get_mouse_position
        x = Math.min(@drag_start.x, current_pos.x)
        y = Math.min(@drag_start.y, current_pos.y)
        w = (current_pos.x - @drag_start.x).abs
        h = (current_pos.y - @drag_start.y).abs
        @selection_rect = RL::Rectangle.new(x: x, y: y, width: w, height: h)
      end

      if @selecting && RL.mouse_button_released?(RL::MouseButton::Left)
        # Finish selection
        if rect = @selection_rect
          select_objects_in_rect(rect)
        end
        @selecting = false
        @selection_rect = nil
      end
    end

    private def handle_move_tool(world_pos : RL::Vector2)
      return if @state.selected_object.nil?

      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        @dragging = true
        @drag_start = world_pos
      end

      if @dragging && RL.mouse_button_down?(RL::MouseButton::Left)
        delta = RL::Vector2.new(
          world_pos.x - @drag_start.x,
          world_pos.y - @drag_start.y
        )

        # Move selected object
        if obj_name = @state.selected_object
          if scene = @state.current_scene
            # Find and move the object
            if hotspot = scene.hotspots.find { |h| h.name == obj_name }
              new_x = hotspot.position.x + delta.x.to_i
              new_y = hotspot.position.y + delta.y.to_i

              # Snap to grid if enabled
              if @state.snap_to_grid
                new_x = (new_x / @state.grid_size).round * @state.grid_size
                new_y = (new_y / @state.grid_size).round * @state.grid_size
              end

              hotspot.position = RL::Vector2.new(new_x.to_f32, new_y.to_f32)
            elsif character = scene.characters.find { |c| c.name == obj_name }
              new_x = character.position.x + delta.x.to_i
              new_y = character.position.y + delta.y.to_i

              if @state.snap_to_grid
                new_x = (new_x / @state.grid_size).round * @state.grid_size
                new_y = (new_y / @state.grid_size).round * @state.grid_size
              end

              character.position = RL::Vector2.new(new_x.to_f32, new_y.to_f32)
            end
          end
        end

        @drag_start = world_pos
      end

      if @dragging && RL.mouse_button_released?(RL::MouseButton::Left)
        @dragging = false
      end
    end

    private def handle_place_tool(world_pos : RL::Vector2)
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        # Placeholder for object placement
        puts "Place object at #{world_pos.x}, #{world_pos.y}"
      end
    end

    private def handle_delete_tool(world_pos : RL::Vector2)
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        if scene = @state.current_scene
          if obj = get_object_at(scene, world_pos)
            # Remove from scene
            scene.hotspots.reject! { |h| h.name == obj }
            scene.characters.reject! { |c| c.name == obj }

            # Clear selection if deleted object was selected
            if @state.selected_object == obj
              @state.selected_object = nil
            end
          end
        end
      end
    end

    private def handle_hotspot_tool(world_pos : RL::Vector2)
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        if scene = @state.current_scene
          # Create new hotspot
          hotspot_count = scene.hotspots.size + 1
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            name: "hotspot_#{hotspot_count}",
            position: RL::Vector2.new(
              snap_to_grid(world_pos.x.to_i).to_f32,
              snap_to_grid(world_pos.y.to_i).to_f32
            ),
            size: RL::Vector2.new(64.0_f32, 64.0_f32)
          )
          scene.hotspots << hotspot
          @state.selected_object = hotspot.name
        end
      end
    end

    private def handle_character_tool(world_pos : RL::Vector2)
      # Placeholder for character placement
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        puts "Place character at #{world_pos.x}, #{world_pos.y}"
      end
    end

    private def handle_keyboard_shortcuts
      # Delete selected objects
      if RL.key_pressed?(RL::KeyboardKey::Delete)
        delete_selected_objects
      end

      # Select all
      if RL.key_down?(RL::KeyboardKey::LeftControl) && RL.key_pressed?(RL::KeyboardKey::A)
        select_all_objects
      end

      # Deselect all
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        @state.selected_object = nil
      end

      # Reset view
      if RL.key_pressed?(RL::KeyboardKey::Home)
        @state.camera_x = 0
        @state.camera_y = 0
        @state.zoom = 1.0f32
      end
    end

    private def draw_background_placeholder
      # Draw checkerboard pattern
      checker_size = 32
      cols = 30
      rows = 20

      (0...rows).each do |row|
        (0...cols).each do |col|
          color = (row + col) % 2 == 0 ? RL::DARKGRAY : RL::GRAY
          RL.draw_rectangle(
            col * checker_size,
            row * checker_size,
            checker_size,
            checker_size,
            color
          )
        end
      end

      # Draw text
      text = "No Background"
      text_width = RL.measure_text(text, 40)
      RL.draw_text(text,
        (cols * checker_size - text_width) // 2,
        (rows * checker_size - 40) // 2,
        40,
        RL::WHITE
      )
    end

    private def draw_hotspots(scene)
      scene.hotspots.each do |hotspot|
        # Determine color based on selection
        is_selected = is_hotspot_selected?(hotspot.name)
        color = if is_selected
                  RL::Color.new(r: 255, g: 200, b: 0, a: 100)
                else
                  RL::Color.new(r: 255, g: 100, b: 0, a: 80)
                end

        # Draw hotspot rectangle
        x = hotspot.position.x.to_i
        y = hotspot.position.y.to_i
        width = hotspot.size.x.to_i
        height = hotspot.size.y.to_i

        RL.draw_rectangle(x, y, width, height, color)
        RL.draw_rectangle_lines(x, y, width, height,
          is_selected ? RL::YELLOW : RL::ORANGE)

        # Draw name
        if @state.zoom > 0.5
          font_size = (12 * @state.zoom).to_i
          RL.draw_text(hotspot.name, x + 2, y + 2, font_size, RL::WHITE)
        end

        # Draw cursor type icon
        if @state.show_hotspots && @state.zoom > 0.7
          draw_cursor_icon(hotspot)
        end
      end
    end

    private def draw_characters(scene)
      scene.characters.each do |character|
        # Get character position and size
        x = character.position.x.to_i
        y = character.position.y.to_i
        width = character.size.x.to_i
        height = character.size.y.to_i

        # Draw character bounds
        bounds_color = is_character_selected?(character.name) ? RL::YELLOW : RL::GREEN
        RL.draw_rectangle_lines(
          x - width // 2,
          y - height // 2,
          width,
          height,
          bounds_color
        )

        # Draw name
        if @state.zoom > 0.5
          font_size = (12 * @state.zoom).to_i
          text_width = RL.measure_text(character.name, font_size)
          RL.draw_text(character.name,
            x - text_width // 2,
            y - height // 2 - font_size - 2,
            font_size,
            RL::WHITE
          )
        end
      end
    end

    private def draw_objects(scene)
      # Draw other scene objects if any
    end

    private def draw_selection_indicators(scene)
      # Draw resize handles for selected hotspots
      @state.selected_hotspots.each do |hotspot_name|
        if hotspot = scene.hotspots.find { |h| h.name == hotspot_name }
          draw_resize_handles(
            hotspot.position.x.to_i,
            hotspot.position.y.to_i,
            hotspot.size.x.to_i,
            hotspot.size.y.to_i
          )
        end
      end

      # Draw resize handles for selected characters
      @state.selected_characters.each do |char_name|
        if character = scene.characters.find { |c| c.name == char_name }
          x = character.position.x.to_i
          y = character.position.y.to_i
          width = character.size.x.to_i
          height = character.size.y.to_i
          draw_resize_handles(
            x - width // 2,
            y - height // 2,
            width,
            height
          )
        end
      end

      # Draw resize handles for single selected object
      if obj_name = @state.selected_object
        if hotspot = scene.hotspots.find { |h| h.name == obj_name }
          draw_resize_handles(
            hotspot.position.x.to_i,
            hotspot.position.y.to_i,
            hotspot.size.x.to_i,
            hotspot.size.y.to_i
          )
        elsif character = scene.characters.find { |c| c.name == obj_name }
          x = character.position.x.to_i
          y = character.position.y.to_i
          width = character.size.x.to_i
          height = character.size.y.to_i
          draw_resize_handles(
            x - width // 2,
            y - height // 2,
            width,
            height
          )
        end
      end
    end

    private def draw_resize_handles(x : Int32, y : Int32, width : Int32, height : Int32)
      handle_size = (6 / @state.zoom).to_i.clamp(4, 8)

      # Corner handles
      positions = [
        {x, y},                       # Top-left
        {x + width, y},               # Top-right
        {x, y + height},              # Bottom-left
        {x + width, y + height},      # Bottom-right
        {x + width // 2, y},          # Top-middle
        {x + width // 2, y + height}, # Bottom-middle
        {x, y + height // 2},         # Left-middle
        {x + width, y + height // 2}, # Right-middle
      ]

      positions.each do |pos|
        RL.draw_rectangle(
          pos[0] - handle_size // 2,
          pos[1] - handle_size // 2,
          handle_size,
          handle_size,
          RL::WHITE
        )
        RL.draw_rectangle_lines(
          pos[0] - handle_size // 2,
          pos[1] - handle_size // 2,
          handle_size,
          handle_size,
          RL::BLACK
        )
      end
    end

    private def draw_tool_preview
      mouse_pos = RL.get_mouse_position
      world_pos = screen_to_world(mouse_pos)

      case @state.current_tool
      when "hotspot"
        # Preview hotspot placement
        x = snap_to_grid(world_pos.x.to_i)
        y = snap_to_grid(world_pos.y.to_i)
        RL.draw_rectangle_lines(x, y, 64, 64, RL::Color.new(r: 255, g: 255, b: 255, a: 128))
      when "character"
        # Preview character placement
        x = snap_to_grid(world_pos.x.to_i)
        y = snap_to_grid(world_pos.y.to_i)
        RL.draw_rectangle_lines(x - 16, y - 24, 32, 48, RL::Color.new(r: 0, g: 255, b: 0, a: 128))
      end
    end

    private def draw_cursor_icon(hotspot)
      icon = case hotspot.cursor_type
             when :hand then "✋"
             when :look then "👁"
             when :talk then "💬"
             when :use  then "⚙"
             else            "➤"
             end

      font_size = (16 * @state.zoom).to_i
      x = hotspot.position.x.to_i
      y = hotspot.position.y.to_i
      width = hotspot.size.x.to_i
      RL.draw_text(icon,
        x + width - font_size - 2,
        y + 2,
        font_size,
        RL::WHITE
      )
    end

    private def screen_to_world(screen_pos : RL::Vector2) : RL::Vector2
      RL::Vector2.new(
        (screen_pos.x - @viewport_x) / @state.zoom + @state.camera_x,
        (screen_pos.y - @viewport_y) / @state.zoom + @state.camera_y
      )
    end

    private def world_to_screen(world_pos : RL::Vector2) : RL::Vector2
      RL::Vector2.new(
        (world_pos.x - @state.camera_x) * @state.zoom + @viewport_x,
        (world_pos.y - @state.camera_y) * @state.zoom + @viewport_y
      )
    end

    private def get_object_at(scene, world_pos : RL::Vector2) : String?
      # Check hotspots
      scene.hotspots.reverse.each do |hotspot|
        if world_pos.x >= hotspot.position.x && world_pos.x <= hotspot.position.x + hotspot.size.x &&
           world_pos.y >= hotspot.position.y && world_pos.y <= hotspot.position.y + hotspot.size.y
          return hotspot.name
        end
      end

      # Check characters
      scene.characters.each do |character|
        if world_pos.x >= character.position.x - 25 &&
           world_pos.x <= character.position.x + 25 &&
           world_pos.y >= character.position.y - 50 &&
           world_pos.y <= character.position.y + 50
          return character.name
        end
      end

      nil
    end

    private def select_objects_in_rect(rect : RL::Rectangle)
      return unless scene = @state.current_scene

      # Convert screen rect to world coordinates
      top_left = screen_to_world(RL::Vector2.new(rect.x, rect.y))
      bottom_right = screen_to_world(RL::Vector2.new(rect.x + rect.width, rect.y + rect.height))

      world_rect = RL::Rectangle.new(
        x: top_left.x,
        y: top_left.y,
        width: bottom_right.x - top_left.x,
        height: bottom_right.y - top_left.y
      )

      # Select all objects in rectangle
      scene.hotspots.each do |hotspot|
        hotspot_rect = RL::Rectangle.new(
          x: hotspot.position.x.to_f32,
          y: hotspot.position.y.to_f32,
          width: hotspot.size.x.to_f32,
          height: hotspot.size.y.to_f32
        )

        if rects_overlap?(hotspot_rect, world_rect)
          @state.selected_object = hotspot.name
        end
      end

      scene.characters.each do |character|
        char_rect = RL::Rectangle.new(
          x: (character.position.x - 25).to_f32,
          y: (character.position.y - 50).to_f32,
          width: 50.0_f32,
          height: 100.0_f32
        )

        if rects_overlap?(char_rect, world_rect)
          @state.selected_object = character.name
        end
      end
    end

    private def delete_selected_objects
      return unless scene = @state.current_scene

      # Delete selected hotspots
      @state.selected_hotspots.each do |hotspot_name|
        scene.hotspots.reject! { |h| h.name == hotspot_name }
      end

      # Delete selected characters
      @state.selected_characters.each do |char_name|
        scene.characters.reject! { |c| c.name == char_name }
      end

      # Also delete single selected object if any
      if obj_name = @state.selected_object
        scene.hotspots.reject! { |h| h.name == obj_name }
        scene.characters.reject! { |c| c.name == obj_name }
      end

      # Clear all selections
      @state.selected_object = nil
      @state.selected_hotspots.clear
      @state.selected_characters.clear
    end

    private def select_all_objects
      return unless scene = @state.current_scene

      # Clear single selection
      @state.selected_object = nil

      # Select all hotspots
      @state.selected_hotspots.clear
      scene.hotspots.each do |hotspot|
        @state.selected_hotspots << hotspot.name
      end

      # Select all characters
      @state.selected_characters.clear
      scene.characters.each do |character|
        @state.selected_characters << character.name
      end
    end

    private def snap_to_grid(value : Int32) : Int32
      return value unless @state.snap_to_grid
      ((value / @state.grid_size).round * @state.grid_size).to_i
    end

    private def mouse_in_viewport?(mouse_pos : RL::Vector2) : Bool
      mouse_pos.x >= @viewport_x && mouse_pos.x <= @viewport_x + @viewport_width &&
        mouse_pos.y >= @viewport_y && mouse_pos.y <= @viewport_y + @viewport_height
    end

    private def rects_overlap?(rect1 : RL::Rectangle, rect2 : RL::Rectangle) : Bool
      !(rect1.x + rect1.width < rect2.x ||
        rect2.x + rect2.width < rect1.x ||
        rect1.y + rect1.height < rect2.y ||
        rect2.y + rect2.height < rect1.y)
    end

    # Helper methods for selection checking
    private def is_hotspot_selected?(name : String) : Bool
      @state.selected_hotspots.includes?(name) || @state.selected_object == name
    end

    private def is_character_selected?(name : String) : Bool
      @state.selected_characters.includes?(name) || @state.selected_object == name
    end
  end
end
