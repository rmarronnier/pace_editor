# Testing extensions for CharacterEditor
# Reopens the class to add e2e testing support methods

module PaceEditor::Editors
  class CharacterEditor
    # Update with a specific input provider (for testing)
    def update_with_input(input : Testing::InputProvider)
      @animation_preview_time += 0.016f32 # Approximate frame time
      @animation_editor.update
      @script_editor.update

      # Handle button clicks with test input
      handle_buttons_with_input(input)
    end

    private def handle_buttons_with_input(input : Testing::InputProvider)
      screen_width = input.get_screen_width
      screen_height = input.get_screen_height
      editor_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      editor_y = Core::EditorWindow::MENU_HEIGHT
      editor_width = screen_width - Core::EditorWindow::TOOL_PALETTE_WIDTH - Core::EditorWindow::PROPERTY_PANEL_WIDTH
      editor_height = screen_height - Core::EditorWindow::MENU_HEIGHT

      mouse_pos = input.get_mouse_position

      if character = get_current_character
        # Character workspace - handle buttons
        preview_width = editor_width // 2
        controls_x = editor_x + preview_width

        # "Select Character" button position
        current_y = editor_y + 50 + 20 + 30 + 25 + 20 + 30 + 50 # Approximate y position
        select_btn_x = controls_x + 10
        select_btn_width = 150
        select_btn_height = 30

        if button_clicked?(mouse_pos, input, select_btn_x, current_y, select_btn_width, select_btn_height)
          @state.select_object(character.name)
        end

        # "Edit Animations" button
        current_y += 50 + 30
        if button_clicked?(mouse_pos, input, controls_x + 10, current_y, 150, 30)
          open_animation_editor(character)
        end

        # "Edit Script" button
        current_y += 50 + 30
        if button_clicked?(mouse_pos, input, controls_x + 10, current_y, 150, 30)
          open_script_editor(character)
        end
      else
        # No character - handle "Create Character" button
        button_width = 150
        button_x = editor_x + (editor_width - button_width) // 2
        message_y = editor_y + editor_height // 2 - 60
        button_y = message_y + 80

        if button_clicked?(mouse_pos, input, button_x, button_y, button_width, 30)
          create_new_character
        end
      end
    end

    private def button_clicked?(mouse_pos : RL::Vector2, input : Testing::InputProvider, x : Int32, y : Int32, width : Int32, height : Int32) : Bool
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height
      is_hover && input.mouse_button_pressed?(RL::MouseButton::Left)
    end

    # Testing helper: create character via test
    def create_character_for_test
      create_new_character
    end

    # Testing helper: get current character
    def current_character_for_test : PointClickEngine::Characters::Character?
      get_current_character
    end
  end
end
