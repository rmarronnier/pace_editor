require "./spec_helper"

describe PaceEditor do
  it "has a version number" do
    PaceEditor::VERSION.should eq("0.1.0")
  end

  describe "Components" do
    it "loads UI helpers" do
      PaceEditor::UI::UIHelpers.should_not be_nil
    end

    it "loads scene editor" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)
      editor.should_not be_nil
    end

    it "integrates components in EditorWindow" do
      window = PaceEditor::Core::EditorWindow.new

      # EditorWindow should use scene editor
      window.scene_editor.should_not be_nil
      window.scene_editor.class.should eq(PaceEditor::Editors::SceneEditor)
    end
  end

  describe "Module Structure" do
    it "has proper namespace organization" do
      # Core modules
      PaceEditor::Core.should_not be_nil

      # UI modules
      PaceEditor::UI.should_not be_nil

      # Editor modules
      PaceEditor::Editors.should_not be_nil
    end
  end
end
