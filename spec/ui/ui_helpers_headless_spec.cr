require "../spec_helper"

# Headless tests for UI helpers that don't require graphics
describe PaceEditor::UI::UIHelpers do
  describe "constants" do
    it "defines UI color constants" do
      # Just verify the constants are defined
      PaceEditor::UI::UIHelpers::PANEL_COLOR.should_not be_nil
      PaceEditor::UI::UIHelpers::PANEL_BORDER_COLOR.should_not be_nil
      PaceEditor::UI::UIHelpers::BUTTON_COLOR.should_not be_nil
      PaceEditor::UI::UIHelpers::BUTTON_HOVER_COLOR.should_not be_nil
      PaceEditor::UI::UIHelpers::BUTTON_PRESSED_COLOR.should_not be_nil
      PaceEditor::UI::UIHelpers::TEXT_COLOR.should_not be_nil
      PaceEditor::UI::UIHelpers::SELECTED_COLOR.should_not be_nil

      # Verify they are Raylib colors
      PaceEditor::UI::UIHelpers::PANEL_COLOR.is_a?(Raylib::Color).should be_true
    end
  end

  describe "method existence" do
    it "has all expected public methods" do
      PaceEditor::UI::UIHelpers.responds_to?(:button).should be_true
      PaceEditor::UI::UIHelpers.responds_to?(:toggle_button).should be_true
      PaceEditor::UI::UIHelpers.responds_to?(:text_input).should be_true
      PaceEditor::UI::UIHelpers.responds_to?(:dropdown).should be_true
      PaceEditor::UI::UIHelpers.responds_to?(:slider).should be_true
      PaceEditor::UI::UIHelpers.responds_to?(:draw_panel).should be_true
      PaceEditor::UI::UIHelpers.responds_to?(:separator).should be_true
      PaceEditor::UI::UIHelpers.responds_to?(:draw_grid).should be_true
      PaceEditor::UI::UIHelpers.responds_to?(:label).should be_true
    end
  end
end
