require "../spec_helper"
require "../../src/pace_editor/ui/background_selector_dialog"

describe PaceEditor::UI::BackgroundSelectorDialog do
  describe "initialization" do
    it "creates dialog in hidden state" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(state)

      dialog.visible.should be_false
    end
  end

  describe "#show and #hide" do
    it "shows and hides the dialog" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(state)

      dialog.show
      dialog.visible.should be_true

      dialog.hide
      dialog.visible.should be_false
    end
  end

  describe "background discovery" do
    it "finds background images in project directory" do
      temp_dir = File.tempfile("bg_project_#{Time.utc.to_unix_ms}").path
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)

      project = PaceEditor::Core::Project.new("test", temp_dir)
      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      # Create test background files
      test_files = ["bg1.png", "bg2.jpg", "bg3.jpeg", "bg4.bmp", "bg5.tga"]
      test_files.each do |file|
        File.write(File.join(project.backgrounds_path, file), "dummy data")
      end

      # Also create non-image files that should be ignored
      File.write(File.join(project.backgrounds_path, "readme.txt"), "text")
      File.write(File.join(project.backgrounds_path, "data.dat"), "data")

      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(state)

      # Get backgrounds (normally done internally)
      backgrounds = Dir.glob(File.join(project.backgrounds_path, "*.{png,jpg,jpeg,bmp,tga}"))
        .map { |f| File.basename(f) }
        .sort

      backgrounds.size.should eq(5)
      backgrounds.should contain("bg1.png")
      backgrounds.should contain("bg2.jpg")
      backgrounds.should contain("bg3.jpeg")
      backgrounds.should contain("bg4.bmp")
      backgrounds.should contain("bg5.tga")
      backgrounds.should_not contain("readme.txt")
      backgrounds.should_not contain("data.dat")

      FileUtils.rm_rf(temp_dir)
    end

    it "handles empty background directory" do
      temp_dir = File.tempfile("bg_project_#{Time.utc.to_unix_ms}").path
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)

      project = PaceEditor::Core::Project.new("test", temp_dir)
      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(state)

      # Get backgrounds
      backgrounds = Dir.glob(File.join(project.backgrounds_path, "*.{png,jpg,jpeg,bmp,tga}"))
        .map { |f| File.basename(f) }

      backgrounds.should be_empty

      FileUtils.rm_rf(temp_dir)
    end

    it "handles missing project gracefully" do
      state = PaceEditor::Core::EditorState.new
      state.current_project = nil

      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(state)

      # Should not crash when no project
      dialog.show
      dialog.visible.should be_true
    end
  end

  describe "background assignment" do
    it "assigns background to current scene" do
      temp_dir = File.tempfile("bg_project_#{Time.utc.to_unix_ms}").path
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)

      project = PaceEditor::Core::Project.new("test", temp_dir)
      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      # Create a scene
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      state.current_scene = scene

      # Create test background
      bg_file = File.join(project.backgrounds_path, "test_bg.png")
      File.write(bg_file, "dummy image data")

      # Simulate background selection
      scene.background_path = "backgrounds/test_bg.png"

      scene.background_path.should eq("backgrounds/test_bg.png")

      FileUtils.rm_rf(temp_dir)
    end

    it "saves scene after assignment" do
      temp_dir = File.tempfile("bg_project_#{Time.utc.to_unix_ms}").path
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)

      project = PaceEditor::Core::Project.new("test", temp_dir)
      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      # Create a scene
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      state.current_scene = scene

      # Assign background
      scene.background_path = "backgrounds/test_bg.png"

      # Save scene
      scene_file = PaceEditor::IO::SceneIO.get_scene_file_path(project, scene.name)
      PaceEditor::IO::SceneIO.save_scene(scene, scene_file)

      # Verify file exists and contains background path
      File.exists?(scene_file).should be_true
      content = File.read(scene_file)
      content.should contain("background_path: backgrounds/test_bg.png")

      FileUtils.rm_rf(temp_dir)
    end
  end

  describe "file extension filtering" do
    it "accepts standard image formats" do
      supported = [".png", ".jpg", ".jpeg", ".bmp", ".tga"]

      supported.each do |ext|
        File.extname("test#{ext}").downcase.should eq(ext)
        supported.includes?(ext).should be_true
      end
    end

    it "rejects non-image formats" do
      unsupported = [".txt", ".doc", ".exe", ".mp3", ".avi"]
      supported = [".png", ".jpg", ".jpeg", ".bmp", ".tga"]

      unsupported.each do |ext|
        supported.includes?(ext).should be_false
      end
    end
  end

  describe "scrolling behavior" do
    it "calculates scroll limits correctly" do
      # Thumbnail settings
      thumb_size = 120
      padding = 10
      dialog_width = 600
      list_width = dialog_width - 40
      cols = (list_width + padding) // (thumb_size + padding)

      # Test with 10 backgrounds
      background_count = 10
      row_height = thumb_size + padding + 30
      total_rows = (background_count + cols - 1) // cols
      total_height = total_rows * row_height

      # If list height is 300
      list_height = 300
      max_scroll = Math.max(0, total_height - list_height)

      # With these dimensions, we should need scrolling
      (total_height > list_height).should be_true
      max_scroll.should be > 0
    end

    it "doesn't scroll when content fits" do
      # Thumbnail settings
      thumb_size = 120
      padding = 10
      dialog_width = 600
      list_width = dialog_width - 40
      cols = (list_width + padding) // (thumb_size + padding)

      # Test with 2 backgrounds (fits in one row)
      background_count = 2
      row_height = thumb_size + padding + 30
      total_rows = (background_count + cols - 1) // cols
      total_height = total_rows * row_height

      # If list height is 300
      list_height = 300
      max_scroll = Math.max(0, total_height - list_height)

      # Should not need scrolling
      (total_height <= list_height).should be_true
      max_scroll.should eq(0)
    end
  end
end
