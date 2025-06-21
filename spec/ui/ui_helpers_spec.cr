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

  describe "with Raylib initialized" do
    before_all do
      RaylibTestHelper.init
    end

    after_all do
      RaylibTestHelper.cleanup
    end

    describe ".draw_panel" do
      it "returns y position without title" do
        # Begin drawing to prevent Raylib errors
        RL.begin_drawing
        y = PaceEditor::UI::UIHelpers.draw_panel(10, 20, 100, 200)
        RL.end_drawing

        y.should eq(20)
      end

      it "returns y position offset with title" do
        RL.begin_drawing
        y = PaceEditor::UI::UIHelpers.draw_panel(10, 20, 100, 200, "Test Panel")
        RL.end_drawing

        y.should eq(45) # 20 + 25 (title height)
      end
    end

    describe ".button" do
      it "returns false when not clicked" do
        # Simulate no mouse click
        clicked = PaceEditor::UI::UIHelpers.button(10, 10, 100, 30, "Test", "hint")
        clicked.should be_false
      end
    end

    describe ".toggle_button" do
      it "maintains toggle state" do
        active = false
        # Without clicking, state should remain unchanged
        result = PaceEditor::UI::UIHelpers.toggle_button(10, 10, 100, 30, "Toggle", active, "hint")
        result.should be_false
      end
    end

    describe ".text_input" do
      it "returns unchanged text without input" do
        text = "initial"
        result_text, active = PaceEditor::UI::UIHelpers.text_input(10, 10, 200, 30, text, false, "placeholder")
        result_text.should eq("initial")
        active.should be_false
      end
    end

    describe ".dropdown" do
      it "returns selected option without interaction" do
        options = ["Option 1", "Option 2", "Option 3"]
        selected = "Option 2"
        result, open = PaceEditor::UI::UIHelpers.dropdown(10, 10, 150, 30, selected, options, false)
        result.should eq("Option 2")
        open.should be_false
      end
    end

    describe ".slider" do
      it "returns value within range" do
        value = 50.0f32
        result = PaceEditor::UI::UIHelpers.slider(10, 10, 200, 20, value, 0.0f32, 100.0f32, "Value")
        result.should be >= 0.0f32
        result.should be <= 100.0f32
      end
    end

    describe ".draw_grid" do
      it "draws without errors" do
        RL.begin_drawing
        # Should not raise an error
        PaceEditor::UI::UIHelpers.draw_grid(
          RL::Vector2.new(x: 0, y: 0),
          1.0f32,
          32,
          800,
          600
        )
        RL.end_drawing
      end
    end

    describe ".label" do
      it "draws without errors" do
        RL.begin_drawing
        PaceEditor::UI::UIHelpers.label(10, 10, "Test Label", 16, RL::WHITE)
        RL.end_drawing
        # No return value to test, just ensure it doesn't crash
      end
    end

    describe ".separator" do
      it "draws without errors" do
        RL.begin_drawing
        PaceEditor::UI::UIHelpers.separator(10, 50, 200)
        RL.end_drawing
        # No return value to test, just ensure it doesn't crash
      end
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
