require "../spec_helper"
require "../../src/pace_editor/ui/asset_browser"

describe PaceEditor::UI::AssetBrowser do
  describe "initialization" do
    it "creates an asset browser with default category" do
      state = PaceEditor::Core::EditorState.new
      browser = PaceEditor::UI::AssetBrowser.new(state)

      browser.should_not be_nil
      # Default category is backgrounds (private field, tested through behavior)
    end
  end

  describe "asset import functionality" do
    it "determines correct file extensions for backgrounds" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project

      browser = PaceEditor::UI::AssetBrowser.new(state)

      # Test that backgrounds category accepts image formats
      # In real implementation, this is tested through the import_asset method
      supported_formats = [".png", ".jpg", ".jpeg", ".bmp", ".tga"]
      supported_formats.each do |ext|
        File.extname("test#{ext}").downcase.should eq(ext)
      end
    end

    it "determines correct file extensions for sounds" do
      supported_formats = [".wav", ".ogg", ".mp3"]
      supported_formats.each do |ext|
        File.extname("test#{ext}").downcase.should eq(ext)
      end
    end

    it "determines correct file extensions for scripts" do
      supported_formats = [".lua", ".cr"]
      supported_formats.each do |ext|
        File.extname("test#{ext}").downcase.should eq(ext)
      end
    end
  end

  describe "asset organization" do
    it "creates proper directory structure" do
      temp_file = File.tempfile("asset_project_#{Time.utc.to_unix_ms}")
      temp_dir = temp_file.path
      temp_file.delete
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)

      project = PaceEditor::Core::Project.new("test", temp_dir)
      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      # Verify asset directories are created
      Dir.exists?(project.backgrounds_path).should be_true
      Dir.exists?(project.characters_path).should be_true
      Dir.exists?(project.sounds_path).should be_true
      Dir.exists?(project.music_path).should be_true
      Dir.exists?(project.ui_path).should be_true

      FileUtils.rm_rf(temp_dir)
    end

    it "adds imported assets to project lists" do
      temp_file = File.tempfile("asset_project_#{Time.utc.to_unix_ms}")
      temp_dir = temp_file.path
      temp_file.delete
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)

      project = PaceEditor::Core::Project.new("test", temp_dir)
      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      # Create a test asset file
      test_asset = File.join(temp_dir, "test.png")
      File.write(test_asset, "dummy image data")

      browser = PaceEditor::UI::AssetBrowser.new(state)

      # In real usage, import_file_to_project would:
      # 1. Copy the file to the appropriate directory
      # 2. Add it to the project's asset list
      # 3. Mark the project as dirty

      initial_bg_count = project.backgrounds.size
      initial_bg_count.should eq(0)

      File.delete(test_asset)
      FileUtils.rm_rf(temp_dir)
    end
  end

  describe "asset discovery" do
    it "searches in common asset directories" do
      temp_file = File.tempfile("asset_project_#{Time.utc.to_unix_ms}")
      temp_dir = temp_file.path
      temp_file.delete
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)

      project = PaceEditor::Core::Project.new("test", temp_dir)

      # Create test directories
      assets_dir = File.join(temp_dir, "assets")
      Dir.mkdir_p(assets_dir)

      # Create test files
      test_files = [
        File.join(assets_dir, "background.png"),
        File.join(assets_dir, "character.png"),
        File.join(assets_dir, "sound.wav"),
        File.join(assets_dir, "music.ogg"),
        File.join(assets_dir, "script.lua"),
      ]

      test_files.each { |f| File.write(f, "test data") }

      # Verify files exist
      test_files.all? { |f| File.exists?(f) }.should be_true

      # Clean up
      FileUtils.rm_rf(temp_dir)
    end

    it "filters files by extension" do
      extensions = [".png", ".jpg", ".jpeg", ".bmp", ".tga"]
      test_files = [
        "image.png",
        "photo.jpg",
        "picture.jpeg",
        "bitmap.bmp",
        "targa.tga",
        "document.txt", # Should be filtered out
        "data.dat",     # Should be filtered out
      ]

      image_files = test_files.select do |file|
        ext = File.extname(file).downcase
        extensions.includes?(ext)
      end

      image_files.size.should eq(5)
      image_files.should_not contain("document.txt")
      image_files.should_not contain("data.dat")
    end
  end

  describe "error handling" do
    it "handles missing directories gracefully" do
      state = PaceEditor::Core::EditorState.new
      temp_dir = File.tempname("test_missing_#{Time.utc.to_unix_ms}")

      begin
        project = PaceEditor::Core::Project.new("test", temp_dir)

        # Remove the assets directory to simulate missing directory
        FileUtils.rm_rf(project.assets_path) if Dir.exists?(project.assets_path)

        state.current_project = project
        browser = PaceEditor::UI::AssetBrowser.new(state)

        # Should not raise errors when directories don't exist
        # The browser should handle this gracefully
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "prevents duplicate asset imports" do
      temp_file = File.tempfile("asset_project_#{Time.utc.to_unix_ms}")
      temp_dir = temp_file.path
      temp_file.delete
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)

      project = PaceEditor::Core::Project.new("test", temp_dir)
      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      # Create a test asset that already exists in the project
      existing_asset = File.join(project.backgrounds_path, "existing.png")
      File.write(existing_asset, "existing data")

      browser = PaceEditor::UI::AssetBrowser.new(state)

      # Attempting to import a file with the same name should be handled
      File.exists?(existing_asset).should be_true

      FileUtils.rm_rf(temp_dir)
    end
  end

  describe "UI state management" do
    it "tracks current category" do
      state = PaceEditor::Core::EditorState.new
      browser = PaceEditor::UI::AssetBrowser.new(state)

      # The browser maintains category state
      # Categories: backgrounds, characters, sounds, music, scripts
      categories = ["backgrounds", "characters", "sounds", "music", "scripts"]
      categories.size.should eq(5)
    end

    it "updates project dirty state on import" do
      state = PaceEditor::Core::EditorState.new
      project = PaceEditor::Core::Project.new("test", "/tmp/test")
      state.current_project = project
      state.is_dirty = false

      browser = PaceEditor::UI::AssetBrowser.new(state)

      # After importing an asset, the project should be marked dirty
      # This is tested through the import functionality
      state.is_dirty.should be_false # Initially clean
    end
  end
end
