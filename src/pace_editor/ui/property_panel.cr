module PaceEditor::UI
  # Property panel for editing selected object properties
  class PropertyPanel
    def initialize(@state : Core::EditorState)
      @scroll_y = 0.0f32
    end

    def update
      # Handle scrolling and input
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
      RL.draw_text("Selected: #{@state.selected_object}", x + 10, y, 14, RL::YELLOW)
      y += 25

      # Generic object properties
      draw_property_section("Transform", x, y, width)
      y += 25
      y = draw_property_field("X:", "0", x, y, width)
      y = draw_property_field("Y:", "0", x, y, width)
      y = draw_property_field("Width:", "64", x, y, width)
      y = draw_property_field("Height:", "64", x, y, width)

      y += 15
      draw_property_section("Appearance", x, y, width)
      y += 25
      y = draw_property_field("Visible:", "true", x, y, width)
      y = draw_property_field("Active:", "true", x, y, width)
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
  end
end
