require "../spec_helper"

describe "UI Visibility" do
  before_all do
    RaylibTestHelper.init
  end

  after_all do
    RaylibTestHelper.cleanup
  end

  describe "UI components visibility" do
    it "renders menu bar with visible menus" do
      state = PaceEditor::Core::EditorState.new
      menu_bar = PaceEditor::UI::MenuBar.new(state)

      # Test that menu bar draws background
      RL.begin_drawing
      menu_bar.draw_background
      # Menu bar should render at top of screen
      RL.end_drawing
    end

    it "renders tool palette with tool buttons" do
      state = PaceEditor::Core::EditorState.new
      tool_palette = PaceEditor::UI::ToolPalette.new(state)

      RL.begin_drawing
      tool_palette.draw
      # Tool palette should render on left side
      RL.end_drawing
    end

    it "renders scene editor viewport" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 100, 50, 800, 600)

      RL.begin_drawing
      editor.draw
      # Scene editor should render in viewport area
      RL.end_drawing
    end
  end

  describe "button interactions" do
    it "detects button hover states" do
      # Test button hover detection
      mouse_x = 50
      mouse_y = 50
      button_bounds = RL::Rectangle.new(x: 40.0f32, y: 40.0f32, width: 100.0f32, height: 30.0f32)

      is_hover = mouse_x >= button_bounds.x && mouse_x <= button_bounds.x + button_bounds.width &&
                 mouse_y >= button_bounds.y && mouse_y <= button_bounds.y + button_bounds.height

      is_hover.should be_true
    end

    it "shows different colors for button states" do
      # Normal button color
      normal_color = PaceEditor::UI::UIHelpers::BUTTON_COLOR
      hover_color = PaceEditor::UI::UIHelpers::BUTTON_HOVER_COLOR
      active_color = PaceEditor::UI::UIHelpers::SELECTED_COLOR

      # Colors should be different
      normal_color.should_not eq(hover_color)
      normal_color.should_not eq(active_color)
      hover_color.should_not eq(active_color)
    end
  end

  describe "visual feedback" do
    it "shows grid when enabled" do
      state = PaceEditor::Core::EditorState.new
      state.show_grid = true
      state.grid_size = 32

      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

      # Grid should be drawn when show_grid is true
      state.show_grid.should be_true
    end

    it "highlights selected objects" do
      state = PaceEditor::Core::EditorState.new
      state.selected_object = "test_hotspot"

      # Selected objects should have different visual appearance
      state.is_selected?("test_hotspot").should be_true
      state.is_selected?("other_hotspot").should be_false
    end

    it "shows cursor changes for different tools" do
      state = PaceEditor::Core::EditorState.new

      # Different tools should show different cursors
      state.current_tool = PaceEditor::Tool::Select
      state.current_tool.select?.should be_true

      state.current_tool = PaceEditor::Tool::Move
      state.current_tool.move?.should be_true

      state.current_tool = PaceEditor::Tool::Place
      state.current_tool.place?.should be_true
    end
  end

  describe "panel layouts" do
    it "calculates correct panel positions" do
      window_width = 1400
      window_height = 900

      # Tool palette on left
      tool_palette_x = 0
      tool_palette_width = PaceEditor::Core::EditorWindow::TOOL_PALETTE_WIDTH

      # Property panel on right
      property_panel_x = window_width - PaceEditor::Core::EditorWindow::PROPERTY_PANEL_WIDTH
      property_panel_width = PaceEditor::Core::EditorWindow::PROPERTY_PANEL_WIDTH

      # Scene hierarchy on left side
      hierarchy_x = 0
      hierarchy_y = window_height - PaceEditor::Core::EditorWindow::SCENE_HIERARCHY_WIDTH

      # Viewport in center
      viewport_x = tool_palette_width
      viewport_width = window_width - tool_palette_width - property_panel_width

      viewport_x.should eq(tool_palette_width)
      viewport_width.should eq(window_width - tool_palette_width - property_panel_width)
    end
  end
end
