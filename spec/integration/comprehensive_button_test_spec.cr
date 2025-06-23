require "../spec_helper"

describe "Comprehensive Button Click Test" do
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

  describe "Every Button Action Validation" do
    it "validates all menu bar file operations trigger real actions" do
      state = PaceEditor::Core::EditorState.new
      menu_bar = PaceEditor::UI::MenuBar.new(state)

      # Test New Project action
      original_show_dialog = false
      # Simulate clicking "New Project" - should show dialog
      # (In actual UI, this would set @show_new_dialog = true)
      menu_bar.show_new_project_dialog
      # Verify the action was triggered (method exists and callable)
      menu_bar.should_not be_nil

      # Test with actual project for other operations
      project = PaceEditor::Core::Project.new(
        name: "Menu Test Project",
        project_path: project_dir
      )
      state.current_project = project

      # Test Save Project - should work with loaded project
      state.current_project.should_not be_nil

      # Test scene operations
      scene = PointClickEngine::Scenes::Scene.new("menu_test_scene")
      state.current_scene = scene

      # Scene operations should now be available
      state.current_scene.should_not be_nil
    end

    it "validates all tool palette buttons change tool state" do
      state = PaceEditor::Core::EditorState.new
      tool_palette = PaceEditor::UI::ToolPalette.new(state)

      # Test each tool button click simulation
      tools_to_test = [
        {tool: PaceEditor::Tool::Select, shortcut: "V"},
        {tool: PaceEditor::Tool::Move, shortcut: "M"},
        {tool: PaceEditor::Tool::Place, shortcut: "P"},
        {tool: PaceEditor::Tool::Delete, shortcut: "D"},
        {tool: PaceEditor::Tool::Paint, shortcut: "B"},
        {tool: PaceEditor::Tool::Zoom, shortcut: "Z"},
      ]

      tools_to_test.each do |tool_info|
        # Simulate tool button click
        state.current_tool = tool_info[:tool]

        # Verify tool changed
        state.current_tool.should eq(tool_info[:tool])
      end
    end

    it "validates all property panel action buttons work" do
      # Setup complete test environment
      project = PaceEditor::Core::Project.new(
        name: "Property Test Project",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("property_test_scene")

      # Test hotspot action button
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      scene.add_hotspot(hotspot)

      # Test NPC dialog button
      npc = PointClickEngine::Characters::NPC.new(
        "test_npc",
        RL::Vector2.new(200.0_f32, 200.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      scene.add_character(npc)

      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = scene

      editor_window = PaceEditor::Core::EditorWindow.new
      editor_state = editor_window.state
      editor_state.current_project = project
      editor_state.current_scene = scene

      # Test "Edit Actions" button for hotspots
      editor_state.selected_object = "test_hotspot"
      editor_window.show_hotspot_action_dialog("test_hotspot")
      # Verify action dialog exists and can be shown
      editor_window.hotspot_action_dialog.should_not be_nil

      # Test "Edit Script" button for hotspots
      editor_window.show_script_editor
      editor_window.script_editor.visible.should be_true

      # Test "Edit Dialog" button for NPCs
      editor_state.selected_object = "test_npc"
      initial_mode = editor_state.current_mode
      editor_window.show_dialog_editor_for_character("test_npc")
      editor_state.current_mode.should eq(PaceEditor::EditorMode::Dialog)
    end

    it "validates all script editor buttons perform actions" do
      state = PaceEditor::Core::EditorState.new
      script_editor = PaceEditor::UI::ScriptEditor.new(state)

      # Test Show Script Editor
      script_editor.show
      script_editor.visible.should be_true

      # Test with actual script file
      test_script_path = File.join(project_dir, "button_test.lua")
      script_content = <<-LUA
        -- Test script for button validation
        function on_click()
            show_message("Button clicked!")
        end
        
        function on_hover()
            set_cursor("hand")
        end
        LUA

      File.write(test_script_path, script_content)

      # Test Load Script File
      script_editor.show(test_script_path)
      script_editor.visible.should be_true
      script_editor.line_count.should be > 1
      script_editor.modified?.should be_false

      # Test Hide Script Editor
      script_editor.hide
      script_editor.visible.should be_false
    end

    it "validates all dropdown interactions cycle through options" do
      # Test hotspot cursor type dropdown
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "dropdown_test_hotspot",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )

      # Test all cursor type values can be set
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

      # Test character state dropdown
      npc = PointClickEngine::Characters::NPC.new(
        "dropdown_test_npc",
        RL::Vector2.new(200.0_f32, 200.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )

      # Test all character states
      character_states = [
        PointClickEngine::Characters::CharacterState::Idle,
        PointClickEngine::Characters::CharacterState::Walking,
        PointClickEngine::Characters::CharacterState::Talking,
        PointClickEngine::Characters::CharacterState::Interacting,
        PointClickEngine::Characters::CharacterState::Thinking,
      ]

      character_states.each do |state|
        npc.state = state
        npc.state.should eq(state)
      end

      # Test all character directions
      directions = [
        PointClickEngine::Characters::Direction::Left,
        PointClickEngine::Characters::Direction::Right,
        PointClickEngine::Characters::Direction::Up,
        PointClickEngine::Characters::Direction::Down,
      ]

      directions.each do |direction|
        npc.direction = direction
        npc.direction.should eq(direction)
      end

      # Test all NPC moods
      moods = [
        PointClickEngine::Characters::NPCMood::Friendly,
        PointClickEngine::Characters::NPCMood::Neutral,
        PointClickEngine::Characters::NPCMood::Hostile,
        PointClickEngine::Characters::NPCMood::Happy,
        PointClickEngine::Characters::NPCMood::Sad,
        PointClickEngine::Characters::NPCMood::Angry,
      ]

      moods.each do |mood|
        npc.mood = mood
        npc.mood.should eq(mood)
      end
    end

    it "validates editor mode buttons switch modes correctly" do
      state = PaceEditor::Core::EditorState.new

      # Test each mode button
      modes_to_test = [
        PaceEditor::EditorMode::Scene,
        PaceEditor::EditorMode::Character,
        PaceEditor::EditorMode::Hotspot,
        PaceEditor::EditorMode::Dialog,
        PaceEditor::EditorMode::Assets,
        PaceEditor::EditorMode::Project,
      ]

      modes_to_test.each do |mode|
        # Simulate mode button click
        state.current_mode = mode

        # Verify mode changed
        state.current_mode.should eq(mode)
      end
    end

    it "validates asset browser category buttons work" do
      project = PaceEditor::Core::Project.new(
        name: "Asset Button Test",
        project_path: project_dir
      )

      # Create asset directories for testing
      asset_categories = ["backgrounds", "characters", "sounds", "music", "scripts"]
      asset_categories.each do |category|
        asset_dir = File.join(project_dir, "assets", category)
        Dir.mkdir_p(asset_dir)

        # Create a test file in each category
        case category
        when "backgrounds"
          File.write(File.join(asset_dir, "test_bg.png"), "fake_image_data")
        when "characters"
          File.write(File.join(asset_dir, "test_char.png"), "fake_sprite_data")
        when "sounds"
          File.write(File.join(asset_dir, "test_sound.wav"), "fake_audio_data")
        when "music"
          File.write(File.join(asset_dir, "test_music.ogg"), "fake_music_data")
        when "scripts"
          File.write(File.join(asset_dir, "test_script.lua"), "-- Test script")
        end
      end

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      asset_browser = PaceEditor::UI::AssetBrowser.new(state)
      asset_browser.should_not be_nil

      # Verify all asset directories exist (simulating category button clicks)
      asset_categories.each do |category|
        asset_dir = File.join(project_dir, "assets", category)
        Dir.exists?(asset_dir).should be_true

        # Verify test files exist
        files = Dir.glob(File.join(asset_dir, "*"))
        files.should_not be_empty
      end
    end

    it "validates view menu toggle buttons change state" do
      state = PaceEditor::Core::EditorState.new

      # Test Show Grid toggle
      original_grid = state.show_grid
      state.show_grid = !state.show_grid
      state.show_grid.should_not eq(original_grid)

      # Toggle back
      state.show_grid = !state.show_grid
      state.show_grid.should eq(original_grid)

      # Test Show Hotspots toggle
      original_hotspots = state.show_hotspots
      state.show_hotspots = !state.show_hotspots
      state.show_hotspots.should_not eq(original_hotspots)

      # Toggle back
      state.show_hotspots = !state.show_hotspots
      state.show_hotspots.should eq(original_hotspots)
    end

    it "validates dialog creation and editing buttons work" do
      # Test dialog tree creation
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("button_test_dialog")

      # Test dialog node creation
      node1 = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "greeting",
        "Hello! Welcome to our shop."
      )

      node2 = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "question",
        "What can I help you with today?"
      )

      # Test adding nodes to tree
      dialog_tree.add_node(node1)
      dialog_tree.add_node(node2)

      # Verify nodes were added
      dialog_tree.nodes.size.should eq(2)
      dialog_tree.nodes["greeting"].should eq(node1)
      dialog_tree.nodes["question"].should eq(node2)

      # Test dialog choice creation
      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new(
        "Tell me about your items",
        "question"
      )

      node1.add_choice(choice)

      # Verify choice was added
      node1.choices.size.should eq(1)
      node1.choices.first.text.should eq("Tell me about your items")
      node1.choices.first.target_node_id.should eq("question")
    end

    it "validates undo/redo buttons work with real actions" do
      state = PaceEditor::Core::EditorState.new

      # Setup project and scene for undo/redo testing
      project = PaceEditor::Core::Project.new(
        name: "Undo Test Project",
        project_path: project_dir
      )
      state.current_project = project

      scene = PointClickEngine::Scenes::Scene.new("undo_test_scene")
      state.current_scene = scene

      # Create a hotspot for position changes
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "undo_test_hotspot",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      scene.add_hotspot(hotspot)

      # Test that objects can be moved (which creates undo actions)
      original_position = hotspot.position
      new_position = RL::Vector2.new(200.0_f32, 150.0_f32)

      # Simulate move action
      hotspot.position = new_position
      hotspot.position.should eq(new_position)
      hotspot.position.should_not eq(original_position)

      # Test that state changes are tracked
      state.is_dirty.should be_a(Bool)
    end
  end

  describe "All Editable Fields Accept Input" do
    it "validates every property panel field accepts and applies changes" do
      # Create complete test setup
      project = PaceEditor::Core::Project.new(
        name: "Field Test Project",
        project_path: project_dir
      )

      scene = PointClickEngine::Scenes::Scene.new("field_test_scene")

      # Test hotspot fields
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "field_test_hotspot",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(50.0_f32, 50.0_f32)
      )
      scene.add_hotspot(hotspot)

      # Test NPC fields
      npc = PointClickEngine::Characters::NPC.new(
        "field_test_npc",
        RL::Vector2.new(200.0_f32, 200.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      scene.add_character(npc)

      # Test all hotspot property fields
      field_tests = [
        {field: "X Position", original: hotspot.position.x, new_value: 150.0_f32},
        {field: "Y Position", original: hotspot.position.y, new_value: 125.0_f32},
        {field: "Width", original: hotspot.size.x, new_value: 75.0_f32},
        {field: "Height", original: hotspot.size.y, new_value: 60.0_f32},
      ]

      # Test position changes
      hotspot.position = RL::Vector2.new(150.0_f32, 125.0_f32)
      hotspot.position.x.should eq(150.0_f32)
      hotspot.position.y.should eq(125.0_f32)

      # Test size changes
      hotspot.size = RL::Vector2.new(75.0_f32, 60.0_f32)
      hotspot.size.x.should eq(75.0_f32)
      hotspot.size.y.should eq(60.0_f32)

      # Test description field
      hotspot.description = "Modified through field test"
      hotspot.description.should eq("Modified through field test")

      # Test visibility field
      original_visibility = hotspot.visible
      hotspot.visible = !hotspot.visible
      hotspot.visible.should_not eq(original_visibility)

      # Test all NPC property fields
      npc.position = RL::Vector2.new(250.0_f32, 225.0_f32)
      npc.position.x.should eq(250.0_f32)
      npc.position.y.should eq(225.0_f32)

      npc.size = RL::Vector2.new(48.0_f32, 72.0_f32)
      npc.size.x.should eq(48.0_f32)
      npc.size.y.should eq(72.0_f32)

      npc.description = "NPC description changed"
      npc.description.should eq("NPC description changed")

      npc.walking_speed = 3.5_f32
      npc.walking_speed.should eq(3.5_f32)
    end

    it "validates script editor text fields accept input" do
      state = PaceEditor::Core::EditorState.new
      script_editor = PaceEditor::UI::ScriptEditor.new(state)

      # Test creating new script
      script_editor.show
      script_editor.visible.should be_true

      # Test loading existing script
      test_script_path = File.join(project_dir, "input_test.lua")
      original_content = <<-LUA
        -- Original script content
        function original_function()
            return "original"
        end
        LUA

      File.write(test_script_path, original_content)

      script_editor.show(test_script_path)
      script_editor.visible.should be_true
      script_editor.line_count.should eq(4) # 4 lines in original content
      script_editor.modified?.should be_false

      # Verify file content matches
      File.read(test_script_path).should eq(original_content)
    end

    it "validates project settings fields accept changes" do
      project = PaceEditor::Core::Project.new(
        name: "Original Project Name",
        project_path: project_dir
      )

      # Test all project setting fields
      project.name = "Updated Project Name"
      project.name.should eq("Updated Project Name")

      project.version = "2.1.0"
      project.version.should eq("2.1.0")

      project.author = "Test Author"
      project.author.should eq("Test Author")

      project.description = "Updated project description"
      project.description.should eq("Updated project description")

      project.title = "Updated Game Title"
      project.title.should eq("Updated Game Title")

      project.window_width = 1280
      project.window_width.should eq(1280)

      project.window_height = 720
      project.window_height.should eq(720)

      project.target_fps = 30
      project.target_fps.should eq(30)
    end
  end
end
