require "../spec_helper"

describe PaceEditor::UI::ProgressiveMenu do
  it "creates menu with all sections" do
    editor_state = PaceEditor::Core::EditorState.new
    ui_state = PaceEditor::UI::UIState.new
    progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)

    progressive_menu.menu_items.keys.should contain("File")
    progressive_menu.menu_items.keys.should contain("Edit")
    progressive_menu.menu_items.keys.should contain("Scene")
    progressive_menu.menu_items.keys.should contain("Character")
    progressive_menu.menu_items.keys.should contain("Dialog")
    progressive_menu.menu_items.keys.should contain("Tools")
    progressive_menu.menu_items.keys.should contain("Help")
  end

  it "initializes with no active menu" do
    editor_state = PaceEditor::Core::EditorState.new
    ui_state = PaceEditor::UI::UIState.new
    progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)

    progressive_menu.active_menu.should be_nil
  end

  describe "menu section visibility" do
    it "shows File menu always" do
      editor_state = PaceEditor::Core::EditorState.new
      ui_state = PaceEditor::UI::UIState.new
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)
      
      file_section = progressive_menu.menu_items["File"]
      file_section.visible?(editor_state, ui_state).should be_true
    end

    it "hides Edit menu when no project" do
      editor_state = PaceEditor::Core::EditorState.new
      ui_state = PaceEditor::UI::UIState.new
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)
      
      edit_section = progressive_menu.menu_items["Edit"]
      edit_section.visible?(editor_state, ui_state).should be_false
    end

    it "shows Edit menu when project exists" do
      editor_state = PaceEditor::Core::EditorState.new
      # Create a project
      temp_dir = File.tempname("test_project_#{Time.utc.to_unix_ms}")
      project = PaceEditor::Core::Project.new("Test Project", temp_dir)
      editor_state.current_project = project
      
      ui_state = PaceEditor::UI::UIState.new
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)

      edit_section = progressive_menu.menu_items["Edit"]
      edit_section.visible?(editor_state, ui_state).should be_true
      
      # Cleanup
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end

    it "shows Help menu always" do
      editor_state = PaceEditor::Core::EditorState.new
      ui_state = PaceEditor::UI::UIState.new
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)
      
      help_section = progressive_menu.menu_items["Help"]
      help_section.visible?(editor_state, ui_state).should be_true
    end
  end

  describe "menu item visibility" do
    it "shows new project item always" do
      editor_state = PaceEditor::Core::EditorState.new
      ui_state = PaceEditor::UI::UIState.new
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)
      
      file_section = progressive_menu.menu_items["File"]
      new_project_item = file_section.items.find { |item|
        item.is_a?(PaceEditor::UI::MenuItem) && item.as(PaceEditor::UI::MenuItem).id == "new_project"
      }
      
      new_project_item.should_not be_nil
      if item = new_project_item.as?(PaceEditor::UI::MenuItem)
        item.visible?(editor_state, ui_state).should be_true
      end
    end

    it "hides save project when no project or not dirty" do
      editor_state = PaceEditor::Core::EditorState.new
      ui_state = PaceEditor::UI::UIState.new
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)
      
      file_section = progressive_menu.menu_items["File"]
      save_item = file_section.items.find { |item|
        item.is_a?(PaceEditor::UI::MenuItem) && item.as(PaceEditor::UI::MenuItem).id == "save_project"
      }
      
      save_item.should_not be_nil
      if item = save_item.as?(PaceEditor::UI::MenuItem)
        item.visible?(editor_state, ui_state).should be_false
      end
    end

    it "shows save project when project exists and is dirty" do
      editor_state = PaceEditor::Core::EditorState.new
      # Create a project
      temp_dir = File.tempname("test_project_#{Time.utc.to_unix_ms}")
      project = PaceEditor::Core::Project.new("Test Project", temp_dir)
      editor_state.current_project = project
      editor_state.is_dirty = true
      
      ui_state = PaceEditor::UI::UIState.new
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)

      file_section = progressive_menu.menu_items["File"]
      save_item = file_section.items.find { |item|
        item.is_a?(PaceEditor::UI::MenuItem) && item.as(PaceEditor::UI::MenuItem).id == "save_project"
      }
      
      save_item.should_not be_nil
      if item = save_item.as?(PaceEditor::UI::MenuItem)
        item.visible?(editor_state, ui_state).should be_true
      end
      
      # Cleanup
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end

  describe "power mode behavior" do
    it "shows all items in power mode" do
      editor_state = PaceEditor::Core::EditorState.new
      ui_state = PaceEditor::UI::UIState.new
      ui_state.enable_power_mode
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)

      edit_section = progressive_menu.menu_items["Edit"]
      visible_items = edit_section.visible_items(editor_state, ui_state)

      # In power mode, should show all items regardless of availability
      visible_items.size.should eq(edit_section.items.size)
    end

    it "filters items in normal mode" do
      editor_state = PaceEditor::Core::EditorState.new
      ui_state = PaceEditor::UI::UIState.new
      ui_state.disable_power_mode
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)

      edit_section = progressive_menu.menu_items["Edit"]
      visible_items = edit_section.visible_items(editor_state, ui_state)

      # In normal mode, should filter based on visibility rules
      # Edit section should have fewer visible items when no project exists
      visible_items.select { |item| item.visible?(editor_state, ui_state) }.size.should be < edit_section.items.size
    end
  end

  describe "menu input handling" do
    it "returns false when mouse is outside menu bar" do
      editor_state = PaceEditor::Core::EditorState.new
      ui_state = PaceEditor::UI::UIState.new
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)
      
      mouse_pos = RL::Vector2.new(x: 100.0_f32, y: 100.0_f32) # Below menu bar
      result = progressive_menu.handle_input(mouse_pos, false)

      result.should be_false
    end

    it "handles hover over menu sections" do
      editor_state = PaceEditor::Core::EditorState.new
      ui_state = PaceEditor::UI::UIState.new
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)
      
      mouse_pos = RL::Vector2.new(x: 15.0_f32, y: 15.0_f32) # Over File menu
      progressive_menu.handle_input(mouse_pos, false)

      progressive_menu.hover_item.should eq("File")
    end

    it "toggles menu on click" do
      editor_state = PaceEditor::Core::EditorState.new
      ui_state = PaceEditor::UI::UIState.new
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)
      
      mouse_pos = RL::Vector2.new(x: 15.0_f32, y: 15.0_f32) # Over File menu
      result = progressive_menu.handle_input(mouse_pos, true)

      result.should be_true
      progressive_menu.active_menu.should eq("File")
    end

    it "closes menu when clicking outside" do
      editor_state = PaceEditor::Core::EditorState.new
      ui_state = PaceEditor::UI::UIState.new
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)
      
      # First open a menu
      mouse_pos = RL::Vector2.new(x: 15.0_f32, y: 15.0_f32)
      progressive_menu.handle_input(mouse_pos, true)

      # Then click outside
      outside_pos = RL::Vector2.new(x: 100.0_f32, y: 100.0_f32)
      progressive_menu.handle_input(outside_pos, true)

      progressive_menu.active_menu.should be_nil
    end
  end

  describe "menu actions" do
    it "has actions for menu items" do
      editor_state = PaceEditor::Core::EditorState.new
      ui_state = PaceEditor::UI::UIState.new
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)
      
      file_section = progressive_menu.menu_items["File"]
      new_project_item = file_section.items.find { |item|
        item.is_a?(PaceEditor::UI::MenuItem) && item.as(PaceEditor::UI::MenuItem).id == "new_project"
      }
      
      new_project_item.should_not be_nil
      if item = new_project_item.as?(PaceEditor::UI::MenuItem)
        item.action.should_not be_nil
      end
    end
  end

  describe "layout calculation" do
    it "calculates menu section widths" do
      editor_state = PaceEditor::Core::EditorState.new
      ui_state = PaceEditor::UI::UIState.new
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)
      
      file_section = progressive_menu.menu_items["File"]
      file_section.width.should be > 0.0_f32
    end

    it "updates section layout positions" do
      editor_state = PaceEditor::Core::EditorState.new
      ui_state = PaceEditor::UI::UIState.new
      progressive_menu = PaceEditor::UI::ProgressiveMenu.new(editor_state, ui_state)
      
      file_section = progressive_menu.menu_items["File"]
      file_section.update_layout(10.0_f32, 0.0_f32)

      file_section.x.should eq(10.0_f32)
      file_section.y.should eq(0.0_f32)
    end
  end
end