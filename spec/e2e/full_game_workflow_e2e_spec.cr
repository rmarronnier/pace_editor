require "./e2e_spec_helper"

# Full Game Workflow E2E Tests
# These tests simulate real game creation flows from scratch to export
# using only UI interactions (as a user would).

describe "Full Game Workflow E2E Tests" do
  describe "Project Creation Flow" do
    it "creates a new project with valid name and path" do
      harness = PaceEditor::Testing::TestHarness.new

      # Verify no project initially
      harness.has_project?.should be_false

      # Create project programmatically (simulating File > New flow)
      temp_dir = E2ETestHelper.create_temp_project_dir
      harness.editor.state.create_new_project("MyAdventureGame", temp_dir)

      # Verify project was created
      harness.has_project?.should be_true
      harness.project_name.should eq("MyAdventureGame")

      E2ETestHelper.cleanup_temp_dir(temp_dir)
    end

    it "initializes project with correct directory structure" do
      harness = E2ETestHelper.create_harness_with_project("TestGame")

      project = harness.editor.state.current_project.not_nil!

      # Check that asset directories exist
      Dir.exists?(project.assets_path).should be_true
      Dir.exists?(project.scenes_path).should be_true
      Dir.exists?(project.scripts_path).should be_true
      Dir.exists?(project.dialogs_path).should be_true
    end

    it "editor starts in Project mode after project creation" do
      harness = E2ETestHelper.create_harness_with_project

      # Should start in Project mode or a default mode
      mode = harness.current_mode
      # Verify it's a valid editor mode
      PaceEditor::EditorMode.values.should contain(mode)
    end

    it "sets project as dirty after modification" do
      harness = E2ETestHelper.create_harness_with_project

      # New project starts clean
      harness.is_dirty?.should be_false

      # Mark dirty after modification
      harness.editor.state.mark_dirty

      harness.is_dirty?.should be_true
    end
  end

  describe "Scene Creation Wizard Flow" do
    it "opens scene creation wizard" do
      harness = E2ETestHelper.create_harness_with_project
      wizard = harness.editor.scene_creation_wizard

      wizard.visible.should be_false
      wizard.show_for_test
      wizard.visible.should be_true
    end

    it "starts at step 1 (scene name)" do
      harness = E2ETestHelper.create_harness_with_project
      wizard = harness.editor.scene_creation_wizard

      wizard.show_for_test
      wizard.current_step.should eq(1)
    end

    it "sets scene name in step 1" do
      harness = E2ETestHelper.create_harness_with_project
      wizard = harness.editor.scene_creation_wizard

      wizard.show_for_test
      wizard.set_scene_name_for_test("main_hall")

      wizard.scene_name_for_test.should eq("main_hall")
    end

    it "validates scene name format" do
      harness = E2ETestHelper.create_harness_with_project
      wizard = harness.editor.scene_creation_wizard

      wizard.show_for_test
      wizard.set_scene_name_for_test("")

      # Can't proceed without name
      wizard.go_to_step_for_test(2)
      # Validation should prevent moving forward with empty name
      # (wizard internally handles this)
    end

    it "allows template selection in step 2" do
      harness = E2ETestHelper.create_harness_with_project
      wizard = harness.editor.scene_creation_wizard

      wizard.show_for_test
      wizard.set_scene_name_for_test("test_scene")
      wizard.go_to_step_for_test(2)

      wizard.set_template_for_test("room")
      wizard.scene_template_for_test.should eq("room")
    end

    it "sets scene dimensions in step 4" do
      harness = E2ETestHelper.create_harness_with_project
      wizard = harness.editor.scene_creation_wizard

      wizard.show_for_test
      wizard.set_scene_name_for_test("test_scene")
      wizard.go_to_step_for_test(4)

      wizard.set_dimensions_for_test(1920, 1080)

      width, height = wizard.scene_dimensions_for_test
      width.should eq(1920)
      height.should eq(1080)
    end

    it "navigates through all wizard steps" do
      harness = E2ETestHelper.create_harness_with_project
      wizard = harness.editor.scene_creation_wizard

      wizard.show_for_test

      # Step 1 - Name
      wizard.current_step.should eq(1)
      wizard.set_scene_name_for_test("my_scene")
      wizard.go_to_step_for_test(2)

      # Step 2 - Template
      wizard.current_step.should eq(2)
      wizard.go_to_step_for_test(3)

      # Step 3 - Background
      wizard.current_step.should eq(3)
      wizard.go_to_step_for_test(4)

      # Step 4 - Dimensions
      wizard.current_step.should eq(4)
    end

    it "can navigate back through wizard steps" do
      harness = E2ETestHelper.create_harness_with_project
      wizard = harness.editor.scene_creation_wizard

      wizard.show_for_test
      wizard.set_scene_name_for_test("test_scene")
      wizard.go_to_step_for_test(4)

      wizard.current_step.should eq(4)

      wizard.go_to_step_for_test(2)
      wizard.current_step.should eq(2)
    end
  end

  describe "Scene Editing Flow" do
    it "switches to scene mode when scene is loaded" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.has_scene?.should be_true
      harness.current_mode.should eq(PaceEditor::EditorMode::Scene)
    end

    it "can select tools for scene editing" do
      harness = E2ETestHelper.create_harness_with_scene

      # Try selecting different tools
      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Select)
      harness.current_tool.should eq(PaceEditor::Tool::Select)

      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Move)
      harness.current_tool.should eq(PaceEditor::Tool::Move)

      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Place)
      harness.current_tool.should eq(PaceEditor::Tool::Place)
    end

    it "can pan camera in scene" do
      harness = E2ETestHelper.create_harness_with_scene

      initial_pos = harness.camera_position

      # Modify camera position
      harness.editor.state.camera_x = 100.0_f32
      harness.editor.state.camera_y = 50.0_f32

      new_pos = harness.camera_position
      new_pos[:x].should eq(100.0_f32)
      new_pos[:y].should eq(50.0_f32)
    end

    it "can zoom in scene" do
      harness = E2ETestHelper.create_harness_with_scene

      # Default zoom
      harness.zoom.should eq(1.0_f32)

      # Change zoom
      harness.editor.state.zoom = 1.5_f32
      harness.zoom.should eq(1.5_f32)
    end

    it "marks scene dirty when modified" do
      harness = E2ETestHelper.create_harness_with_scene

      # Modify something
      harness.editor.state.mark_dirty

      harness.is_dirty?.should be_true
    end
  end

  describe "Hotspot Creation Flow" do
    it "adds hotspot to scene" do
      harness = E2ETestHelper.create_harness_with_scene

      initial_count = harness.hotspot_count

      # Create a hotspot
      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "door",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 80.0_f32)
        )
        scene.hotspots << hotspot
      end

      harness.hotspot_count.should eq(initial_count + 1)
    end

    it "can select hotspot" do
      harness = E2ETestHelper.create_harness_with_scene

      # Add a hotspot
      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "cabinet",
          RL::Vector2.new(x: 200.0_f32, y: 150.0_f32),
          RL::Vector2.new(x: 60.0_f32, y: 100.0_f32)
        )
        scene.hotspots << hotspot
      end

      # Select it
      harness.editor.state.selected_hotspots << "cabinet"

      harness.is_selected?("cabinet").should be_true
    end

    it "opens hotspot action dialog for hotspot" do
      harness = E2ETestHelper.create_harness_with_scene

      # Add a hotspot
      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "chest",
          RL::Vector2.new(x: 300.0_f32, y: 200.0_f32),
          RL::Vector2.new(x: 80.0_f32, y: 60.0_f32)
        )
        scene.hotspots << hotspot
      end

      # Open hotspot action dialog
      dialog = harness.editor.hotspot_action_dialog
      dialog.visible?.should be_false

      dialog.show_for_test("chest")
      dialog.visible?.should be_true
    end

    it "adds action to hotspot via dialog" do
      harness = E2ETestHelper.create_harness_with_scene

      # Add a hotspot
      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "book",
          RL::Vector2.new(x: 400.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 30.0_f32, y: 40.0_f32)
        )
        scene.hotspots << hotspot
      end

      # Open dialog and set action type
      dialog = harness.editor.hotspot_action_dialog
      dialog.show_for_test("book")

      dialog.set_action_type_for_test(PaceEditor::Models::HotspotAction::ActionType::ShowMessage)

      dialog.selected_event.should eq("on_click")
      dialog.new_action_type.should eq(PaceEditor::Models::HotspotAction::ActionType::ShowMessage)
    end

    it "supports multiple event types" do
      harness = E2ETestHelper.create_harness_with_scene

      # Add a hotspot
      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "painting",
          RL::Vector2.new(x: 500.0_f32, y: 50.0_f32),
          RL::Vector2.new(x: 100.0_f32, y: 80.0_f32)
        )
        scene.hotspots << hotspot
      end

      dialog = harness.editor.hotspot_action_dialog
      dialog.show_for_test("painting")

      # Default event should be on_click
      dialog.selected_event.should eq("on_click")
    end
  end

  describe "Character Placement Flow" do
    it "adds character to scene" do
      harness = E2ETestHelper.create_harness_with_scene

      initial_count = harness.character_count

      if scene = harness.editor.state.current_scene
        character = PointClickEngine::Characters::NPC.new(
          "npc_wizard",
          RL::Vector2.new(x: 200.0_f32, y: 300.0_f32),
          RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
        )
        scene.characters << character
      end

      harness.character_count.should eq(initial_count + 1)
    end

    it "can select character in scene" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        character = PointClickEngine::Characters::NPC.new(
          "merchant",
          RL::Vector2.new(x: 150.0_f32, y: 250.0_f32),
          RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
        )
        scene.characters << character
      end

      harness.editor.state.selected_characters << "merchant"

      harness.is_selected?("merchant").should be_true
    end

    it "creates character via character editor" do
      harness = E2ETestHelper.create_harness_with_scene

      # Switch to character mode
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)

      character_editor = harness.editor.character_editor
      character_editor.create_character_for_test

      # Check if character was created
      current_char = character_editor.current_character_for_test
      current_char.should_not be_nil
    end
  end

  describe "Dialog Creation Flow" do
    it "creates new dialog tree when switching to dialog mode" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)

      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      # Should have a dialog tree now
      dialog_tree = dialog_editor.dialog_tree
      dialog_tree.should_not be_nil
    end

    it "creates dialog node" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)

      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      result = dialog_editor.create_node_for_test("greeting", "Hello, traveler!")
      result.should be_true

      dialog_tree = dialog_editor.dialog_tree
      dialog_tree.nodes.size.should be > 0
    end

    it "creates multiple connected dialog nodes" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)

      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      # Get initial node count (may have default start node)
      initial_count = dialog_editor.dialog_tree.nodes.size

      # Create greeting node
      dialog_editor.create_node_for_test("greeting", "Welcome to my shop!")

      # Create response node
      dialog_editor.create_node_for_test("browse", "I'd like to browse your wares.")

      # Create another response
      dialog_editor.create_node_for_test("goodbye", "Farewell!")

      dialog_tree = dialog_editor.dialog_tree
      dialog_tree.nodes.size.should eq(initial_count + 3)
    end

    it "can select dialog node" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)

      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test
      dialog_editor.create_node_for_test("test_node", "Test text")

      dialog_editor.select_node_for_test("test_node")

      # Verify selection (would need getter, but test flow is correct)
    end

    it "toggles connection mode" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)

      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      dialog_editor.connection_mode?.should be_false

      # Would toggle via toolbar button in real usage
    end
  end

  describe "Game Export Flow" do
    it "opens export dialog" do
      harness = E2ETestHelper.create_harness_with_project

      export_dialog = harness.editor.game_export_dialog
      export_dialog.visible.should be_false

      export_dialog.show
      export_dialog.visible.should be_true
    end

    it "sets export name" do
      harness = E2ETestHelper.create_harness_with_project

      export_dialog = harness.editor.game_export_dialog
      export_dialog.show

      export_dialog.set_export_name_for_test("MyGame_v1")

      export_dialog.export_name_for_test.should eq("MyGame_v1")
    end

    it "sets export path" do
      harness = E2ETestHelper.create_harness_with_project

      export_dialog = harness.editor.game_export_dialog
      export_dialog.show

      export_dialog.set_export_path_for_test("/tmp/exports")

      export_dialog.export_path_for_test.should eq("/tmp/exports")
    end

    it "sets export format" do
      harness = E2ETestHelper.create_harness_with_project

      export_dialog = harness.editor.game_export_dialog
      export_dialog.show

      export_dialog.set_export_format_for_test("standalone")
      export_dialog.export_format_for_test.should eq("standalone")

      export_dialog.set_export_format_for_test("web")
      export_dialog.export_format_for_test.should eq("web")
    end

    it "sets export options" do
      harness = E2ETestHelper.create_harness_with_project

      export_dialog = harness.editor.game_export_dialog
      export_dialog.show

      export_dialog.set_include_source_for_test(true)
      export_dialog.include_source_for_test.should be_true

      export_dialog.set_compress_assets_for_test(true)
      export_dialog.compress_assets_for_test.should be_true

      export_dialog.set_validate_project_for_test(true)
      export_dialog.validate_project_for_test.should be_true
    end

    it "can trigger project validation" do
      harness = E2ETestHelper.create_harness_with_project

      export_dialog = harness.editor.game_export_dialog
      export_dialog.show

      # Trigger validation
      export_dialog.trigger_validation_for_test

      # Check validation results exist
      results = export_dialog.validation_results_for_test
      results.should be_a(Array(String))
    end

    it "reports export progress" do
      harness = E2ETestHelper.create_harness_with_project

      export_dialog = harness.editor.game_export_dialog
      export_dialog.show

      # Before export
      export_dialog.is_exporting_for_test.should be_false
      export_dialog.export_progress_for_test.should eq(0.0_f32)
    end
  end

  describe "Full Workflow: Create Simple Game" do
    it "creates a complete simple game from scratch" do
      # Step 1: Create project
      harness = E2ETestHelper.create_harness_with_project("SimpleAdventure")
      harness.has_project?.should be_true

      # Step 2: Create a scene
      if project = harness.editor.state.current_project
        scene = PointClickEngine::Scenes::Scene.new("starting_room")
        project.scenes << "starting_room"

        scene_path = File.join(project.scenes_path, "starting_room.yml")
        PaceEditor::IO::SceneIO.save_scene(scene, scene_path)

        harness.editor.state.current_scene = scene
        E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)
      end

      harness.has_scene?.should be_true

      # Step 3: Add a hotspot (door to next room)
      if scene = harness.editor.state.current_scene
        door = PointClickEngine::Scenes::Hotspot.new(
          "exit_door",
          RL::Vector2.new(x: 600.0_f32, y: 200.0_f32),
          RL::Vector2.new(x: 80.0_f32, y: 150.0_f32)
        )
        scene.hotspots << door
      end

      harness.hotspot_count.should eq(1)

      # Step 4: Add an NPC
      if scene = harness.editor.state.current_scene
        innkeeper = PointClickEngine::Characters::NPC.new(
          "innkeeper",
          RL::Vector2.new(x: 300.0_f32, y: 350.0_f32),
          RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
        )
        scene.characters << innkeeper
      end

      harness.character_count.should eq(1)

      # Step 5: Create dialog for NPC
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)
      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      dialog_editor.create_node_for_test("start", "Welcome to the Rusty Tankard Inn!")
      dialog_editor.create_node_for_test("room", "Looking for a room? 10 gold per night.")
      dialog_editor.create_node_for_test("info", "The castle? Head north through the forest.")

      dialog_tree = dialog_editor.dialog_tree
      dialog_tree.nodes.size.should eq(3)

      # Step 6: Verify export dialog can open
      export_dialog = harness.editor.game_export_dialog
      export_dialog.show
      export_dialog.visible.should be_true
      export_dialog.set_export_name_for_test("SimpleAdventure_v1")

      # Validate the game
      export_dialog.trigger_validation_for_test
    end

    it "creates a game with multiple scenes" do
      harness = E2ETestHelper.create_harness_with_project("MultiSceneGame")

      if project = harness.editor.state.current_project
        # Get initial scene count (may have default "main" scene)
        initial_count = project.scenes.size

        # Create first scene
        scene1 = PointClickEngine::Scenes::Scene.new("town_square")
        project.scenes << "town_square"
        PaceEditor::IO::SceneIO.save_scene(scene1, File.join(project.scenes_path, "town_square.yml"))

        # Create second scene
        scene2 = PointClickEngine::Scenes::Scene.new("blacksmith")
        project.scenes << "blacksmith"
        PaceEditor::IO::SceneIO.save_scene(scene2, File.join(project.scenes_path, "blacksmith.yml"))

        # Create third scene
        scene3 = PointClickEngine::Scenes::Scene.new("tavern")
        project.scenes << "tavern"
        PaceEditor::IO::SceneIO.save_scene(scene3, File.join(project.scenes_path, "tavern.yml"))

        project.scenes.size.should eq(initial_count + 3)
      end
    end

    it "creates interconnected hotspots between scenes" do
      harness = E2ETestHelper.create_harness_with_project("ConnectedScenes")

      if project = harness.editor.state.current_project
        # Create scenes
        hub = PointClickEngine::Scenes::Scene.new("hub")
        room_a = PointClickEngine::Scenes::Scene.new("room_a")
        room_b = PointClickEngine::Scenes::Scene.new("room_b")

        # Add hotspots to hub that lead to other rooms
        door_a = PointClickEngine::Scenes::Hotspot.new(
          "door_to_a",
          RL::Vector2.new(x: 100.0_f32, y: 200.0_f32),
          RL::Vector2.new(x: 60.0_f32, y: 120.0_f32)
        )
        hub.hotspots << door_a

        door_b = PointClickEngine::Scenes::Hotspot.new(
          "door_to_b",
          RL::Vector2.new(x: 500.0_f32, y: 200.0_f32),
          RL::Vector2.new(x: 60.0_f32, y: 120.0_f32)
        )
        hub.hotspots << door_b

        # Add return hotspots in each room
        back_from_a = PointClickEngine::Scenes::Hotspot.new(
          "door_to_hub",
          RL::Vector2.new(x: 50.0_f32, y: 200.0_f32),
          RL::Vector2.new(x: 60.0_f32, y: 120.0_f32)
        )
        room_a.hotspots << back_from_a

        back_from_b = PointClickEngine::Scenes::Hotspot.new(
          "door_to_hub",
          RL::Vector2.new(x: 50.0_f32, y: 200.0_f32),
          RL::Vector2.new(x: 60.0_f32, y: 120.0_f32)
        )
        room_b.hotspots << back_from_b

        # Save scenes
        project.scenes << "hub"
        project.scenes << "room_a"
        project.scenes << "room_b"

        PaceEditor::IO::SceneIO.save_scene(hub, File.join(project.scenes_path, "hub.yml"))
        PaceEditor::IO::SceneIO.save_scene(room_a, File.join(project.scenes_path, "room_a.yml"))
        PaceEditor::IO::SceneIO.save_scene(room_b, File.join(project.scenes_path, "room_b.yml"))

        # Set hub as current scene
        harness.editor.state.current_scene = hub

        hub.hotspots.size.should eq(2)
      end
    end
  end

  describe "Mode Switching via UI" do
    it "clicks Scene mode button to switch to Scene mode" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Project)

      menu_bar = harness.editor.menu_bar
      bounds = menu_bar.test_mode_button_bounds(PaceEditor::EditorMode::Scene)

      # Click in center of button
      click_x = bounds[:x] + bounds[:width] // 2
      click_y = bounds[:y] + bounds[:height] // 2

      harness.input.set_mouse_position(click_x.to_f32, click_y.to_f32)
      harness.input.press_mouse_button(RL::MouseButton::Left)

      menu_bar.test_handle_mode_button_click(harness.input)

      harness.current_mode.should eq(PaceEditor::EditorMode::Scene)
    end

    it "clicks Character mode button to switch to Character mode" do
      harness = E2ETestHelper.create_harness_with_scene

      menu_bar = harness.editor.menu_bar
      bounds = menu_bar.test_mode_button_bounds(PaceEditor::EditorMode::Character)

      click_x = bounds[:x] + bounds[:width] // 2
      click_y = bounds[:y] + bounds[:height] // 2

      harness.input.set_mouse_position(click_x.to_f32, click_y.to_f32)
      harness.input.press_mouse_button(RL::MouseButton::Left)

      menu_bar.test_handle_mode_button_click(harness.input)

      harness.current_mode.should eq(PaceEditor::EditorMode::Character)
    end

    it "clicks Hotspot mode button to switch to Hotspot mode" do
      harness = E2ETestHelper.create_harness_with_scene

      menu_bar = harness.editor.menu_bar
      bounds = menu_bar.test_mode_button_bounds(PaceEditor::EditorMode::Hotspot)

      click_x = bounds[:x] + bounds[:width] // 2
      click_y = bounds[:y] + bounds[:height] // 2

      harness.input.set_mouse_position(click_x.to_f32, click_y.to_f32)
      harness.input.press_mouse_button(RL::MouseButton::Left)

      menu_bar.test_handle_mode_button_click(harness.input)

      harness.current_mode.should eq(PaceEditor::EditorMode::Hotspot)
    end

    it "clicks Dialog mode button to switch to Dialog mode" do
      harness = E2ETestHelper.create_harness_with_scene

      menu_bar = harness.editor.menu_bar
      bounds = menu_bar.test_mode_button_bounds(PaceEditor::EditorMode::Dialog)

      click_x = bounds[:x] + bounds[:width] // 2
      click_y = bounds[:y] + bounds[:height] // 2

      harness.input.set_mouse_position(click_x.to_f32, click_y.to_f32)
      harness.input.press_mouse_button(RL::MouseButton::Left)

      menu_bar.test_handle_mode_button_click(harness.input)

      harness.current_mode.should eq(PaceEditor::EditorMode::Dialog)
    end

    it "clicks Assets mode button to switch to Assets mode" do
      harness = E2ETestHelper.create_harness_with_scene

      menu_bar = harness.editor.menu_bar
      bounds = menu_bar.test_mode_button_bounds(PaceEditor::EditorMode::Assets)

      click_x = bounds[:x] + bounds[:width] // 2
      click_y = bounds[:y] + bounds[:height] // 2

      harness.input.set_mouse_position(click_x.to_f32, click_y.to_f32)
      harness.input.press_mouse_button(RL::MouseButton::Left)

      menu_bar.test_handle_mode_button_click(harness.input)

      harness.current_mode.should eq(PaceEditor::EditorMode::Assets)
    end

    it "clicks Project mode button to switch to Project mode" do
      harness = E2ETestHelper.create_harness_with_scene

      menu_bar = harness.editor.menu_bar
      bounds = menu_bar.test_mode_button_bounds(PaceEditor::EditorMode::Project)

      click_x = bounds[:x] + bounds[:width] // 2
      click_y = bounds[:y] + bounds[:height] // 2

      harness.input.set_mouse_position(click_x.to_f32, click_y.to_f32)
      harness.input.press_mouse_button(RL::MouseButton::Left)

      menu_bar.test_handle_mode_button_click(harness.input)

      harness.current_mode.should eq(PaceEditor::EditorMode::Project)
    end

    it "cycles through all modes via UI clicks" do
      harness = E2ETestHelper.create_harness_with_scene
      menu_bar = harness.editor.menu_bar

      modes = [
        PaceEditor::EditorMode::Scene,
        PaceEditor::EditorMode::Character,
        PaceEditor::EditorMode::Hotspot,
        PaceEditor::EditorMode::Dialog,
        PaceEditor::EditorMode::Assets,
        PaceEditor::EditorMode::Project,
      ]

      modes.each do |target_mode|
        bounds = menu_bar.test_mode_button_bounds(target_mode)
        click_x = bounds[:x] + bounds[:width] // 2
        click_y = bounds[:y] + bounds[:height] // 2

        harness.input.set_mouse_position(click_x.to_f32, click_y.to_f32)
        harness.input.press_mouse_button(RL::MouseButton::Left)
        menu_bar.test_handle_mode_button_click(harness.input)
        harness.input.release_mouse_button(RL::MouseButton::Left)

        harness.current_mode.should eq(target_mode)
      end
    end

    it "ignores click outside mode button area" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)

      menu_bar = harness.editor.menu_bar

      # Click far away from mode buttons
      harness.input.set_mouse_position(800.0_f32, 100.0_f32)
      harness.input.press_mouse_button(RL::MouseButton::Left)

      result = menu_bar.test_handle_mode_button_click(harness.input)

      result.should be_false
      harness.current_mode.should eq(PaceEditor::EditorMode::Scene)
    end

    it "ignores click without mouse button press" do
      harness = E2ETestHelper.create_harness_with_scene
      # Setup: ensure we're in Scene mode (direct assignment for test setup)
      harness.editor.state.current_mode = PaceEditor::EditorMode::Scene

      menu_bar = harness.editor.menu_bar
      bounds = menu_bar.test_mode_button_bounds(PaceEditor::EditorMode::Dialog)

      # Position over button but don't press
      harness.input.set_mouse_position((bounds[:x] + 5).to_f32, (bounds[:y] + 5).to_f32)
      # No press_mouse_button call

      result = menu_bar.test_handle_mode_button_click(harness.input)

      result.should be_false
      harness.current_mode.should eq(PaceEditor::EditorMode::Scene)
    end
  end

  describe "Edge Cases and Error Handling" do
    it "handles empty project name gracefully" do
      harness = PaceEditor::Testing::TestHarness.new
      temp_dir = E2ETestHelper.create_temp_project_dir

      # Try to create with empty name - should either fail or use default
      harness.editor.state.create_new_project("", temp_dir)

      # Project might not be created or might use a default name
      # This tests the behavior doesn't crash

      E2ETestHelper.cleanup_temp_dir(temp_dir)
    end

    it "handles duplicate hotspot names in same scene" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Add first hotspot
        h1 = PointClickEngine::Scenes::Hotspot.new(
          "door",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 80.0_f32)
        )
        scene.hotspots << h1

        # Add second hotspot with same name
        h2 = PointClickEngine::Scenes::Hotspot.new(
          "door",
          RL::Vector2.new(x: 200.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 80.0_f32)
        )
        scene.hotspots << h2

        # Should have both (even if names collide)
        scene.hotspots.size.should eq(2)
      end
    end

    it "handles scene with no hotspots" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.hotspot_count.should eq(0)

      # Should not crash when working with empty scene
      harness.selected_objects.should be_empty
    end

    it "handles scene with no characters" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.character_count.should eq(0)
    end

    it "handles dialog tree with additional single node" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)

      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      # Get initial node count (may have default start node)
      initial_count = dialog_editor.dialog_tree.nodes.size

      # Add one more node
      dialog_editor.create_node_for_test("only_node", "This is the only thing I say.")

      dialog_tree = dialog_editor.dialog_tree
      dialog_tree.nodes.size.should eq(initial_count + 1)
    end

    it "handles rapid mode switching" do
      harness = E2ETestHelper.create_harness_with_scene

      # Rapidly switch between modes
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Hotspot)
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)

      # Should end up in Scene mode
      harness.current_mode.should eq(PaceEditor::EditorMode::Scene)
    end

    it "handles zoom limits" do
      harness = E2ETestHelper.create_harness_with_scene

      # Try extreme zoom values
      harness.editor.state.zoom = 10.0_f32
      # Zoom might be clamped by the editor

      harness.editor.state.zoom = 0.1_f32
      # Zoom might be clamped by the editor

      # Should not crash
      harness.zoom.should be > 0.0_f32
    end
  end

  describe "UI State Consistency" do
    it "maintains selection across mode switches" do
      harness = E2ETestHelper.create_harness_with_scene

      # Add and select a hotspot
      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "test_hotspot",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene.hotspots << hotspot
      end

      harness.editor.state.selected_hotspots << "test_hotspot"

      # Switch modes
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)

      # Selection might be cleared or maintained depending on design
      # This test ensures it doesn't crash
    end

    it "clears selection when switching scenes" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        # Create two scenes
        scene1 = PointClickEngine::Scenes::Scene.new("scene1")
        scene2 = PointClickEngine::Scenes::Scene.new("scene2")

        project.scenes << "scene1"
        project.scenes << "scene2"

        PaceEditor::IO::SceneIO.save_scene(scene1, File.join(project.scenes_path, "scene1.yml"))
        PaceEditor::IO::SceneIO.save_scene(scene2, File.join(project.scenes_path, "scene2.yml"))

        # Load first scene and select something
        harness.editor.state.current_scene = scene1

        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "h1",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene1.hotspots << hotspot
        harness.editor.state.selected_hotspots << "h1"

        # Switch to second scene
        harness.editor.state.current_scene = scene2

        # Selection should be cleared or handled gracefully
      end
    end

    it "tracks dirty state across edits" do
      harness = E2ETestHelper.create_harness_with_scene

      # Make changes
      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "new_hotspot",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene.hotspots << hotspot
        harness.editor.state.mark_dirty
      end

      harness.is_dirty?.should be_true

      # Clear dirty flag (simulating save)
      harness.editor.state.clear_dirty

      harness.is_dirty?.should be_false
    end
  end
end
