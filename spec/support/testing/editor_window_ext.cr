# Testing extensions for EditorWindow
# Reopens the class to add e2e testing support methods

module PaceEditor::Core
  class EditorWindow
    # Update with a specific input provider (for testing)
    def update_for_test(input : Testing::InputProvider)
      # Check for window resize
      if input.window_resized?
        @window_width = input.get_screen_width
        @window_height = input.get_screen_height
        calculate_viewport_dimensions
      end

      # Handle progressive UI input first (highest priority)
      mouse_pos = input.get_mouse_position
      mouse_clicked = input.mouse_button_pressed?(RL::MouseButton::Left)

      # Check guided workflow input (handles both getting started panel and tutorials)
      if @guided_workflow.handle_input(mouse_pos, mouse_clicked)
        return # Input consumed by guided workflow
      end

      # Check progressive menu input with test provider
      if @progressive_menu.handle_input_with_test(input)
        return # Input consumed by progressive menu
      end

      # Handle global shortcuts with test input
      handle_shortcuts_with_input(input)

      # Update current editor based on mode
      case @state.current_mode
      when .scene?
        @scene_editor.update_with_input(input)
      when .character?
        @character_editor.update_with_input(input)
      when .hotspot?
        @hotspot_editor.update
      when .dialog?
        @dialog_editor.update_with_input(input)
      when .assets?
        @asset_browser.update
      when .project?
        # Project settings handled by property panel
      end

      # Update progressive UI state
      @ui_state.update_project_progress(@state)
      @guided_workflow.update

      # Update UI components with test input
      @menu_bar.update
      @tool_palette.update_with_input(input)
      @property_panel.update_with_input(input)
      @scene_hierarchy.update_with_input(input)
      @asset_browser.update_with_input(input) if @state.current_mode.assets?

      # Update dialogs with test input
      @hotspot_action_dialog.update_with_input(input)
      @script_editor.update
      @background_import_dialog.update
      @asset_import_dialog.update
      @scene_creation_wizard.update
      @game_export_dialog.update

      # Clean up finished confirm dialog
      if dialog = @confirm_dialog
        unless dialog.visible?
          @confirm_dialog = nil
        end
      end
    end

    # Draw without begin/end drawing (for render texture capture)
    def draw_for_test
      RL.clear_background(RL::Color.new(r: 50, g: 50, b: 50, a: 255))

      # Draw progressive menu instead of old menu bar
      @progressive_menu.draw(@window_width)

      # Draw tool palette if visible
      if @ui_state.get_component_visibility("tool_palette", @state).visible?
        @tool_palette.draw
      end

      # Draw main editor area
      draw_editor_viewport

      # Draw side panels with visibility checks
      if @ui_state.get_component_visibility("scene_hierarchy", @state).visible?
        @scene_hierarchy.draw
      end

      if @ui_state.get_component_visibility("property_panel", @state).visible?
        @property_panel.draw
      end

      # Draw asset browser if in assets mode and visible
      if @state.current_mode.assets? && @ui_state.get_component_visibility("asset_browser", @state).visible?
        @asset_browser.draw
      end

      # Draw status bar
      draw_status_bar

      # Draw guided workflow (getting started, hints, tutorials)
      @guided_workflow.draw

      # Draw dialogs on top of everything
      @hotspot_action_dialog.draw
      @script_editor.draw
      @background_import_dialog.draw
      @asset_import_dialog.draw
      @scene_creation_wizard.draw
      @game_export_dialog.draw

      # Draw new project dialog if needed
      if @state.show_new_project_dialog
        draw_new_project_dialog
      end

      # Draw menu bar dialogs (open project, etc)
      @menu_bar.draw

      # Draw confirm dialog if active
      if dialog = @confirm_dialog
        dialog.draw
      end
    end

    # Handle shortcuts with a specific input provider
    private def handle_shortcuts_with_input(input : Testing::InputProvider)
      # File operations
      if input.key_down?(RL::KeyboardKey::LeftControl) || input.key_down?(RL::KeyboardKey::RightControl)
        if input.key_pressed?(RL::KeyboardKey::N)
          @menu_bar.show_new_project_dialog
        elsif input.key_pressed?(RL::KeyboardKey::O)
          @menu_bar.show_open_project_dialog
        elsif input.key_pressed?(RL::KeyboardKey::S)
          @state.save_project
        elsif input.key_pressed?(RL::KeyboardKey::Z)
          @state.undo
        elsif input.key_pressed?(RL::KeyboardKey::Y)
          @state.redo
        end
      end

      # Fullscreen toggle with F11
      if input.key_pressed?(RL::KeyboardKey::F11)
        toggle_fullscreen
      end

      # Tool shortcuts
      if input.key_pressed?(RL::KeyboardKey::V)
        @state.current_tool = Tool::Select
      elsif input.key_pressed?(RL::KeyboardKey::M)
        @state.current_tool = Tool::Move
      elsif input.key_pressed?(RL::KeyboardKey::P)
        @state.current_tool = Tool::Place
      elsif input.key_pressed?(RL::KeyboardKey::D)
        @state.current_tool = Tool::Delete
      end

      # View shortcuts
      if input.key_pressed?(RL::KeyboardKey::G)
        @state.show_grid = !@state.show_grid
      elsif input.key_pressed?(RL::KeyboardKey::H)
        @state.show_hotspots = !@state.show_hotspots
      end

      # Camera controls
      if input.key_down?(RL::KeyboardKey::Space)
        if input.mouse_button_down?(RL::MouseButton::Left)
          delta = input.get_mouse_delta
          @state.camera_x -= delta.x / @state.zoom
          @state.camera_y -= delta.y / @state.zoom
        end
      end

      # Zoom with mouse wheel
      wheel_move = input.get_mouse_wheel_move
      if wheel_move != 0
        mouse_pos = input.get_mouse_position
        if mouse_pos.x >= @viewport_x && mouse_pos.x < @viewport_x + @viewport_width &&
           mouse_pos.y >= @viewport_y && mouse_pos.y < @viewport_y + @viewport_height
          if wheel_move > 0
            @state.zoom_in
          else
            @state.zoom_out
          end
        end
      end
    end
  end
end
