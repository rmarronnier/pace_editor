# Testing extensions for SceneEditor
# Reopens the class to add e2e testing support methods

module PaceEditor::Editors
  class SceneEditor
    # Update with a specific input provider (for testing)
    def update_with_input(input : Testing::InputProvider)
      # Update dialogs first
      @background_selector.update
      @object_type_dialog.update

      # Don't process scene input if dialog is open
      return if @background_selector.visible || @object_type_dialog.visible

      mouse_pos = input.get_mouse_position
      viewport_bounds = RL::Rectangle.new(
        x: @viewport_x.to_f32,
        y: @viewport_y.to_f32,
        width: @viewport_width.to_f32,
        height: @viewport_height.to_f32
      )

      # Only process input if mouse is in viewport
      if mouse_in_viewport?(mouse_pos)
        handle_camera_controls_with_input(input)
        handle_tool_input_with_input(input)
      end

      handle_keyboard_shortcuts_with_input(input)
      @last_mouse_pos = mouse_pos
    end

    # Camera controls with test input provider
    private def handle_camera_controls_with_input(input : Testing::InputProvider)
      # Mouse wheel zoom (enhanced with smooth zooming)
      wheel = input.get_mouse_wheel_move
      if wheel != 0
        # Zoom towards mouse position
        mouse_world_before = screen_to_world(input.get_mouse_position)

        zoom_factor = wheel > 0 ? 1.1f32 : 0.9f32
        @state.zoom *= zoom_factor
        @state.zoom = @state.zoom.clamp(0.1f32, 5.0f32)

        # Adjust camera to keep mouse position stable
        mouse_world_after = screen_to_world(input.get_mouse_position)
        @state.camera_x -= (mouse_world_after.x - mouse_world_before.x)
        @state.camera_y -= (mouse_world_after.y - mouse_world_before.y)
      end

      # Middle mouse pan (or space + left mouse)
      if input.mouse_button_down?(RL::MouseButton::Middle) ||
         (input.key_down?(RL::KeyboardKey::Space) && input.mouse_button_down?(RL::MouseButton::Left))
        if !@camera_dragging
          @camera_dragging = true
          @drag_start = input.get_mouse_position
        end

        delta = input.get_mouse_delta
        @state.camera_x -= delta.x / @state.zoom
        @state.camera_y -= delta.y / @state.zoom
      else
        @camera_dragging = false
      end

      # Keyboard pan with smooth movement
      pan_speed = 5.0f32 / @state.zoom
      pan_speed *= 3.0f32 if input.key_down?(RL::KeyboardKey::LeftShift)

      @state.camera_x -= pan_speed if input.key_down?(RL::KeyboardKey::A) || input.key_down?(RL::KeyboardKey::Left)
      @state.camera_x += pan_speed if input.key_down?(RL::KeyboardKey::D) || input.key_down?(RL::KeyboardKey::Right)
      @state.camera_y -= pan_speed if input.key_down?(RL::KeyboardKey::W) || input.key_down?(RL::KeyboardKey::Up)
      @state.camera_y += pan_speed if input.key_down?(RL::KeyboardKey::S) || input.key_down?(RL::KeyboardKey::Down)
    end

    # Tool input handling with test input provider
    private def handle_tool_input_with_input(input : Testing::InputProvider)
      return if @camera_dragging

      mouse_pos = input.get_mouse_position
      world_pos = screen_to_world(mouse_pos)

      case @state.current_tool
      when Tool::Select
        handle_select_tool_with_input(input, mouse_pos, world_pos)
      when Tool::Move
        handle_move_tool_with_input(input, world_pos)
      when Tool::Place
        handle_place_tool_with_input(input, world_pos)
      when Tool::Delete
        handle_delete_tool_with_input(input, world_pos)
      end
    end

    private def handle_select_tool_with_input(input : Testing::InputProvider, screen_pos : RL::Vector2, world_pos : RL::Vector2)
      return unless scene = @state.current_scene

      if input.mouse_button_pressed?(RL::MouseButton::Left)
        @selecting = true
        @drag_start = screen_pos

        # Check if clicking on an object
        if obj = get_object_at(scene, world_pos)
          if input.key_down?(RL::KeyboardKey::LeftControl)
            # Toggle selection in multi-select mode
            @state.toggle_object_selection(obj)
          else
            # Single selection (clear others)
            @state.select_object(obj, multi_select: false)
          end

          # Start dragging if object is selected
          if @state.is_selected?(obj)
            @dragging = true
            @state.current_tool = Tool::Move
          end
          @selecting = false
        else
          # Start selection rectangle or clear selection
          unless input.key_down?(RL::KeyboardKey::LeftControl)
            @state.clear_selection
          end
        end
      end

      if @selecting && input.mouse_button_down?(RL::MouseButton::Left)
        # Update selection rectangle
        current_pos = input.get_mouse_position
        x = Math.min(@drag_start.x, current_pos.x)
        y = Math.min(@drag_start.y, current_pos.y)
        w = (current_pos.x - @drag_start.x).abs
        h = (current_pos.y - @drag_start.y).abs
        @selection_rect = RL::Rectangle.new(x: x, y: y, width: w, height: h)
      end

      if @selecting && input.mouse_button_released?(RL::MouseButton::Left)
        # Finish selection
        if rect = @selection_rect
          select_objects_in_rect(rect)
        end
        @selecting = false
        @selection_rect = nil
      end
    end

    private def handle_move_tool_with_input(input : Testing::InputProvider, world_pos : RL::Vector2)
      return if @state.get_selected_objects.empty?

      if input.mouse_button_pressed?(RL::MouseButton::Left)
        @dragging = true
        @drag_start = world_pos

        # Capture starting positions for all selected objects for undo
        @drag_start_positions = {} of String => RL::Vector2
        if scene = @state.current_scene
          @state.get_selected_objects.each do |obj_name|
            if hotspot = scene.hotspots.find { |h| h.name == obj_name }
              @drag_start_positions[obj_name] = hotspot.position
            elsif character = scene.characters.find { |c| c.name == obj_name }
              @drag_start_positions[obj_name] = character.position
            end
          end
        end
      end

      if @dragging && input.mouse_button_down?(RL::MouseButton::Left)
        delta = RL::Vector2.new(
          world_pos.x - @drag_start.x,
          world_pos.y - @drag_start.y
        )

        # Move all selected objects
        if scene = @state.current_scene
          @state.get_selected_objects.each do |obj_name|
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

      if @dragging && input.mouse_button_released?(RL::MouseButton::Left)
        @dragging = false

        # Create undo actions for all moved objects
        if scene = @state.current_scene
          @drag_start_positions.each do |obj_name, start_pos|
            current_pos = RL::Vector2.new(0.0_f32, 0.0_f32)

            if hotspot = scene.hotspots.find { |h| h.name == obj_name }
              current_pos = hotspot.position
            elsif character = scene.characters.find { |c| c.name == obj_name }
              current_pos = character.position
            end

            # Only create undo action if position actually changed
            if start_pos.x != current_pos.x || start_pos.y != current_pos.y
              move_action = Core::MoveObjectAction.new(obj_name, start_pos, current_pos, @state)
              @state.add_undo_action(move_action)
            end
          end
        end

        @drag_start_positions.clear
      end
    end

    private def handle_place_tool_with_input(input : Testing::InputProvider, world_pos : RL::Vector2)
      if input.mouse_button_pressed?(RL::MouseButton::Left)
        return unless scene = @state.current_scene

        # For testing, directly place a hotspot without showing dialog
        snapped_pos = RL::Vector2.new(
          snap_to_grid(world_pos.x.to_i).to_f32,
          snap_to_grid(world_pos.y.to_i).to_f32
        )
        place_hotspot_at(snapped_pos)
      end
    end

    private def handle_delete_tool_with_input(input : Testing::InputProvider, world_pos : RL::Vector2)
      if input.mouse_button_pressed?(RL::MouseButton::Left)
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

    private def handle_keyboard_shortcuts_with_input(input : Testing::InputProvider)
      # Delete selected objects
      if input.key_pressed?(RL::KeyboardKey::Delete)
        delete_selected_objects
      end

      # Undo (Ctrl+Z)
      if input.key_down?(RL::KeyboardKey::LeftControl) && input.key_pressed?(RL::KeyboardKey::Z)
        if @state.can_undo?
          @state.undo
          puts "Undo performed"
        end
      end

      # Redo (Ctrl+Y or Ctrl+Shift+Z)
      if (input.key_down?(RL::KeyboardKey::LeftControl) && input.key_pressed?(RL::KeyboardKey::Y)) ||
         (input.key_down?(RL::KeyboardKey::LeftControl) && input.key_down?(RL::KeyboardKey::LeftShift) && input.key_pressed?(RL::KeyboardKey::Z))
        if @state.can_redo?
          @state.redo
          puts "Redo performed"
        end
      end

      # Save scene (Ctrl+S)
      if input.key_down?(RL::KeyboardKey::LeftControl) && input.key_pressed?(RL::KeyboardKey::S)
        save_scene
        @state.is_dirty = false
        puts "Scene saved"
      end

      # Open background selector (B)
      if input.key_pressed?(RL::KeyboardKey::B) && !input.key_down?(RL::KeyboardKey::LeftControl)
        show_background_selector
      end

      # Select all
      if input.key_down?(RL::KeyboardKey::LeftControl) && input.key_pressed?(RL::KeyboardKey::A)
        select_all_objects
      end

      # Deselect all
      if input.key_pressed?(RL::KeyboardKey::Escape)
        @state.selected_object = nil
      end

      # Reset view
      if input.key_pressed?(RL::KeyboardKey::Home)
        @state.camera_x = 0
        @state.camera_y = 0
        @state.zoom = 1.0f32
      end
    end
  end
end
