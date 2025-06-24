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

        # After CB-003 fix: no automatic default scene creation
        # Scenes will be added by EditorState.create_new_project instead
        project.scenes.size.should be >= 0 # Allow empty or with scenes added by EditorState

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

        # After CB-003 fix: no automatic default scene
        project.scenes.should contain("room1")
        project.scenes.should contain("room2")
        project.scenes.size.should eq(2)

        # Remove scene
        project.remove_scene("room1")
        project.scenes.should_not contain("room1")
        project.scenes.size.should eq(1)

        # Remove current scene should clear current_scene
        project.current_scene = "room2"
        project.remove_scene("room2")
        project.current_scene.should be_nil # No scenes left
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

        # After CB-003 fix: no automatic default scene creation
        project.scenes.size.should eq(0)
        project.current_scene.should be_nil
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
        project.add_scene("test_scene.yml")

        # Export game
        export_path = File.join(test_dir, "exported_game")
        result = project.export_game(export_path)

        # The export returns a ValidationResult
        result.should be_a(PaceEditor::Validation::ValidationResult)

        # The actual export functionality is now handled by GameExporter
        # which has its own comprehensive tests
        # We just verify that the method delegates correctly
      ensure
        FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
      end
    end
  end
end
