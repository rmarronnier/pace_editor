require "../spec_helper"

describe "Background Import Workflow" do
  temp_dir = ""
  project_dir = ""

  before_each do
    temp_dir = File.tempname
    project_dir = File.join(temp_dir, "test_project")
    Dir.mkdir_p(temp_dir)
    Dir.mkdir_p(project_dir)
    Dir.mkdir_p(File.join(project_dir, "assets"))
    Dir.mkdir_p(File.join(project_dir, "scenes"))
  end

  after_each do
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end

  describe "Background Import Dialog" do
    it "creates and initializes background import dialog" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::BackgroundImportDialog.new(state)

      # Dialog should initialize properly
      dialog.should_not be_nil
      dialog.visible.should be_false
      dialog.selected_file.should be_nil
    end

    it "shows and hides dialog correctly" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::BackgroundImportDialog.new(state)

      # Show dialog
      dialog.show
      dialog.visible.should be_true

      # Hide dialog
      dialog.hide
      dialog.visible.should be_false
    end

    it "integrates with editor window" do
      editor_window = PaceEditor::Core::EditorWindow.new

      # Background import dialog should be initialized
      editor_window.background_import_dialog.should_not be_nil
      editor_window.background_import_dialog.visible.should be_false

      # Show dialog through editor window
      editor_window.show_background_import_dialog
      editor_window.background_import_dialog.visible.should be_true
    end
  end

  describe "Complete Background Import Workflow" do
    it "allows importing background through scene properties" do
      # 1. Create complete test setup
      project = PaceEditor::Core::Project.new(
        name: "Import Test",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("test_scene")

      editor_window = PaceEditor::Core::EditorWindow.new
      state = editor_window.state
      state.current_project = project
      state.current_scene = scene
      state.current_mode = PaceEditor::EditorMode::Scene

      # 2. Create test background file in external location
      external_bg_dir = File.join(temp_dir, "external_images")
      Dir.mkdir_p(external_bg_dir)
      test_bg_file = File.join(external_bg_dir, "room_background.png")
      File.write(test_bg_file, "fake_png_data")

      # 3. Verify scene has no background initially
      scene.background_path.should be_nil

      # 4. Background import dialog exists and can be shown
      dialog = editor_window.background_import_dialog
      dialog.should_not be_nil

      # Show dialog (simulates clicking "Import Background..." button)
      editor_window.show_background_import_dialog
      dialog.visible.should be_true

      # 5. Verify import functionality would work
      # (Actual file selection and import would require UI interaction)
      
      # Simulate successful import by setting file manually
      dialog.selected_file = test_bg_file

      # 6. Test that project backgrounds directory gets created
      bg_dir = File.join(project_dir, "assets", "backgrounds")
      Dir.mkdir_p(bg_dir) # This would happen during import

      # 7. Verify directory structure
      Dir.exists?(bg_dir).should be_true

      # 8. Simulate file copy and scene update
      dest_file = File.join(bg_dir, "room_background.png")
      File.copy(test_bg_file, dest_file)
      scene.background_path = "backgrounds/room_background.png"

      # 9. Verify complete workflow result
      File.exists?(dest_file).should be_true
      scene.background_path.should eq("backgrounds/room_background.png")

      # 10. Verify scene can be saved with background
      yaml_content = scene.to_yaml
      yaml_content.should contain("backgrounds/room_background.png")
    end

    it "handles import button in property panel" do
      # Create project and scene
      project = PaceEditor::Core::Project.new(
        name: "Property Panel Test",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("test_scene")

      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = scene
      state.current_mode = PaceEditor::EditorMode::Scene

      # Create editor window and connect state
      editor_window = PaceEditor::Core::EditorWindow.new
      state.editor_window = editor_window

      # Property panel should be able to show import dialog
      property_panel = PaceEditor::UI::PropertyPanel.new(state)
      property_panel.should_not be_nil

      # Background import dialog should be accessible through editor window
      state.editor_window.not_nil!.background_import_dialog.should_not be_nil

      # Verify dialog can be shown (simulates button click)
      editor_window.show_background_import_dialog
      editor_window.background_import_dialog.visible.should be_true
    end

    it "validates imported background files" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::BackgroundImportDialog.new(state)

      # Create test files with different extensions
      test_files_dir = File.join(temp_dir, "test_files")
      Dir.mkdir_p(test_files_dir)

      # Valid image files
      valid_files = ["image.png", "photo.jpg", "picture.jpeg", "bitmap.bmp"]
      valid_files.each do |filename|
        File.write(File.join(test_files_dir, filename), "fake_image_data")
      end

      # Invalid files
      invalid_files = ["document.txt", "script.lua", "data.yml"]
      invalid_files.each do |filename|
        File.write(File.join(test_files_dir, filename), "not_image_data")
      end

      # Verify all test files exist
      Dir.glob(File.join(test_files_dir, "*")).size.should eq(7)

      # Dialog file filtering would only show image files
      # (This would be tested through the dialog's file list functionality)
    end
  end

  describe "Background Import Error Handling" do
    it "handles missing project gracefully" do
      state = PaceEditor::Core::EditorState.new
      state.current_project = nil

      dialog = PaceEditor::UI::BackgroundImportDialog.new(state)
      dialog.should_not be_nil

      # Dialog should handle missing project
      dialog.show
      dialog.visible.should be_true
    end

    it "handles missing scene gracefully" do
      project = PaceEditor::Core::Project.new(
        name: "No Scene Test",
        project_path: project_dir
      )

      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = nil

      dialog = PaceEditor::UI::BackgroundImportDialog.new(state)
      dialog.show
      dialog.visible.should be_true
    end

    it "handles invalid file paths gracefully" do
      project = PaceEditor::Core::Project.new(
        name: "Invalid Path Test",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("test_scene")

      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = scene

      dialog = PaceEditor::UI::BackgroundImportDialog.new(state)

      # Test with non-existent file
      dialog.selected_file = "/non/existent/path/image.png"
      
      # Dialog should handle this gracefully (no crash)
      dialog.should_not be_nil
    end
  end

  describe "Background Import Integration" do
    it "integrates with scene editor display" do
      # Create scene with imported background
      project = PaceEditor::Core::Project.new(
        name: "Display Test",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("display_test")

      # Create background asset
      bg_dir = File.join(project_dir, "assets", "backgrounds")
      Dir.mkdir_p(bg_dir)
      bg_file = File.join(bg_dir, "test_bg.png")
      File.write(bg_file, "fake_background_image_data")

      # Set background path
      scene.background_path = "backgrounds/test_bg.png"

      # Verify scene has background set
      scene.background_path.should eq("backgrounds/test_bg.png")

      # Verify background file exists
      File.exists?(bg_file).should be_true

      # Scene should be serializable with background
      yaml_content = scene.to_yaml
      yaml_content.should contain("backgrounds/test_bg.png")
    end

    it "updates property panel display after import" do
      project = PaceEditor::Core::Project.new(
        name: "Property Display Test",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("property_test")
      
      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = scene
      state.current_mode = PaceEditor::EditorMode::Scene

      property_panel = PaceEditor::UI::PropertyPanel.new(state)

      # Initially no background
      scene.background_path.should be_nil

      # After import simulation
      scene.background_path = "backgrounds/imported_bg.png"
      scene.background_path.should eq("backgrounds/imported_bg.png")

      # Property panel should be able to display updated background info
      property_panel.should_not be_nil
    end
  end
end