require "../ui/animation_editor"
require "../ui/script_editor"
require "../ui/colors"

module PaceEditor::Editors
  # Character editor for configuring character properties and animations
  class CharacterEditor
    property current_character : PointClickEngine::Characters::Character? = nil
    property animation_preview_time : Float32 = 0.0f32

    @animation_editor : UI::AnimationEditor
    @script_editor : UI::ScriptEditor

    def initialize(@state : Core::EditorState)
      @animation_editor = UI::AnimationEditor.new(@state)
      @script_editor = UI::ScriptEditor.new(@state)
    end

    def update
      @animation_preview_time += RL.get_frame_time
      @animation_editor.update
      @script_editor.update
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
      RL.draw_rectangle(editor_x, editor_y, editor_width, editor_height, UI::Colors::PANEL_MEDIUM)

      if character = get_current_character
        draw_character_workspace(character, editor_x, editor_y, editor_width, editor_height)
      else
        draw_no_character_message(editor_x, editor_y, editor_width, editor_height)
      end

      # Draw animation editor and script editor on top
      @animation_editor.draw
      @script_editor.draw
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
      RL.draw_rectangle(x, y, width, height, UI::Colors::PANEL_LIGHT)
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
        char_width, char_height, UI::Colors::CHARACTER_BOUNDS)
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
      RL.draw_rectangle(x, y, width, height, UI::Colors::PANEL_DARK)

      # Controls title
      RL.draw_text("Character Editor", x + 10, y + 10, 18, RL::WHITE)

      current_y = y + 50

      # Character info section
      RL.draw_text("Selected Character:", x + 10, current_y, 14, RL::LIGHTGRAY)
      current_y += 20
      RL.draw_text(character.name, x + 20, current_y, 16, RL::YELLOW)
      current_y += 30

      # Instructions for editing properties
      instruction_text = "To edit character properties:"
      RL.draw_text(instruction_text, x + 10, current_y, 14, RL::WHITE)
      current_y += 25

      instruction1 = "1. Make sure this character is selected"
      RL.draw_text(instruction1, x + 20, current_y, 12, RL::LIGHTGRAY)
      current_y += 20

      instruction2 = "2. Use the Properties panel on the right →"
      RL.draw_text(instruction2, x + 20, current_y, 12, RL::LIGHTGRAY)
      current_y += 30

      # Character selection button
      is_selected = @state.selected_object == character.name
      button_text = is_selected ? "✓ Selected" : "Select Character"
      button_color = is_selected ? RL::GREEN : RL::BLUE

      if draw_colored_button(button_text, x + 10, current_y, 150, 30, button_color)
        if !is_selected
          @state.select_object(character.name)
        end
      end
      current_y += 50

      # Animation section
      draw_section_header("Animation Tools", x, current_y, width)
      current_y += 30

      # Edit animations button
      if draw_button("Edit Animations", x + 10, current_y, 150, 30)
        open_animation_editor(character)
      end
      current_y += 50

      # Script section
      draw_section_header("Script Tools", x, current_y, width)
      current_y += 30

      # Script editing button
      if draw_button("Edit Script", x + 10, current_y, 150, 30)
        open_script_editor(character)
      end
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

    private def draw_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32) : Bool
      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      bg_color = is_hover ? UI::Colors::BUTTON_HOVER : UI::Colors::BUTTON_NORMAL

      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, RL::WHITE)

      text_width = RL.measure_text(text, 14)
      text_x = x + (width - text_width) // 2
      RL.draw_text(text, text_x, y + (height - 14) // 2, 14, RL::WHITE)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def draw_colored_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32, color : RL::Color) : Bool
      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      # Lighten color on hover
      bg_color = if is_hover
                   RL::Color.new(
                     r: [color.r.to_i + 30, 255].min.to_u8,
                     g: [color.g.to_i + 30, 255].min.to_u8,
                     b: [color.b.to_i + 30, 255].min.to_u8,
                     a: color.a
                   )
                 else
                   color
                 end

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

    private def open_script_editor(character : PointClickEngine::Characters::Character)
      # Find or create character's script path
      script_path = get_character_script_path(character.name)
      @script_editor.show(script_path)
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

    private def get_character_script_path(character_name : String) : String?
      return nil unless project = @state.current_project

      # Create scripts directory if it doesn't exist
      scripts_path = File.join(project.assets_path, "scripts")
      Dir.mkdir_p(scripts_path) unless Dir.exists?(scripts_path)

      # Generate script filename based on character name
      script_filename = "#{character_name.downcase.gsub(/[^a-z0-9_]/, "_")}_character.lua"
      script_path = File.join(scripts_path, script_filename)

      # Create default script if it doesn't exist
      unless File.exists?(script_path)
        default_script = <<-LUA
-- Character script for #{character_name}
-- This script defines behavior and interactions for the character

function on_character_click(character)
    -- Called when the character is clicked
    print("#{character_name} was clicked!")
end

function on_character_interact(character, player)
    -- Called when the player interacts with this character
    print("Player is interacting with #{character_name}")
end

function on_character_update(character, dt)
    -- Called every frame to update character behavior
    -- dt is the time since last frame in seconds
end

function on_character_enter_scene(character)
    -- Called when the character enters a scene
    print("#{character_name} entered the scene")
end

function on_character_leave_scene(character)
    -- Called when the character leaves a scene
    print("#{character_name} left the scene")
end
LUA

        File.write(script_path, default_script)
      end

      script_path
    end
  end
end
