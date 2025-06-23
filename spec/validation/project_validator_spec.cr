require "../spec_helper"
require "../../src/pace_editor/validation/project_validator"
require "../../src/pace_editor/core/project"
require "../../src/pace_editor/models/game_config"
require "file_utils"

describe PaceEditor::Validation::ProjectValidator do
  # Create a temporary test directory
  test_dir = ""
  project = uninitialized PaceEditor::Core::Project

  before_each do
    test_dir = File.join(Dir.tempdir, "pace_editor_project_test_#{Random.rand(10000)}")
    Dir.mkdir_p(test_dir)
    project = PaceEditor::Core::Project.new("TestProject", test_dir)
  end

  after_each do
    FileUtils.rm_rf(test_dir) if test_dir && Dir.exists?(test_dir)
  end

  describe "#validate" do
    it "validates a valid project" do
      validator = PaceEditor::Validation::ProjectValidator.new(project)
      result = validator.validate
      
      result.valid?.should be_true
    end

    it "detects missing project directory" do
      project.project_path = "/nonexistent/path"
      
      validator = PaceEditor::Validation::ProjectValidator.new(project)
      result = validator.validate
      
      result.errors.any? { |e| e.message.includes?("Project directory does not exist") }.should be_true
    end

    it "validates project name" do
      project.name = "Invalid Project Name!"
      
      validator = PaceEditor::Validation::ProjectValidator.new(project)
      result = validator.validate
      
      result.errors.any? { |e| e.message.includes?("Project name must contain only letters, numbers, and underscores") }.should be_true
    end

    it "validates window dimensions" do
      project.window_width = 200
      project.window_height = 8000
      
      validator = PaceEditor::Validation::ProjectValidator.new(project)
      result = validator.validate
      
      result.errors.any? { |e| e.message.includes?("Window width must be between") }.should be_true
      result.errors.any? { |e| e.message.includes?("Window height must be between") }.should be_true
    end

    it "validates target FPS" do
      project.target_fps = 25
      
      validator = PaceEditor::Validation::ProjectValidator.new(project)
      result = validator.validate
      
      result.errors.any? { |e| e.message.includes?("Target FPS must be between") }.should be_true
    end

    it "includes asset validation" do
      # Asset validation should be included
      validator = PaceEditor::Validation::ProjectValidator.new(project)
      result = validator.validate
      
      # Should have warnings about missing asset directories
      result.warnings.any? { |w| w.message.includes?("Missing directory") }.should be_true
    end
  end

  describe "#validate_for_export" do
    it "validates game config" do
      config = PaceEditor::Models::GameConfig.create_default(project.name)
      config.window.width = 100  # Invalid
      
      validator = PaceEditor::Validation::ProjectValidator.new(project)
      result = validator.validate_for_export(config)
      
      result.errors.any? { |e| e.message.includes?("Window width must be between") }.should be_true
    end

    it "requires at least one scene" do
      config = PaceEditor::Models::GameConfig.create_default(project.name)
      project.scenes.clear
      
      validator = PaceEditor::Validation::ProjectValidator.new(project)
      result = validator.validate_for_export(config)
      
      result.errors.any? { |e| e.message.includes?("Project must have at least one scene") }.should be_true
    end

    it "validates scene files exist" do
      project.scenes << "missing_scene"
      config = PaceEditor::Models::GameConfig.create_default(project.name)
      
      validator = PaceEditor::Validation::ProjectValidator.new(project)
      result = validator.validate_for_export(config)
      
      result.errors.any? { |e| e.message.includes?("Scene file not found") }.should be_true
    end

    it "validates current scene reference" do
      project.scenes << "scene1"
      project.scenes << "scene2"
      project.current_scene = "scene3"  # Not in scenes list
      
      config = PaceEditor::Models::GameConfig.create_default(project.name)
      
      validator = PaceEditor::Validation::ProjectValidator.new(project)
      result = validator.validate_for_export(config)
      
      result.warnings.any? { |w| w.message.includes?("Current scene 'scene3' is not in the scenes list") }.should be_true
    end

    it "passes validation for properly configured project" do
      # Create scene file
      scene_file = project.get_scene_file_path("main_scene")
      File.write(scene_file, "name: main_scene\n")
      project.scenes << "main_scene"
      
      # Create required assets
      Dir.mkdir_p(File.join(project.assets_path, "sprites"))
      File.write(File.join(project.assets_path, "sprites/player.png"), "")
      
      config = PaceEditor::Models::GameConfig.create_default(project.name)
      config.player.sprite_path = "assets/sprites/player.png"
      
      validator = PaceEditor::Validation::ProjectValidator.new(project)
      result = validator.validate_for_export(config)
      
      result.valid?.should be_true
    end
  end
end