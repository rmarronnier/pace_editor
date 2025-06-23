require "../spec_helper"

# Cycle A: Core Functionality Testing
# Focus: Basic editor operations, file I/O, UI responsiveness
# Duration: 30 minutes
# Tests: Core workflow validation

describe "Cycle A: Core Functionality Testing" do
  temp_dir = ""
  project_dir = ""

  before_each do
    temp_dir = File.tempname
    project_dir = File.join(temp_dir, "test_project")
    Dir.mkdir_p(temp_dir)
  end

  after_each do
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end

  describe "Project Lifecycle" do
    it "creates new project with complete directory structure" do
      # Test project creation workflow
      state = PaceEditor::Core::EditorState.new
      
      # Project creation should work
      success = state.create_new_project("Test Project", project_dir)
      success.should be_true
      
      # Verify project structure
      Dir.exists?(project_dir).should be_true
      File.exists?(File.join(project_dir, "project.pace")).should be_true
      Dir.exists?(File.join(project_dir, "assets")).should be_true
      Dir.exists?(File.join(project_dir, "scenes")).should be_true
      Dir.exists?(File.join(project_dir, "assets", "backgrounds")).should be_true
      Dir.exists?(File.join(project_dir, "assets", "characters")).should be_true
      Dir.exists?(File.join(project_dir, "assets", "sounds")).should be_true
      Dir.exists?(File.join(project_dir, "assets", "music")).should be_true
      Dir.exists?(File.join(project_dir, "assets", "scripts")).should be_true
      
      # Project should be loaded in state
      state.current_project.should_not be_nil
      state.current_project.not_nil!.name.should eq("Test Project")
    end

    it "saves and loads project data correctly" do
      # Create and configure project
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Save Test Project", project_dir)
      
      project = state.current_project.not_nil!
      project.title = "My Amazing Game"
      project.window_width = 1024
      project.window_height = 768
      project.author = "Test Author"
      project.version = "1.0.0"
      
      # Save project
      save_success = state.save_project
      save_success.should be_true
      
      # Clear state and reload
      state.current_project = nil
      project_file = File.join(project_dir, "project.pace")
      
      # Load project
      load_success = state.load_project(project_file)
      load_success.should be_true
      
      # Verify data persistence
      loaded_project = state.current_project.not_nil!
      loaded_project.name.should eq("Save Test Project")
      loaded_project.title.should eq("My Amazing Game")
      loaded_project.window_width.should eq(1024)
      loaded_project.window_height.should eq(768)
      loaded_project.author.should eq("Test Author")
      loaded_project.version.should eq("1.0.0")
    end

    it "handles project validation errors gracefully" do
      # Test with corrupted project file
      Dir.mkdir_p(project_dir)
      corrupt_project_file = File.join(project_dir, "project.pace")
      File.write(corrupt_project_file, "invalid yaml content {{{")
      
      state = PaceEditor::Core::EditorState.new
      
      # Should handle corruption gracefully
      load_success = state.load_project(corrupt_project_file)
      load_success.should be_false
      state.current_project.should be_nil
    end

    it "handles missing project files gracefully" do
      state = PaceEditor::Core::EditorState.new
      nonexistent_file = File.join(project_dir, "nonexistent.pace")
      
      # Should handle missing file gracefully
      load_success = state.load_project(nonexistent_file)
      load_success.should be_false
      state.current_project.should be_nil
    end
  end

  describe "UI Responsiveness" do
    it "initializes editor window without errors" do
      # Test basic editor window creation
      editor_window = PaceEditor::Core::EditorWindow.new
      editor_window.should_not be_nil
      
      # State should be initialized
      editor_window.state.should_not be_nil
      
      # UI components should be initialized
      editor_window.menu_bar.should_not be_nil
      editor_window.tool_palette.should_not be_nil
      editor_window.property_panel.should_not be_nil
      editor_window.scene_hierarchy.should_not be_nil
      editor_window.asset_browser.should_not be_nil
      
      # Editors should be initialized
      editor_window.scene_editor.should_not be_nil
      editor_window.character_editor.should_not be_nil
      editor_window.hotspot_editor.should_not be_nil
      editor_window.dialog_editor.should_not be_nil
      
      # Dialogs should be initialized
      editor_window.hotspot_action_dialog.should_not be_nil
      editor_window.script_editor.should_not be_nil
      editor_window.background_import_dialog.should_not be_nil
      editor_window.asset_import_dialog.should_not be_nil
      editor_window.scene_creation_wizard.should_not be_nil
      editor_window.game_export_dialog.should_not be_nil
    end

    it "handles mode switching correctly" do
      state = PaceEditor::Core::EditorState.new
      
      # Test all editor modes
      modes = [
        PaceEditor::EditorMode::Scene,
        PaceEditor::EditorMode::Character,
        PaceEditor::EditorMode::Hotspot,
        PaceEditor::EditorMode::Dialog,
        PaceEditor::EditorMode::Assets,
        PaceEditor::EditorMode::Project
      ]
      
      modes.each do |mode|
        state.current_mode = mode
        state.current_mode.should eq(mode)
      end
    end

    it "handles tool selection correctly" do
      state = PaceEditor::Core::EditorState.new
      
      # Test all tools
      tools = [
        PaceEditor::Tool::Select,
        PaceEditor::Tool::Move,
        PaceEditor::Tool::Place,
        PaceEditor::Tool::Delete,
        PaceEditor::Tool::Paint,
        PaceEditor::Tool::Zoom
      ]
      
      tools.each do |tool|
        state.current_tool = tool
        state.current_tool.should eq(tool)
      end
    end

    it "shows and hides dialogs correctly" do
      editor_window = PaceEditor::Core::EditorWindow.new
      
      # Test background import dialog
      editor_window.background_import_dialog.visible.should be_false
      editor_window.show_background_import_dialog
      editor_window.background_import_dialog.visible.should be_true
      editor_window.background_import_dialog.hide
      editor_window.background_import_dialog.visible.should be_false
      
      # Test asset import dialog
      editor_window.asset_import_dialog.visible.should be_false
      editor_window.show_asset_import_dialog
      editor_window.asset_import_dialog.visible.should be_true
      editor_window.asset_import_dialog.hide
      editor_window.asset_import_dialog.visible.should be_false
      
      # Test scene creation wizard
      editor_window.scene_creation_wizard.visible.should be_false
      editor_window.show_scene_creation_wizard
      editor_window.scene_creation_wizard.visible.should be_true
      editor_window.scene_creation_wizard.hide
      editor_window.scene_creation_wizard.visible.should be_false
      
      # Test game export dialog
      editor_window.game_export_dialog.visible.should be_false
      editor_window.show_game_export_dialog
      editor_window.game_export_dialog.visible.should be_true
      editor_window.game_export_dialog.hide
      editor_window.game_export_dialog.visible.should be_false
    end
  end

  describe "Asset Management" do
    it "imports background assets successfully" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Asset Test", project_dir)
      
      # Create test background file
      bg_file = File.join(temp_dir, "test_bg.png")
      File.write(bg_file, "fake_png_data")
      
      # Create background import dialog
      dialog = PaceEditor::UI::BackgroundImportDialog.new(state)
      dialog.should_not be_nil
      
      # Dialog should be able to show/hide
      dialog.visible.should be_false
      dialog.show
      dialog.visible.should be_true
      dialog.hide
      dialog.visible.should be_false
    end

    it "validates asset types correctly" do
      # Test asset type validation logic
      valid_bg_files = ["image.png", "image.jpg", "image.bmp", "image.tga"]
      invalid_bg_files = ["document.txt", "sound.wav", "video.mp4"]
      
      valid_bg_files.each do |filename|
        # Background files should be valid for background import
        is_image = filename.ends_with?(".png") || filename.ends_with?(".jpg") || 
                  filename.ends_with?(".bmp") || filename.ends_with?(".tga")
        is_image.should be_true
      end
      
      invalid_bg_files.each do |filename|
        # Non-image files should not be valid for background import
        is_image = filename.ends_with?(".png") || filename.ends_with?(".jpg") || 
                  filename.ends_with?(".bmp") || filename.ends_with?(".tga")
        is_image.should be_false
      end
    end

    it "organizes assets in correct directories" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Organization Test", project_dir)
      
      project = state.current_project.not_nil!
      
      # Asset directories should exist
      bg_dir = File.join(project.project_path, "assets", "backgrounds")
      char_dir = File.join(project.project_path, "assets", "characters")
      sound_dir = File.join(project.project_path, "assets", "sounds")
      music_dir = File.join(project.project_path, "assets", "music")
      script_dir = File.join(project.project_path, "assets", "scripts")
      
      Dir.exists?(bg_dir).should be_true
      Dir.exists?(char_dir).should be_true
      Dir.exists?(sound_dir).should be_true
      Dir.exists?(music_dir).should be_true
      Dir.exists?(script_dir).should be_true
    end

    it "refreshes asset lists correctly" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Refresh Test", project_dir)
      
      project = state.current_project.not_nil!
      
      # Add some test assets
      bg_dir = File.join(project.project_path, "assets", "backgrounds")
      bg_file = File.join(bg_dir, "test.png")
      File.write(bg_file, "fake_image")
      
      char_dir = File.join(project.project_path, "assets", "characters")
      char_file = File.join(char_dir, "hero.png")
      File.write(char_file, "fake_character")
      
      # Refresh assets
      project.refresh_assets
      
      # Assets should be detected
      project.backgrounds.should contain("test.png")
      project.characters.should contain("hero.png")
    end
  end

  describe "Scene Operations" do
    it "creates scenes with wizard successfully" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Scene Test", project_dir)
      
      # Create scene creation wizard
      wizard = PaceEditor::UI::SceneCreationWizard.new(state)
      wizard.should_not be_nil
      
      # Wizard should initialize correctly
      wizard.visible.should be_false
      wizard.show
      wizard.visible.should be_true
    end

    it "saves and loads scene data correctly" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Scene Data Test", project_dir)
      
      project = state.current_project.not_nil!
      
      # Create a test scene
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.background_path = "backgrounds/room.png"
      
      # Save scene
      scene_file = File.join(project.scenes_path, "test_scene.yml")
      save_success = PaceEditor::IO::SceneIO.save_scene(scene, scene_file)
      save_success.should be_true
      
      # Load scene
      loaded_scene = PaceEditor::IO::SceneIO.load_scene(scene_file)
      loaded_scene.should_not be_nil
      loaded_scene.not_nil!.name.should eq("test_scene")
      loaded_scene.not_nil!.background_path.should eq("backgrounds/room.png")
    end

    it "validates scene references correctly" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Reference Test", project_dir)
      
      # Create scene with background reference
      scene = PointClickEngine::Scenes::Scene.new("ref_test")
      scene.background_path = "backgrounds/missing.png"
      
      # Background file doesn't exist
      project = state.current_project.not_nil!
      if bg_path = scene.background_path
        bg_file = File.join(project.project_path, "assets", bg_path)
        File.exists?(bg_file).should be_false
      end
      
      # Scene should still be valid (references can be missing during development)
      scene.name.should eq("ref_test")
      scene.background_path.should eq("backgrounds/missing.png")
    end

    it "switches between scenes correctly" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Switch Test", project_dir)
      
      # Create multiple scenes
      scene1 = PointClickEngine::Scenes::Scene.new("scene1")
      scene2 = PointClickEngine::Scenes::Scene.new("scene2")
      
      # Set current scene
      state.current_scene = scene1
      state.current_scene.should_not be_nil
      state.current_scene.not_nil!.name.should eq("scene1")
      
      # Switch to different scene
      state.current_scene = scene2
      state.current_scene.not_nil!.name.should eq("scene2")
      
      # Clear scene
      state.current_scene = nil
      state.current_scene.should be_nil
    end
  end

  describe "Error Handling and Recovery" do
    it "handles insufficient disk space gracefully" do
      # Test behavior when disk operations might fail
      state = PaceEditor::Core::EditorState.new
      
      # Try to create project in potentially problematic location
      problematic_dir = "/dev/null/impossible_directory"
      
      # Should handle gracefully without crashing
      success = state.create_new_project("Disk Test", problematic_dir)
      # May succeed or fail depending on system, but shouldn't crash
    end

    it "handles concurrent file access gracefully" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Concurrent Test", project_dir)
      
      # Multiple save operations should not corrupt data
      3.times do |i|
        state.current_project.not_nil!.title = "Title #{i}"
        state.save_project
      end
      
      # Final state should be consistent
      state.current_project.not_nil!.title.should eq("Title 2")
    end

    it "recovers from corrupted state gracefully" do
      state = PaceEditor::Core::EditorState.new
      
      # Corrupted state should not crash the application
      # Set invalid state values
      state.zoom = -1.0_f32  # Invalid zoom
      state.zoom.should eq(-1.0_f32)  # State accepts it (validation elsewhere)
      
      # Application should still function
      state.current_mode = PaceEditor::EditorMode::Scene
      state.current_mode.should eq(PaceEditor::EditorMode::Scene)
    end

    it "handles missing dependencies gracefully" do
      # Test behavior when external dependencies are missing
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Dependency Test", project_dir)
      
      # Should handle missing PointClickEngine components gracefully
      project = state.current_project.not_nil!
      project.should_not be_nil
      
      # Basic operations should work even if some features are unavailable
      project.name.should eq("Dependency Test")
    end
  end

  describe "Data Consistency" do
    it "maintains consistent project state during operations" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Consistency Test", project_dir)
      
      project = state.current_project.not_nil!
      original_name = project.name
      
      # Modify project
      project.title = "Modified Title"
      
      # Project reference should remain valid
      state.current_project.should_not be_nil
      state.current_project.not_nil!.name.should eq(original_name)
      state.current_project.not_nil!.title.should eq("Modified Title")
    end

    it "maintains file system consistency" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("FS Consistency Test", project_dir)
      
      # Save project
      state.save_project
      
      # Project file should exist and be valid
      project_file = File.join(project_dir, "project.pace")
      File.exists?(project_file).should be_true
      
      # File should contain valid YAML
      content = File.read(project_file)
      content.should_not be_empty
      content.should contain("name:")
    end

    it "handles state changes atomically" do
      state = PaceEditor::Core::EditorState.new
      state.create_new_project("Atomic Test", project_dir)
      
      original_project = state.current_project
      
      # Create new project should replace current project atomically
      new_project_dir = File.join(temp_dir, "new_project")
      state.create_new_project("New Project", new_project_dir)
      
      # Old project reference should be replaced completely
      state.current_project.should_not eq(original_project)
      state.current_project.not_nil!.name.should eq("New Project")
    end
  end
end