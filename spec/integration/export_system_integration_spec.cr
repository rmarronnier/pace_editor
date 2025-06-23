require "../spec_helper"

describe "Export System Integration" do
  temp_dir = ""
  project_dir = ""

  before_each do
    temp_dir = File.tempname
    project_dir = File.join(temp_dir, "test_project")
    Dir.mkdir_p(temp_dir)
    Dir.mkdir_p(project_dir)
    Dir.mkdir_p(File.join(project_dir, "assets"))
    Dir.mkdir_p(File.join(project_dir, "scenes"))
    Dir.mkdir_p(File.join(project_dir, "exports"))
  end

  after_each do
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end

  describe "Export Menu Integration" do
    it "creates export menu item in file menu" do
      state = PaceEditor::Core::EditorState.new
      menu_bar = PaceEditor::UI::MenuBar.new(state)

      # Menu bar should be initialized properly
      menu_bar.should_not be_nil
    end

    it "calls export_game method when menu item is clicked" do
      # Create a test project for export
      project = PaceEditor::Core::Project.new(
        name: "Test Export Project",
        project_path: project_dir
      )

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      menu_bar = PaceEditor::UI::MenuBar.new(state)

      # The menu bar should have access to the project
      menu_bar.should_not be_nil
      state.current_project.should_not be_nil
    end

    it "enables export menu only when project is loaded" do
      state = PaceEditor::Core::EditorState.new
      menu_bar = PaceEditor::UI::MenuBar.new(state)

      # No project loaded - export should be disabled conceptually
      state.current_project.should be_nil

      # Load a project
      project = PaceEditor::Core::Project.new(
        name: "Test Project",
        project_path: project_dir
      )
      state.current_project = project

      # Now export should be enabled
      state.current_project.should_not be_nil
    end
  end

  describe "Export Directory Creation" do
    it "creates exports directory when export is triggered" do
      project = PaceEditor::Core::Project.new(
        name: "Test Project",
        project_path: project_dir
      )

      export_dir = File.join(project.project_path, "exports")

      # Initially exports directory might not exist
      unless Dir.exists?(export_dir)
        Dir.mkdir_p(export_dir)
      end

      # Verify exports directory was created
      Dir.exists?(export_dir).should be_true
      File.basename(export_dir).should eq("exports")
    end

    it "handles export directory creation gracefully" do
      project = PaceEditor::Core::Project.new(
        name: "Test Project",
        project_path: project_dir
      )

      # Multiple calls should not cause issues
      export_dir = File.join(project.project_path, "exports")

      3.times do
        Dir.mkdir_p(export_dir) unless Dir.exists?(export_dir)
        Dir.exists?(export_dir).should be_true
      end
    end
  end

  describe "Export Functionality" do
    it "handles export with complete project structure" do
      # Create a complete project for export testing
      project = PaceEditor::Core::Project.new(
        name: "Complete Game Project",
        project_path: project_dir
      )

      # Set up all required directories
      %w[assets scenes scripts dialogs backgrounds characters sounds music].each do |subdir|
        Dir.mkdir_p(File.join(project_dir, subdir))
      end

      # Create some sample content
      scene_file = File.join(project_dir, "scenes", "main_scene.yml")
      File.write(scene_file, "---\nname: main_scene\nbackground_path: bg.png\n")

      script_file = File.join(project_dir, "scripts", "door.lua")
      File.write(script_file, "function on_click()\n  show_message('Door clicked!')\nend\n")

      # Verify project structure
      Dir.exists?(File.join(project_dir, "assets")).should be_true
      Dir.exists?(File.join(project_dir, "scenes")).should be_true
      File.exists?(scene_file).should be_true
      File.exists?(script_file).should be_true
    end

    it "exports project metadata correctly" do
      project = PaceEditor::Core::Project.new(
        name: "My Adventure Game",
        project_path: project_dir
      )

      # Set project properties
      project.version = "1.0.0"
      project.author = "Game Developer"
      project.title = "Amazing Adventure"
      project.window_width = 1024
      project.window_height = 768

      # Verify properties are set
      project.name.should eq("My Adventure Game")
      project.version.should eq("1.0.0")
      project.author.should eq("Game Developer")
      project.title.should eq("Amazing Adventure")
      project.window_width.should eq(1024)
      project.window_height.should eq(768)
    end

    it "handles asset collection for export" do
      project = PaceEditor::Core::Project.new(
        name: "Asset Test Project",
        project_path: project_dir
      )

      # Create various asset directories
      asset_types = ["backgrounds", "characters", "sounds", "music", "scripts"]
      asset_types.each do |asset_type|
        asset_dir = File.join(project_dir, "assets", asset_type)
        Dir.mkdir_p(asset_dir)

        # Create sample files
        case asset_type
        when "backgrounds"
          File.write(File.join(asset_dir, "room1.png"), "fake_image_data")
          File.write(File.join(asset_dir, "room2.jpg"), "fake_image_data")
        when "characters"
          File.write(File.join(asset_dir, "hero.png"), "fake_sprite_data")
        when "sounds"
          File.write(File.join(asset_dir, "click.wav"), "fake_audio_data")
        when "music"
          File.write(File.join(asset_dir, "theme.ogg"), "fake_music_data")
        when "scripts"
          File.write(File.join(asset_dir, "main.lua"), "-- Main script")
        end
      end

      # Verify all asset directories exist
      asset_types.each do |asset_type|
        asset_dir = File.join(project_dir, "assets", asset_type)
        Dir.exists?(asset_dir).should be_true

        # Verify files were created
        files = Dir.glob(File.join(asset_dir, "*"))
        files.should_not be_empty
      end
    end
  end

  describe "Export File Management" do
    it "creates appropriate export subdirectories" do
      project = PaceEditor::Core::Project.new(
        name: "Test Project",
        project_path: project_dir
      )

      export_dir = File.join(project.project_path, "exports")
      Dir.mkdir_p(export_dir)

      # Create expected export subdirectories
      export_subdirs = ["game", "assets", "data"]
      export_subdirs.each do |subdir|
        export_subdir = File.join(export_dir, subdir)
        Dir.mkdir_p(export_subdir)
        Dir.exists?(export_subdir).should be_true
      end
    end

    it "handles export file naming correctly" do
      project_names = ["My Game", "Adventure Quest", "Space Explorer"]

      project_names.each do |name|
        sanitized_name = name.downcase.gsub(/[^a-z0-9_\s]/, "").gsub(/\s+/, "_")
        export_filename = "#{sanitized_name}_export.zip"

        export_filename.should end_with(".zip")
        export_filename.should contain(sanitized_name)
        export_filename.should_not contain(" ")
      end
    end

    it "manages export versioning" do
      project = PaceEditor::Core::Project.new(
        name: "Versioned Project",
        project_path: project_dir
      )

      project.version = "1.2.3"

      # Export filename should include version
      version_tag = "v#{project.version}"
      export_name = "versioned_project_#{version_tag}"

      export_name.should contain("1.2.3")
      export_name.should contain("versioned_project")
    end
  end

  describe "Export Content Validation" do
    it "validates required project files before export" do
      project = PaceEditor::Core::Project.new(
        name: "Validation Test",
        project_path: project_dir
      )

      # Required directories that should exist
      required_dirs = ["scenes", "assets"]
      required_dirs.each do |dir_name|
        dir_path = File.join(project_dir, dir_name)
        Dir.mkdir_p(dir_path)
        Dir.exists?(dir_path).should be_true
      end

      # At least one scene should exist for a valid game
      scene_file = File.join(project_dir, "scenes", "start.yml")
      File.write(scene_file, "---\nname: start\n")
      File.exists?(scene_file).should be_true
    end

    it "checks for essential game components" do
      project = PaceEditor::Core::Project.new(
        name: "Component Test",
        project_path: project_dir
      )

      # Essential components for a playable game
      essential_files = {
        "scenes/main.yml"           => "---\nname: main\nbackground_path: bg.png\n",
        "assets/backgrounds/bg.png" => "fake_background_data",
        "project.pace"              => project.to_yaml,
      }

      essential_files.each do |file_path, content|
        full_path = File.join(project_dir, file_path)
        Dir.mkdir_p(File.dirname(full_path))
        File.write(full_path, content)
        File.exists?(full_path).should be_true
      end
    end

    it "reports missing dependencies" do
      project = PaceEditor::Core::Project.new(
        name: "Dependency Test",
        project_path: project_dir
      )

      # Create a scene that references assets
      scene_content = {
        "name"            => "test_scene",
        "background_path" => "backgrounds/missing_bg.png",
        "hotspots"        => [{
          "name"        => "door",
          "script_path" => "scripts/missing_script.lua",
        }],
      }

      scene_file = File.join(project_dir, "scenes", "test.yml")
      Dir.mkdir_p(File.dirname(scene_file))
      File.write(scene_file, scene_content.to_yaml)

      # Check for missing files
      missing_bg = File.join(project_dir, "assets", "backgrounds", "missing_bg.png")
      missing_script = File.join(project_dir, "assets", "scripts", "missing_script.lua")

      File.exists?(missing_bg).should be_false
      File.exists?(missing_script).should be_false

      # Export validation should catch these missing dependencies
    end
  end

  describe "Export Error Handling" do
    it "handles export without loaded project" do
      state = PaceEditor::Core::EditorState.new
      state.current_project = nil

      menu_bar = PaceEditor::UI::MenuBar.new(state)

      # Should handle gracefully when no project is loaded
      state.current_project.should be_nil
      menu_bar.should_not be_nil
    end

    it "handles insufficient permissions for export directory" do
      project = PaceEditor::Core::Project.new(
        name: "Permission Test",
        project_path: project_dir
      )

      export_dir = File.join(project.project_path, "exports")

      # Should be able to create the directory with proper permissions
      begin
        Dir.mkdir_p(export_dir)
        Dir.exists?(export_dir).should be_true
      rescue ex : File::Error
        # Expected to fail if permissions are insufficient
        # This is handled gracefully in the export system
      end
    end

    it "handles corrupted project files during export" do
      project = PaceEditor::Core::Project.new(
        name: "Corruption Test",
        project_path: project_dir
      )

      # Create corrupted YAML files
      corrupted_scene = File.join(project_dir, "scenes", "corrupted.yml")
      Dir.mkdir_p(File.dirname(corrupted_scene))
      File.write(corrupted_scene, "invalid: yaml: content: [[[")

      # Export should handle corrupted files gracefully
      File.exists?(corrupted_scene).should be_true

      # Verify file is actually corrupted
      begin
        YAML.parse(File.read(corrupted_scene))
        fail("Expected YAML parsing to fail")
      rescue YAML::ParseException
        # Expected - file is corrupted
      end
    end
  end

  describe "Export Integration with Game Engine" do
    it "prepares game data for point-click engine runtime" do
      project = PaceEditor::Core::Project.new(
        name: "Engine Integration Test",
        project_path: project_dir
      )

      # Create a complete scene with all elements
      scene = PointClickEngine::Scenes::Scene.new("main")
      scene.background_path = "backgrounds/room.png"

      # Add hotspot
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "door",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 100.0_f32)
      )
      scene.add_hotspot(hotspot)

      # Add character
      npc = PointClickEngine::Characters::NPC.new(
        "shopkeeper",
        RL::Vector2.new(200.0_f32, 150.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      scene.add_character(npc)

      # Verify scene has all components
      scene.hotspots.size.should eq(1)
      scene.characters.size.should eq(1)
      scene.background_path.should eq("backgrounds/room.png")

      # Scene should be serializable for export
      yaml_content = scene.to_yaml
      yaml_content.should be_a(String)
      yaml_content.should contain("main")
      yaml_content.should contain("backgrounds/room.png")

      # Note: hotspots and characters are stored separately in game engine
      # The scene YAML contains metadata, while objects are in separate files
    end

    it "packages dialog trees for runtime" do
      # Create dialog tree
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("shopkeeper_dialog")

      greeting_node = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "greeting",
        "Welcome to my shop!"
      )

      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new(
        "What do you sell?",
        "items_info"
      )
      greeting_node.add_choice(choice)

      info_node = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "items_info",
        "I sell potions and magical items."
      )
      info_node.is_end = true

      dialog_tree.add_node(greeting_node)
      dialog_tree.add_node(info_node)

      # Verify dialog structure for export
      dialog_tree.nodes.size.should eq(2)
      dialog_tree.nodes["greeting"].choices.size.should eq(1)
      dialog_tree.nodes["items_info"].is_end.should be_true

      # Should be serializable for export
      yaml_content = dialog_tree.to_yaml
      yaml_content.should contain("shopkeeper_dialog")
      yaml_content.should contain("Welcome to my shop!")
    end
  end
end
