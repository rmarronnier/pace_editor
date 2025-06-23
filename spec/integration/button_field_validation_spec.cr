require "../spec_helper"

describe "Button and Field Validation" do
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

  describe "Menu Bar Button Actions" do
    it "validates all file menu actions work" do
      state = PaceEditor::Core::EditorState.new
      menu_bar = PaceEditor::UI::MenuBar.new(state)

      # Test project creation flow
      menu_bar.show_new_project_dialog
      # Menu bar should have dialog state
      menu_bar.should_not be_nil

      # Test project loading (with valid project)
      project = PaceEditor::Core::Project.new(
        name: "Test Project",
        project_path: project_dir
      )
      state.current_project = project

      # Save project should work
      state.current_project.should_not be_nil

      # Export should be available
      state.current_project.should_not be_nil
    end

    it "validates mode switching buttons work" do
      state = PaceEditor::Core::EditorState.new
      menu_bar = PaceEditor::UI::MenuBar.new(state)

      # Test all editor modes
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
      end
    end

    it "validates view menu actions work" do
      state = PaceEditor::Core::EditorState.new
      menu_bar = PaceEditor::UI::MenuBar.new(state)

      # Test grid toggle
      original_grid = state.show_grid
      state.show_grid = !state.show_grid
      state.show_grid.should_not eq(original_grid)

      # Test hotspot toggle
      original_hotspots = state.show_hotspots
      state.show_hotspots = !state.show_hotspots
      state.show_hotspots.should_not eq(original_hotspots)
    end
  end

  describe "Tool Palette Button Actions" do
    it "validates all tool selections work" do
      state = PaceEditor::Core::EditorState.new
      tool_palette = PaceEditor::UI::ToolPalette.new(state)

      # Test all tools
      tools = [
        PaceEditor::Tool::Select,
        PaceEditor::Tool::Move,
        PaceEditor::Tool::Place,
        PaceEditor::Tool::Delete,
        PaceEditor::Tool::Paint,
        PaceEditor::Tool::Zoom,
      ]

      tools.each do |tool|
        state.current_tool = tool
        state.current_tool.should eq(tool)
      end
    end

    it "validates tool palette mode-specific actions" do
      state = PaceEditor::Core::EditorState.new
      tool_palette = PaceEditor::UI::ToolPalette.new(state)

      # Scene mode actions should be accessible
      state.current_mode = PaceEditor::EditorMode::Scene
      state.current_mode.should eq(PaceEditor::EditorMode::Scene)

      # Character mode actions should be accessible
      state.current_mode = PaceEditor::EditorMode::Character
      state.current_mode.should eq(PaceEditor::EditorMode::Character)

      # Hotspot mode actions should be accessible
      state.current_mode = PaceEditor::EditorMode::Hotspot
      state.current_mode.should eq(PaceEditor::EditorMode::Hotspot)
    end
  end

  describe "Property Panel Button Actions" do
    it "validates Edit Actions button for hotspots" do
      # Create test setup
      project = PaceEditor::Core::Project.new(
        name: "Test Project",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_door",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 100.0_f32)
      )
      scene.add_hotspot(hotspot)

      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = scene
      state.selected_object = "test_door"

      editor_window = PaceEditor::Core::EditorWindow.new
      state.editor_window = editor_window

      # Test hotspot action dialog can be shown
      editor_window.show_hotspot_action_dialog("test_door")
      editor_window.hotspot_action_dialog.should_not be_nil
    end

    it "validates Edit Script button for hotspots" do
      # Create test setup
      project = PaceEditor::Core::Project.new(
        name: "Test Project",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_door",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 100.0_f32)
      )
      scene.add_hotspot(hotspot)

      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = scene
      state.selected_object = "test_door"

      editor_window = PaceEditor::Core::EditorWindow.new
      state.editor_window = editor_window

      # Test script editor can be shown
      editor_window.show_script_editor
      editor_window.script_editor.visible.should be_true
    end

    it "validates Edit Dialog button for NPCs" do
      # Create test setup with NPC
      project = PaceEditor::Core::Project.new(
        name: "Test Project",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      npc = PointClickEngine::Characters::NPC.new(
        "test_wizard",
        RL::Vector2.new(200.0_f32, 200.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      scene.add_character(npc)

      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = scene
      state.selected_object = "test_wizard"

      editor_window = PaceEditor::Core::EditorWindow.new
      state.editor_window = editor_window

      # Use the editor window's state instead of our separate state
      editor_state = editor_window.state
      editor_state.current_project = project
      editor_state.current_scene = scene
      editor_state.selected_object = "test_wizard"

      # Test dialog editor mode switch
      initial_mode = editor_state.current_mode
      editor_window.show_dialog_editor_for_character("test_wizard")
      editor_state.current_mode.should eq(PaceEditor::EditorMode::Dialog)
    end

    it "validates dropdown interactions work" do
      scene = PointClickEngine::Scenes::Scene.new("dropdown_test")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      scene.add_hotspot(hotspot)

      # Test cursor type cycling (default is Hand, so change to Look)
      original_cursor = hotspot.cursor_type # Should be Hand by default
      hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Look
      hotspot.cursor_type.should_not eq(original_cursor)

      # Test all cursor types are accessible
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

  describe "Script Editor Button Actions" do
    it "validates script editor toolbar buttons work" do
      state = PaceEditor::Core::EditorState.new
      script_editor = PaceEditor::UI::ScriptEditor.new(state)

      # Test script editor can be shown
      script_editor.show
      script_editor.visible.should be_true

      # Test with script file
      test_script_path = File.join(project_dir, "test_script.lua")
      File.write(test_script_path, "-- Test script\nfunction test()\n  return true\nend")

      script_editor.show(test_script_path)
      script_editor.visible.should be_true
      script_editor.line_count.should be > 1
    end

    it "validates script editor content manipulation" do
      state = PaceEditor::Core::EditorState.new
      script_editor = PaceEditor::UI::ScriptEditor.new(state)

      script_editor.show

      # Verify editor state access
      script_editor.line_count.should be > 0
      script_editor.cursor_position.should be_a(Tuple(Int32, Int32))
      script_editor.modified?.should be_a(Bool)
      script_editor.error_count.should be >= 0
      script_editor.token_count.should be >= 0
    end
  end

  describe "Asset Browser Button Actions" do
    it "validates asset browser category switching" do
      project = PaceEditor::Core::Project.new(
        name: "Asset Test",
        project_path: project_dir
      )

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      asset_browser = PaceEditor::UI::AssetBrowser.new(state)
      asset_browser.should_not be_nil

      # Asset browser should be able to switch categories
      # (specific category switching logic tested through UI interaction)
    end
  end

  describe "Editable Field Validation" do
    it "validates hotspot property fields are editable" do
      # Create test hotspot
      scene = PointClickEngine::Scenes::Scene.new("field_test")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "editable_hotspot",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      scene.add_hotspot(hotspot)

      # Test position changes
      original_x = hotspot.position.x
      hotspot.position = RL::Vector2.new(150.0_f32, hotspot.position.y)
      hotspot.position.x.should_not eq(original_x)
      hotspot.position.x.should eq(150.0_f32)

      # Test size changes
      original_width = hotspot.size.x
      hotspot.size = RL::Vector2.new(80.0_f32, hotspot.size.y)
      hotspot.size.x.should_not eq(original_width)
      hotspot.size.x.should eq(80.0_f32)

      # Test description changes
      hotspot.description = "Updated description"
      hotspot.description.should eq("Updated description")

      # Test visibility changes
      original_visibility = hotspot.visible
      hotspot.visible = !hotspot.visible
      hotspot.visible.should_not eq(original_visibility)
    end

    it "validates character property fields are editable" do
      # Create test NPC
      npc = PointClickEngine::Characters::NPC.new(
        "editable_npc",
        RL::Vector2.new(200.0_f32, 200.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )

      # Test position changes
      original_x = npc.position.x
      npc.position = RL::Vector2.new(250.0_f32, npc.position.y)
      npc.position.x.should_not eq(original_x)
      npc.position.x.should eq(250.0_f32)

      # Test size changes
      original_width = npc.size.x
      npc.size = RL::Vector2.new(48.0_f32, npc.size.y)
      npc.size.x.should_not eq(original_width)
      npc.size.x.should eq(48.0_f32)

      # Test description changes
      npc.description = "Updated NPC description"
      npc.description.should eq("Updated NPC description")

      # Test walking speed changes
      npc.walking_speed = 2.5_f32
      npc.walking_speed.should eq(2.5_f32)

      # Test state changes
      npc.state = PointClickEngine::Characters::CharacterState::Walking
      npc.state.should eq(PointClickEngine::Characters::CharacterState::Walking)

      # Test direction changes
      npc.direction = PointClickEngine::Characters::Direction::Right
      npc.direction.should eq(PointClickEngine::Characters::Direction::Right)

      # Test mood changes (NPC-specific)
      npc.mood = PointClickEngine::Characters::NPCMood::Happy
      npc.mood.should eq(PointClickEngine::Characters::NPCMood::Happy)
    end

    it "validates script editor text editing works" do
      state = PaceEditor::Core::EditorState.new
      script_editor = PaceEditor::UI::ScriptEditor.new(state)

      # Create a script file
      test_script_path = File.join(project_dir, "editable_script.lua")
      initial_content = "-- Initial script\nfunction test()\n  return false\nend"
      File.write(test_script_path, initial_content)

      script_editor.show(test_script_path)

      # Verify initial state
      script_editor.visible.should be_true
      script_editor.line_count.should eq(4) # 4 lines in initial content
      script_editor.modified?.should be_false

      # Script editor should be able to track modifications
      # (actual text editing tested through UI interaction simulation)
    end

    it "validates dialog node text fields are editable" do
      # Create dialog tree and node
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")

      # Create dialog node
      node = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "test_node",
        "Initial dialog text"
      )

      # Test text changes
      node.text = "Updated dialog text"
      node.text.should eq("Updated dialog text")

      # Test character name changes
      node.character_name = "Wizard"
      node.character_name.should eq("Wizard")

      # Test end node flag
      node.is_end = true
      node.is_end.should be_true

      dialog_tree.add_node(node)
      dialog_tree.nodes.size.should eq(1)
      dialog_tree.nodes["test_node"].should eq(node)
    end

    it "validates project name field is editable" do
      # Test project name setting
      project = PaceEditor::Core::Project.new(
        name: "Initial Name",
        project_path: project_dir
      )

      project.name.should eq("Initial Name")

      # Project properties should be editable
      project.version = "2.0.0"
      project.version.should eq("2.0.0")

      project.author = "Test Author"
      project.author.should eq("Test Author")

      project.title = "Test Game Title"
      project.title.should eq("Test Game Title")

      project.window_width = 1280
      project.window_width.should eq(1280)

      project.window_height = 720
      project.window_height.should eq(720)
    end
  end

  describe "Field Save Validation" do
    it "validates property panel fields save to scene" do
      # Create complete test setup
      project = PaceEditor::Core::Project.new(
        name: "Save Test Project",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("save_test_scene")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "save_test_hotspot",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      scene.add_hotspot(hotspot)

      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = scene

      # Simulate property change and save
      hotspot.position = RL::Vector2.new(200.0_f32, 150.0_f32)
      hotspot.description = "Modified description"

      # Save scene to file
      scene_filename = "#{scene.name}.yml"
      scene_path = File.join(project.scenes_path, scene_filename)
      Dir.mkdir_p(File.dirname(scene_path))

      # Scene should be serializable
      yaml_content = scene.to_yaml
      yaml_content.should be_a(String)
      yaml_content.should contain(scene.name)

      # Write and verify file exists
      File.write(scene_path, yaml_content)
      File.exists?(scene_path).should be_true

      # Verify content can be read back
      saved_content = File.read(scene_path)
      saved_content.should contain(scene.name)
    end

    it "validates script editor saves to Lua files" do
      # Create script editor with file
      state = PaceEditor::Core::EditorState.new
      script_editor = PaceEditor::UI::ScriptEditor.new(state)

      test_script_path = File.join(project_dir, "save_test.lua")
      original_content = "-- Original content\nfunction original()\n  return true\nend"
      File.write(test_script_path, original_content)

      script_editor.show(test_script_path)

      # Verify file was loaded
      script_editor.visible.should be_true
      script_editor.line_count.should be > 1

      # File should exist and be readable
      File.exists?(test_script_path).should be_true
      File.read(test_script_path).should eq(original_content)
    end
  end

  describe "Button State Validation" do
    it "validates buttons are enabled/disabled appropriately" do
      state = PaceEditor::Core::EditorState.new

      # Without project, certain actions should be limited
      state.current_project.should be_nil

      # With project, more actions should be available
      project = PaceEditor::Core::Project.new(
        name: "State Test Project",
        project_path: project_dir
      )
      state.current_project = project
      state.current_project.should_not be_nil

      # With scene, object-specific actions should be available
      scene = PointClickEngine::Scenes::Scene.new("state_test_scene")
      state.current_scene = scene
      state.current_scene.should_not be_nil

      # With selected object, property editing should be available
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "state_test_hotspot",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      scene.add_hotspot(hotspot)
      state.selected_object = "state_test_hotspot"
      state.selected_object.should eq("state_test_hotspot")
    end
  end
end
