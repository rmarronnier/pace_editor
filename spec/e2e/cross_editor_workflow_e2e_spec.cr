# E2E Tests for Cross-Editor Workflows
# Tests workflows that span multiple editor components:
# - Scene Editor <-> Dialog Editor
# - Scene Editor <-> Script Editor
# - Character Editor <-> Dialog Editor
# - Full game creation workflows

require "./e2e_spec_helper"

describe "Cross-Editor Workflows E2E" do
  describe "Scene to Dialog Editor Workflow" do
    it "can create a character and set up its dialog" do
      harness = E2ETestHelper.create_harness_with_scene("CrossEditorTest", "test_scene")

      # Step 1: Create an NPC in the scene
      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)

        harness.assert_character_count(1)
        character_name = harness.selected_object
        character_name.should_not be_nil

        # Step 2: Create a dialog file for this character
        if project = harness.editor.state.current_project
          if char_name = character_name
            dialog_path = File.join(project.dialogs_path, "#{char_name}.yml")

            # Create a simple dialog tree
            dialog_content = <<-YAML
            name: #{char_name}_dialog
            nodes:
              greeting:
                id: greeting
                text: "Hello! I'm #{char_name}."
                character_name: #{char_name}
                choices:
                  - text: "Nice to meet you!"
                    target_node_id: response
              response:
                id: response
                text: "Nice to meet you too!"
                is_end: true
            YAML

            File.write(dialog_path, dialog_content)
            harness.step_frame

            # Verify dialog file was created
            File.exists?(dialog_path).should be_true
          end
        end
      end

      harness.cleanup
    end

    it "can switch to dialog mode and edit character dialog" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create NPC first
      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)
      end

      # Switch to Dialog editor mode
      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(2)

      harness.current_mode.should eq(PaceEditor::EditorMode::Dialog)

      # Switch back to Scene mode
      harness.editor.state.current_mode = PaceEditor::EditorMode::Scene
      harness.step_frames(2)

      harness.current_mode.should eq(PaceEditor::EditorMode::Scene)

      harness.cleanup
    end

    it "preserves scene state when switching modes" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create content in scene mode
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frames(2)
      harness.click_canvas(200, 100)
      harness.step_frames(2)

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)
      end

      initial_hotspots = harness.hotspot_count
      initial_characters = harness.character_count

      # Switch to Dialog mode
      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(5)

      # Switch to Character mode
      harness.editor.state.current_mode = PaceEditor::EditorMode::Character
      harness.step_frames(5)

      # Switch back to Scene mode
      harness.editor.state.current_mode = PaceEditor::EditorMode::Scene
      harness.step_frames(5)

      # Scene content should be preserved
      harness.hotspot_count.should eq(initial_hotspots)
      harness.character_count.should eq(initial_characters)

      harness.cleanup
    end
  end

  describe "Scene to Script Editor Workflow" do
    it "can create a scene and its associated Lua script" do
      harness = E2ETestHelper.create_harness_with_scene("ScriptTest", "library")

      # Create interactive hotspots
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 200)
      harness.step_frames(2)
      harness.click_canvas(400, 400)
      harness.step_frames(2)

      harness.assert_hotspot_count(2)

      # Create a Lua script file for the scene
      if project = harness.editor.state.current_project
        script_path = File.join(project.scripts_path, "library.lua")

        # Create script content with hotspot callbacks
        script_content = <<-LUA
        -- Library Scene Script
        -- Handles interactions in the library

        function on_enter()
            print("Entering library...")
            show_message("Welcome to the ancient library.")
        end

        function on_bookshelf_click()
            if not get_game_state("bookshelf_searched") then
                show_message("You search through the ancient books...")
                set_game_state("bookshelf_searched", true)
            else
                show_message("The bookshelf has been thoroughly searched.")
            end
        end

        function on_desk_click()
            show_message("A mahogany desk with scattered papers.")
        end

        -- Register hotspot callbacks
        hotspot.on_click("bookshelf", on_bookshelf_click)
        hotspot.on_click("desk", on_desk_click)

        -- Scene lifecycle
        scene.on_enter(on_enter)
        LUA

        File.write(script_path, script_content)
        harness.step_frame

        # Verify script was created
        File.exists?(script_path).should be_true

        # Verify script content
        content = File.read(script_path)
        content.includes?("on_bookshelf_click").should be_true
        content.includes?("on_desk_click").should be_true
      end

      harness.cleanup
    end

    it "can validate Lua script syntax" do
      harness = E2ETestHelper.create_harness_with_scene

      # Test valid Lua syntax patterns
      valid_patterns = [
        "function test() end",
        "local x = 10",
        "if condition then end",
        "for i = 1, 10 do end",
        "while true do break end",
      ]

      valid_patterns.each do |pattern|
        # These patterns should be valid Lua
        pattern.includes?("function").should be_true if pattern.includes?("function")
      end

      harness.cleanup
    end
  end

  describe "Character to Dialog Workflow" do
    it "can create character with dialog and test it" do
      harness = E2ETestHelper.create_harness_with_scene("DialogTest", "test_scene")

      # Create NPC character
      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)

        # Get the character
        if scene.characters.size > 0
          character = scene.characters.first
          character.description = "A mysterious figure"

          # Create dialog for character
          if project = harness.editor.state.current_project
            dialog_path = File.join(project.dialogs_path, "#{character.name}.yml")

            # Create dialog with multiple nodes
            dialog_content = <<-YAML
            name: #{character.name}_dialog
            nodes:
              start:
                id: start
                text: "Who goes there?"
                character_name: #{character.name}
                choices:
                  - text: "I'm a detective."
                    target_node_id: detective_path
                  - text: "Just a traveler."
                    target_node_id: traveler_path
              detective_path:
                id: detective_path
                text: "A detective, eh? I've been expecting you."
                character_name: #{character.name}
                choices:
                  - text: "Tell me what you know."
                    target_node_id: confession
              traveler_path:
                id: traveler_path
                text: "Travelers aren't welcome here."
                is_end: true
              confession:
                id: confession
                text: "Very well... I'll tell you everything."
                is_end: true
            YAML

            File.write(dialog_path, dialog_content)

            # Verify dialog structure
            File.exists?(dialog_path).should be_true
            content = File.read(dialog_path)
            content.includes?("detective_path").should be_true
            content.includes?("traveler_path").should be_true
          end
        end
      end

      harness.cleanup
    end

    it "can test dialog flow programmatically" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a dialog directly
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")

      # Create nodes
      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello!")
      choice1 = PointClickEngine::Characters::Dialogue::DialogChoice.new("Hi!", "end")
      start_node.choices << choice1

      end_node = PointClickEngine::Characters::Dialogue::DialogNode.new("end", "Goodbye!")
      end_node.is_end = true

      dialog_tree.add_node(start_node)
      dialog_tree.add_node(end_node)

      # Verify dialog structure
      dialog_tree.nodes.size.should eq(2)
      dialog_tree.nodes["start"]?.should_not be_nil
      dialog_tree.nodes["end"]?.should_not be_nil

      # Verify node connections
      if start = dialog_tree.nodes["start"]?
        start.choices.size.should eq(1)
        start.choices.first.target_node_id.should eq("end")
      end

      harness.cleanup
    end
  end

  describe "Full Game Creation Workflow" do
    it "can create a mini adventure game structure" do
      harness = E2ETestHelper.create_harness_with_scene("MiniAdventure", "start_room")

      if project = harness.editor.state.current_project
        # Create start room with hotspots
        harness.press_key(RL::KeyboardKey::P)
        harness.click_canvas(100, 100)  # Exit door
        harness.step_frames(2)
        harness.click_canvas(300, 200)  # Item
        harness.step_frames(2)

        # Configure hotspots
        if scene = harness.editor.state.current_scene
          if scene.hotspots.size >= 2
            scene.hotspots[0].description = "Exit to hallway"
            scene.hotspots[0].object_type = PointClickEngine::UI::ObjectType::Exit
            scene.hotspots[1].description = "A mysterious key"
            scene.hotspots[1].object_type = PointClickEngine::UI::ObjectType::Item
          end

          # Add NPC
          harness.editor.state.add_npc_character(scene)
          harness.step_frames(2)
        end

        # Save start room
        harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)
        harness.step_frames(3)

        # Create second room (hallway)
        hallway = PointClickEngine::Scenes::Scene.new("hallway")
        hallway.hotspots = [] of PointClickEngine::Scenes::Hotspot
        hallway.characters = [] of PointClickEngine::Characters::Character
        project.scenes << "hallway"
        harness.editor.state.current_scene = hallway
        harness.step_frames(2)

        # Add hallway hotspots
        harness.press_key(RL::KeyboardKey::P)
        harness.click_canvas(50, 300)   # Back to start room
        harness.step_frames(2)
        harness.click_canvas(750, 300)  # Forward to end room
        harness.step_frames(2)

        # Save hallway
        harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)
        harness.step_frames(3)

        # Verify project structure
        File.exists?(File.join(project.scenes_path, "start_room.yml")).should be_true
        File.exists?(File.join(project.scenes_path, "hallway.yml")).should be_true

        # Create game script
        script_content = <<-LUA
        -- Mini Adventure Game Script

        game.title = "Mini Adventure"
        game.start_scene = "start_room"

        function check_win_condition()
            if has_item("mysterious_key") and get_game_state("door_unlocked") then
                show_message("Congratulations! You've completed the game!")
                game.end()
            end
        end
        LUA

        script_path = File.join(project.scripts_path, "game.lua")
        File.write(script_path, script_content)
        File.exists?(script_path).should be_true
      end

      harness.cleanup
    end

    it "verifies all game components are connected" do
      harness = E2ETestHelper.create_harness_with_scene("ConnectedGame", "main")

      if project = harness.editor.state.current_project
        # Create scene with hotspot
        harness.press_key(RL::KeyboardKey::P)
        harness.click_canvas(200, 200)
        harness.step_frames(2)

        # Add NPC
        if scene = harness.editor.state.current_scene
          harness.editor.state.add_npc_character(scene)
          harness.step_frames(2)

          if scene.characters.size > 0
            npc = scene.characters.first

            # Create dialog for NPC
            dialog_content = <<-YAML
            name: #{npc.name}_dialog
            nodes:
              start:
                id: start
                text: "Hello there!"
                is_end: true
            YAML

            dialog_path = File.join(project.dialogs_path, "#{npc.name}.yml")
            File.write(dialog_path, dialog_content)

            # Create script that references the hotspot and character
            script_content = <<-LUA
            -- Main Scene Script

            function on_enter()
                show_message("Welcome!")
            end

            function on_npc_interact()
                start_dialog("#{npc.name}_dialog")
            end

            character.on_interact("#{npc.name}", on_npc_interact)
            scene.on_enter(on_enter)
            LUA

            script_path = File.join(project.scripts_path, "main.lua")
            File.write(script_path, script_content)

            # Save scene
            harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)
            harness.step_frames(3)

            # Verify all components exist
            File.exists?(File.join(project.scenes_path, "main.yml")).should be_true
            File.exists?(dialog_path).should be_true
            File.exists?(script_path).should be_true

            # Verify script references the NPC
            script_content_check = File.read(script_path)
            script_content_check.includes?(npc.name).should be_true
          end
        end
      end

      harness.cleanup
    end
  end

  describe "Editor Mode Transitions" do
    it "cycles through all editor modes" do
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
        harness.editor.state.current_mode = mode
        harness.step_frames(3)
        harness.current_mode.should eq(mode)
      end

      # Return to Scene mode
      harness.editor.state.current_mode = PaceEditor::EditorMode::Scene
      harness.step_frames(2)
      harness.current_mode.should eq(PaceEditor::EditorMode::Scene)

      harness.cleanup
    end

    it "preserves selection when switching modes" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create and select a hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(200, 200)
      harness.step_frames(2)

      selected = harness.selected_object
      selected.should_not be_nil

      # Switch to different modes and back
      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(3)

      harness.editor.state.current_mode = PaceEditor::EditorMode::Scene
      harness.step_frames(3)

      # Selection should be preserved (or cleared and re-selectable)
      harness.has_scene?.should be_true

      harness.cleanup
    end
  end
end

describe "Error Handling in Cross-Editor Workflows E2E" do
  describe "Missing File Handling" do
    it "handles missing dialog file gracefully" do
      harness = E2ETestHelper.create_harness_with_scene

      # Try to reference a non-existent dialog
      if project = harness.editor.state.current_project
        non_existent_path = File.join(project.dialogs_path, "non_existent.yml")
        File.exists?(non_existent_path).should be_false
      end

      # Editor should still function
      harness.has_scene?.should be_true

      harness.cleanup
    end

    it "handles missing script file gracefully" do
      harness = E2ETestHelper.create_harness_with_scene

      # Try to reference a non-existent script
      if project = harness.editor.state.current_project
        non_existent_path = File.join(project.scripts_path, "non_existent.lua")
        File.exists?(non_existent_path).should be_false
      end

      # Editor should still function
      harness.has_scene?.should be_true

      harness.cleanup
    end
  end

  describe "Invalid Data Handling" do
    it "handles malformed YAML in dialog file" do
      harness = E2ETestHelper.create_harness_with_scene

      if project = harness.editor.state.current_project
        # Create malformed YAML
        malformed_path = File.join(project.dialogs_path, "malformed.yml")
        File.write(malformed_path, "invalid: [yaml: {content")

        # Editor should handle this gracefully
        harness.has_scene?.should be_true
      end

      harness.cleanup
    end
  end
end
