require "../spec_helper"

describe PaceEditor::Editors::DialogEditor do
  describe "#initialize" do
    it "initializes with correct default values" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::DialogEditor.new(state)

      editor.current_dialog.should be_nil
      editor.selected_node.should be_nil
      editor.camera_offset.x.should eq(0)
      editor.camera_offset.y.should eq(0)
    end
  end
end