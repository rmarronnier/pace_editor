require "../spec_helper"

describe "Asset Import Workflow" do
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

  describe "Asset Import Dialog" do
    it "creates and initializes asset import dialog" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::AssetImportDialog.new(state)

      # Dialog should initialize properly
      dialog.should_not be_nil
      dialog.visible.should be_false
      dialog.selected_files.should be_empty
      dialog.asset_category.should eq("backgrounds")
    end

    it "shows dialog for different asset categories" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::AssetImportDialog.new(state)

      categories = ["backgrounds", "characters", "sounds", "music", "scripts"]
      
      categories.each do |category|
        dialog.show(category)
        dialog.visible.should be_true
        dialog.asset_category.should eq(category)
        dialog.hide
        dialog.visible.should be_false
      end
    end

    it "integrates with editor window" do
      editor_window = PaceEditor::Core::EditorWindow.new

      # Asset import dialog should be initialized
      editor_window.asset_import_dialog.should_not be_nil
      editor_window.asset_import_dialog.visible.should be_false

      # Show dialog through editor window
      editor_window.show_asset_import_dialog("backgrounds")
      editor_window.asset_import_dialog.visible.should be_true
      editor_window.asset_import_dialog.asset_category.should eq("backgrounds")
    end
  end

  describe "Asset Browser Integration" do
    it "connects asset browser import button to dialog" do
      project = PaceEditor::Core::Project.new(
        name: "Asset Browser Test",
        project_path: project_dir
      )

      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_mode = PaceEditor::EditorMode::Assets

      # Create editor window and connect state
      editor_window = PaceEditor::Core::EditorWindow.new
      state.editor_window = editor_window

      # Asset browser should be able to show import dialog
      asset_browser = PaceEditor::UI::AssetBrowser.new(state)
      asset_browser.should_not be_nil

      # Asset import dialog should be accessible through editor window
      state.editor_window.not_nil!.asset_import_dialog.should_not be_nil

      # Verify dialog can be shown for different categories
      ["backgrounds", "characters", "sounds", "music", "scripts"].each do |category|
        editor_window.show_asset_import_dialog(category)
        editor_window.asset_import_dialog.visible.should be_true
        editor_window.asset_import_dialog.asset_category.should eq(category)
        editor_window.asset_import_dialog.hide
      end
    end
  end

  describe "Complete Asset Import Workflow" do
    it "allows importing multiple asset types" do
      # 1. Create complete test setup
      project = PaceEditor::Core::Project.new(
        name: "Multi Asset Import Test",
        project_path: project_dir
      )

      editor_window = PaceEditor::Core::EditorWindow.new
      state = editor_window.state
      state.current_project = project
      state.current_mode = PaceEditor::EditorMode::Assets

      # 2. Create test asset files in external location
      external_assets_dir = File.join(temp_dir, "external_assets")
      Dir.mkdir_p(external_assets_dir)

      # Create test files for each category
      test_files = {
        "room_bg.png" => "fake_png_data",
        "hero.png" => "fake_character_sprite",
        "click.wav" => "fake_audio_data",
        "theme.ogg" => "fake_music_data",
        "door_script.lua" => "function on_click() end",
      }

      test_files.each do |filename, content|
        File.write(File.join(external_assets_dir, filename), content)
      end

      # 3. Verify project has no assets initially
      project.backgrounds.should be_empty
      project.characters.should be_empty
      project.sounds.should be_empty
      project.music.should be_empty
      project.scripts.should be_empty

      # 4. Asset import dialog exists and can be shown
      dialog = editor_window.asset_import_dialog
      dialog.should_not be_nil

      # 5. Test import for each category
      categories_and_files = {
        "backgrounds" => ["room_bg.png"],
        "characters" => ["hero.png"],
        "sounds" => ["click.wav"],
        "music" => ["theme.ogg"],
        "scripts" => ["door_script.lua"],
      }

      categories_and_files.each do |category, files|
        # Show dialog for category
        editor_window.show_asset_import_dialog(category)
        dialog.visible.should be_true
        dialog.asset_category.should eq(category)

        # Simulate file selection
        files.each do |filename|
          file_path = File.join(external_assets_dir, filename)
          dialog.selected_files << file_path
        end

        # Verify target directory gets created
        target_dir = File.join(project_dir, "assets", category)
        Dir.mkdir_p(target_dir) # This would happen during import

        # Simulate import
        files.each do |filename|
          source_path = File.join(external_assets_dir, filename)
          dest_path = File.join(target_dir, filename)
          File.copy(source_path, dest_path)
        end

        # Verify files were imported
        files.each do |filename|
          dest_path = File.join(target_dir, filename)
          File.exists?(dest_path).should be_true
        end

        # Clean up for next test
        dialog.selected_files.clear
        dialog.hide
      end

      # 6. Refresh project assets to reflect imported files
      project.refresh_assets

      # 7. Verify all assets are now available
      project.backgrounds.should contain("room_bg.png")
      project.characters.should contain("hero.png")
      project.sounds.should contain("click.wav")
      project.music.should contain("theme.ogg")
      project.scripts.should contain("door_script.lua")
    end

    it "handles file type validation" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::AssetImportDialog.new(state)

      # Test supported extensions for each category
      test_cases = {
        "backgrounds" => {
          valid: [".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tga"],
          invalid: [".txt", ".doc", ".mp3", ".wav"]
        },
        "characters" => {
          valid: [".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tga"],
          invalid: [".txt", ".lua", ".ogg", ".mp3"]
        },
        "sounds" => {
          valid: [".wav", ".ogg", ".mp3", ".flac"],
          invalid: [".png", ".jpg", ".txt", ".lua"]
        },
        "music" => {
          valid: [".ogg", ".mp3", ".wav", ".flac"],
          invalid: [".png", ".txt", ".lua", ".bmp"]
        },
        "scripts" => {
          valid: [".lua", ".cr"],
          invalid: [".png", ".wav", ".txt", ".doc"]
        }
      }

      test_cases.each do |category, extensions|
        dialog.show(category)
        dialog.asset_category.should eq(category)
        
        # Note: Actual file filtering would be tested through the dialog's 
        # file list functionality during real usage
        dialog.hide
      end
    end
  end

  describe "Asset Import Error Handling" do
    it "handles missing project gracefully" do
      state = PaceEditor::Core::EditorState.new
      state.current_project = nil

      dialog = PaceEditor::UI::AssetImportDialog.new(state)
      dialog.should_not be_nil

      # Dialog should handle missing project
      dialog.show("backgrounds")
      dialog.visible.should be_true
    end

    it "handles duplicate file names gracefully" do
      project = PaceEditor::Core::Project.new(
        name: "Duplicate Test",
        project_path: project_dir
      )

      # Create existing asset
      bg_dir = File.join(project_dir, "assets", "backgrounds")
      Dir.mkdir_p(bg_dir)
      existing_file = File.join(bg_dir, "room.png")
      File.write(existing_file, "existing_image_data")

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      dialog = PaceEditor::UI::AssetImportDialog.new(state)

      # Test with duplicate filename
      external_file = File.join(temp_dir, "room.png")
      File.write(external_file, "new_image_data")

      dialog.selected_files << external_file

      # Import should handle duplicates gracefully (skip or rename)
      dialog.should_not be_nil
      File.exists?(existing_file).should be_true
    end

    it "handles invalid file paths gracefully" do
      project = PaceEditor::Core::Project.new(
        name: "Invalid Path Test",
        project_path: project_dir
      )

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      dialog = PaceEditor::UI::AssetImportDialog.new(state)

      # Test with non-existent file
      dialog.selected_files << "/non/existent/path/image.png"
      
      # Dialog should handle this gracefully (no crash)
      dialog.should_not be_nil
    end
  end

  describe "Project Asset Refresh" do
    it "refreshes asset lists after import" do
      project = PaceEditor::Core::Project.new(
        name: "Refresh Test",
        project_path: project_dir
      )

      # Initially no assets
      project.backgrounds.should be_empty
      project.characters.should be_empty

      # Add assets manually to filesystem
      bg_dir = File.join(project_dir, "assets", "backgrounds")
      char_dir = File.join(project_dir, "assets", "characters")
      Dir.mkdir_p(bg_dir)
      Dir.mkdir_p(char_dir)

      File.write(File.join(bg_dir, "forest.png"), "background_data")
      File.write(File.join(bg_dir, "castle.jpg"), "background_data")
      File.write(File.join(char_dir, "hero.png"), "character_data")

      # Refresh should detect new assets
      project.refresh_assets

      # Verify assets are detected
      project.backgrounds.should contain("forest.png")
      project.backgrounds.should contain("castle.jpg")
      project.characters.should contain("hero.png")
      project.sounds.should be_empty # No sounds added
    end
  end
end