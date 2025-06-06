require "../spec_helper"

describe PaceEditor::Editors::HotspotEditor do
  describe "#initialize" do
    it "initializes with default values" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::HotspotEditor.new(state)

      # Just check that it initializes without error
      editor.should_not be_nil
    end
  end
end
