require "../spec_helper"
require "../../src/pace_editor/export/game_exporter"
require "../../src/pace_editor/core/project"
require "file_utils"

# Helper method to setup a valid project
def setup_valid_project(project : PaceEditor::Core::Project)
  # Add a scene
  project.scenes << "main_scene"
  project.current_scene = "main_scene"

  # Create scene file
  scene_content = <<-YAML
  name: main_scene
  background_path: assets/backgrounds/main.png
  hotspots: []
  YAML

  File.write(project.get_scene_file_path("main_scene"), scene_content)

  # Create required asset directories
  Dir.mkdir_p(File.join(project.assets_path, "sprites"))
  Dir.mkdir_p(File.join(project.assets_path, "backgrounds"))

  # Create player sprite
  File.write(File.join(project.assets_path, "sprites/player.png"), "")
end

describe PaceEditor::Export::GameExporter do
  # Create a temporary test directory
  test_dir = ""
  project = uninitialized PaceEditor::Core::Project
  export_path = ""

  before_each do
    test_dir = File.join(Dir.tempdir, "pace_editor_export_test_#{Random.rand(10000)}")
    Dir.mkdir_p(test_dir)
    project = PaceEditor::Core::Project.new("TestGame", test_dir)
    export_path = File.join(test_dir, "export")
  end

  after_each do
    FileUtils.rm_rf(test_dir) if test_dir && Dir.exists?(test_dir)
  end

  describe "#export" do
    it "fails validation when project is invalid" do
      # Project with no scenes
      project.scenes.clear

      exporter = PaceEditor::Export::GameExporter.new(project)
      result = exporter.export(export_path)

      result.valid?.should be_false
      result.errors.any? { |e| e.message.includes?("Project must have at least one scene") }.should be_true

      # Export directory should not be created
      Dir.exists?(export_path).should be_false
    end

    it "exports valid project successfully" do
      # Setup a valid project
      setup_valid_project(project)

      exporter = PaceEditor::Export::GameExporter.new(project)
      result = exporter.export(export_path)

      result.valid?.should be_true
      result.errors.should be_empty

      # Check directory structure
      Dir.exists?(export_path).should be_true
      Dir.exists?(File.join(export_path, "scenes")).should be_true
      Dir.exists?(File.join(export_path, "assets")).should be_true
      Dir.exists?(File.join(export_path, "assets/backgrounds")).should be_true
      Dir.exists?(File.join(export_path, "assets/sprites")).should be_true

      # Check files
      File.exists?(File.join(export_path, "game_config.yaml")).should be_true
      File.exists?(File.join(export_path, "main.cr")).should be_true
      File.exists?(File.join(export_path, "shard.yml")).should be_true
    end

    it "generates valid game_config.yaml" do
      setup_valid_project(project)
      project.window_width = 1280
      project.window_height = 720
      project.target_fps = 120
      project.author = "Test Author"
      project.version = "2.0.0"

      exporter = PaceEditor::Export::GameExporter.new(project)
      result = exporter.export(export_path)

      result.valid?.should be_true

      # Read and parse generated config
      config_path = File.join(export_path, "game_config.yaml")
      config_content = File.read(config_path)

      config_content.should contain "title: My Adventure Game"
      config_content.should contain "version: 2.0.0"
      config_content.should contain "author: Test Author"
      config_content.should contain "width: 1280"
      config_content.should contain "height: 720"
      config_content.should contain "target_fps: 120"
      config_content.should contain "start_scene: main_scene"
    end

    it "copies assets to correct locations" do
      setup_valid_project(project)

      # Add some assets
      project.backgrounds << "forest.png"
      project.characters << "hero.png"
      project.sounds << "click.wav"
      project.music << "theme.ogg"

      # Create the asset files
      File.write(File.join(project.assets_path, "backgrounds/forest.png"), "bg")
      File.write(File.join(project.assets_path, "characters/hero.png"), "char")
      File.write(File.join(project.assets_path, "sounds/click.wav"), "snd")
      File.write(File.join(project.assets_path, "music/theme.ogg"), "mus")

      exporter = PaceEditor::Export::GameExporter.new(project)
      result = exporter.export(export_path)

      result.valid?.should be_true

      # Check assets were copied
      File.exists?(File.join(export_path, "assets/backgrounds/forest.png")).should be_true
      File.exists?(File.join(export_path, "assets/sprites/hero.png")).should be_true
      File.exists?(File.join(export_path, "assets/sounds/effects/click.wav")).should be_true
      File.exists?(File.join(export_path, "assets/music/theme.ogg")).should be_true
    end

    it "exports scenes" do
      setup_valid_project(project)

      # Add another scene
      project.scenes << "level1"
      scene_content = "name: level1\nbackground_path: assets/backgrounds/level1.png\n"
      File.write(project.get_scene_file_path("level1"), scene_content)

      exporter = PaceEditor::Export::GameExporter.new(project)
      result = exporter.export(export_path)

      result.valid?.should be_true

      # Check scenes were copied
      File.exists?(File.join(export_path, "scenes/main_scene.yaml")).should be_true
      File.exists?(File.join(export_path, "scenes/level1.yaml")).should be_true
    end

    it "creates placeholder files" do
      setup_valid_project(project)

      exporter = PaceEditor::Export::GameExporter.new(project)
      result = exporter.export(export_path)

      result.valid?.should be_true

      # Check placeholder files
      items_file = File.join(export_path, "items/items.yaml")
      File.exists?(items_file).should be_true
      File.read(items_file).should eq "items: {}\n"

      quests_file = File.join(export_path, "quests/main_quests.yaml")
      File.exists?(quests_file).should be_true
      File.read(quests_file).should eq "quests: []\n"
    end

    it "generates valid main.cr" do
      setup_valid_project(project)

      exporter = PaceEditor::Export::GameExporter.new(project)
      result = exporter.export(export_path)

      result.valid?.should be_true

      main_content = File.read(File.join(export_path, "main.cr"))
      main_content.should contain "require \"point_click_engine\""
      main_content.should contain "PointClickEngine::Game.from_config"
      main_content.should contain "engine.run"
    end

    it "generates valid shard.yml" do
      setup_valid_project(project)
      project.description = "An awesome adventure"
      project.author = "Game Developer"

      exporter = PaceEditor::Export::GameExporter.new(project)
      result = exporter.export(export_path)

      result.valid?.should be_true

      shard_content = File.read(File.join(export_path, "shard.yml"))
      shard_content.should contain "name: testgame"
      shard_content.should contain "version: 1.0.0"
      shard_content.should contain "description: An awesome adventure"
      shard_content.should contain "authors:\n  - Game Developer"
      shard_content.should contain "point_click_engine:"
    end

    it "handles export errors gracefully" do
      setup_valid_project(project)

      # Make export path unwritable
      Dir.mkdir_p(export_path)
      File.chmod(export_path, 0o444)

      exporter = PaceEditor::Export::GameExporter.new(project)
      result = exporter.export(File.join(export_path, "subdir"))

      result.valid?.should be_false
      result.errors.any? { |e| e.message.includes?("Export failed:") }.should be_true
    ensure
      File.chmod(export_path, 0o755) if Dir.exists?(export_path)
    end

    it "exports to ZIP when path ends with .zip" do
      setup_valid_project(project)
      zip_path = File.join(test_dir, "game.zip")

      exporter = PaceEditor::Export::GameExporter.new(project)
      result = exporter.export(zip_path)

      result.valid?.should be_true

      # ZIP file should be created
      File.exists?(zip_path).should be_true

      # Temporary export directory should be cleaned up
      Dir.glob(File.join(project.exports_path, "game_export")).should be_empty
    end
  end
end
