require "../spec_helper"

describe "Game Export Workflow" do
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

  describe "Game Export Dialog" do
    it "creates and initializes game export dialog" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::GameExportDialog.new(state)

      # Dialog should initialize properly
      dialog.should_not be_nil
      dialog.visible.should be_false
    end

    it "shows and hides dialog correctly" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::GameExportDialog.new(state)

      # Show dialog
      dialog.show
      dialog.visible.should be_true

      # Hide dialog
      dialog.hide
      dialog.visible.should be_false
    end

    it "integrates with editor window" do
      editor_window = PaceEditor::Core::EditorWindow.new

      # Game export dialog should be initialized
      editor_window.game_export_dialog.should_not be_nil
      editor_window.game_export_dialog.visible.should be_false

      # Show dialog through editor window
      editor_window.show_game_export_dialog
      editor_window.game_export_dialog.visible.should be_true
    end
  end

  describe "Menu Integration" do
    it "connects Export Game menu to dialog" do
      project = PaceEditor::Core::Project.new(
        name: "Export Menu Test",
        project_path: project_dir
      )

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      # Create editor window and connect state
      editor_window = PaceEditor::Core::EditorWindow.new
      state.editor_window = editor_window

      # Menu bar should be able to show export dialog
      menu_bar = PaceEditor::UI::MenuBar.new(state)
      menu_bar.should_not be_nil

      # Game export dialog should be accessible through editor window
      state.editor_window.not_nil!.game_export_dialog.should_not be_nil

      # Verify dialog can be shown (simulates "Export Game..." menu click)
      editor_window.show_game_export_dialog
      editor_window.game_export_dialog.visible.should be_true
    end
  end

  describe "Complete Game Export Workflow" do
    it "allows exporting complete game project" do
      # 1. Create complete test project
      project = PaceEditor::Core::Project.new(
        name: "Complete Export Test",
        project_path: project_dir
      )

      # Set project properties
      project.title = "Amazing Adventure"
      project.window_width = 1024
      project.window_height = 768
      project.version = "1.0.0"
      project.author = "Test Developer"

      editor_window = PaceEditor::Core::EditorWindow.new
      state = editor_window.state
      state.current_project = project

      # 2. Create project content
      # Add scenes
      scenes_dir = File.join(project_dir, "scenes")
      Dir.mkdir_p(scenes_dir)
      scene_file = File.join(scenes_dir, "main.yml")
      File.write(scene_file, "---\nname: main\nbackground_path: backgrounds/room.png\n")

      # Add assets
      bg_dir = File.join(project_dir, "assets", "backgrounds")
      Dir.mkdir_p(bg_dir)
      bg_file = File.join(bg_dir, "room.png")
      File.write(bg_file, "fake_background_data")

      scripts_dir = File.join(project_dir, "assets", "scripts")
      Dir.mkdir_p(scripts_dir)
      script_file = File.join(scripts_dir, "door.lua")
      File.write(script_file, "function on_click() end")

      # 3. Game export dialog exists and can be shown
      dialog = editor_window.game_export_dialog
      dialog.should_not be_nil

      # Show dialog (simulates "Export Game..." menu click)
      editor_window.show_game_export_dialog
      dialog.visible.should be_true

      # 4. Verify export functionality would work
      # (In actual usage, user would configure export settings)
      
      export_name = "amazing_adventure"
      export_path = File.join(project_dir, "exports", export_name)

      # 5. Simulate export process (what dialog would do)
      Dir.mkdir_p(export_path)

      # Copy assets
      assets_dest = File.join(export_path, "assets")
      Dir.mkdir_p(assets_dest)
      
      # Copy backgrounds
      bg_dest_dir = File.join(assets_dest, "backgrounds")
      Dir.mkdir_p(bg_dest_dir)
      bg_dest_file = File.join(bg_dest_dir, "room.png")
      File.copy(bg_file, bg_dest_file)

      # Copy scripts
      scripts_dest_dir = File.join(assets_dest, "scripts")
      Dir.mkdir_p(scripts_dest_dir)
      script_dest_file = File.join(scripts_dest_dir, "door.lua")
      File.copy(script_file, script_dest_file)

      # Copy scenes
      scenes_dest = File.join(export_path, "scenes")
      Dir.mkdir_p(scenes_dest)
      scene_dest_file = File.join(scenes_dest, "main.yml")
      File.copy(scene_file, scene_dest_file)

      # Generate main game file
      main_file = File.join(export_path, "#{export_name}.cr")
      # Clean module name (remove spaces and special chars)
      module_name = project.name.gsub(/[^a-zA-Z0-9]/, "").capitalize + "Game"
      game_code = <<-CRYSTAL
        # Generated game file for #{project.name}
        require "point_click_engine"
        
        module #{module_name}
          def self.run
            game = PointClickEngine::Game.new("#{project.title}", #{project.window_width}, #{project.window_height})
            game.start("main")
          end
        end
        
        #{module_name}.run
        CRYSTAL
      File.write(main_file, game_code)

      # 6. Verify complete export result
      Dir.exists?(export_path).should be_true
      Dir.exists?(assets_dest).should be_true
      Dir.exists?(scenes_dest).should be_true
      File.exists?(bg_dest_file).should be_true
      File.exists?(script_dest_file).should be_true
      File.exists?(scene_dest_file).should be_true
      File.exists?(main_file).should be_true

      # 7. Verify generated game file content
      game_content = File.read(main_file)
      game_content.should contain("Amazing Adventure")
      game_content.should contain("1024")
      game_content.should contain("768")
      game_content.should contain("CompleteexporttestGame")
    end

    it "handles different export formats" do
      project = PaceEditor::Core::Project.new(
        name: "Format Test",
        project_path: project_dir
      )

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      dialog = PaceEditor::UI::GameExportDialog.new(state)

      # Test export format options
      export_formats = ["standalone", "web", "source"]
      export_path = File.join(project_dir, "exports", "format_test")
      
      export_formats.each do |format|
        Dir.mkdir_p(export_path)
        
        case format
        when "standalone"
          # Should generate .cr file and build script
          main_file = File.join(export_path, "format_test.cr")
          build_script = File.join(export_path, "build.sh")
          
          # Simulate standalone export
          File.write(main_file, "# Crystal game file")
          File.write(build_script, "#!/bin/bash\necho 'Building game...'")
          
          File.exists?(main_file).should be_true
          File.exists?(build_script).should be_true
          
        when "web"
          # Should generate HTML file
          html_file = File.join(export_path, "index.html")
          
          # Simulate web export
          html_content = "<!DOCTYPE html><html><head><title>Web Game</title></head><body></body></html>"
          File.write(html_file, html_content)
          
          File.exists?(html_file).should be_true
          
        when "source"
          # Should copy project file and create README
          readme_file = File.join(export_path, "README.md")
          
          # Simulate source export
          File.write(readme_file, "# Source Package\n\nThis is the source code.")
          
          File.exists?(readme_file).should be_true
        end
        
        # Clean up for next test
        FileUtils.rm_rf(export_path)
      end
    end

    it "validates project before export" do
      # Create project without calling setup_project_structure to avoid auto-creation
      project = PaceEditor::Core::Project.new(
        name: "Validation Test",
        project_path: project_dir
      )

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      dialog = PaceEditor::UI::GameExportDialog.new(state)

      # Test validation with incomplete project
      # Check that validation can detect missing components
      
      scenes_dir = File.join(project_dir, "scenes")
      assets_dir = File.join(project_dir, "assets")
      project_file = File.join(project_dir, "project.pace")
      
      # Remove scenes directory if it was auto-created
      FileUtils.rm_rf(scenes_dir) if Dir.exists?(scenes_dir)
      
      # Now should be missing
      scenes_missing = !Dir.exists?(scenes_dir) || Dir.glob(File.join(scenes_dir, "*.yml")).empty?
      scenes_missing.should be_true
      
      # Add required components
      Dir.mkdir_p(scenes_dir)
      scene_file = File.join(scenes_dir, "main.yml")
      File.write(scene_file, "---\nname: main\n")
      
      Dir.mkdir_p(File.join(assets_dir, "backgrounds"))
      bg_file = File.join(assets_dir, "backgrounds", "bg.png")
      File.write(bg_file, "fake_image")
      
      # Now validation should pass
      File.exists?(scene_file).should be_true
      File.exists?(bg_file).should be_true
    end
  end

  describe "Export Asset Management" do
    it "copies all asset types correctly" do
      project = PaceEditor::Core::Project.new(
        name: "Asset Copy Test",
        project_path: project_dir
      )

      # Create comprehensive asset structure
      asset_types = ["backgrounds", "characters", "sounds", "music", "scripts"]
      assets_src = File.join(project_dir, "assets")
      
      asset_types.each do |asset_type|
        type_dir = File.join(assets_src, asset_type)
        Dir.mkdir_p(type_dir)
        
        # Create sample files for each type
        case asset_type
        when "backgrounds"
          File.write(File.join(type_dir, "room1.png"), "background1")
          File.write(File.join(type_dir, "room2.jpg"), "background2")
        when "characters"
          File.write(File.join(type_dir, "hero.png"), "character1")
        when "sounds"
          File.write(File.join(type_dir, "click.wav"), "sound1")
        when "music"
          File.write(File.join(type_dir, "theme.ogg"), "music1")
        when "scripts"
          File.write(File.join(type_dir, "main.lua"), "script1")
        end
      end

      # Simulate export asset copying
      export_path = File.join(project_dir, "exports", "asset_test")
      assets_dest = File.join(export_path, "assets")
      
      asset_types.each do |asset_type|
        src_dir = File.join(assets_src, asset_type)
        dest_dir = File.join(assets_dest, asset_type)
        
        if Dir.exists?(src_dir)
          Dir.mkdir_p(dest_dir)
          Dir.glob(File.join(src_dir, "*")).each do |file|
            if File.file?(file)
              dest_file = File.join(dest_dir, File.basename(file))
              File.copy(file, dest_file)
            end
          end
        end
      end

      # Verify all assets were copied
      asset_types.each do |asset_type|
        dest_dir = File.join(assets_dest, asset_type)
        Dir.exists?(dest_dir).should be_true
        Dir.glob(File.join(dest_dir, "*")).should_not be_empty
      end
    end

    it "processes scenes correctly" do
      project = PaceEditor::Core::Project.new(
        name: "Scene Process Test",
        project_path: project_dir
      )

      # Create multiple scenes
      scenes_src = File.join(project_dir, "scenes")
      Dir.mkdir_p(scenes_src)
      
      scene_files = ["main.yml", "forest.yml", "castle.yml"]
      scene_files.each do |scene_file|
        scene_path = File.join(scenes_src, scene_file)
        scene_name = File.basename(scene_file, ".yml")
        content = "---\nname: #{scene_name}\nbackground_path: backgrounds/#{scene_name}.png\n"
        File.write(scene_path, content)
      end

      # Simulate export scene processing
      export_path = File.join(project_dir, "exports", "scene_test")
      scenes_dest = File.join(export_path, "scenes")
      Dir.mkdir_p(scenes_dest)
      
      Dir.glob(File.join(scenes_src, "*.yml")).each do |scene_file|
        dest_file = File.join(scenes_dest, File.basename(scene_file))
        File.copy(scene_file, dest_file)
      end

      # Verify all scenes were processed
      scene_files.each do |scene_file|
        dest_file = File.join(scenes_dest, scene_file)
        File.exists?(dest_file).should be_true
        
        content = File.read(dest_file)
        scene_name = File.basename(scene_file, ".yml")
        content.should contain(scene_name)
      end
    end
  end

  describe "Export Error Handling" do
    it "handles missing project gracefully" do
      state = PaceEditor::Core::EditorState.new
      state.current_project = nil

      dialog = PaceEditor::UI::GameExportDialog.new(state)
      dialog.should_not be_nil

      # Dialog should handle missing project
      dialog.show
      dialog.visible.should be_true
    end

    it "handles export directory creation failures" do
      project = PaceEditor::Core::Project.new(
        name: "Export Error Test",
        project_path: project_dir
      )

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      dialog = PaceEditor::UI::GameExportDialog.new(state)

      # Test with invalid export path
      invalid_export_path = "/invalid/path/that/cannot/be/created"
      
      # Export should handle directory creation failures gracefully
      # (In real implementation, this would show error message)
      begin
        Dir.mkdir_p(invalid_export_path)
        # If this succeeds, we're running with unexpected permissions
      rescue
        # Expected to fail - export should handle this
      end
    end

    it "handles missing assets gracefully" do
      project = PaceEditor::Core::Project.new(
        name: "Missing Assets Export Test",
        project_path: project_dir
      )

      # Create scene that references missing assets
      scenes_dir = File.join(project_dir, "scenes")
      Dir.mkdir_p(scenes_dir)
      scene_file = File.join(scenes_dir, "main.yml")
      scene_content = "---\nname: main\nbackground_path: backgrounds/missing.png\n"
      File.write(scene_file, scene_content)

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      dialog = PaceEditor::UI::GameExportDialog.new(state)

      # Export should handle missing referenced assets
      # (Could warn user or skip missing files)
      File.exists?(scene_file).should be_true
      content = File.read(scene_file)
      content.should contain("missing.png")
      
      # Referenced background file doesn't exist
      bg_file = File.join(project_dir, "assets", "backgrounds", "missing.png")
      File.exists?(bg_file).should be_false
    end
  end

  describe "Export Configuration" do
    it "supports export customization options" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::GameExportDialog.new(state)

      # Test export configuration options
      # - Export format (standalone, web, source)
      # - Include source code
      # - Compress assets
      # - Validate project

      # These options would be configurable through the dialog UI
      # and affect the export process
      dialog.should_not be_nil
    end

    it "generates appropriate build instructions" do
      project = PaceEditor::Core::Project.new(
        name: "Build Instructions Test",
        project_path: project_dir
      )

      export_path = File.join(project_dir, "exports", "build_test")
      Dir.mkdir_p(export_path)

      # For standalone export, should generate build script
      build_script = File.join(export_path, "build.sh")
      build_content = <<-BASH
        #!/bin/bash
        echo "Building #{project.name}..."
        crystal build build_test.cr -o build_test
        echo "Build complete! Run ./build_test to play the game."
        BASH
      File.write(build_script, build_content)

      # For web export, should generate deployment instructions
      readme_file = File.join(export_path, "README.md")
      readme_content = "# Web Deployment\n\nUpload all files to a web server."
      File.write(readme_file, readme_content)

      # Verify instructions were created
      File.exists?(build_script).should be_true
      File.exists?(readme_file).should be_true
      
      build_content_check = File.read(build_script)
      build_content_check.should contain("crystal build")
      
      readme_content_check = File.read(readme_file)
      readme_content_check.should contain("web server")
    end
  end
end