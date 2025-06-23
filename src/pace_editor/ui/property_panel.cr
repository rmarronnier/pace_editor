module PaceEditor::UI
  # Property panel for editing selected object properties
  class PropertyPanel
    @active_field : String?
    @scroll_y : Float32
    @edit_buffer : String
    @cursor_position : Int32
    @cursor_blink_timer : Float32
    
    def initialize(@state : Core::EditorState)
      @scroll_y = 0.0f32
      @active_field = nil
      @edit_buffer = ""
      @cursor_position = 0
      @cursor_blink_timer = 0.0f32
    end

    def update
      # Handle text input for active field
      if field = @active_field
        handle_text_input
      end
      
      # Update cursor blink
      @cursor_blink_timer += RL.get_frame_time
      if @cursor_blink_timer > 1.0f32
        @cursor_blink_timer = 0.0f32
      end
      
      # Handle scrolling
      if RL.get_mouse_wheel_move != 0
        mouse_pos = RL.get_mouse_position
        panel_x = Core::EditorWindow::WINDOW_WIDTH - Core::EditorWindow::PROPERTY_PANEL_WIDTH
        if mouse_pos.x >= panel_x
          @scroll_y -= RL.get_mouse_wheel_move * 20
          @scroll_y = @scroll_y.clamp(0.0_f32, Float32::MAX)
        end
      end
    end
    
    private def handle_text_input
      # Handle character input
      key = RL.get_char_pressed
      while key > 0
        if key >= 32 && key <= 126
          @edit_buffer = @edit_buffer.insert(@cursor_position, key.chr.to_s)
          @cursor_position += 1
        end
        key = RL.get_char_pressed
      end
      
      # Handle special keys
      if RL.key_pressed?(RL::KeyboardKey::Backspace) && @cursor_position > 0
        @edit_buffer = @edit_buffer.delete_at(@cursor_position - 1)
        @cursor_position -= 1
      end
      
      if RL.key_pressed?(RL::KeyboardKey::Delete) && @cursor_position < @edit_buffer.size
        @edit_buffer = @edit_buffer.delete_at(@cursor_position)
      end
      
      if RL.key_pressed?(RL::KeyboardKey::Left) && @cursor_position > 0
        @cursor_position -= 1
      end
      
      if RL.key_pressed?(RL::KeyboardKey::Right) && @cursor_position < @edit_buffer.size
        @cursor_position += 1
      end
      
      if RL.key_pressed?(RL::KeyboardKey::Home)
        @cursor_position = 0
      end
      
      if RL.key_pressed?(RL::KeyboardKey::End)
        @cursor_position = @edit_buffer.size
      end
      
      # Apply changes on Enter
      if RL.key_pressed?(RL::KeyboardKey::Enter)
        apply_property_change(@active_field.not_nil!, @edit_buffer)
        @active_field = nil
      end
      
      # Cancel on Escape
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        @active_field = nil
      end
    end

    def draw
      panel_x = Core::EditorWindow::WINDOW_WIDTH - Core::EditorWindow::PROPERTY_PANEL_WIDTH
      panel_y = Core::EditorWindow::MENU_HEIGHT
      panel_width = Core::EditorWindow::PROPERTY_PANEL_WIDTH
      panel_height = Core::EditorWindow::WINDOW_HEIGHT - Core::EditorWindow::MENU_HEIGHT

      # Draw panel background
      RL.draw_rectangle(panel_x, panel_y, panel_width, panel_height,
        RL::Color.new(r: 45, g: 45, b: 45, a: 255))
      RL.draw_line(panel_x, panel_y, panel_x, Core::EditorWindow::WINDOW_HEIGHT, RL::GRAY)

      # Panel title
      RL.draw_text("Properties", panel_x + 10, panel_y + 10, 18, RL::WHITE)

      y = panel_y + 40

      # Draw properties based on current selection and mode
      if @state.selected_object
        draw_object_properties(panel_x, y, panel_width)
      elsif @state.current_mode.project?
        draw_project_properties(panel_x, y, panel_width)
      else
        draw_mode_properties(panel_x, y, panel_width)
      end
    end

    private def draw_object_properties(x : Int32, y : Int32, width : Int32)
      return unless scene = @state.current_scene
      return unless obj_name = @state.selected_object
      
      # Find the selected object
      if hotspot = scene.hotspots.find { |h| h.name == obj_name }
        draw_hotspot_object_properties(hotspot, x, y, width)
      elsif character = scene.characters.find { |c| c.name == obj_name }
        draw_character_object_properties(character, x, y, width)
      else
        RL.draw_text("Object not found", x + 10, y, 14, RL::RED)
      end
    end
    
    private def draw_hotspot_object_properties(hotspot : PointClickEngine::Scenes::Hotspot, x : Int32, y : Int32, width : Int32)
      RL.draw_text("Hotspot: #{hotspot.name}", x + 10, y, 14, RL::YELLOW)
      y += 25
      
      # Transform properties
      draw_property_section("Transform", x, y, width)
      y += 25
      y = draw_editable_property("hotspot_x", "X:", hotspot.position.x.to_s, x, y, width)
      y = draw_editable_property("hotspot_y", "Y:", hotspot.position.y.to_s, x, y, width)
      y = draw_editable_property("hotspot_width", "Width:", hotspot.size.x.to_s, x, y, width)
      y = draw_editable_property("hotspot_height", "Height:", hotspot.size.y.to_s, x, y, width)
      
      y += 15
      draw_property_section("Properties", x, y, width)
      y += 25
      y = draw_editable_property("hotspot_desc", "Description:", hotspot.description, x, y, width)
      y = draw_editable_property("hotspot_visible", "Visible:", hotspot.visible.to_s, x, y, width)
      
      # Cursor type dropdown
      y = draw_cursor_type_dropdown(hotspot, x, y, width)
      
      # Edit Actions button
      y += 15
      if draw_action_button("Edit Actions...", x + 10, y, width - 20)
        # Show action editor dialog
        if window = @state.editor_window
          window.show_hotspot_action_dialog(hotspot.name)
        end
      end
      y += 30
    end
    
    private def draw_character_object_properties(character : PointClickEngine::Characters::Character, x : Int32, y : Int32, width : Int32)
      RL.draw_text("Character: #{character.name}", x + 10, y, 14, RL::YELLOW)
      y += 25
      
      # Transform properties
      draw_property_section("Transform", x, y, width)
      y += 25
      y = draw_editable_property("char_x", "X:", character.position.x.to_s, x, y, width)
      y = draw_editable_property("char_y", "Y:", character.position.y.to_s, x, y, width)
      y = draw_editable_property("char_width", "Width:", character.size.x.to_s, x, y, width)
      y = draw_editable_property("char_height", "Height:", character.size.y.to_s, x, y, width)
      
      y += 15
      draw_property_section("Properties", x, y, width)
      y += 25
      y = draw_editable_property("char_desc", "Description:", character.description, x, y, width)
      y = draw_editable_property("char_speed", "Walk Speed:", character.walking_speed.to_s, x, y, width)
      
      # State dropdown
      y = draw_character_state_dropdown(character, x, y, width)
      
      # Direction dropdown
      y = draw_character_direction_dropdown(character, x, y, width)
      
      # If NPC, show mood
      if npc = character.as?(PointClickEngine::Characters::NPC)
        y = draw_npc_mood_dropdown(npc, x, y, width)
      end
    end

    private def draw_project_properties(x : Int32, y : Int32, width : Int32)
      return unless project = @state.current_project

      draw_property_section("Project Settings", x, y, width)
      y += 25

      y = draw_property_field("Name:", project.name, x, y, width)
      y = draw_property_field("Version:", project.version, x, y, width)
      y = draw_property_field("Author:", project.author, x, y, width)

      y += 15
      draw_property_section("Game Settings", x, y, width)
      y += 25

      y = draw_property_field("Title:", project.title, x, y, width)
      y = draw_property_field("Width:", project.window_width.to_s, x, y, width)
      y = draw_property_field("Height:", project.window_height.to_s, x, y, width)
      y = draw_property_field("FPS:", project.target_fps.to_s, x, y, width)
    end

    private def draw_mode_properties(x : Int32, y : Int32, width : Int32)
      case @state.current_mode
      when .scene?
        draw_scene_properties(x, y, width)
      when .character?
        draw_character_properties(x, y, width)
      when .hotspot?
        draw_hotspot_properties(x, y, width)
      when .dialog?
        draw_dialog_properties(x, y, width)
      when .assets?
        draw_asset_properties(x, y, width)
      end
    end

    private def draw_scene_properties(x : Int32, y : Int32, width : Int32)
      draw_property_section("Scene Settings", x, y, width)
      y += 25

      if scene = @state.current_scene
        y = draw_property_field("Name:", scene.name, x, y, width)
        y = draw_property_field("Background:", scene.background_path || "None", x, y, width)
        y = draw_property_field("Scale:", scene.scale.to_s, x, y, width)

        y += 15
        draw_property_section("Objects", x, y, width)
        y += 25

        RL.draw_text("Hotspots: #{scene.hotspots.size}", x + 10, y, 12, RL::LIGHTGRAY)
        y += 20
        RL.draw_text("Characters: #{scene.characters.size}", x + 10, y, 12, RL::LIGHTGRAY)
      else
        RL.draw_text("No scene loaded", x + 10, y, 14, RL::LIGHTGRAY)
      end
    end

    private def draw_character_properties(x : Int32, y : Int32, width : Int32)
      draw_property_section("Character Editor", x, y, width)
      y += 25

      RL.draw_text("Select a character to edit", x + 10, y, 12, RL::LIGHTGRAY)
    end

    private def draw_hotspot_properties(x : Int32, y : Int32, width : Int32)
      draw_property_section("Hotspot Editor", x, y, width)
      y += 25

      RL.draw_text("Select a hotspot to edit", x + 10, y, 12, RL::LIGHTGRAY)
    end

    private def draw_dialog_properties(x : Int32, y : Int32, width : Int32)
      draw_property_section("Dialog Editor", x, y, width)
      y += 25

      RL.draw_text("Select a dialog node to edit", x + 10, y, 12, RL::LIGHTGRAY)
    end

    private def draw_asset_properties(x : Int32, y : Int32, width : Int32)
      draw_property_section("Asset Browser", x, y, width)
      y += 25

      if project = @state.current_project
        RL.draw_text("Backgrounds: #{project.backgrounds.size}", x + 10, y, 12, RL::LIGHTGRAY)
        y += 20
        RL.draw_text("Characters: #{project.characters.size}", x + 10, y, 12, RL::LIGHTGRAY)
        y += 20
        RL.draw_text("Sounds: #{project.sounds.size}", x + 10, y, 12, RL::LIGHTGRAY)
        y += 20
        RL.draw_text("Music: #{project.music.size}", x + 10, y, 12, RL::LIGHTGRAY)
        y += 20
        RL.draw_text("Scripts: #{project.scripts.size}", x + 10, y, 12, RL::LIGHTGRAY)
      end
    end

    private def draw_property_section(title : String, x : Int32, y : Int32, width : Int32)
      RL.draw_text(title, x + 10, y, 14, RL::WHITE)
      RL.draw_line(x + 10, y + 18, x + width - 10, y + 18, RL::GRAY)
    end

    private def draw_property_field(label : String, value : String, x : Int32, y : Int32, width : Int32) : Int32
      label_width = 80

      # Draw label
      RL.draw_text(label, x + 10, y, 12, RL::LIGHTGRAY)

      # Draw value field background
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
    
    private def draw_editable_property(field_id : String, label : String, value : String, x : Int32, y : Int32, width : Int32) : Int32
      label_width = 80
      
      # Draw label
      RL.draw_text(label, x + 10, y, 12, RL::LIGHTGRAY)
      
      # Draw value field
      field_x = x + 10 + label_width
      field_width = width - label_width - 30
      field_height = 18
      
      # Check if this field is active
      is_active = @active_field == field_id
      
      # Handle click to activate field
      mouse_pos = RL.get_mouse_position
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        if mouse_pos.x >= field_x && mouse_pos.x <= field_x + field_width &&
           mouse_pos.y >= y - 2 && mouse_pos.y <= y - 2 + field_height
          @active_field = field_id
          @edit_buffer = value
          @cursor_position = value.size
        elsif is_active
          # Apply changes when clicking outside
          apply_property_change(field_id, @edit_buffer)
          @active_field = nil
        end
      end
      
      # Draw field background
      bg_color = is_active ? RL::Color.new(r: 50, g: 50, b: 50, a: 255) : RL::Color.new(r: 30, g: 30, b: 30, a: 255)
      border_color = is_active ? RL::WHITE : RL::GRAY
      
      RL.draw_rectangle(field_x, y - 2, field_width, field_height, bg_color)
      RL.draw_rectangle_lines(field_x, y - 2, field_width, field_height, border_color)
      
      # Draw value text
      display_value = is_active ? @edit_buffer : value
      value_to_draw = display_value.size > 20 ? display_value[0...17] + "..." : display_value
      RL.draw_text(value_to_draw, field_x + 5, y, 12, RL::WHITE)
      
      # Draw cursor if active
      if is_active && @cursor_blink_timer < 0.5f32
        cursor_x = field_x + 5 + RL.measure_text(value_to_draw[0...@cursor_position], 12)
        RL.draw_line(cursor_x, y, cursor_x, y + 12, RL::WHITE)
      end
      
      y + 25
    end
    
    private def draw_cursor_type_dropdown(hotspot : PointClickEngine::Scenes::Hotspot, x : Int32, y : Int32, width : Int32) : Int32
      label = "Cursor:"
      current_value = hotspot.cursor_type.to_s
      
      # Simple dropdown - for now just cycle through values on click
      y_ret = draw_property_field(label, current_value, x, y, width)
      
      # Check for click
      mouse_pos = RL.get_mouse_position
      field_x = x + 10 + 80
      field_width = width - 80 - 30
      if RL.mouse_button_pressed?(RL::MouseButton::Left) &&
         mouse_pos.x >= field_x && mouse_pos.x <= field_x + field_width &&
         mouse_pos.y >= y - 2 && mouse_pos.y <= y - 2 + 18
        # Cycle to next cursor type
        case hotspot.cursor_type
        when PointClickEngine::Scenes::Hotspot::CursorType::Default
          hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
        when PointClickEngine::Scenes::Hotspot::CursorType::Hand
          hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Look
        when PointClickEngine::Scenes::Hotspot::CursorType::Look
          hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Talk
        when PointClickEngine::Scenes::Hotspot::CursorType::Talk
          hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Use
        when PointClickEngine::Scenes::Hotspot::CursorType::Use
          hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Default
        end
        save_scene
      end
      
      y_ret
    end
    
    private def draw_character_state_dropdown(character : PointClickEngine::Characters::Character, x : Int32, y : Int32, width : Int32) : Int32
      label = "State:"
      current_value = character.state.to_s
      
      y_ret = draw_property_field(label, current_value, x, y, width)
      
      # Check for click to cycle states
      mouse_pos = RL.get_mouse_position
      field_x = x + 10 + 80
      field_width = width - 80 - 30
      if RL.mouse_button_pressed?(RL::MouseButton::Left) &&
         mouse_pos.x >= field_x && mouse_pos.x <= field_x + field_width &&
         mouse_pos.y >= y - 2 && mouse_pos.y <= y - 2 + 18
        # Cycle to next state
        case character.state
        when PointClickEngine::Characters::CharacterState::Idle
          character.state = PointClickEngine::Characters::CharacterState::Walking
        when PointClickEngine::Characters::CharacterState::Walking
          character.state = PointClickEngine::Characters::CharacterState::Talking
        when PointClickEngine::Characters::CharacterState::Talking
          character.state = PointClickEngine::Characters::CharacterState::Interacting
        when PointClickEngine::Characters::CharacterState::Interacting
          character.state = PointClickEngine::Characters::CharacterState::Thinking
        when PointClickEngine::Characters::CharacterState::Thinking
          character.state = PointClickEngine::Characters::CharacterState::Idle
        end
        save_scene
      end
      
      y_ret
    end
    
    private def draw_character_direction_dropdown(character : PointClickEngine::Characters::Character, x : Int32, y : Int32, width : Int32) : Int32
      label = "Direction:"
      current_value = character.direction.to_s
      
      y_ret = draw_property_field(label, current_value, x, y, width)
      
      # Check for click to cycle directions
      mouse_pos = RL.get_mouse_position
      field_x = x + 10 + 80
      field_width = width - 80 - 30
      if RL.mouse_button_pressed?(RL::MouseButton::Left) &&
         mouse_pos.x >= field_x && mouse_pos.x <= field_x + field_width &&
         mouse_pos.y >= y - 2 && mouse_pos.y <= y - 2 + 18
        # Cycle to next direction
        case character.direction
        when PointClickEngine::Characters::Direction::Left
          character.direction = PointClickEngine::Characters::Direction::Right
        when PointClickEngine::Characters::Direction::Right
          character.direction = PointClickEngine::Characters::Direction::Up
        when PointClickEngine::Characters::Direction::Up
          character.direction = PointClickEngine::Characters::Direction::Down
        when PointClickEngine::Characters::Direction::Down
          character.direction = PointClickEngine::Characters::Direction::Left
        end
        save_scene
      end
      
      y_ret
    end
    
    private def draw_npc_mood_dropdown(npc : PointClickEngine::Characters::NPC, x : Int32, y : Int32, width : Int32) : Int32
      label = "Mood:"
      current_value = npc.mood.to_s
      
      y_ret = draw_property_field(label, current_value, x, y, width)
      
      # Check for click to cycle moods
      mouse_pos = RL.get_mouse_position
      field_x = x + 10 + 80
      field_width = width - 80 - 30
      if RL.mouse_button_pressed?(RL::MouseButton::Left) &&
         mouse_pos.x >= field_x && mouse_pos.x <= field_x + field_width &&
         mouse_pos.y >= y - 2 && mouse_pos.y <= y - 2 + 18
        # Cycle to next mood
        case npc.mood
        when PointClickEngine::Characters::NPCMood::Friendly
          npc.mood = PointClickEngine::Characters::NPCMood::Neutral
        when PointClickEngine::Characters::NPCMood::Neutral
          npc.mood = PointClickEngine::Characters::NPCMood::Hostile
        when PointClickEngine::Characters::NPCMood::Hostile
          npc.mood = PointClickEngine::Characters::NPCMood::Sad
        when PointClickEngine::Characters::NPCMood::Sad
          npc.mood = PointClickEngine::Characters::NPCMood::Happy
        when PointClickEngine::Characters::NPCMood::Happy
          npc.mood = PointClickEngine::Characters::NPCMood::Angry
        when PointClickEngine::Characters::NPCMood::Angry
          npc.mood = PointClickEngine::Characters::NPCMood::Friendly
        end
        save_scene
      end
      
      y_ret
    end
    
    private def apply_property_change(field_id : String, new_value : String)
      return unless scene = @state.current_scene
      return unless obj_name = @state.selected_object
      
      # Find the object and apply the change
      if field_id.starts_with?("hotspot_")
        if hotspot = scene.hotspots.find { |h| h.name == obj_name }
          case field_id
          when "hotspot_x"
            if x = new_value.to_f32?
              old_pos = hotspot.position
              hotspot.position = RL::Vector2.new(x, hotspot.position.y)
              # Create undo action
              move_action = Core::MoveObjectAction.new(obj_name, old_pos, hotspot.position, @state)
              @state.add_undo_action(move_action)
            end
          when "hotspot_y"
            if y = new_value.to_f32?
              old_pos = hotspot.position
              hotspot.position = RL::Vector2.new(hotspot.position.x, y)
              # Create undo action
              move_action = Core::MoveObjectAction.new(obj_name, old_pos, hotspot.position, @state)
              @state.add_undo_action(move_action)
            end
          when "hotspot_width"
            if width = new_value.to_f32?
              hotspot.size = RL::Vector2.new(width, hotspot.size.y)
            end
          when "hotspot_height"
            if height = new_value.to_f32?
              hotspot.size = RL::Vector2.new(hotspot.size.x, height)
            end
          when "hotspot_desc"
            hotspot.description = new_value
          when "hotspot_visible"
            hotspot.visible = new_value.downcase == "true"
          end
          save_scene
        end
      elsif field_id.starts_with?("char_")
        if character = scene.characters.find { |c| c.name == obj_name }
          case field_id
          when "char_x"
            if x = new_value.to_f32?
              old_pos = character.position
              character.position = RL::Vector2.new(x, character.position.y)
              # Create undo action
              move_action = Core::MoveObjectAction.new(obj_name, old_pos, character.position, @state)
              @state.add_undo_action(move_action)
            end
          when "char_y"
            if y = new_value.to_f32?
              old_pos = character.position
              character.position = RL::Vector2.new(character.position.x, y)
              # Create undo action
              move_action = Core::MoveObjectAction.new(obj_name, old_pos, character.position, @state)
              @state.add_undo_action(move_action)
            end
          when "char_width"
            if width = new_value.to_f32?
              character.size = RL::Vector2.new(width, character.size.y)
            end
          when "char_height"
            if height = new_value.to_f32?
              character.size = RL::Vector2.new(character.size.x, height)
            end
          when "char_desc"
            character.description = new_value
          when "char_speed"
            if speed = new_value.to_f32?
              character.walking_speed = speed
            end
          end
          save_scene
        end
      end
    end
    
    private def save_scene
      return unless scene = @state.current_scene
      return unless project = @state.current_project
      
      scene_filename = "#{scene.name}.yml"
      scene_path = File.join(project.scenes_path, scene_filename)
      PaceEditor::IO::SceneIO.save_scene(scene, scene_path)
      @state.is_dirty = true
    end
    
    private def draw_action_button(text : String, x : Int32, y : Int32, width : Int32) : Bool
      height = 25
      
      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height
      
      bg_color = is_hover ? RL::Color.new(r: 70, g: 100, b: 70, a: 255) : RL::Color.new(r: 50, g: 80, b: 50, a: 255)
      
      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, RL::WHITE)
      
      text_width = RL.measure_text(text, 14)
      text_x = x + (width - text_width) // 2
      text_y = y + (height - 14) // 2
      RL.draw_text(text, text_x, text_y, 14, RL::WHITE)
      
      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end
  end
end
