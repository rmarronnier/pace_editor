require "./e2e_spec_helper"

describe "MenuBar E2E Tests" do
  describe "Initialization" do
    it "initializes with all menus closed" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      menu_bar.test_show_file_menu.should be_false
      menu_bar.test_show_edit_menu.should be_false
      menu_bar.test_show_view_menu.should be_false
    end

    it "initializes with all dialogs closed" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      menu_bar.test_show_new_dialog.should be_false
      menu_bar.test_show_open_dialog.should be_false
      menu_bar.test_show_save_dialog.should be_false
      menu_bar.test_show_about_dialog.should be_false
      menu_bar.test_show_scene_dialog.should be_false
    end

    it "initializes with empty project name" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      menu_bar.test_new_project_name.should eq("")
      menu_bar.test_new_project_path.should eq("")
    end

    it "initializes with default save path" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      menu_bar.test_save_project_path.should eq("./projects")
    end
  end

  describe "Menu toggling" do
    it "toggles file menu" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      menu_bar.test_show_file_menu.should be_false
      menu_bar.test_toggle_file_menu
      menu_bar.test_show_file_menu.should be_true
      menu_bar.test_toggle_file_menu
      menu_bar.test_show_file_menu.should be_false
    end

    it "toggles edit menu" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      menu_bar.test_show_edit_menu.should be_false
      menu_bar.test_toggle_edit_menu
      menu_bar.test_show_edit_menu.should be_true
      menu_bar.test_toggle_edit_menu
      menu_bar.test_show_edit_menu.should be_false
    end

    it "toggles view menu" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      menu_bar.test_show_view_menu.should be_false
      menu_bar.test_toggle_view_menu
      menu_bar.test_show_view_menu.should be_true
      menu_bar.test_toggle_view_menu
      menu_bar.test_show_view_menu.should be_false
    end

    it "closes other menus when opening file menu" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      menu_bar.test_set_show_edit_menu(true)
      menu_bar.test_set_show_view_menu(true)

      menu_bar.test_toggle_file_menu

      menu_bar.test_show_file_menu.should be_true
      menu_bar.test_show_edit_menu.should be_false
      menu_bar.test_show_view_menu.should be_false
    end

    it "closes other menus when opening edit menu" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      menu_bar.test_set_show_file_menu(true)
      menu_bar.test_set_show_view_menu(true)

      menu_bar.test_toggle_edit_menu

      menu_bar.test_show_file_menu.should be_false
      menu_bar.test_show_edit_menu.should be_true
      menu_bar.test_show_view_menu.should be_false
    end

    it "closes other menus when opening view menu" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      menu_bar.test_set_show_file_menu(true)
      menu_bar.test_set_show_edit_menu(true)

      menu_bar.test_toggle_view_menu

      menu_bar.test_show_file_menu.should be_false
      menu_bar.test_show_edit_menu.should be_false
      menu_bar.test_show_view_menu.should be_true
    end

    it "closes all menus" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      menu_bar.test_set_show_file_menu(true)
      menu_bar.test_set_show_edit_menu(true)
      menu_bar.test_set_show_view_menu(true)

      menu_bar.test_close_all_menus

      menu_bar.test_show_file_menu.should be_false
      menu_bar.test_show_edit_menu.should be_false
      menu_bar.test_show_view_menu.should be_false
    end
  end

  describe "Dialog management" do
    it "closes all dialogs" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      menu_bar.test_set_show_new_dialog(true)
      menu_bar.test_set_show_open_dialog(true)
      menu_bar.test_set_show_save_dialog(true)
      menu_bar.test_set_show_scene_dialog(true)

      menu_bar.test_close_all_dialogs

      menu_bar.test_show_new_dialog.should be_false
      menu_bar.test_show_open_dialog.should be_false
      menu_bar.test_show_save_dialog.should be_false
      menu_bar.test_show_scene_dialog.should be_false
    end
  end

  describe "Project name handling" do
    it "sets new project name" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      menu_bar.test_set_new_project_name("My Game")

      menu_bar.test_new_project_name.should eq("My Game")
    end

    it "sets new project path" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      menu_bar.test_set_new_project_path("/home/user/projects")

      menu_bar.test_new_project_path.should eq("/home/user/projects")
    end
  end

  describe "Menu button bounds" do
    it "calculates file menu button bounds" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      bounds = menu_bar.test_file_menu_button_bounds
      bounds[:x].should eq(10)
      bounds[:y].should eq(5)
      bounds[:width].should eq(40)
      bounds[:height].should eq(20)
    end

    it "calculates edit menu button bounds" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      bounds = menu_bar.test_edit_menu_button_bounds
      bounds[:x].should eq(60)
      bounds[:y].should eq(5)
      bounds[:width].should eq(40)
      bounds[:height].should eq(20)
    end

    it "calculates view menu button bounds" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      bounds = menu_bar.test_view_menu_button_bounds
      bounds[:x].should eq(110)
      bounds[:y].should eq(5)
      bounds[:width].should eq(40)
      bounds[:height].should eq(20)
    end
  end

  describe "Dropdown bounds" do
    it "calculates file dropdown bounds" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      bounds = menu_bar.test_file_dropdown_bounds
      bounds[:x].should eq(10)
      bounds[:y].should eq(PaceEditor::Core::EditorWindow::MENU_HEIGHT)
      bounds[:width].should eq(140)
      bounds[:height].should eq(200)
    end

    it "calculates edit dropdown bounds" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      bounds = menu_bar.test_edit_dropdown_bounds
      bounds[:x].should eq(60)
      bounds[:y].should eq(PaceEditor::Core::EditorWindow::MENU_HEIGHT)
      bounds[:width].should eq(120)
      bounds[:height].should eq(96)
    end

    it "calculates view dropdown bounds" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      bounds = menu_bar.test_view_dropdown_bounds
      bounds[:x].should eq(110)
      bounds[:y].should eq(PaceEditor::Core::EditorWindow::MENU_HEIGHT)
      bounds[:width].should eq(140)
      bounds[:height].should eq(72)
    end
  end

  describe "Click handling with input" do
    it "closes menus when clicking outside" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      # Open file menu
      menu_bar.test_set_show_file_menu(true)

      # Click outside menu area
      input = harness.input
      input.set_mouse_position(500.0_f32, 200.0_f32)
      input.press_mouse_button(RL::MouseButton::Left)

      menu_bar.update_with_input(input)

      menu_bar.test_show_file_menu.should be_false
    end

    it "keeps menu open when clicking inside dropdown" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      # Open file menu
      menu_bar.test_set_show_file_menu(true)

      # Click inside file dropdown (x: 10-150, y: MENU_HEIGHT to MENU_HEIGHT+120)
      input = harness.input
      input.set_mouse_position(50.0_f32, (PaceEditor::Core::EditorWindow::MENU_HEIGHT + 50).to_f32)
      input.press_mouse_button(RL::MouseButton::Left)

      menu_bar.update_with_input(input)

      menu_bar.test_show_file_menu.should be_true
    end
  end

  describe "Mode buttons position" do
    it "has correct mode buttons start position" do
      harness = E2ETestHelper.create_harness_with_project
      menu_bar = PaceEditor::UI::MenuBar.new(harness.editor.state)

      x = menu_bar.test_mode_buttons_start_x
      x.should be > 100  # After File, Edit, View menus
    end
  end
end
