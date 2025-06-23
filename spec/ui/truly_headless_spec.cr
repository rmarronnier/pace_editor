require "../headless_spec_helper"

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
      project.path.should eq(temp_dir)

      # Clean up
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end

  describe PaceEditor::Models::AnimationData do
    it "can be created and serialized" do
      data = PaceEditor::Models::AnimationData.new
      data.sprite_width = 32
      data.sprite_height = 48

      yaml = data.to_yaml
      yaml.should contain("sprite_width: 32")
      yaml.should contain("sprite_height: 48")
    end
  end

  describe PaceEditor::Models::Animation do
    it "stores animation properties" do
      anim = PaceEditor::Models::Animation.new("walk")
      anim.name.should eq("walk")
      anim.loop.should be_true
      anim.fps.should eq(8.0_f32)
    end
  end

  describe PaceEditor::Models::SyntaxToken do
    it "creates syntax tokens" do
      token = PaceEditor::Models::SyntaxToken.new(
        type: PaceEditor::Models::TokenType::Keyword,
        text: "function",
        start_pos: 0,
        end_pos: 8
      )

      token.type.should eq(PaceEditor::Models::TokenType::Keyword)
      token.text.should eq("function")
    end
  end
end
