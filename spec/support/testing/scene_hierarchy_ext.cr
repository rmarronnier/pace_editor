# Testing extensions for SceneHierarchy
# Reopens the class to add e2e testing support methods

module PaceEditor::UI
  class SceneHierarchy
    # Update with a specific input provider (for testing)
    def update_with_input(input : Testing::InputProvider)
      return unless @state.current_mode.scene?

      mouse_pos = input.get_mouse_position
      screen_height = input.get_screen_height

      panel_x = Core::EditorWindow::TOOL_PALETTE_WIDTH
      panel_y = screen_height - 200
      panel_width = Core::EditorWindow::SCENE_HIERARCHY_WIDTH

      # Check if click is within panel bounds
      return unless mouse_pos.x >= panel_x && mouse_pos.x <= panel_x + panel_width &&
                    mouse_pos.y >= panel_y && mouse_pos.y <= panel_y + 200

      return unless scene = @state.current_scene

      y = panel_y + 35

      # Scene root (always expanded, skip 20 pixels)
      y += 20

      # Hotspots section
      hotspots_node_y = y
      if tree_node_clicked?(mouse_pos, input, panel_x + 20, hotspots_node_y)
        if @expanded_nodes.includes?("hotspots")
          @expanded_nodes.delete("hotspots")
        else
          @expanded_nodes.add("hotspots")
        end
      end
      y += 20

      if @expanded_nodes.includes?("hotspots")
        scene.hotspots.each do |hotspot|
          if tree_item_clicked?(mouse_pos, input, panel_x + 40, y)
            @state.select_object(hotspot.name)
          end
          y += 18
        end
      end

      # Characters section
      characters_node_y = y
      if tree_node_clicked?(mouse_pos, input, panel_x + 20, characters_node_y)
        if @expanded_nodes.includes?("characters")
          @expanded_nodes.delete("characters")
        else
          @expanded_nodes.add("characters")
        end
      end
      y += 20

      if @expanded_nodes.includes?("characters")
        scene.characters.each do |character|
          if tree_item_clicked?(mouse_pos, input, panel_x + 40, y)
            @state.select_object(character.name)
          end
          y += 18
        end
      end

      # Objects section
      objects_node_y = y
      if tree_node_clicked?(mouse_pos, input, panel_x + 20, objects_node_y)
        if @expanded_nodes.includes?("objects")
          @expanded_nodes.delete("objects")
        else
          @expanded_nodes.add("objects")
        end
      end
    end

    private def tree_node_clicked?(mouse_pos : RL::Vector2, input : Testing::InputProvider, x : Int32, y : Int32) : Bool
      return false unless input.mouse_button_pressed?(RL::MouseButton::Left)

      # Tree node click area (triangle + text)
      click_width = 150 # Approximate
      click_height = 16

      mouse_pos.x >= x && mouse_pos.x <= x + click_width &&
        mouse_pos.y >= y && mouse_pos.y <= y + click_height
    end

    private def tree_item_clicked?(mouse_pos : RL::Vector2, input : Testing::InputProvider, x : Int32, y : Int32) : Bool
      return false unless input.mouse_button_pressed?(RL::MouseButton::Left)

      # Tree item click area
      click_width = 150 # Approximate
      click_height = 14

      mouse_pos.x >= x && mouse_pos.x <= x + click_width &&
        mouse_pos.y >= y && mouse_pos.y <= y + click_height
    end

    # Testing helper: expand a node
    def expand_node_for_test(node_name : String)
      @expanded_nodes.add(node_name)
    end

    # Testing helper: collapse a node
    def collapse_node_for_test(node_name : String)
      @expanded_nodes.delete(node_name)
    end

    # Testing helper: check if node is expanded
    def node_expanded?(node_name : String) : Bool
      @expanded_nodes.includes?(node_name)
    end
  end
end
