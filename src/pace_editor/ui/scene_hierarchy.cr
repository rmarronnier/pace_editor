module PaceEditor::UI
  # Scene hierarchy panel showing scene objects in a tree view
  class SceneHierarchy
    def initialize(@state : Core::EditorState)
      @expanded_nodes = Set(String).new
    end

    def update
      # Handle tree node expansion/collapse
    end

    def draw
      return unless @state.current_mode.scene?

      panel_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      panel_y = Core::EditorWindow::WINDOW_HEIGHT - 200 # Bottom panel
      panel_width = Core::EditorWindow::SCENE_HIERARCHY_WIDTH
      panel_height = 200

      # Draw panel background
      RL.draw_rectangle(panel_x, panel_y, panel_width, panel_height,
        RL::Color.new(r: 45, g: 45, b: 45, a: 255))
      RL.draw_rectangle_lines(panel_x, panel_y, panel_width, panel_height, RL::GRAY)

      # Panel title
      RL.draw_text("Scene Hierarchy", panel_x + 10, panel_y + 10, 16, RL::WHITE)

      y = panel_y + 35

      if scene = @state.current_scene
        # Scene root
        if draw_tree_node("Scene: #{scene.name}", panel_x + 10, y, true)
          # Scene is always expanded
        end
        y += 20

        # Hotspots section
        if draw_tree_node("Hotspots", panel_x + 20, y, @expanded_nodes.includes?("hotspots"))
          if @expanded_nodes.includes?("hotspots")
            @expanded_nodes.delete("hotspots")
          else
            @expanded_nodes.add("hotspots")
          end
        end
        y += 20

        if @expanded_nodes.includes?("hotspots")
          scene.hotspots.each do |hotspot|
            if draw_tree_item(hotspot.name, panel_x + 40, y, @state.is_selected?(hotspot.name))
              @state.select_object(hotspot.name)
            end
            y += 18
          end
        end

        # Characters section
        if draw_tree_node("Characters", panel_x + 20, y, @expanded_nodes.includes?("characters"))
          if @expanded_nodes.includes?("characters")
            @expanded_nodes.delete("characters")
          else
            @expanded_nodes.add("characters")
          end
        end
        y += 20

        if @expanded_nodes.includes?("characters")
          scene.characters.each do |character|
            if draw_tree_item(character.name, panel_x + 40, y, @state.is_selected?(character.name))
              @state.select_object(character.name)
            end
            y += 18
          end
        end

        # Objects section
        if draw_tree_node("Objects", panel_x + 20, y, @expanded_nodes.includes?("objects"))
          if @expanded_nodes.includes?("objects")
            @expanded_nodes.delete("objects")
          else
            @expanded_nodes.add("objects")
          end
        end
        y += 20

        if @expanded_nodes.includes?("objects")
          scene.objects.each do |object|
            # Show only non-character, non-hotspot objects
            next if scene.characters.any? { |c| c == object }
            next if scene.hotspots.any? { |h| h == object }

            object_name = object.class.name.split("::").last
            if draw_tree_item(object_name, panel_x + 40, y, false)
              # Select object
            end
            y += 18
          end
        end
      else
        RL.draw_text("No scene loaded", panel_x + 10, y, 14, RL::LIGHTGRAY)
      end
    end

    private def draw_tree_node(text : String, x : Int32, y : Int32, expanded : Bool) : Bool
      # Draw expand/collapse triangle
      triangle_size = 8
      if expanded
        # Down arrow (expanded)
        RL.draw_triangle(
          RL::Vector2.new(x.to_f32, y.to_f32 + 2),
          RL::Vector2.new(x.to_f32 + triangle_size, y.to_f32 + 2),
          RL::Vector2.new(x.to_f32 + triangle_size/2, y.to_f32 + triangle_size + 2),
          RL::WHITE
        )
      else
        # Right arrow (collapsed)
        RL.draw_triangle(
          RL::Vector2.new(x.to_f32 + 2, y.to_f32),
          RL::Vector2.new(x.to_f32 + 2, y.to_f32 + triangle_size),
          RL::Vector2.new(x.to_f32 + triangle_size + 2, y.to_f32 + triangle_size/2),
          RL::WHITE
        )
      end

      # Draw text
      RL.draw_text(text, x + triangle_size + 8, y, 14, RL::WHITE)

      # Check for click
      text_width = RL.measure_text(text, 14)
      mouse_pos = RL.get_mouse_position
      is_clicked = mouse_pos.x >= x && mouse_pos.x <= x + triangle_size + 8 + text_width &&
                   mouse_pos.y >= y && mouse_pos.y <= y + 16 &&
                   RL.mouse_button_pressed?(RL::MouseButton::Left)

      is_clicked
    end

    private def draw_tree_item(text : String, x : Int32, y : Int32, selected : Bool) : Bool
      # Draw selection background
      if selected
        text_width = RL.measure_text(text, 12)
        RL.draw_rectangle(x - 2, y - 1, text_width + 4, 15,
          RL::Color.new(r: 100, g: 150, b: 200, a: 100))
      end

      # Draw bullet point
      RL.draw_circle(x + 4, y + 6, 2, RL::LIGHTGRAY)

      # Draw text
      color = selected ? RL::YELLOW : RL::LIGHTGRAY
      RL.draw_text(text, x + 12, y, 12, color)

      # Check for click
      text_width = RL.measure_text(text, 12)
      mouse_pos = RL.get_mouse_position
      is_clicked = mouse_pos.x >= x && mouse_pos.x <= x + 12 + text_width &&
                   mouse_pos.y >= y && mouse_pos.y <= y + 14 &&
                   RL.mouse_button_pressed?(RL::MouseButton::Left)

      is_clicked
    end
  end
end
