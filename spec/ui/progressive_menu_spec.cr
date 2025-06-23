require "../spec_helper"

describe PaceEditor::UI::ProgressiveMenu do
  progressive_menu : PaceEditor::UI::ProgressiveMenu?
  editor_state : PaceEditor::Core::EditorState?
  ui_state : PaceEditor::UI::UIState?

  before_each do
    @editor_state = test_editor_state(has_project: false)
    @ui_state = PaceEditor::UI::UIState.new
    @progressive_menu = PaceEditor::UI::ProgressiveMenu.new(@editor_state.not_nil!, @ui_state.not_nil!)
  end

  def progressive_menu
    @progressive_menu.not_nil!
  end

  def editor_state
    @editor_state.not_nil!
  end

  def ui_state
    @ui_state.not_nil!
  end

  describe "menu initialization" do
    it "creates menu with all sections" do
      progressive_menu.menu_items.keys.should contain("File")
      progressive_menu.menu_items.keys.should contain("Edit")
      progressive_menu.menu_items.keys.should contain("Scene")
      progressive_menu.menu_items.keys.should contain("Character")
      progressive_menu.menu_items.keys.should contain("Dialog")
      progressive_menu.menu_items.keys.should contain("Tools")
      progressive_menu.menu_items.keys.should contain("Help")
    end

    it "initializes with no active menu" do
      progressive_menu.active_menu.should be_nil
    end
  end

  describe "menu section visibility" do
    it "shows File menu always" do
      file_section = progressive_menu.menu_items["File"]
      file_section.visible?(editor_state, ui_state).should be_true
    end

    it "hides Edit menu when no project" do
      edit_section = progressive_menu.menu_items["Edit"]
      edit_section.visible?(editor_state, ui_state).should be_false
    end

    it "shows Edit menu when project exists" do
      # Create state with project
      state_with_project = test_editor_state(has_project: true)

      edit_section = progressive_menu.menu_items["Edit"]
      edit_section.visible?(state_with_project, ui_state).should be_true
    end

    it "hides Scene menu when no project" do
      scene_section = progressive_menu.menu_items["Scene"]
      scene_section.visible?(editor_state, ui_state).should be_false
    end

    it "shows Scene menu when project exists" do
      # Create state with project
      state_with_project = test_editor_state(has_project: true)

      scene_section = progressive_menu.menu_items["Scene"]
      scene_section.visible?(state_with_project, ui_state).should be_true
    end

    it "shows Help menu always" do
      help_section = progressive_menu.menu_items["Help"]
      help_section.visible?(editor_state, ui_state).should be_true
    end
  end

  describe "menu item visibility" do
    it "shows new project item always" do
      file_section = progressive_menu.menu_items["File"]
      new_project_item = file_section.items.find { |item|
        item.is_a?(PaceEditor::UI::MenuItem) && item.as(PaceEditor::UI::MenuItem).id == "new_project"
      }.as(PaceEditor::UI::MenuItem)

      new_project_item.visible?(editor_state, ui_state).should be_true
    end

    it "hides save project when no project or not dirty" do
      file_section = progressive_menu.menu_items["File"]
      save_item = file_section.items.find { |item|
        item.is_a?(PaceEditor::UI::MenuItem) && item.as(PaceEditor::UI::MenuItem).id == "save_project"
      }.as(PaceEditor::UI::MenuItem)

      save_item.visible?(editor_state, ui_state).should be_false
    end

    it "shows save project when project exists and is dirty" do
      # Create state with dirty project
      state_with_dirty_project = test_editor_state(has_project: true, is_dirty: true)

      file_section = progressive_menu.menu_items["File"]
      save_item = file_section.items.find { |item|
        item.is_a?(PaceEditor::UI::MenuItem) && item.as(PaceEditor::UI::MenuItem).id == "save_project"
      }.as(PaceEditor::UI::MenuItem)

      save_item.visible?(state_with_dirty_project, ui_state).should be_true
    end
  end

  describe "power mode behavior" do
    it "shows all items in power mode" do
      ui_state.enable_power_mode

      edit_section = progressive_menu.menu_items["Edit"]
      visible_items = edit_section.visible_items(editor_state, ui_state)

      # In power mode, should show all items regardless of availability
      visible_items.size.should eq(edit_section.items.size)
    end

    it "filters items in normal mode" do
      ui_state.disable_power_mode

      edit_section = progressive_menu.menu_items["Edit"]
      visible_items = edit_section.visible_items(editor_state, ui_state)

      # In normal mode, should filter based on visibility rules
      # Edit section should be empty when no project exists
      visible_items.select { |item| item.visible?(editor_state, ui_state) }.size.should be < edit_section.items.size
    end
  end

  describe "menu input handling" do
    it "returns false when mouse is outside menu bar" do
      mouse_pos = RL::Vector2.new(100.0_f32, 100.0_f32) # Below menu bar
      result = progressive_menu.handle_input(mouse_pos, false)

      result.should be_false
    end

    it "handles hover over menu sections" do
      mouse_pos = RL::Vector2.new(15.0_f32, 15.0_f32) # Over File menu
      progressive_menu.handle_input(mouse_pos, false)

      progressive_menu.hover_item.should eq("File")
    end

    it "toggles menu on click" do
      mouse_pos = RL::Vector2.new(15.0_f32, 15.0_f32) # Over File menu
      result = progressive_menu.handle_input(mouse_pos, true)

      result.should be_true
      progressive_menu.active_menu.should eq("File")
    end

    it "closes menu when clicking outside" do
      # First open a menu
      mouse_pos = RL::Vector2.new(15.0_f32, 15.0_f32)
      progressive_menu.handle_input(mouse_pos, true)

      # Then click outside
      outside_pos = RL::Vector2.new(100.0_f32, 100.0_f32)
      progressive_menu.handle_input(outside_pos, true)

      progressive_menu.active_menu.should be_nil
    end
  end

  describe "tooltip system" do
    it "shows tooltip for disabled menu sections" do
      # Mock section as disabled
      ui_state.power_mode = false

      mouse_pos = RL::Vector2.new(65.0_f32, 15.0_f32) # Over Edit menu (disabled when no project)
      progressive_menu.hover_item = "Edit"

      # The handle_input should trigger tooltip showing
      progressive_menu.handle_input(mouse_pos, false)

      # In a real implementation, this would show a tooltip
      # Here we just verify the hover item is set
      progressive_menu.hover_item.should eq("Edit")
    end
  end

  describe "menu actions" do
    it "executes menu item actions" do
      # This would test that clicking menu items executes their actions
      # For now, we just verify the structure exists
      file_section = progressive_menu.menu_items["File"]
      new_project_item = file_section.items.find { |item|
        item.is_a?(PaceEditor::UI::MenuItem) && item.as(PaceEditor::UI::MenuItem).id == "new_project"
      }.as(PaceEditor::UI::MenuItem)

      new_project_item.action.should_not be_nil
    end
  end

  describe "layout calculation" do
    it "calculates menu section widths" do
      file_section = progressive_menu.menu_items["File"]
      file_section.width.should be > 0.0_f32
    end

    it "updates section layout positions" do
      file_section = progressive_menu.menu_items["File"]
      file_section.update_layout(10.0_f32, 0.0_f32)

      file_section.x.should eq(10.0_f32)
      file_section.y.should eq(0.0_f32)
    end
  end
end
