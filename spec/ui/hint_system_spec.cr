require "../spec_helper"

describe "Hint System Extensions" do
  describe "UIHint" do
    it "creates hint with all properties" do
      hint = PaceEditor::UI::UIHint.new(
        "test_id",
        "Test hint message",
        PaceEditor::UI::UIHintType::Info,
        priority: 5,
        expires_in: 30.seconds
      )

      hint.id.should eq("test_id")
      hint.text.should eq("Test hint message")
      hint.type.should eq(PaceEditor::UI::UIHintType::Info)
      hint.priority.should eq(5)
      hint.expires_at.should_not be_nil
    end

    it "creates hint without expiration" do
      hint = PaceEditor::UI::UIHint.new(
        "test_id",
        "Test hint message",
        PaceEditor::UI::UIHintType::Warning
      )

      hint.expires_at.should be_nil
      hint.expired?.should be_false
    end

    it "checks expiration correctly" do
      # Create expired hint
      hint = PaceEditor::UI::UIHint.new(
        "test_id",
        "Test hint message",
        PaceEditor::UI::UIHintType::Error,
        expires_in: -1.seconds
      )

      hint.expired?.should be_true
    end

    it "handles different hint types" do
      info_hint = PaceEditor::UI::UIHint.new("1", "Info", PaceEditor::UI::UIHintType::Info)
      warning_hint = PaceEditor::UI::UIHint.new("2", "Warning", PaceEditor::UI::UIHintType::Warning)
      error_hint = PaceEditor::UI::UIHint.new("3", "Error", PaceEditor::UI::UIHintType::Error)
      success_hint = PaceEditor::UI::UIHint.new("4", "Success", PaceEditor::UI::UIHintType::Success)

      info_hint.type.should eq(PaceEditor::UI::UIHintType::Info)
      warning_hint.type.should eq(PaceEditor::UI::UIHintType::Warning)
      error_hint.type.should eq(PaceEditor::UI::UIHintType::Error)
      success_hint.type.should eq(PaceEditor::UI::UIHintType::Success)
    end
  end
end
