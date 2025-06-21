require "../spec_helper"
require "file_utils"

describe "Project Creation Integration" do
  describe "projects folder structure" do
    it "creates projects in proper folder hierarchy" do
      # Create a temporary directory for testing
      original_dir = Dir.current
      test_base_dir = File.tempname("pace_editor_test")
      Dir.mkdir_p(test_base_dir)

      begin
        Dir.cd(test_base_dir)

        # Create a state and simulate project creation like the MenuBar does
        state = PaceEditor::Core::EditorState.new

        # Test project creation with projects folder structure
        projects_dir = "./projects"
        sanitized_name = "my_test_game"
        project_path = File.join(projects_dir, sanitized_name)

        # Create projects directory (like MenuBar does)
        Dir.mkdir_p(projects_dir) unless Dir.exists?(projects_dir)

        # Create the project
        result = state.create_new_project("My Test Game", project_path)

        result.should be_true

        # Verify the structure
        Dir.exists?(projects_dir).should be_true
        Dir.exists?(project_path).should be_true

        project = state.current_project.not_nil!

        # Verify all required folders exist
        Dir.exists?(project.assets_path).should be_true
        Dir.exists?(project.scenes_path).should be_true
        Dir.exists?(project.scripts_path).should be_true
        Dir.exists?(project.dialogs_path).should be_true
        Dir.exists?(project.exports_path).should be_true

        # Verify asset subfolders
        ["backgrounds", "characters", "sounds", "music", "ui"].each do |subfolder|
          Dir.exists?(File.join(project.assets_path, subfolder)).should be_true
        end

        # Verify project file exists in the right location
        project_file = File.join(project_path, "#{project.name}.pace")
        File.exists?(project_file).should be_true
      ensure
        Dir.cd(original_dir)
        FileUtils.rm_rf(test_base_dir) if Dir.exists?(test_base_dir)
      end
    end

    it "handles project name sanitization correctly" do
      original_dir = Dir.current
      test_base_dir = File.tempname("pace_editor_test")
      Dir.mkdir_p(test_base_dir)

      begin
        Dir.cd(test_base_dir)

        state = PaceEditor::Core::EditorState.new
        projects_dir = "./projects"

        # Test with special characters and spaces
        project_name = "My Cool Game! (2024)"
        sanitized_name = project_name.downcase.gsub(/[^a-z0-9_\s]/, "").gsub(/\s+/, "_")
        project_path = File.join(projects_dir, sanitized_name)

        Dir.mkdir_p(projects_dir) unless Dir.exists?(projects_dir)

        result = state.create_new_project(project_name, project_path)
        result.should be_true

        # Verify the sanitized folder name
        sanitized_name.should eq("my_cool_game_2024")
        Dir.exists?(File.join(projects_dir, "my_cool_game_2024")).should be_true
      ensure
        Dir.cd(original_dir)
        FileUtils.rm_rf(test_base_dir) if Dir.exists?(test_base_dir)
      end
    end

    it "handles duplicate project names correctly" do
      original_dir = Dir.current
      test_base_dir = File.tempname("pace_editor_test")
      Dir.mkdir_p(test_base_dir)

      begin
        Dir.cd(test_base_dir)

        projects_dir = "./projects"
        Dir.mkdir_p(projects_dir)

        # Create first project
        state1 = PaceEditor::Core::EditorState.new
        project_path1 = File.join(projects_dir, "test_game")
        result1 = state1.create_new_project("Test Game", project_path1)
        result1.should be_true

        # Try to create second project with same path (simulating MenuBar logic)
        project_path2 = File.join(projects_dir, "test_game")

        # This should still work since we handle duplicates in MenuBar
        # For this test, let's verify that if we manually handle the conflict,
        # it works as expected
        if Dir.exists?(project_path2)
          project_path2 = "#{project_path2}_1"
        end

        state2 = PaceEditor::Core::EditorState.new
        result2 = state2.create_new_project("Test Game", project_path2)
        result2.should be_true

        # Verify both projects exist
        Dir.exists?(File.join(projects_dir, "test_game")).should be_true
        Dir.exists?(File.join(projects_dir, "test_game_1")).should be_true
      ensure
        Dir.cd(original_dir)
        FileUtils.rm_rf(test_base_dir) if Dir.exists?(test_base_dir)
      end
    end
  end
end
