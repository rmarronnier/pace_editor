# Testing extensions for SceneCreationWizard
# Reopens the class to add e2e testing support methods

module PaceEditor::UI
  class SceneCreationWizard
    # Update with a specific input provider (for testing)
    def update_with_input(input : Testing::InputProvider)
      return unless @visible

      mouse_pos = input.get_mouse_position
      mouse_clicked = input.mouse_button_pressed?(RL::MouseButton::Left)

      screen_width = input.get_screen_width
      screen_height = input.get_screen_height

      # Calculate dialog bounds
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      # Handle step-specific input
      case @step
      when 1
        handle_step1_input_with_test(dialog_x, dialog_y, dialog_width, input)
      when 2
        handle_step2_input_with_test(dialog_x, dialog_y, dialog_width, input)
      when 3
        handle_step3_input_with_test(dialog_x, dialog_y, dialog_width, input)
      when 4
        handle_step4_input_with_test(dialog_x, dialog_y, dialog_width, input)
      end

      # Handle navigation buttons
      handle_navigation_with_test(dialog_x, dialog_y, dialog_width, dialog_height, input)

      # Handle text input for scene name
      if @step == 1 && @name_field_active
        handle_text_input_with_test(input)
      end

      # Handle Escape to close
      if input.key_pressed?(RL::KeyboardKey::Escape)
        hide
      end
    end

    private def handle_step1_input_with_test(dialog_x : Int32, dialog_y : Int32, dialog_width : Int32, input : Testing::InputProvider)
      mouse_pos = input.get_mouse_position

      # Scene name field
      field_x = dialog_x + 20
      field_y = dialog_y + 100
      field_width = dialog_width - 40
      field_height = 30

      if input.mouse_button_pressed?(RL::MouseButton::Left)
        if mouse_pos.x >= field_x && mouse_pos.x <= field_x + field_width &&
           mouse_pos.y >= field_y && mouse_pos.y <= field_y + field_height
          @name_field_active = true
          @cursor_position = @scene_name.size
        else
          @name_field_active = false
        end
      end

      # Example scene name buttons
      examples = ["main_hall", "forest_path", "intro_scene"]
      example_y = dialog_y + 160
      examples.each_with_index do |example, index|
        btn_x = dialog_x + 20 + index * 150
        btn_width = 140
        btn_height = 25

        if input.mouse_button_pressed?(RL::MouseButton::Left) &&
           mouse_pos.x >= btn_x && mouse_pos.x <= btn_x + btn_width &&
           mouse_pos.y >= example_y && mouse_pos.y <= example_y + btn_height
          @scene_name = example
          @name_field_active = false
        end
      end
    end

    private def handle_step2_input_with_test(dialog_x : Int32, dialog_y : Int32, dialog_width : Int32, input : Testing::InputProvider)
      mouse_pos = input.get_mouse_position

      # Template selection buttons
      templates = ["empty", "room", "outdoor", "menu"]
      button_width = 120
      button_height = 100
      spacing = 20
      start_x = dialog_x + (dialog_width - (templates.size * (button_width + spacing) - spacing)) // 2
      start_y = dialog_y + 120

      templates.each_with_index do |template, index|
        btn_x = start_x + index * (button_width + spacing)

        if input.mouse_button_pressed?(RL::MouseButton::Left) &&
           mouse_pos.x >= btn_x && mouse_pos.x <= btn_x + button_width &&
           mouse_pos.y >= start_y && mouse_pos.y <= start_y + button_height
          @scene_template = template
        end
      end
    end

    private def handle_step3_input_with_test(dialog_x : Int32, dialog_y : Int32, dialog_width : Int32, input : Testing::InputProvider)
      mouse_pos = input.get_mouse_position

      # Background selection area
      # This would normally show thumbnails of available backgrounds
      bg_area_y = dialog_y + 100
      bg_area_height = 300

      # Import button
      import_btn_x = dialog_x + dialog_width - 120
      import_btn_y = dialog_y + 420
      import_btn_width = 100
      import_btn_height = 30

      if input.mouse_button_pressed?(RL::MouseButton::Left) &&
         mouse_pos.x >= import_btn_x && mouse_pos.x <= import_btn_x + import_btn_width &&
         mouse_pos.y >= import_btn_y && mouse_pos.y <= import_btn_y + import_btn_height
        # Would open background import dialog
        @state.editor_window.try(&.show_background_import_dialog)
      end
    end

    private def handle_step4_input_with_test(dialog_x : Int32, dialog_y : Int32, dialog_width : Int32, input : Testing::InputProvider)
      mouse_pos = input.get_mouse_position

      # Dimension preset buttons
      presets = [
        {name: "HD", width: 1920, height: 1080},
        {name: "720p", width: 1280, height: 720},
        {name: "Square", width: 800, height: 800},
        {name: "4:3", width: 1024, height: 768},
      ]

      preset_y = dialog_y + 120
      presets.each_with_index do |preset, index|
        btn_x = dialog_x + 20 + index * 100
        btn_width = 90
        btn_height = 30

        if input.mouse_button_pressed?(RL::MouseButton::Left) &&
           mouse_pos.x >= btn_x && mouse_pos.x <= btn_x + btn_width &&
           mouse_pos.y >= preset_y && mouse_pos.y <= preset_y + btn_height
          @scene_width = preset[:width]
          @scene_height = preset[:height]
        end
      end
    end

    private def handle_navigation_with_test(dialog_x : Int32, dialog_y : Int32, dialog_width : Int32, dialog_height : Int32, input : Testing::InputProvider)
      mouse_pos = input.get_mouse_position
      button_y = dialog_y + dialog_height - 50
      button_height = 30
      button_width = 80

      # Previous button (visible on steps 2-4)
      if @step > 1
        prev_x = dialog_x + 20
        if input.mouse_button_pressed?(RL::MouseButton::Left) &&
           mouse_pos.x >= prev_x && mouse_pos.x <= prev_x + button_width &&
           mouse_pos.y >= button_y && mouse_pos.y <= button_y + button_height
          @step -= 1
        end
      end

      # Next/Create button
      next_x = dialog_x + dialog_width - button_width - 20
      if input.mouse_button_pressed?(RL::MouseButton::Left) &&
         mouse_pos.x >= next_x && mouse_pos.x <= next_x + button_width &&
         mouse_pos.y >= button_y && mouse_pos.y <= button_y + button_height
        if @step < 4
          if validate_current_step
            @step += 1
          end
        else
          # Create button on final step
          if validate_current_step
            create_scene
          end
        end
      end

      # Cancel button
      cancel_x = dialog_x + dialog_width // 2 - button_width // 2
      if input.mouse_button_pressed?(RL::MouseButton::Left) &&
         mouse_pos.x >= cancel_x && mouse_pos.x <= cancel_x + button_width &&
         mouse_pos.y >= button_y && mouse_pos.y <= button_y + button_height
        hide
      end
    end

    private def handle_text_input_with_test(input : Testing::InputProvider)
      cursor_pos = @cursor_position || @scene_name.size

      # Handle character input
      chars = input.get_typed_chars
      chars.each do |key|
        if key >= 32 && key <= 126
          char = key.chr
          # Validate character (alphanumeric, underscore, hyphen)
          if char.alphanumeric? || char == '_' || char == '-'
            if @scene_name.size < 30
              @scene_name = @scene_name.insert(cursor_pos, char.to_s)
              cursor_pos += 1
            end
          end
        end
      end

      # Handle special keys
      if input.key_pressed?(RL::KeyboardKey::Backspace) && cursor_pos > 0
        @scene_name = @scene_name.delete_at(cursor_pos - 1)
        cursor_pos -= 1
      end

      if input.key_pressed?(RL::KeyboardKey::Delete) && cursor_pos < @scene_name.size
        @scene_name = @scene_name.delete_at(cursor_pos)
      end

      if input.key_pressed?(RL::KeyboardKey::Left) && cursor_pos > 0
        cursor_pos -= 1
      end

      if input.key_pressed?(RL::KeyboardKey::Right) && cursor_pos < @scene_name.size
        cursor_pos += 1
      end

      if input.key_pressed?(RL::KeyboardKey::Enter)
        @name_field_active = false
      end

      @cursor_position = cursor_pos
    end

    private def validate_current_step : Bool
      case @step
      when 1
        # Validate scene name
        !@scene_name.empty? && @scene_name.matches?(/^[a-zA-Z0-9_-]+$/)
      when 2
        # Template is always valid (has default)
        true
      when 3
        # Background is optional
        true
      when 4
        # Validate dimensions
        @scene_width > 0 && @scene_height > 0
      else
        true
      end
    end

    # Testing helpers
    def current_step : Int32
      @step
    end

    def scene_name_for_test : String
      @scene_name
    end

    def set_scene_name_for_test(name : String)
      @scene_name = name
    end

    def scene_template_for_test : String
      @scene_template
    end

    def set_template_for_test(template : String)
      @scene_template = template
    end

    def scene_dimensions_for_test : {Int32, Int32}
      {@scene_width, @scene_height}
    end

    def set_dimensions_for_test(width : Int32, height : Int32)
      @scene_width = width
      @scene_height = height
    end

    def name_field_active? : Bool
      @name_field_active == true
    end

    def activate_name_field_for_test
      @name_field_active = true
      @cursor_position = @scene_name.size
    end

    def go_to_step_for_test(step : Int32)
      @step = step.clamp(1, 4)
    end

    def show_for_test
      show
    end

    def validation_error_for_test : String?
      @validation_error
    end

    # Get button positions for clicking
    def get_next_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      {dialog_x + dialog_width - 60, dialog_y + dialog_height - 35}
    end

    def get_prev_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      {dialog_x + 60, dialog_y + dialog_height - 35}
    end

    def get_name_field_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_width = 600
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - 500) // 2
      {dialog_x + dialog_width // 2, dialog_y + 115}
    end

    def get_template_button_position(template : String, screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      templates = ["empty", "room", "outdoor", "menu"]
      index = templates.index(template) || 0

      dialog_width = 600
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - 500) // 2

      button_width = 120
      spacing = 20
      start_x = dialog_x + (dialog_width - (templates.size * (button_width + spacing) - spacing)) // 2

      {start_x + index * (button_width + spacing) + button_width // 2, dialog_y + 170}
    end
  end
end
