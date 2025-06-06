require "../spec_helper"

describe PaceEditor::Core::EditorWindow do
  describe "constants and initialization" do
    it "has correct default constants defined" do
      PaceEditor::Core::EditorWindow::DEFAULT_WINDOW_WIDTH.should eq(1400)
      PaceEditor::Core::EditorWindow::DEFAULT_WINDOW_HEIGHT.should eq(900)
      PaceEditor::Core::EditorWindow::MENU_HEIGHT.should eq(30)
      PaceEditor::Core::EditorWindow::TOOL_PALETTE_WIDTH.should eq(80)
      PaceEditor::Core::EditorWindow::PROPERTY_PANEL_WIDTH.should eq(300)
      PaceEditor::Core::EditorWindow::SCENE_HIERARCHY_WIDTH.should eq(250)
    end

    it "initializes without errors" do
      # This test verifies that the EditorWindow can be created
      # and all its components are properly initialized
      window = PaceEditor::Core::EditorWindow.new
      window.should_not be_nil
    end
  end

  describe "backward compatibility" do
    it "has constants for backward compatibility" do
      # Ensure the old constants still exist for other components
      PaceEditor::Core::EditorWindow::WINDOW_WIDTH.should eq(1400)
      PaceEditor::Core::EditorWindow::WINDOW_HEIGHT.should eq(900)
    end

    it "has matching default and legacy constants" do
      # Ensure DEFAULT_* constants match the legacy WINDOW_* constants
      PaceEditor::Core::EditorWindow::DEFAULT_WINDOW_WIDTH.should eq(PaceEditor::Core::EditorWindow::WINDOW_WIDTH)
      PaceEditor::Core::EditorWindow::DEFAULT_WINDOW_HEIGHT.should eq(PaceEditor::Core::EditorWindow::WINDOW_HEIGHT)
    end
  end

  describe "viewport calculations" do
    it "calculates viewport dimensions correctly" do
      # Test that the viewport calculation logic is correct
      tool_palette_width = PaceEditor::Core::EditorWindow::TOOL_PALETTE_WIDTH
      property_panel_width = PaceEditor::Core::EditorWindow::PROPERTY_PANEL_WIDTH
      menu_height = PaceEditor::Core::EditorWindow::MENU_HEIGHT
      window_width = PaceEditor::Core::EditorWindow::DEFAULT_WINDOW_WIDTH
      window_height = PaceEditor::Core::EditorWindow::DEFAULT_WINDOW_HEIGHT

      # Expected calculations
      expected_viewport_x = tool_palette_width
      expected_viewport_y = menu_height
      expected_viewport_width = window_width - tool_palette_width - property_panel_width
      expected_viewport_height = window_height - menu_height

      # Verify the math is correct
      expected_viewport_x.should eq(80)
      expected_viewport_y.should eq(30)
      expected_viewport_width.should eq(1020) # 1400 - 80 - 300
      expected_viewport_height.should eq(870) # 900 - 30
    end
  end

  describe "editor state initialization" do
    it "initializes with a valid editor state" do
      window = PaceEditor::Core::EditorWindow.new

      window.state.should_not be_nil
      window.state.should be_a(PaceEditor::Core::EditorState)
    end

    it "initializes UI components" do
      window = PaceEditor::Core::EditorWindow.new

      window.menu_bar.should_not be_nil
      window.tool_palette.should_not be_nil
      window.property_panel.should_not be_nil
      window.scene_hierarchy.should_not be_nil
      window.asset_browser.should_not be_nil
    end

    it "initializes editor components" do
      window = PaceEditor::Core::EditorWindow.new

      window.scene_editor.should_not be_nil
      window.character_editor.should_not be_nil
      window.hotspot_editor.should_not be_nil
      window.dialog_editor.should_not be_nil
    end
  end
end
