require "../spec_helper"

# Test basic model functionality without any UI
describe "Headless Model Tests" do
  describe PaceEditor::Core::EditorState do
    it "creates editor state" do
      state = PaceEditor::Core::EditorState.new
      state.should_not be_nil
    end
  end

  describe PaceEditor::Core::Project do
    it "creates a project" do
      temp_dir = File.tempname("test_project_#{Time.utc.to_unix_ms}")
      project = PaceEditor::Core::Project.new("test", temp_dir)

      project.name.should eq("test")
      project.project_path.should eq(temp_dir)

      # Clean up
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end

  # Note: AnimationData is part of AnimationEditor, not Models
  # SyntaxToken and other models may not be properly exposed yet
end
