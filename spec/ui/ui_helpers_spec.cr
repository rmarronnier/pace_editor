require "../spec_helper"

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

  # Note: Drawing tests are skipped because they require Raylib initialization
  # In a real test environment, you would initialize Raylib before running these tests

  describe ".button" do
    it "exists as a method" do
      PaceEditor::UI::UIHelpers.responds_to?(:button).should be_true
    end
  end

  describe ".toggle_button" do
    it "exists as a method" do
      PaceEditor::UI::UIHelpers.responds_to?(:toggle_button).should be_true
    end
  end

  describe ".text_input" do
    it "exists as a method" do
      PaceEditor::UI::UIHelpers.responds_to?(:text_input).should be_true
    end
  end

  describe ".dropdown" do
    it "exists as a method" do
      PaceEditor::UI::UIHelpers.responds_to?(:dropdown).should be_true
    end
  end

  describe ".slider" do
    it "exists as a method" do
      PaceEditor::UI::UIHelpers.responds_to?(:slider).should be_true
    end
  end

  # Note: color_picker is not implemented in the current version

  # Note: checkbox is not implemented in the current version

  describe ".draw_panel" do
    it "exists as a method" do
      PaceEditor::UI::UIHelpers.responds_to?(:draw_panel).should be_true
    end
  end

  describe ".separator" do
    it "exists as a method" do
      PaceEditor::UI::UIHelpers.responds_to?(:separator).should be_true
    end
  end

  describe ".draw_grid" do
    it "exists as a method" do
      PaceEditor::UI::UIHelpers.responds_to?(:draw_grid).should be_true
    end
  end

  describe ".label" do
    it "exists as a method" do
      PaceEditor::UI::UIHelpers.responds_to?(:label).should be_true
    end
  end

  # Note: tooltip is a private method (draw_tooltip)

  # Note: icon_button is not implemented, only draw_icon exists as a private method

  # Note: draw_resize_handles is not implemented in UIHelpers
end
