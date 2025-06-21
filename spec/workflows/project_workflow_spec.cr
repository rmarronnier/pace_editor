require "../spec_helper"
require "file_utils"

describe "Project Workflow" do
  # Create a temporary directory for test projects
  temp_dir = "/tmp/pace_editor_test_#{Time.utc.to_unix}"

  before_all do
    Dir.mkdir_p(temp_dir)
  end

  after_all do
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end

  before_each do
    # Clean up any leftover files before each test
    if Dir.exists?(temp_dir)
      Dir.glob("#{temp_dir}/**/*").each do |file|
        File.delete(file) if File.file?(file)
      end
    end
  end

  describe "complete project lifecycle" do
    it "creates a new project with proper structure" do
      project_name = "test_game"
      project_path = "#{temp_dir}/#{project_name}"

      # Create project
      project = PaceEditor::Core::Project.new
      project.name = project_name
      project.project_path = project_path

      # Project should initialize with default structure
      project.name.should eq(project_name)
      project.project_path.should eq(project_path)

      # Save project to create directory structure
      Dir.mkdir_p(project_path)
      project.save_project

      # Verify project file was created
      File.exists?("#{project_path}/project.pace").should be_true

      # Verify directory structure
      Dir.exists?("#{project_path}/assets").should be_true
      Dir.exists?("#{project_path}/assets/backgrounds").should be_true
      Dir.exists?("#{project_path}/assets/characters").should be_true
      Dir.exists?("#{project_path}/assets/sounds").should be_true
      Dir.exists?("#{project_path}/assets/music").should be_true
      Dir.exists?("#{project_path}/scenes").should be_true
      Dir.exists?("#{project_path}/scripts").should be_true
      Dir.exists?("#{project_path}/dialogs").should be_true
    end

    it "loads an existing project" do
      project_path = "#{temp_dir}/existing_game"

      # Create a project first
      project = PaceEditor::Core::Project.new
      project.name = "existing_game"
      project.project_path = project_path
      Dir.mkdir_p(project_path)
      project.save_project

      # Load the project
      loaded_project = PaceEditor::Core::Project.load_project("#{project_path}/project.pace")

      loaded_project.should_not be_nil
      loaded_project.name.should eq("existing_game")
      loaded_project.project_path.should eq(project_path)
    end

    it "manages project assets" do
      project = PaceEditor::Core::Project.new
      project.name = "asset_test"
      project.project_path = "#{temp_dir}/asset_test"

      # Add assets
      project.scenes << "intro_scene"
      project.scenes << "main_menu"
      project.characters << "player"
      project.characters << "npc_merchant"
      project.backgrounds << "village_bg"
      project.backgrounds << "forest_bg"

      # Verify assets are tracked
      project.scenes.size.should eq(2)
      project.characters.size.should eq(2)
      project.backgrounds.size.should eq(2)

      # Save and reload
      Dir.mkdir_p(project.project_path)
      project.save_project

      reloaded = PaceEditor::Core::Project.load_project("#{project.project_path}/project.pace")
      reloaded.scenes.should eq(["intro_scene", "main_menu"])
      reloaded.characters.should eq(["player", "npc_merchant"])
      reloaded.backgrounds.should eq(["village_bg", "forest_bg"])
    end
  end
end
