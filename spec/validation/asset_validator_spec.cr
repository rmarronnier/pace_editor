require "../spec_helper"
require "../../src/pace_editor/validation/asset_validator"
require "file_utils"

describe PaceEditor::Validation::AssetValidator do
  # Create a temporary test directory
  test_dir = ""

  before_each do
    test_dir = File.join(Dir.tempdir, "pace_editor_assets_test_#{Random.rand(10000)}")
    Dir.mkdir_p(test_dir)
  end

  after_each do
    FileUtils.rm_rf(test_dir) if test_dir && Dir.exists?(test_dir)
  end

  describe "#validate" do
    it "validates missing directories" do
      validator = PaceEditor::Validation::AssetValidator.new(test_dir)
      result = validator.validate
      
      result.valid?.should be_true  # Missing directories are warnings, not errors
      result.warnings.any? { |w| w.message.includes?("Missing directory: assets") }.should be_true
      result.warnings.any? { |w| w.message.includes?("Missing directory: assets/backgrounds") }.should be_true
      result.warnings.any? { |w| w.message.includes?("Missing directory: assets/sprites") }.should be_true
    end

    it "validates with proper directory structure" do
      # Create all required directories
      dirs = [
        "assets",
        "assets/backgrounds",
        "assets/sprites",
        "assets/items",
        "assets/portraits",
        "assets/music",
        "assets/sounds"
      ]
      
      dirs.each do |dir|
        Dir.mkdir_p(File.join(test_dir, dir))
      end
      
      validator = PaceEditor::Validation::AssetValidator.new(test_dir)
      result = validator.validate
      
      result.valid?.should be_true
      result.warnings.should be_empty
    end

    it "validates background file formats" do
      Dir.mkdir_p(File.join(test_dir, "assets/backgrounds"))
      
      # Valid files
      File.write(File.join(test_dir, "assets/backgrounds/scene1.png"), "")
      File.write(File.join(test_dir, "assets/backgrounds/scene2.jpg"), "")
      
      # Invalid file
      File.write(File.join(test_dir, "assets/backgrounds/scene3.bmp"), "")
      
      validator = PaceEditor::Validation::AssetValidator.new(test_dir)
      result = validator.validate
      
      result.warnings.any? { |w| w.message.includes?("Background file should be PNG or JPG") }.should be_true
    end

    it "validates sprite file formats" do
      Dir.mkdir_p(File.join(test_dir, "assets/sprites"))
      
      # Valid file
      File.write(File.join(test_dir, "assets/sprites/player.png"), "")
      
      # Invalid file
      File.write(File.join(test_dir, "assets/sprites/enemy.gif"), "")
      
      validator = PaceEditor::Validation::AssetValidator.new(test_dir)
      result = validator.validate
      
      result.warnings.any? { |w| w.message.includes?("Sprite file should be PNG") }.should be_true
    end

    it "validates audio file formats" do
      Dir.mkdir_p(File.join(test_dir, "assets/music"))
      Dir.mkdir_p(File.join(test_dir, "assets/sounds"))
      
      # Valid files
      File.write(File.join(test_dir, "assets/music/theme.ogg"), "")
      File.write(File.join(test_dir, "assets/sounds/click.wav"), "")
      
      # Invalid files
      File.write(File.join(test_dir, "assets/music/intro.aac"), "")
      File.write(File.join(test_dir, "assets/sounds/boom.flac"), "")
      
      validator = PaceEditor::Validation::AssetValidator.new(test_dir)
      result = validator.validate
      
      result.errors.any? { |e| e.message.includes?("Music file must be OGG, WAV, or MP3") }.should be_true
      result.errors.any? { |e| e.message.includes?("Sound file must be OGG, WAV, or MP3") }.should be_true
    end

    it "warns about large files" do
      Dir.mkdir_p(File.join(test_dir, "assets/backgrounds"))
      Dir.mkdir_p(File.join(test_dir, "assets/music"))
      
      # Create a "large" file (we'll fake the size check in the test)
      large_image = File.join(test_dir, "assets/backgrounds/huge.png")
      File.write(large_image, "x" * (11 * 1024 * 1024))  # 11 MB
      
      large_audio = File.join(test_dir, "assets/music/symphony.ogg")
      File.write(large_audio, "x" * (21 * 1024 * 1024))  # 21 MB
      
      validator = PaceEditor::Validation::AssetValidator.new(test_dir)
      result = validator.validate
      
      result.warnings.any? { |w| w.message.includes?("Large image file") }.should be_true
      result.warnings.any? { |w| w.message.includes?("Large audio file") }.should be_true
    end

    it "validates filename conventions" do
      Dir.mkdir_p(File.join(test_dir, "assets/sprites"))
      
      # Invalid filename
      File.write(File.join(test_dir, "assets/sprites/my-sprite!.png"), "")
      File.write(File.join(test_dir, "assets/sprites/sprite with spaces.png"), "")
      
      validator = PaceEditor::Validation::AssetValidator.new(test_dir)
      result = validator.validate
      
      result.warnings.select { |w| w.message.includes?("filename should contain only letters, numbers, and underscores") }.size.should eq 2
    end

    it "validates nested directories" do
      Dir.mkdir_p(File.join(test_dir, "assets/sprites/characters/enemies"))
      
      # File in nested directory
      File.write(File.join(test_dir, "assets/sprites/characters/enemies/orc.png"), "")
      
      validator = PaceEditor::Validation::AssetValidator.new(test_dir)
      result = validator.validate
      
      # Should validate files in nested directories
      result.valid?.should be_true
    end
  end
end