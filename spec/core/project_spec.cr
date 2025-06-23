require "../spec_helper"
require "file_utils"

describe PaceEditor::Core::Project do
  describe "#initialize" do
    it "creates a new project with correct structure" do
      test_dir = File.tempname("test_project_#{Time.utc.to_unix_ms}")
      project = PaceEditor::Core::Project.create_new("Test Game", test_dir)

      begin
        project.name.should eq("Test Game")
        project.project_path.should eq(test_dir)
        project.title.should eq("Test Game")
        project.window_width.should eq(1024)
        project.window_height.should eq(768)
        project.target_fps.should eq(60)

        # Check directory structure was created
        Dir.exists?(project.assets_path).should be_true
        Dir.exists?(project.scenes_path).should be_true
        Dir.exists?(project.scripts_path).should be_true
        Dir.exists?(project.dialogs_path).should be_true
        Dir.exists?(project.exports_path).should be_true

        # Check asset subdirectories
        Dir.exists?(File.join(project.assets_path, "backgrounds")).should be_true
        Dir.exists?(File.join(project.assets_path, "characters")).should be_true
        Dir.exists?(File.join(project.assets_path, "sounds")).should be_true
        Dir.exists?(File.join(project.assets_path, "music")).should be_true
        Dir.exists?(File.join(project.assets_path, "ui")).should be_true

        # Check that default scene was created
        project.scenes.should contain("main_scene")
        project.current_scene.should eq("main_scene")

        # Check that project file was created
        project_file = File.join(test_dir, "#{project.name}.pace")
        File.exists?(project_file).should be_true
      ensure
        # Clean up
        FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
      end
    end
  end

  describe "#save and #load" do
    it "saves and loads project correctly" do
      test_dir = File.tempname("test_project_#{Time.utc.to_unix_ms}")

      begin
        # Create and configure project
        original_project = PaceEditor::Core::Project.new("Save Test", test_dir)
        original_project.version = "2.0.0"
        original_project.description = "Test description"
        original_project.author = "Test Author"
        original_project.window_width = 1280
        original_project.window_height = 720
        original_project.target_fps = 30

        # Add some assets
        original_project.add_asset("test_bg.png", "backgrounds")
        original_project.add_asset("test_char.png", "characters")
        original_project.add_asset("test_sound.wav", "sounds")

        # Save project
        original_project.save

        # Load project
        project_file = File.join(test_dir, "#{original_project.name}.pace")
        loaded_project = PaceEditor::Core::Project.load(project_file)

        # Verify loaded project
        loaded_project.name.should eq("Save Test")
        loaded_project.version.should eq("2.0.0")
        loaded_project.description.should eq("Test description")
        loaded_project.author.should eq("Test Author")
        loaded_project.window_width.should eq(1280)
        loaded_project.window_height.should eq(720)
        loaded_project.target_fps.should eq(30)

        # Verify assets
        loaded_project.backgrounds.should contain("test_bg.png")
        loaded_project.characters.should contain("test_char.png")
        loaded_project.sounds.should contain("test_sound.wav")
      ensure
        FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
      end
    end
  end

  describe "#add_scene and #remove_scene" do
    it "manages scenes correctly" do
      test_dir = File.tempname("test_project_#{Time.utc.to_unix_ms}")

      begin
        project = PaceEditor::Core::Project.new("Scene Test", test_dir)

        # Add scenes
        project.add_scene("room1")
        project.add_scene("room2")

        project.scenes.should contain("main_scene") # Default scene
        project.scenes.should contain("room1")
        project.scenes.should contain("room2")
        project.scenes.size.should eq(3)

        # Remove scene
        project.remove_scene("room1")
        project.scenes.should_not contain("room1")
        project.scenes.size.should eq(2)

        # Remove current scene should switch to another
        project.current_scene = "room2.yml"
        project.remove_scene("room2.yml")
        project.current_scene.should eq("main_scene")
      ensure
        FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
      end
    end
  end

  describe "#add_asset" do
    it "categorizes assets correctly" do
      test_dir = File.tempname("test_project_#{Time.utc.to_unix_ms}")

      begin
        project = PaceEditor::Core::Project.new("Asset Test", test_dir)

        # Add various asset types
        project.add_asset("bg1.png", "backgrounds")
        project.add_asset("bg2.jpg", "backgrounds")
        project.add_asset("hero.png", "characters")
        project.add_asset("npc.png", "characters")
        project.add_asset("footstep.wav", "sounds")
        project.add_asset("theme.mp3", "music")
        project.add_asset("ai_behavior.lua", "scripts")

        # Verify categorization
        project.backgrounds.should eq(["bg1.png", "bg2.jpg"])
        project.characters.should eq(["hero.png", "npc.png"])
        project.sounds.should eq(["footstep.wav"])
        project.music.should eq(["theme.mp3"])
        project.scripts.should eq(["ai_behavior.lua"])

        # Test duplicate prevention
        project.add_asset("bg1.png", "backgrounds")
        project.backgrounds.size.should eq(2) # Should not add duplicate

      ensure
        FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
      end
    end
  end

  describe "#get_scene_file_path and #get_asset_file_path" do
    it "returns correct file paths" do
      test_dir = File.tempname("test_project_#{Time.utc.to_unix_ms}")

      begin
        project = PaceEditor::Core::Project.new("Path Test", test_dir)

        scene_path = project.get_scene_file_path("test_scene")
        scene_path.should eq(File.join(project.scenes_path, "test_scene.yaml"))

        asset_path = project.get_asset_file_path("test_bg.png", "backgrounds")
        asset_path.should eq(File.join(project.assets_path, "backgrounds", "test_bg.png"))
      ensure
        FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
      end
    end
  end

  describe "#create_new" do
    it "creates a new project with default settings" do
      test_dir = File.tempname("test_project_#{Time.utc.to_unix_ms}")

      begin
        project = PaceEditor::Core::Project.create_new("New Adventure", test_dir)

        project.name.should eq("New Adventure")
        project.title.should eq("New Adventure")
        project.version.should eq("1.0.0")
        project.description.should eq("")
        project.author.should eq("")

        # Should have default scene
        project.scenes.size.should eq(1)
        project.current_scene.should eq("main_scene")
      ensure
        FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
      end
    end
  end

  describe "#export_game" do
    it "creates export directory structure" do
      test_dir = File.tempname("export_test_project_#{Time.utc.to_unix_ms}")

      begin
        project = PaceEditor::Core::Project.new("Export Test", test_dir)

        # Create some test files
        test_asset = File.join(project.assets_path, "backgrounds", "test.txt")
        Dir.mkdir_p(File.dirname(test_asset))
        File.write(test_asset, "test content")

        test_scene = File.join(project.scenes_path, "test_scene.yml")
        File.write(test_scene, "test: scene")

        # Export game
        export_path = File.join(test_dir, "exported_game")
        project.export_game(export_path)

        # Check export structure
        Dir.exists?(export_path).should be_true

        # Check main game file was created
        main_file = File.join(export_path, "main.cr")
        File.exists?(main_file).should be_true

        shard_file = File.join(export_path, "shard.yml")
        File.exists?(shard_file).should be_true

        # Check assets were copied
        Dir.exists?(File.join(export_path, "assets")).should be_true
        Dir.exists?(File.join(export_path, "scenes")).should be_true
        Dir.exists?(File.join(export_path, "scripts")).should be_true
        Dir.exists?(File.join(export_path, "dialogs")).should be_true
      ensure
        FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
      end
    end
  end
end
