require "../ui/animation_editor"

module PaceEditor::Editors
  # Character editor for configuring character properties and animations
  class CharacterEditor
    property current_character : PointClickEngine::Characters::Character? = nil
    property animation_preview_time : Float32 = 0.0f32

    @animation_editor : UI::AnimationEditor

    def initialize(@state : Core::EditorState)
      @animation_editor = UI::AnimationEditor.new(@state)
    end

    def update
      @animation_preview_time += RL.get_frame_time
      @animation_editor.update
    end

    def update_viewport(viewport_x : Int32, viewport_y : Int32, viewport_width : Int32, viewport_height : Int32)
      # Character editor uses full viewport, no special handling needed
      # This method exists for consistency with other editors
    end

    def draw
      # Character editor takes over the main viewport
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      editor_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      editor_y = Core::EditorWindow::MENU_HEIGHT
      editor_width = screen_width - Core::EditorWindow::TOOL_PALETTE_WIDTH - Core::EditorWindow::PROPERTY_PANEL_WIDTH
      editor_height = screen_height - Core::EditorWindow::MENU_HEIGHT

      # Draw background
      RL.draw_rectangle(editor_x, editor_y, editor_width, editor_height,
        RL::Color.new(r: 40, g: 40, b: 40, a: 255))

      if character = get_current_character
        draw_character_workspace(character, editor_x, editor_y, editor_width, editor_height)
      else
        draw_no_character_message(editor_x, editor_y, editor_width, editor_height)
      end

      # Draw animation editor on top
      @animation_editor.draw
    end

    private def get_current_character : PointClickEngine::Characters::Character?
      return @current_character if @current_character

      # Try to get character from selection
      if selected = @state.selected_object
        if scene = @state.current_scene
          @current_character = scene.characters.find { |c| c.name == selected }
        end
      end

      @current_character
    end

    private def draw_character_workspace(character : PointClickEngine::Characters::Character, x : Int32, y : Int32, width : Int32, height : Int32)
      # Split workspace into sections
      preview_width = width // 2
      controls_width = width - preview_width

      # Draw character preview section
      draw_character_preview(character, x, y, preview_width, height)

      # Draw character controls
      draw_character_controls(character, x + preview_width, y, controls_width, height)
    end

    private def draw_character_preview(character : PointClickEngine::Characters::Character, x : Int32, y : Int32, width : Int32, height : Int32)
      # Preview section background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 50, g: 50, b: 50, a: 255))
      RL.draw_line(x + width, y, x + width, y + height, RL::GRAY)

      # Preview title
      RL.draw_text("Character Preview", x + 10, y + 10, 18, RL::WHITE)

      # Character sprite preview
      preview_x = x + width // 2
      preview_y = y + height // 2

      # Draw character bounds
      char_width = character.size.x.to_i
      char_height = character.size.y.to_i

      RL.draw_rectangle(preview_x - char_width//2, preview_y - char_height//2,
        char_width, char_height, RL::Color.new(r: 100, g: 100, b: 200, a: 150))
      RL.draw_rectangle_lines(preview_x - char_width//2, preview_y - char_height//2,
        char_width, char_height, RL::BLUE)

      # Draw character name
      name_width = RL.measure_text(character.name, 16)
      RL.draw_text(character.name, preview_x - name_width//2, preview_y - char_height//2 - 25, 16, RL::WHITE)

      # Animation controls
      controls_y = y + height - 100
      RL.draw_text("Animation:", x + 10, controls_y, 14, RL::WHITE)

      # Play/Pause button
      if draw_button("Play", x + 10, controls_y + 20, 60, 25)
        # Toggle animation
      end

      # Edit animations button
      if draw_button("Edit", x + 80, controls_y + 20, 60, 25)
        open_animation_editor(character)
      end

      # Animation frame info
      RL.draw_text("Frame: 0/1", x + 150, controls_y + 25, 12, RL::LIGHTGRAY)
    end

    private def draw_character_controls(character : PointClickEngine::Characters::Character, x : Int32, y : Int32, width : Int32, height : Int32)
      # Controls section background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 45, g: 45, b: 45, a: 255))

      # Controls title
      RL.draw_text("Character Properties", x + 10, y + 10, 18, RL::WHITE)

      current_y = y + 40

      # Basic properties section
      draw_section_header("Basic Properties", x, current_y, width)
      current_y += 30

      current_y = draw_property_field("Name:", character.name, x, current_y, width)
      current_y = draw_property_field("X:", character.position.x.to_s, x, current_y, width)
      current_y = draw_property_field("Y:", character.position.y.to_s, x, current_y, width)
      current_y = draw_property_field("Width:", character.size.x.to_s, x, current_y, width)
      current_y = draw_property_field("Height:", character.size.y.to_s, x, current_y, width)

      current_y += 20

      # Animation properties section
      draw_section_header("Animation", x, current_y, width)
      current_y += 30

      current_y = draw_property_field("Sprite Sheet:", "None", x, current_y, width)
      current_y = draw_property_field("Frame Width:", "32", x, current_y, width)
      current_y = draw_property_field("Frame Height:", "32", x, current_y, width)
      current_y = draw_property_field("Frame Count:", "1", x, current_y, width)
      current_y = draw_property_field("Frame Speed:", "0.1", x, current_y, width)

      current_y += 20

      # Script properties section
      draw_section_header("Scripting", x, current_y, width)
      current_y += 30

      current_y = draw_property_field("Script File:", "None", x, current_y, width)

      # Script editing button
      if draw_button("Edit Script", x + 10, current_y, 100, 25)
        # Open script editor
      end
      current_y += 35

      # Behavior properties
      draw_section_header("Behavior", x, current_y, width)
      current_y += 30

      current_y = draw_property_field("AI Behavior:", "None", x, current_y, width)
      current_y = draw_property_field("Movement Speed:", "100", x, current_y, width)
      current_y = draw_property_field("Interaction Range:", "50", x, current_y, width)
    end

    private def draw_no_character_message(x : Int32, y : Int32, width : Int32, height : Int32)
      message = "No Character Selected"
      message_width = RL.measure_text(message, 24)
      message_x = x + (width - message_width) // 2
      message_y = y + height // 2 - 60

      RL.draw_text(message, message_x, message_y, 24, RL::LIGHTGRAY)

      instruction = "Select a character from the scene or create a new one"
      instruction_width = RL.measure_text(instruction, 16)
      instruction_x = x + (width - instruction_width) // 2
      RL.draw_text(instruction, instruction_x, message_y + 40, 16, RL::GRAY)

      # Create character button
      button_width = 150
      button_x = x + (width - button_width) // 2
      if draw_button("Create Character", button_x, message_y + 80, button_width, 30)
        create_new_character
      end
    end

    private def draw_section_header(title : String, x : Int32, y : Int32, width : Int32)
      RL.draw_text(title, x + 10, y, 16, RL::WHITE)
      RL.draw_line(x + 10, y + 20, x + width - 10, y + 20, RL::GRAY)
    end

    private def draw_property_field(label : String, value : String, x : Int32, y : Int32, width : Int32) : Int32
      label_width = 100

      # Draw label
      RL.draw_text(label, x + 10, y, 12, RL::LIGHTGRAY)

      # Draw value field
      field_x = x + 10 + label_width
      field_width = width - label_width - 30
      field_height = 18

      RL.draw_rectangle(field_x, y - 2, field_width, field_height,
        RL::Color.new(r: 30, g: 30, b: 30, a: 255))
      RL.draw_rectangle_lines(field_x, y - 2, field_width, field_height, RL::GRAY)

      # Draw value text
      value_to_draw = value.size > 20 ? value[0...17] + "..." : value
      RL.draw_text(value_to_draw, field_x + 5, y, 12, RL::WHITE)

      y + 25
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

    private def create_new_character
      # Create a new character and add it to the scene
      if scene = @state.current_scene
        new_character = PointClickEngine::Characters::NPC.new(
          "new_character",
          RL::Vector2.new(x: 100, y: 100),
          RL::Vector2.new(x: 64, y: 64)
        )
        scene.add_character(new_character)
        @current_character = new_character
        @state.select_object(new_character.name)
        @state.save_current_scene(scene)
      end
    end

    private def open_animation_editor(character : PointClickEngine::Characters::Character)
      # Find character's sprite sheet path
      sprite_path = get_character_sprite_path(character.name)
      @animation_editor.show(character.name, sprite_path)
    end

    private def get_character_sprite_path(character_name : String) : String?
      return nil unless project = @state.current_project

      # Look for sprite sheet in character assets
      characters_path = File.join(project.assets_path, "characters")
      return nil unless Dir.exists?(characters_path)

      # Common sprite sheet extensions
      extensions = [".png", ".jpg", ".jpeg"]
      possible_names = [
        character_name.downcase.gsub(" ", "_"),
        character_name.downcase,
        "#{character_name.downcase}_spritesheet",
        "#{character_name.downcase.gsub(" ", "_")}_sheet",
      ]

      possible_names.each do |name|
        extensions.each do |ext|
          full_path = File.join(characters_path, "#{name}#{ext}")
          if File.exists?(full_path)
            return full_path
          end
        end
      end

      nil
    end
  end
end
