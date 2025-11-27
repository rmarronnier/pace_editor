require "./e2e_spec_helper"

# Complex Interaction E2E Tests
# Tests advanced workflows involving multiple steps, undo/redo, and complex state management

describe "Complex Interactions E2E Tests" do
  describe "Undo/Redo Workflow" do
    it "tracks dirty state through multiple edits" do
      harness = E2ETestHelper.create_harness_with_scene

      # Start clean
      harness.editor.state.clear_dirty
      harness.is_dirty?.should be_false

      # Make multiple edits
      3.times do |i|
        if scene = harness.editor.state.current_scene
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "undo_test_#{i}",
            RL::Vector2.new(x: (i * 100).to_f32, y: 100.0_f32),
            RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
          )
          scene.hotspots << hotspot
          harness.editor.state.mark_dirty
        end
      end

      harness.is_dirty?.should be_true
      harness.hotspot_count.should eq(3)
    end

    it "can clear dirty state after save" do
      harness = E2ETestHelper.create_harness_with_scene

      # Make changes
      harness.editor.state.mark_dirty
      harness.is_dirty?.should be_true

      # Simulate save
      harness.editor.state.clear_dirty
      harness.is_dirty?.should be_false
    end

    it "maintains dirty state across mode switches" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.mark_dirty
      harness.is_dirty?.should be_true

      # Switch modes
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      harness.is_dirty?.should be_true

      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)
      harness.is_dirty?.should be_true

      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)
      harness.is_dirty?.should be_true
    end
  end

  describe "Multi-Selection Workflow" do
    it "selects multiple hotspots" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create multiple hotspots
      if scene = harness.editor.state.current_scene
        3.times do |i|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "multi_select_#{i}",
            RL::Vector2.new(x: (i * 100).to_f32, y: 100.0_f32),
            RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
          )
          scene.hotspots << hotspot
        end
      end

      # Select multiple
      harness.editor.state.selected_hotspots << "multi_select_0"
      harness.editor.state.selected_hotspots << "multi_select_1"

      harness.editor.state.selected_hotspots.size.should eq(2)
      harness.is_selected?("multi_select_0").should be_true
      harness.is_selected?("multi_select_1").should be_true
      harness.is_selected?("multi_select_2").should be_false
    end

    it "selects multiple characters" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create multiple characters
      if scene = harness.editor.state.current_scene
        3.times do |i|
          npc = PointClickEngine::Characters::NPC.new(
            "multi_char_#{i}",
            RL::Vector2.new(x: (i * 100).to_f32, y: 200.0_f32),
            RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
          )
          scene.characters << npc
        end
      end

      # Select multiple
      harness.editor.state.selected_characters << "multi_char_0"
      harness.editor.state.selected_characters << "multi_char_2"

      harness.editor.state.selected_characters.size.should eq(2)
      harness.is_selected?("multi_char_0").should be_true
      harness.is_selected?("multi_char_2").should be_true
    end

    it "clears selection" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create and select
      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "clear_test",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene.hotspots << hotspot
      end

      harness.editor.state.selected_hotspots << "clear_test"
      harness.editor.state.selected_hotspots.size.should eq(1)

      # Clear selection
      harness.editor.state.selected_hotspots.clear
      harness.editor.state.selected_hotspots.size.should eq(0)
    end

    it "handles mixed hotspot and character selection" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Add hotspot
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "mixed_hotspot",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene.hotspots << hotspot

        # Add character
        npc = PointClickEngine::Characters::NPC.new(
          "mixed_char",
          RL::Vector2.new(x: 200.0_f32, y: 200.0_f32),
          RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
        )
        scene.characters << npc
      end

      # Select both types
      harness.editor.state.selected_hotspots << "mixed_hotspot"
      harness.editor.state.selected_characters << "mixed_char"

      harness.selected_objects.size.should eq(2)
      harness.is_selected?("mixed_hotspot").should be_true
      harness.is_selected?("mixed_char").should be_true
    end
  end

  describe "Complex Scene Building" do
    it "builds a room with multiple interactive elements" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Add furniture hotspots
        furniture = [
          {name: "bookshelf", x: 50, y: 100, w: 80, h: 150},
          {name: "desk", x: 200, y: 150, w: 100, h: 60},
          {name: "chair", x: 220, y: 180, w: 40, h: 40},
          {name: "window", x: 400, y: 50, w: 80, h: 100},
          {name: "door", x: 600, y: 100, w: 60, h: 120},
        ]

        furniture.each do |item|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            item[:name],
            RL::Vector2.new(x: item[:x].to_f32, y: item[:y].to_f32),
            RL::Vector2.new(x: item[:w].to_f32, y: item[:h].to_f32)
          )
          scene.hotspots << hotspot
        end

        # Add NPCs
        npc = PointClickEngine::Characters::NPC.new(
          "librarian",
          RL::Vector2.new(x: 100.0_f32, y: 250.0_f32),
          RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
        )
        scene.characters << npc

        scene.hotspots.size.should eq(5)
        scene.characters.size.should eq(1)
      end
    end

    it "builds an outdoor scene with multiple zones" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Exit hotspots to other scenes
        exits = [
          {name: "north_exit", x: 400, y: 0, w: 200, h: 50},
          {name: "south_exit", x: 400, y: 550, w: 200, h: 50},
          {name: "east_exit", x: 750, y: 250, w: 50, h: 200},
          {name: "west_exit", x: 0, y: 250, w: 50, h: 200},
        ]

        exits.each do |exit|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            exit[:name],
            RL::Vector2.new(x: exit[:x].to_f32, y: exit[:y].to_f32),
            RL::Vector2.new(x: exit[:w].to_f32, y: exit[:h].to_f32)
          )
          scene.hotspots << hotspot
        end

        # Interactive objects
        objects = [
          {name: "fountain", x: 350, y: 200, w: 100, h: 100},
          {name: "bench", x: 200, y: 350, w: 80, h: 40},
          {name: "tree", x: 550, y: 150, w: 60, h: 120},
        ]

        objects.each do |obj|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            obj[:name],
            RL::Vector2.new(x: obj[:x].to_f32, y: obj[:y].to_f32),
            RL::Vector2.new(x: obj[:w].to_f32, y: obj[:h].to_f32)
          )
          scene.hotspots << hotspot
        end

        # NPCs in the area
        npcs = [
          {name: "guard", x: 100, y: 300},
          {name: "merchant", x: 500, y: 400},
          {name: "child", x: 380, y: 320},
        ]

        npcs.each do |npc_data|
          npc = PointClickEngine::Characters::NPC.new(
            npc_data[:name],
            RL::Vector2.new(x: npc_data[:x].to_f32, y: npc_data[:y].to_f32),
            RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
          )
          scene.characters << npc
        end

        scene.hotspots.size.should eq(7)
        scene.characters.size.should eq(3)
      end
    end
  end

  describe "Dialog Tree Complexity" do
    it "creates branching dialog with multiple choices" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)

      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      # Create a branching conversation
      dialog_editor.create_node_for_test("greeting", "Hello traveler! What brings you to our village?")
      dialog_editor.create_node_for_test("ask_directions", "I'm looking for the old ruins.")
      dialog_editor.create_node_for_test("ask_shop", "Where can I buy supplies?")
      dialog_editor.create_node_for_test("ask_news", "Any news from the capital?")
      dialog_editor.create_node_for_test("directions_response", "The ruins are north of here, past the forest.")
      dialog_editor.create_node_for_test("shop_response", "The general store is just down the road.")
      dialog_editor.create_node_for_test("news_response", "I heard the king is preparing for war...")
      dialog_editor.create_node_for_test("goodbye", "Safe travels, stranger!")

      dialog_tree = dialog_editor.dialog_tree
      # Should have initial node + 8 we created
      dialog_tree.nodes.size.should be >= 8
    end

    it "creates deep dialog chain" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)

      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      # Create a long conversation chain
      5.times do |i|
        dialog_editor.create_node_for_test(
          "chain_#{i}",
          "This is dialog node #{i} in the chain."
        )
      end

      dialog_tree = dialog_editor.dialog_tree
      dialog_tree.nodes.size.should be >= 5
    end

    it "handles dialog with conditional branches" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)

      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      # Create dialog with different paths
      dialog_editor.create_node_for_test("start", "Do you have the key?")
      dialog_editor.create_node_for_test("has_key", "Ah, excellent! Please enter.")
      dialog_editor.create_node_for_test("no_key", "Sorry, you cannot enter without a key.")
      dialog_editor.create_node_for_test("where_key", "You can find a key at the blacksmith.")

      dialog_tree = dialog_editor.dialog_tree
      dialog_tree.nodes.size.should be >= 4
    end
  end

  describe "Project-Wide Operations" do
    it "creates project with multiple scenes" do
      harness = E2ETestHelper.create_harness_with_project("MultiSceneProject")

      if project = harness.editor.state.current_project
        initial_count = project.scenes.size

        # Create several scenes
        scenes_to_create = ["intro", "village", "forest", "dungeon", "boss_room", "ending"]

        scenes_to_create.each do |scene_name|
          scene = PointClickEngine::Scenes::Scene.new(scene_name)
          project.scenes << scene_name
          PaceEditor::IO::SceneIO.save_scene(scene, File.join(project.scenes_path, "#{scene_name}.yml"))
        end

        project.scenes.size.should eq(initial_count + scenes_to_create.size)
      end
    end

    it "switches between multiple scenes preserving state" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        # Create two scenes with different content
        scene1 = PointClickEngine::Scenes::Scene.new("scene_a")
        hotspot1 = PointClickEngine::Scenes::Hotspot.new(
          "scene_a_hotspot",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene1.hotspots << hotspot1

        scene2 = PointClickEngine::Scenes::Scene.new("scene_b")
        hotspot2 = PointClickEngine::Scenes::Hotspot.new(
          "scene_b_hotspot",
          RL::Vector2.new(x: 200.0_f32, y: 200.0_f32),
          RL::Vector2.new(x: 60.0_f32, y: 60.0_f32)
        )
        scene2.hotspots << hotspot2

        # Save both scenes
        project.scenes << "scene_a"
        project.scenes << "scene_b"
        PaceEditor::IO::SceneIO.save_scene(scene1, File.join(project.scenes_path, "scene_a.yml"))
        PaceEditor::IO::SceneIO.save_scene(scene2, File.join(project.scenes_path, "scene_b.yml"))

        # Switch between scenes
        harness.editor.state.current_scene = scene1
        harness.hotspot_count.should eq(1)
        harness.scene_name.should eq("scene_a")

        harness.editor.state.current_scene = scene2
        harness.hotspot_count.should eq(1)
        harness.scene_name.should eq("scene_b")

        # Switch back
        harness.editor.state.current_scene = scene1
        harness.scene_name.should eq("scene_a")
      end
    end

    it "validates project structure" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        # Verify all required paths exist
        Dir.exists?(project.assets_path).should be_true
        Dir.exists?(project.scenes_path).should be_true
        Dir.exists?(project.scripts_path).should be_true
        Dir.exists?(project.dialogs_path).should be_true

        # Add content and verify persistence
        scene = PointClickEngine::Scenes::Scene.new("validation_test")
        scene_path = File.join(project.scenes_path, "validation_test.yml")
        PaceEditor::IO::SceneIO.save_scene(scene, scene_path)

        File.exists?(scene_path).should be_true
      end
    end
  end

  describe "Mode Transition Workflows" do
    it "transitions through all modes in sequence" do
      harness = E2ETestHelper.create_harness_with_scene

      modes = [
        PaceEditor::EditorMode::Scene,
        PaceEditor::EditorMode::Character,
        PaceEditor::EditorMode::Hotspot,
        PaceEditor::EditorMode::Dialog,
        PaceEditor::EditorMode::Assets,
        PaceEditor::EditorMode::Script,
        PaceEditor::EditorMode::Project,
      ]

      modes.each do |mode|
        E2EUIHelpers.click_mode_button(harness, mode)
        harness.current_mode.should eq(mode)
      end
    end

    it "preserves camera state across mode changes" do
      harness = E2ETestHelper.create_harness_with_scene

      # Set camera position
      harness.editor.state.camera_x = 250.0_f32
      harness.editor.state.camera_y = 150.0_f32
      harness.editor.state.zoom = 1.5_f32

      # Switch modes
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)

      # Camera should be preserved
      pos = harness.camera_position
      pos[:x].should eq(250.0_f32)
      pos[:y].should eq(150.0_f32)
      harness.zoom.should eq(1.5_f32)
    end

    it "mode switch triggers UI state update" do
      harness = E2ETestHelper.create_harness_with_scene

      # Track mode switch
      harness.ui_state.track_mode_switch(PaceEditor::EditorMode::Character)

      harness.ui_state.last_mode_switch.should_not be_nil
      harness.ui_state.recent_actions.any? { |a| a.includes?("mode_switch") }.should be_true
    end
  end

  describe "Tool and Selection Interaction" do
    it "tool change affects subsequent operations" do
      harness = E2ETestHelper.create_harness_with_scene

      # Start with select tool
      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Select)
      harness.current_tool.should eq(PaceEditor::Tool::Select)

      # Change to move tool
      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Move)
      harness.current_tool.should eq(PaceEditor::Tool::Move)

      # Change to place tool
      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Place)
      harness.current_tool.should eq(PaceEditor::Tool::Place)
    end

    it "selection persists through tool changes" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create and select a hotspot
      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "persist_test",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene.hotspots << hotspot
      end

      harness.editor.state.selected_hotspots << "persist_test"

      # Change tools
      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Move)
      harness.is_selected?("persist_test").should be_true

      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Delete)
      harness.is_selected?("persist_test").should be_true
    end
  end

  describe "Hotspot Action Configuration" do
    it "configures hotspot with show message action" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "message_hotspot",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene.hotspots << hotspot
      end

      # Open action dialog
      dialog = harness.editor.hotspot_action_dialog
      dialog.show_for_test("message_hotspot")
      dialog.visible?.should be_true

      # Set action type
      dialog.set_action_type_for_test(PaceEditor::Models::HotspotAction::ActionType::ShowMessage)
      dialog.new_action_type.should eq(PaceEditor::Models::HotspotAction::ActionType::ShowMessage)
    end

    it "configures hotspot with scene change action" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "door_hotspot",
          RL::Vector2.new(x: 500.0_f32, y: 200.0_f32),
          RL::Vector2.new(x: 60.0_f32, y: 120.0_f32)
        )
        scene.hotspots << hotspot
      end

      # Open action dialog
      dialog = harness.editor.hotspot_action_dialog
      dialog.show_for_test("door_hotspot")

      # Set action type to scene change
      dialog.set_action_type_for_test(PaceEditor::Models::HotspotAction::ActionType::ChangeScene)
      dialog.new_action_type.should eq(PaceEditor::Models::HotspotAction::ActionType::ChangeScene)
    end

    it "supports multiple action types on different events" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspot
      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "multi_action_hotspot",
          RL::Vector2.new(x: 300.0_f32, y: 150.0_f32),
          RL::Vector2.new(x: 80.0_f32, y: 80.0_f32)
        )
        scene.hotspots << hotspot
      end

      dialog = harness.editor.hotspot_action_dialog
      dialog.show_for_test("multi_action_hotspot")

      # Default event should be on_click
      dialog.selected_event.should eq("on_click")

      # Can set different action type
      dialog.set_action_type_for_test(PaceEditor::Models::HotspotAction::ActionType::PlaySound)
      dialog.new_action_type.should eq(PaceEditor::Models::HotspotAction::ActionType::PlaySound)
    end
  end

  describe "Complex Export Scenarios" do
    it "validates project before export" do
      harness = E2ETestHelper.create_harness_with_scene

      # Add some content
      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "export_test_hotspot",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene.hotspots << hotspot
      end

      # Open export dialog
      export_dialog = harness.editor.game_export_dialog
      export_dialog.show

      # Run validation
      export_dialog.set_validate_project_for_test(true)
      export_dialog.trigger_validation_for_test

      results = export_dialog.validation_results_for_test
      results.should be_a(Array(String))
    end

    it "configures export with all options" do
      harness = E2ETestHelper.create_harness_with_project

      export_dialog = harness.editor.game_export_dialog
      export_dialog.show

      # Set all options
      export_dialog.set_export_name_for_test("MyGame_Release")
      export_dialog.set_export_format_for_test("standalone")
      export_dialog.set_include_source_for_test(false)
      export_dialog.set_compress_assets_for_test(true)
      export_dialog.set_validate_project_for_test(true)

      # Verify all options
      export_dialog.export_name_for_test.should eq("MyGame_Release")
      export_dialog.export_format_for_test.should eq("standalone")
      export_dialog.include_source_for_test.should be_false
      export_dialog.compress_assets_for_test.should be_true
      export_dialog.validate_project_for_test.should be_true
    end

    it "export dialog tracks progress state" do
      harness = E2ETestHelper.create_harness_with_project

      export_dialog = harness.editor.game_export_dialog
      export_dialog.show

      # Initially not exporting
      export_dialog.is_exporting_for_test.should be_false
      export_dialog.export_progress_for_test.should eq(0.0_f32)
    end
  end

  describe "UI State Hints and Guidance" do
    it "shows hints for new users" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.show_hints = true

      hint = PaceEditor::UI::UIHint.new(
        "welcome_hint",
        "Welcome to PACE Editor! Start by creating a scene.",
        PaceEditor::UI::UIHintType::Info
      )
      harness.ui_state.add_hint(hint)

      harness.ui_state.hint_queue.size.should eq(1)
    end

    it "tracks tutorial completion" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.mark_tutorial_completed("scene_creation")
      harness.ui_state.mark_tutorial_completed("hotspot_basics")

      harness.ui_state.is_tutorial_completed?("scene_creation").should be_true
      harness.ui_state.is_tutorial_completed?("hotspot_basics").should be_true
      harness.ui_state.is_tutorial_completed?("advanced_scripting").should be_false
    end

    it "provides contextual suggestions" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.ui_state.update_project_progress(harness.editor.state)

      suggestion = harness.ui_state.get_next_suggested_action(harness.editor.state)
      # May return nil or a suggestion string
      if suggestion
        suggestion.should be_a(String)
      end
    end
  end

  describe "Power Mode Features" do
    it "enables all advanced features in power mode" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.power_mode.should be_false

      harness.ui_state.enable_power_mode

      harness.ui_state.power_mode.should be_true
      harness.ui_state.show_advanced_tools.should be_true
    end

    it "power mode shows all editor modes" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.enable_power_mode

      modes = harness.ui_state.get_available_modes(harness.editor.state)

      # Should have all modes available
      modes.size.should eq(PaceEditor::EditorMode.values.size)
    end

    it "can toggle power mode on and off" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.power_mode.should be_false

      harness.ui_state.toggle_power_mode
      harness.ui_state.power_mode.should be_true

      harness.ui_state.toggle_power_mode
      harness.ui_state.power_mode.should be_false
    end
  end

  describe "Tooltip System" do
    it "shows and hides tooltips" do
      harness = E2ETestHelper.create_harness_with_project

      harness.ui_state.has_active_tooltip?.should be_false

      harness.ui_state.show_tooltip("Click to select", RL::Vector2.new(x: 100.0_f32, y: 100.0_f32))

      harness.ui_state.has_active_tooltip?.should be_true
      harness.ui_state.active_tooltip.should eq("Click to select")

      harness.ui_state.hide_tooltip

      harness.ui_state.has_active_tooltip?.should be_false
    end

    it "tooltip position is tracked" do
      harness = E2ETestHelper.create_harness_with_project

      pos = RL::Vector2.new(x: 250.0_f32, y: 150.0_f32)
      harness.ui_state.show_tooltip("Test tooltip", pos)

      harness.ui_state.tooltip_position.should_not be_nil
    end
  end

  describe "Progressive UI Disclosure" do
    it "reveals features based on project state" do
      harness = E2ETestHelper.create_harness_with_project

      # Without scene, some features may be hidden
      visibility_no_scene = harness.ui_state.get_component_visibility("scene_editor", harness.editor.state)

      # Create a scene
      if project = harness.editor.state.current_project
        scene = PointClickEngine::Scenes::Scene.new("progressive_test")
        project.scenes << "progressive_test"
        PaceEditor::IO::SceneIO.save_scene(scene, File.join(project.scenes_path, "progressive_test.yml"))
        harness.editor.state.current_scene = scene
      end

      # With scene, scene editor should be visible
      visibility_with_scene = harness.ui_state.get_component_visibility("scene_editor", harness.editor.state)
      visibility_with_scene.should eq(PaceEditor::UI::ComponentState::Visible)
    end

    it "can override component visibility" do
      harness = E2ETestHelper.create_harness_with_scene

      # Override to hidden
      harness.ui_state.override_component_visibility("scene_editor", PaceEditor::UI::ComponentState::Hidden)

      visibility = harness.ui_state.get_component_visibility("scene_editor", harness.editor.state)
      visibility.should eq(PaceEditor::UI::ComponentState::Hidden)

      # Clear override
      harness.ui_state.clear_visibility_override("scene_editor")

      visibility = harness.ui_state.get_component_visibility("scene_editor", harness.editor.state)
      visibility.should eq(PaceEditor::UI::ComponentState::Visible)
    end
  end
end
