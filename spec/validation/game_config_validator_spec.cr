require "../spec_helper"
require "../../src/pace_editor/validation/game_config_validator"
require "../../src/pace_editor/models/game_config"
require "file_utils"

describe PaceEditor::Validation::GameConfigValidator do
  # Create a temporary test directory
  test_dir = ""

  before_each do
    test_dir = File.join(Dir.tempdir, "pace_editor_test_#{Random.rand(10000)}")
    Dir.mkdir_p(test_dir)
    Dir.mkdir_p(File.join(test_dir, "assets", "sprites"))
    Dir.mkdir_p(File.join(test_dir, "assets", "music"))
    Dir.mkdir_p(File.join(test_dir, "assets", "sounds"))
    Dir.mkdir_p(File.join(test_dir, "scenes"))
  end

  after_each do
    FileUtils.rm_rf(test_dir) if test_dir && Dir.exists?(test_dir)
  end

  describe "#validate" do
    it "validates a valid game config" do
      # Create required files
      File.write(File.join(test_dir, "assets/sprites/player.png"), "")
      File.write(File.join(test_dir, "scenes/intro.yaml"), "")
      
      config = PaceEditor::Models::GameConfig.create_default("TestGame")
      config.start_scene = "intro"
      
      validator = PaceEditor::Validation::GameConfigValidator.new(config, test_dir)
      result = validator.validate
      
      result.valid?.should be_true
      result.warnings.should be_empty
    end

    it "detects missing player sprite" do
      config = PaceEditor::Models::GameConfig.create_default("TestGame")
      
      validator = PaceEditor::Validation::GameConfigValidator.new(config, test_dir)
      result = validator.validate
      
      result.valid?.should be_false
      result.errors.any? { |e| e.message.includes?("Player sprite not found") }.should be_true
    end

    it "validates sprite file extension" do
      File.write(File.join(test_dir, "assets/sprites/player.bmp"), "")
      
      config = PaceEditor::Models::GameConfig.create_default("TestGame")
      config.player.sprite_path = "assets/sprites/player.bmp"
      
      validator = PaceEditor::Validation::GameConfigValidator.new(config, test_dir)
      result = validator.validate
      
      result.errors.any? { |e| e.message.includes?("Player sprite must be PNG or JPG") }.should be_true
    end

    it "validates music file paths" do
      # Create player sprite to make config valid
      File.write(File.join(test_dir, "assets/sprites/player.png"), "")
      
      config = PaceEditor::Models::GameConfig.create_default("TestGame")
      config.assets.audio.music["theme"] = "assets/music/theme.ogg"
      config.assets.audio.music["battle"] = "assets/music/battle.mp3"
      
      # Create one file but not the other
      File.write(File.join(test_dir, "assets/music/theme.ogg"), "")
      
      validator = PaceEditor::Validation::GameConfigValidator.new(config, test_dir)
      result = validator.validate
      
      # Should have warning for missing file
      result.warnings.any? { |w| w.message.includes?("Music file not found: battle") }.should be_true
      # But still be valid (warnings don't fail validation)
      result.valid?.should be_true
    end

    it "validates audio file extensions" do
      File.write(File.join(test_dir, "assets/sounds/click.txt"), "")
      
      config = PaceEditor::Models::GameConfig.create_default("TestGame")
      config.assets.audio.sounds["click"] = "assets/sounds/click.txt"
      
      validator = PaceEditor::Validation::GameConfigValidator.new(config, test_dir)
      result = validator.validate
      
      result.errors.any? { |e| e.message.includes?("Sound file must be OGG, WAV, or MP3") }.should be_true
    end

    it "validates start scene exists" do
      config = PaceEditor::Models::GameConfig.create_default("TestGame")
      config.start_scene = "missing_scene"
      
      validator = PaceEditor::Validation::GameConfigValidator.new(config, test_dir)
      result = validator.validate
      
      result.errors.any? { |e| e.message.includes?("Start scene 'missing_scene' not found") }.should be_true
    end

    it "validates start scene with glob patterns" do
      # Create scene file
      File.write(File.join(test_dir, "scenes/level1.yaml"), "")
      
      config = PaceEditor::Models::GameConfig.create_default("TestGame")
      config.start_scene = "level1"
      config.assets.scenes = ["scenes/*.yaml"]
      
      validator = PaceEditor::Validation::GameConfigValidator.new(config, test_dir)
      result = validator.validate
      
      # Should find the scene through glob pattern
      result.errors.none? { |e| e.message.includes?("Start scene") }.should be_true
    end

    it "warns about missing start scene" do
      config = PaceEditor::Models::GameConfig.create_default("TestGame")
      config.start_scene = nil
      
      validator = PaceEditor::Validation::GameConfigValidator.new(config, test_dir)
      result = validator.validate
      
      result.warnings.any? { |w| w.message.includes?("No start scene specified") }.should be_true
    end

    it "validates start music reference" do
      config = PaceEditor::Models::GameConfig.create_default("TestGame")
      config.start_music = "nonexistent_music"
      
      validator = PaceEditor::Validation::GameConfigValidator.new(config, test_dir)
      result = validator.validate
      
      result.warnings.any? { |w| w.message.includes?("Start music 'nonexistent_music' not defined") }.should be_true
    end

    it "validates all model validation rules" do
      config = PaceEditor::Models::GameConfig.create_default("TestGame")
      config.window.width = 100  # Invalid width
      
      validator = PaceEditor::Validation::GameConfigValidator.new(config, test_dir)
      result = validator.validate
      
      result.errors.any? { |e| e.message.includes?("Window width must be between") }.should be_true
    end
  end
end