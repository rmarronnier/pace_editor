# Test extensions for MenuBar
module PaceEditor::UI
  class MenuBar
    # Test-friendly update method that accepts an InputProvider
    def update_with_input(input : PaceEditor::Testing::SimulatedInputProvider)
      if input.mouse_button_pressed?(RL::MouseButton::Left)
        mouse_pos = input.get_mouse_position

        # Don't close if clicking on a dropdown menu
        in_file_dropdown = @show_file_menu && mouse_pos.x >= 10 && mouse_pos.x <= 150 &&
                           mouse_pos.y >= Core::EditorWindow::MENU_HEIGHT && mouse_pos.y <= Core::EditorWindow::MENU_HEIGHT + 120
        in_edit_dropdown = @show_edit_menu && mouse_pos.x >= 60 && mouse_pos.x <= 180 &&
                           mouse_pos.y >= Core::EditorWindow::MENU_HEIGHT && mouse_pos.y <= Core::EditorWindow::MENU_HEIGHT + 96
        in_view_dropdown = @show_view_menu && mouse_pos.x >= 110 && mouse_pos.x <= 250 &&
                           mouse_pos.y >= Core::EditorWindow::MENU_HEIGHT && mouse_pos.y <= Core::EditorWindow::MENU_HEIGHT + 72

        # Only close if clicking outside menu area and not in any dropdown
        if mouse_pos.y > Core::EditorWindow::MENU_HEIGHT && !in_file_dropdown && !in_edit_dropdown && !in_view_dropdown
          @show_file_menu = false
          @show_edit_menu = false
          @show_view_menu = false
        end
      end
    end

    # Testing getters
    def test_show_file_menu : Bool
      @show_file_menu
    end

    def test_show_edit_menu : Bool
      @show_edit_menu
    end

    def test_show_view_menu : Bool
      @show_view_menu
    end

    def test_show_new_dialog : Bool
      @show_new_dialog
    end

    def test_show_open_dialog : Bool
      @show_open_dialog
    end

    def test_show_save_dialog : Bool
      @show_save_dialog
    end

    def test_show_about_dialog : Bool
      @show_about_dialog
    end

    def test_show_scene_dialog : Bool
      @show_scene_dialog
    end

    def test_new_project_name : String
      @new_project_name
    end

    def test_new_project_path : String
      @new_project_path
    end

    def test_save_project_name : String
      @save_project_name
    end

    def test_save_project_path : String
      @save_project_path
    end

    # Testing setters
    def test_set_show_file_menu(show : Bool)
      @show_file_menu = show
    end

    def test_set_show_edit_menu(show : Bool)
      @show_edit_menu = show
    end

    def test_set_show_view_menu(show : Bool)
      @show_view_menu = show
    end

    def test_set_show_new_dialog(show : Bool)
      @show_new_dialog = show
    end

    def test_set_show_open_dialog(show : Bool)
      @show_open_dialog = show
    end

    def test_set_show_save_dialog(show : Bool)
      @show_save_dialog = show
    end

    def test_set_show_scene_dialog(show : Bool)
      @show_scene_dialog = show
    end

    def test_set_new_project_name(name : String)
      @new_project_name = name
    end

    def test_set_new_project_path(path : String)
      @new_project_path = path
    end

    # Calculate menu button bounds for testing
    def test_file_menu_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      {x: 10, y: 5, width: 40, height: 20}
    end

    def test_edit_menu_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      {x: 60, y: 5, width: 40, height: 20}
    end

    def test_view_menu_button_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      {x: 110, y: 5, width: 40, height: 20}
    end

    def test_file_dropdown_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      {x: 10, y: Core::EditorWindow::MENU_HEIGHT, width: 140, height: 200}
    end

    def test_edit_dropdown_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      {x: 60, y: Core::EditorWindow::MENU_HEIGHT, width: 120, height: 96}
    end

    def test_view_dropdown_bounds : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      {x: 110, y: Core::EditorWindow::MENU_HEIGHT, width: 140, height: 72}
    end

    # Mode button bounds
    def test_mode_buttons_start_x : Int32
      190  # File(50) + Edit(50) + View(50) + margin(40)
    end

    # Get bounds for a specific mode button
    def test_mode_button_bounds(mode : PaceEditor::EditorMode) : NamedTuple(x: Int32, y: Int32, width: Int32, height: Int32)
      modes = [
        {PaceEditor::EditorMode::Scene, "Scene"},
        {PaceEditor::EditorMode::Character, "Character"},
        {PaceEditor::EditorMode::Hotspot, "Hotspot"},
        {PaceEditor::EditorMode::Dialog, "Dialog"},
        {PaceEditor::EditorMode::Assets, "Assets"},
        {PaceEditor::EditorMode::Script, "Script"},
        {PaceEditor::EditorMode::Project, "Project"},
      ]

      x = test_mode_buttons_start_x
      modes.each do |m, label|
        width = label.size * 8 + 20  # Approximate: ~8 pixels per char + padding
        if m == mode
          return {x: x, y: 2, width: width, height: 20}
        end
        x += width
      end

      # Default fallback
      {x: test_mode_buttons_start_x, y: 2, width: 60, height: 20}
    end

    # Process mode button clicks using simulated input
    def test_handle_mode_button_click(input : PaceEditor::Testing::SimulatedInputProvider) : Bool
      return false unless input.mouse_button_pressed?(RL::MouseButton::Left)

      mouse_pos = input.get_mouse_position
      modes = [
        {PaceEditor::EditorMode::Scene, "Scene"},
        {PaceEditor::EditorMode::Character, "Character"},
        {PaceEditor::EditorMode::Hotspot, "Hotspot"},
        {PaceEditor::EditorMode::Dialog, "Dialog"},
        {PaceEditor::EditorMode::Assets, "Assets"},
        {PaceEditor::EditorMode::Script, "Script"},
        {PaceEditor::EditorMode::Project, "Project"},
      ]

      x = test_mode_buttons_start_x
      modes.each do |mode, label|
        width = label.size * 8 + 20
        height = 25

        # Check if click is within this button's bounds
        if mouse_pos.x >= x && mouse_pos.x <= x + width &&
           mouse_pos.y >= 2 && mouse_pos.y <= 2 + height
          @state.current_mode = mode
          return true
        end

        x += width
      end

      false
    end

    # Trigger menu actions for testing
    def test_toggle_file_menu
      @show_file_menu = !@show_file_menu
      @show_edit_menu = false
      @show_view_menu = false
    end

    def test_toggle_edit_menu
      @show_edit_menu = !@show_edit_menu
      @show_file_menu = false
      @show_view_menu = false
    end

    def test_toggle_view_menu
      @show_view_menu = !@show_view_menu
      @show_file_menu = false
      @show_edit_menu = false
    end

    def test_close_all_menus
      @show_file_menu = false
      @show_edit_menu = false
      @show_view_menu = false
    end

    def test_close_all_dialogs
      @show_new_dialog = false
      @show_open_dialog = false
      @show_save_dialog = false
      @show_about_dialog = false
      @show_scene_dialog = false
    end
  end
end
