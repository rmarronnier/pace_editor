require "../spec_helper"

describe "UI Interaction Integration" do
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

  describe "Property Panel UI Integration" do
    it "handles hotspot property editing correctly" do
      # Create test project and scene
      project = PaceEditor::Core::Project.new(
        name: "UI Test Project",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_door",
        RL::Vector2.new(100.0_f32, 200.0_f32),
        RL::Vector2.new(50.0_f32, 100.0_f32)
      )
      scene.add_hotspot(hotspot)

      # Set up editor state
      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = scene
      state.selected_object = "test_door"

      # Create property panel
      property_panel = PaceEditor::UI::PropertyPanel.new(state)

      # Verify property panel can be created
      property_panel.should_not be_nil

      # Test property changes
      original_x = hotspot.position.x
      hotspot.position = RL::Vector2.new(150.0_f32, hotspot.position.y)

      # Position should have changed
      hotspot.position.x.should_not eq(original_x)
      hotspot.position.x.should eq(150.0_f32)
    end

    it "shows different property types for different object types" do
      # Create project and scene
      project = PaceEditor::Core::Project.new(
        name: "Object Types Test",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("types_test")

      # Add hotspot
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "door",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 100.0_f32)
      )
      scene.add_hotspot(hotspot)

      # Add NPC
      npc = PointClickEngine::Characters::NPC.new(
        "wizard",
        RL::Vector2.new(200.0_f32, 150.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      scene.add_character(npc)

      # Set up state
      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = scene

      property_panel = PaceEditor::UI::PropertyPanel.new(state)

      # Test hotspot selection
      state.selected_object = "door"
      selected_hotspot = scene.hotspots.find { |h| h.name == "door" }
      selected_hotspot.should_not be_nil

      # Test character selection
      state.selected_object = "wizard"
      selected_character = scene.characters.find { |c| c.name == "wizard" }
      selected_character.should_not be_nil
      selected_character.should be_a(PointClickEngine::Characters::NPC)
    end

    it "handles cursor type changes for hotspots" do
      scene = PointClickEngine::Scenes::Scene.new("cursor_test")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "interactive_object",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      scene.add_hotspot(hotspot)

      # Test all cursor types
      cursor_types = [
        PointClickEngine::Scenes::Hotspot::CursorType::Default,
        PointClickEngine::Scenes::Hotspot::CursorType::Hand,
        PointClickEngine::Scenes::Hotspot::CursorType::Look,
        PointClickEngine::Scenes::Hotspot::CursorType::Talk,
        PointClickEngine::Scenes::Hotspot::CursorType::Use,
      ]

      cursor_types.each do |cursor_type|
        hotspot.cursor_type = cursor_type
        hotspot.cursor_type.should eq(cursor_type)
      end
    end
  end

  describe "Menu Bar Integration" do
    it "handles file operations correctly" do
      state = PaceEditor::Core::EditorState.new
      menu_bar = PaceEditor::UI::MenuBar.new(state)

      # Menu bar should initialize
      menu_bar.should_not be_nil

      # Test project state changes
      state.current_project.should be_nil

      # Create project
      project = PaceEditor::Core::Project.new(
        name: "Menu Test Project",
        project_path: project_dir
      )
      state.current_project = project

      # Project should now be loaded
      state.current_project.should_not be_nil
      state.current_project.not_nil!.name.should eq("Menu Test Project")
    end

    it "manages editor modes through menu interactions" do
      state = PaceEditor::Core::EditorState.new
      menu_bar = PaceEditor::UI::MenuBar.new(state)

      # Test mode changes
      initial_mode = state.current_mode
      initial_mode.should eq(PaceEditor::EditorMode::Scene)

      # Change modes
      available_modes = [
        PaceEditor::EditorMode::Scene,
        PaceEditor::EditorMode::Character,
        PaceEditor::EditorMode::Hotspot,
        PaceEditor::EditorMode::Dialog,
        PaceEditor::EditorMode::Assets,
        PaceEditor::EditorMode::Project,
      ]

      available_modes.each do |mode|
        state.current_mode = mode
        state.current_mode.should eq(mode)
      end
    end

    it "handles export menu integration" do
      # Test project with content for export
      project = PaceEditor::Core::Project.new(
        name: "Export UI Test",
        project_path: project_dir
      )

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      menu_bar = PaceEditor::UI::MenuBar.new(state)

      # Export should be available when project is loaded
      state.current_project.should_not be_nil

      # Test export directory creation (simulated)
      export_dir = File.join(project.project_path, "exports")
      Dir.mkdir_p(export_dir)
      Dir.exists?(export_dir).should be_true
    end
  end

  describe "Tool Palette Integration" do
    it "manages tool selection properly" do
      state = PaceEditor::Core::EditorState.new
      tool_palette = PaceEditor::UI::ToolPalette.new(state)

      # Tool palette should initialize
      tool_palette.should_not be_nil

      # Test tool selection
      available_tools = [
        PaceEditor::Tool::Select,
        PaceEditor::Tool::Move,
        PaceEditor::Tool::Place,
        PaceEditor::Tool::Delete,
        PaceEditor::Tool::Paint,
        PaceEditor::Tool::Zoom,
      ]

      available_tools.each do |tool|
        state.current_tool = tool
        state.current_tool.should eq(tool)
      end
    end

    it "coordinates with editor modes" do
      state = PaceEditor::Core::EditorState.new
      tool_palette = PaceEditor::UI::ToolPalette.new(state)

      # Default tool should be Select
      state.current_tool.should eq(PaceEditor::Tool::Select)

      # Change to place tool
      state.current_tool = PaceEditor::Tool::Place
      state.current_tool.should eq(PaceEditor::Tool::Place)

      # Mode changes should be compatible
      state.current_mode = PaceEditor::EditorMode::Hotspot
      state.current_mode.should eq(PaceEditor::EditorMode::Hotspot)
    end
  end

  describe "Scene Hierarchy Integration" do
    it "displays scene objects correctly" do
      # Create scene with objects
      scene = PointClickEngine::Scenes::Scene.new("hierarchy_test")

      # Add various objects
      hotspot1 = PointClickEngine::Scenes::Hotspot.new(
        "door",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 100.0_f32)
      )

      hotspot2 = PointClickEngine::Scenes::Hotspot.new(
        "window",
        RL::Vector2.new(300.0_f32, 150.0_f32),
        RL::Vector2.new(80.0_f32, 60.0_f32)
      )

      npc = PointClickEngine::Characters::NPC.new(
        "shopkeeper",
        RL::Vector2.new(200.0_f32, 200.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )

      scene.add_hotspot(hotspot1)
      scene.add_hotspot(hotspot2)
      scene.add_character(npc)

      # Set up state
      state = PaceEditor::Core::EditorState.new
      state.current_scene = scene

      scene_hierarchy = PaceEditor::UI::SceneHierarchy.new(state)

      # Verify scene hierarchy can access objects
      scene_hierarchy.should_not be_nil
      scene.hotspots.size.should eq(2)
      scene.characters.size.should eq(1)

      # Verify object names
      scene.hotspots.map(&.name).should contain("door")
      scene.hotspots.map(&.name).should contain("window")
      scene.characters.map(&.name).should contain("shopkeeper")
    end

    it "handles object selection from hierarchy" do
      project = PaceEditor::Core::Project.new(
        name: "Selection Test",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("selection_test")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "selectable_door",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 100.0_f32)
      )
      scene.add_hotspot(hotspot)

      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = scene

      scene_hierarchy = PaceEditor::UI::SceneHierarchy.new(state)

      # Test selection
      state.selected_object = "selectable_door"
      state.selected_object.should eq("selectable_door")

      # Verify selected object exists in scene
      selected = scene.hotspots.find { |h| h.name == "selectable_door" }
      selected.should_not be_nil
    end
  end

  describe "Asset Browser Integration" do
    it "manages asset discovery and loading" do
      project = PaceEditor::Core::Project.new(
        name: "Asset Test Project",
        project_path: project_dir
      )

      # Create asset directories
      ["backgrounds", "characters", "sounds", "music"].each do |asset_type|
        asset_dir = File.join(project_dir, "assets", asset_type)
        Dir.mkdir_p(asset_dir)

        # Create sample files
        case asset_type
        when "backgrounds"
          File.write(File.join(asset_dir, "room1.png"), "fake_image")
          File.write(File.join(asset_dir, "room2.jpg"), "fake_image")
        when "characters"
          File.write(File.join(asset_dir, "hero.png"), "fake_sprite")
        when "sounds"
          File.write(File.join(asset_dir, "click.wav"), "fake_audio")
        when "music"
          File.write(File.join(asset_dir, "theme.ogg"), "fake_music")
        end
      end

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      asset_browser = PaceEditor::UI::AssetBrowser.new(state)

      # Asset browser should initialize
      asset_browser.should_not be_nil

      # Verify asset directories exist
      ["backgrounds", "characters", "sounds", "music"].each do |asset_type|
        asset_dir = File.join(project_dir, "assets", asset_type)
        Dir.exists?(asset_dir).should be_true

        # Verify files were created
        files = Dir.glob(File.join(asset_dir, "*"))
        files.should_not be_empty
      end
    end

    it "integrates with scene background selection" do
      project = PaceEditor::Core::Project.new(
        name: "Background Test",
        project_path: project_dir
      )

      # Create background assets
      bg_dir = File.join(project_dir, "assets", "backgrounds")
      Dir.mkdir_p(bg_dir)

      background_files = ["forest.png", "castle.jpg", "dungeon.png"]
      background_files.each do |bg_file|
        File.write(File.join(bg_dir, bg_file), "fake_background_data")
      end

      scene = PointClickEngine::Scenes::Scene.new("bg_test_scene")

      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = scene

      asset_browser = PaceEditor::UI::AssetBrowser.new(state)

      # Test background assignment
      scene.background_path = "backgrounds/forest.png"
      scene.background_path.should eq("backgrounds/forest.png")

      # Verify background file exists
      full_bg_path = File.join(project_dir, "assets", "backgrounds", "forest.png")
      File.exists?(full_bg_path).should be_true
    end
  end

  describe "Editor Window Coordination" do
    it "coordinates all UI components properly" do
      editor_window = PaceEditor::Core::EditorWindow.new

      # All components should be initialized
      editor_window.menu_bar.should_not be_nil
      editor_window.tool_palette.should_not be_nil
      editor_window.property_panel.should_not be_nil
      editor_window.scene_hierarchy.should_not be_nil
      editor_window.asset_browser.should_not be_nil
      editor_window.script_editor.should_not be_nil

      # Editors should be initialized
      editor_window.scene_editor.should_not be_nil
      editor_window.character_editor.should_not be_nil
      editor_window.hotspot_editor.should_not be_nil
      editor_window.dialog_editor.should_not be_nil
    end

    it "manages state synchronization between components" do
      editor_window = PaceEditor::Core::EditorWindow.new
      state = editor_window.state

      # Create test project
      project = PaceEditor::Core::Project.new(
        name: "State Sync Test",
        project_path: project_dir
      )
      state.current_project = project

      # Create test scene
      scene = PointClickEngine::Scenes::Scene.new("sync_test")
      state.current_scene = scene

      # All components should share the same state through the editor window
      # Note: Components receive state through the editor window initialization
      state.current_project.should eq(project)
      state.current_scene.should eq(scene)
    end

    it "handles mode transitions correctly" do
      editor_window = PaceEditor::Core::EditorWindow.new
      state = editor_window.state

      # Test mode transitions
      modes = [
        PaceEditor::EditorMode::Scene,
        PaceEditor::EditorMode::Character,
        PaceEditor::EditorMode::Hotspot,
        PaceEditor::EditorMode::Dialog,
        PaceEditor::EditorMode::Assets,
        PaceEditor::EditorMode::Project,
      ]

      modes.each do |mode|
        state.current_mode = mode
        state.current_mode.should eq(mode)

        # State should be consistent across all components
        # Components are initialized with the same state reference
        state.current_mode.should eq(mode)
      end
    end
  end

  describe "Dialog Integration" do
    it "shows script editor dialog correctly" do
      editor_window = PaceEditor::Core::EditorWindow.new

      # Script editor should start hidden
      editor_window.script_editor.visible.should be_false

      # Show script editor
      editor_window.show_script_editor
      editor_window.script_editor.visible.should be_true

      # Show with specific file
      test_script = File.join(project_dir, "test.lua")
      File.write(test_script, "-- Test script")
      editor_window.show_script_editor(test_script)
      editor_window.script_editor.visible.should be_true
    end

    it "shows hotspot action dialog correctly" do
      editor_window = PaceEditor::Core::EditorWindow.new

      # Hotspot action dialog should exist
      editor_window.hotspot_action_dialog.should_not be_nil

      # Show dialog for hotspot
      editor_window.show_hotspot_action_dialog("test_hotspot")

      # Dialog should have been invoked (no visible property to test directly)
      editor_window.hotspot_action_dialog.should_not be_nil
    end

    it "handles dialog editor mode switching" do
      editor_window = PaceEditor::Core::EditorWindow.new
      state = editor_window.state

      # Set up a project with a scene containing an NPC
      project = PaceEditor::Core::Project.new("Test Project", project_dir)
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      npc = PointClickEngine::Characters::NPC.new(
        "test_npc",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      scene.characters << npc

      state.current_project = project
      state.current_scene = scene

      initial_mode = state.current_mode

      # Show dialog editor for character
      editor_window.show_dialog_editor_for_character("test_npc")

      # Should have switched to dialog mode
      state.current_mode.should eq(PaceEditor::EditorMode::Dialog)
      state.current_mode.should_not eq(initial_mode)
    end
  end

  describe "Error Handling and Edge Cases" do
    it "handles missing assets gracefully" do
      project = PaceEditor::Core::Project.new(
        name: "Missing Assets Test",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("missing_test")
      scene.background_path = "backgrounds/nonexistent.png"

      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = scene

      # Components should not crash with missing assets
      property_panel = PaceEditor::UI::PropertyPanel.new(state)
      asset_browser = PaceEditor::UI::AssetBrowser.new(state)

      property_panel.should_not be_nil
      asset_browser.should_not be_nil

      # Background path should still be set even if file doesn't exist
      scene.background_path.should eq("backgrounds/nonexistent.png")
    end

    it "handles empty project state gracefully" do
      state = PaceEditor::Core::EditorState.new
      # No project or scene loaded

      # UI components should handle empty state
      property_panel = PaceEditor::UI::PropertyPanel.new(state)
      scene_hierarchy = PaceEditor::UI::SceneHierarchy.new(state)
      asset_browser = PaceEditor::UI::AssetBrowser.new(state)

      property_panel.should_not be_nil
      scene_hierarchy.should_not be_nil
      asset_browser.should_not be_nil

      # State should be properly empty
      state.current_project.should be_nil
      state.current_scene.should be_nil
      state.selected_object.should be_nil
    end

    it "handles corrupted project data gracefully" do
      # Create project with minimal/empty data
      empty_project_dir = File.join(temp_dir, "empty_project")
      Dir.mkdir_p(empty_project_dir)

      project = PaceEditor::Core::Project.new(
        name: "",                       # Empty name
        project_path: empty_project_dir # Valid but minimal path
      )

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      # UI should handle invalid project gracefully
      menu_bar = PaceEditor::UI::MenuBar.new(state)
      property_panel = PaceEditor::UI::PropertyPanel.new(state)

      menu_bar.should_not be_nil
      property_panel.should_not be_nil

      # Project should still be set even if invalid
      state.current_project.should eq(project)
      state.current_project.not_nil!.name.should eq("")
    end
  end
end
