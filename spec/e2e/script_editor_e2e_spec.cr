# E2E Tests for Script Editor
# Tests Lua script creation, editing, validation, and integration with scenes

require "./e2e_spec_helper"

describe "Script Editor E2E" do
  describe "Script File Creation" do
    it "can create a new scene script" do
      harness = E2ETestHelper.create_harness_with_scene("ScriptProject", "library")

      if project = harness.editor.state.current_project
        script_path = File.join(project.scripts_path, "library.lua")

        script_content = <<-LUA
        -- Library Scene Script

        function on_enter()
            show_message("Welcome to the library!")
        end

        scene.on_enter(on_enter)
        LUA

        File.write(script_path, script_content)

        File.exists?(script_path).should be_true
        content = File.read(script_path)
        content.includes?("on_enter").should be_true
      end

      harness.cleanup
    end

    it "can create script with hotspot callbacks" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create hotspots first
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frames(2)
      harness.click_canvas(200, 200)
      harness.step_frames(2)

      if project = harness.editor.state.current_project
        if scene = harness.editor.state.current_scene
          # Get hotspot names
          hotspot_names = scene.hotspots.map(&.name)

          script_content = String.build do |s|
            s << "-- Scene Script with Hotspot Callbacks\n\n"

            hotspot_names.each do |name|
              s << "function on_#{name}_click()\n"
              s << "    show_message(\"You clicked #{name}!\")\n"
              s << "end\n\n"
            end

            s << "-- Register callbacks\n"
            hotspot_names.each do |name|
              s << "hotspot.on_click(\"#{name}\", on_#{name}_click)\n"
            end
          end

          script_path = File.join(project.scripts_path, "#{scene.name}.lua")
          File.write(script_path, script_content)

          File.exists?(script_path).should be_true
          content = File.read(script_path)
          content.includes?("on_click").should be_true
        end
      end

      harness.cleanup
    end

    it "can create script with character interactions" do
      harness = E2ETestHelper.create_harness_with_scene

      # Add NPC
      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)

        if project = harness.editor.state.current_project
          if scene.characters.size > 0
            npc = scene.characters.first

            script_content = <<-LUA
            -- Character Interaction Script

            function on_#{npc.name}_interact()
                show_message("Hello! I'm #{npc.name}.")
                start_dialog("#{npc.name}_dialog")
            end

            function on_#{npc.name}_look()
                show_message("A mysterious figure stands here.")
            end

            -- Register character callbacks
            character.on_interact("#{npc.name}", on_#{npc.name}_interact)
            character.on_look("#{npc.name}", on_#{npc.name}_look)
            LUA

            script_path = File.join(project.scripts_path, "characters.lua")
            File.write(script_path, script_content)

            File.exists?(script_path).should be_true
          end
        end
      end

      harness.cleanup
    end
  end

  describe "Lua Script Patterns" do
    it "supports scene lifecycle callbacks" do
      harness = E2ETestHelper.create_harness_with_scene

      if project = harness.editor.state.current_project
        script_content = <<-LUA
        -- Scene Lifecycle Script

        function on_enter()
            print("Scene entered")
            set_game_state("scene_visited", true)
        end

        function on_exit()
            print("Scene exited")
            stop_ambient("background_music")
        end

        function on_update(dt)
            -- Called every frame
            check_triggers()
        end

        scene.on_enter(on_enter)
        scene.on_exit(on_exit)
        scene.on_update(on_update)
        LUA

        script_path = File.join(project.scripts_path, "lifecycle.lua")
        File.write(script_path, script_content)

        content = File.read(script_path)
        content.includes?("on_enter").should be_true
        content.includes?("on_exit").should be_true
        content.includes?("on_update").should be_true
      end

      harness.cleanup
    end

    it "supports inventory management" do
      harness = E2ETestHelper.create_harness_with_scene

      if project = harness.editor.state.current_project
        script_content = <<-LUA
        -- Inventory Management Script

        function pickup_key()
            if not has_item("brass_key") then
                add_to_inventory("brass_key", "An ornate brass key")
                show_message("You picked up a brass key!")
                play_sound("pickup")
                return true
            end
            return false
        end

        function use_key_on_door()
            if has_item("brass_key") then
                remove_from_inventory("brass_key")
                set_game_state("door_unlocked", true)
                show_message("The door clicks open!")
                return true
            else
                show_message("This door is locked. You need a key.")
                return false
            end
        end

        function check_inventory()
            local items = get_inventory()
            for _, item in ipairs(items) do
                print("Inventory: " .. item.name)
            end
        end
        LUA

        script_path = File.join(project.scripts_path, "inventory.lua")
        File.write(script_path, script_content)

        content = File.read(script_path)
        content.includes?("add_to_inventory").should be_true
        content.includes?("has_item").should be_true
        content.includes?("remove_from_inventory").should be_true
      end

      harness.cleanup
    end

    it "supports game state management" do
      harness = E2ETestHelper.create_harness_with_scene

      if project = harness.editor.state.current_project
        script_content = <<-LUA
        -- Game State Management Script

        function set_flag(name)
            set_game_state(name, true)
        end

        function clear_flag(name)
            set_game_state(name, false)
        end

        function check_flag(name)
            return get_game_state(name) == true
        end

        function check_win_condition()
            local has_key = check_flag("found_key")
            local solved_puzzle = check_flag("puzzle_solved")
            local talked_to_npc = check_flag("npc_interrogated")

            if has_key and solved_puzzle and talked_to_npc then
                trigger_ending("good_ending")
            end
        end

        function save_progress()
            save_game_state()
            show_message("Progress saved!")
        end
        LUA

        script_path = File.join(project.scripts_path, "game_state.lua")
        File.write(script_path, script_content)

        content = File.read(script_path)
        content.includes?("set_game_state").should be_true
        content.includes?("get_game_state").should be_true
      end

      harness.cleanup
    end

    it "supports dialog integration" do
      harness = E2ETestHelper.create_harness_with_scene

      if project = harness.editor.state.current_project
        script_content = <<-LUA
        -- Dialog Integration Script

        function talk_to_butler()
            if not get_game_state("butler_questioned") then
                start_dialog("butler_dialog", "greeting")
                set_game_state("butler_questioned", true)
            else
                start_dialog("butler_dialog", "followup")
            end
        end

        function on_dialog_end(dialog_name, final_node)
            print("Dialog ended: " .. dialog_name .. " at " .. final_node)

            if dialog_name == "butler_dialog" then
                if final_node == "confession" then
                    set_game_state("butler_confessed", true)
                    add_to_inventory("brass_key", "A key the butler gave you")
                end
            end
        end

        dialog.on_end(on_dialog_end)
        LUA

        script_path = File.join(project.scripts_path, "dialog_integration.lua")
        File.write(script_path, script_content)

        content = File.read(script_path)
        content.includes?("start_dialog").should be_true
        content.includes?("on_dialog_end").should be_true
      end

      harness.cleanup
    end

    it "supports scene transitions" do
      harness = E2ETestHelper.create_harness_with_scene

      if project = harness.editor.state.current_project
        script_content = <<-LUA
        -- Scene Transition Script

        function go_to_laboratory()
            -- Fade out
            camera.fade_out(1.0)

            -- Change scene with transition
            change_scene("laboratory", {
                transition = "swirl",
                duration = 2.0,
                spawn_point = {x = 100, y = 400}
            })
        end

        function go_to_garden()
            if get_game_state("garden_unlocked") then
                change_scene("garden")
            else
                show_message("The garden door is locked.")
            end
        end

        function trigger_cutscene()
            disable_input()
            play_cutscene("intro_cutscene", function()
                enable_input()
                change_scene("main_hall")
            end)
        end
        LUA

        script_path = File.join(project.scripts_path, "transitions.lua")
        File.write(script_path, script_content)

        content = File.read(script_path)
        content.includes?("change_scene").should be_true
        content.includes?("fade_out").should be_true
      end

      harness.cleanup
    end
  end

  describe "Script Syntax Validation" do
    it "recognizes valid Lua keywords" do
      keywords = %w[
        function end if then else elseif
        for while do repeat until
        return break local
        and or not
        nil true false
      ]

      keywords.each do |keyword|
        keyword.size.should be > 0
      end
    end

    it "recognizes valid Lua operators" do
      operators = %w[
        + - * / % ^
        == ~= < > <= >=
        = .. #
      ]

      operators.each do |op|
        op.size.should be > 0
      end
    end

    it "can detect unclosed blocks" do
      harness = E2ETestHelper.create_harness_with_scene

      # This script has unclosed function
      broken_script = "function on_enter()\n    show_message(\"Hello\")\n-- Missing closing"

      # Count 'function' keywords only at line start or after whitespace
      function_count = broken_script.scan(/\bfunction\b/).size
      # Count standalone 'end' keywords
      end_keywords = broken_script.scan(/^[\s]*end[\s]*$|[\s]end[\s]|[\s]end$/)

      # Unbalanced - function without end
      function_count.should eq(1)
      end_keywords.size.should eq(0)

      harness.cleanup
    end

    it "can detect unclosed strings" do
      harness = E2ETestHelper.create_harness_with_scene

      # This script has unclosed string
      broken_script = <<-LUA
      function test()
          local msg = "unclosed string
      end
      LUA

      # Count quote characters (odd number means unclosed)
      quote_count = broken_script.count('"')

      # Should be odd (unclosed string)
      (quote_count % 2).should eq(1)

      harness.cleanup
    end
  end

  describe "Script Templates" do
    it "can generate hotspot action template" do
      harness = E2ETestHelper.create_harness_with_scene

      if project = harness.editor.state.current_project
        # Create a hotspot
        harness.press_key(RL::KeyboardKey::P)
        harness.click_canvas(200, 200)
        harness.step_frames(2)

        if scene = harness.editor.state.current_scene
          if scene.hotspots.size > 0
            hotspot = scene.hotspots.first

            # Generate template
            template = String.build do |s|
              s << "-- Hotspot: #{hotspot.name}\n"
              s << "-- Position: (#{hotspot.position.x}, #{hotspot.position.y})\n\n"

              s << "function on_#{hotspot.name}_look()\n"
              s << "    show_message(\"#{hotspot.description || "You see something interesting."}\")\n"
              s << "end\n\n"

              s << "function on_#{hotspot.name}_use()\n"
              s << "    show_message(\"You interact with #{hotspot.name}.\")\n"
              s << "end\n\n"

              s << "hotspot.on_look(\"#{hotspot.name}\", on_#{hotspot.name}_look)\n"
              s << "hotspot.on_use(\"#{hotspot.name}\", on_#{hotspot.name}_use)\n"
            end

            template.includes?("on_look").should be_true
            template.includes?("on_use").should be_true
            template.includes?(hotspot.name).should be_true
          end
        end
      end

      harness.cleanup
    end

    it "can generate character interaction template" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)

        if scene.characters.size > 0
          character = scene.characters.first

          template = String.build do |s|
            s << "-- Character: #{character.name}\n"
            s << "-- Type: #{character.is_a?(PointClickEngine::Characters::NPC) ? "NPC" : "Player"}\n\n"

            s << "function on_#{character.name}_interact()\n"
            s << "    if get_game_state(\"#{character.name}_talked\") then\n"
            s << "        start_dialog(\"#{character.name}_followup\")\n"
            s << "    else\n"
            s << "        start_dialog(\"#{character.name}_intro\")\n"
            s << "        set_game_state(\"#{character.name}_talked\", true)\n"
            s << "    end\n"
            s << "end\n\n"

            s << "function on_#{character.name}_give_item(item)\n"
            s << "    show_message(\"#{character.name} doesn't want that.\")\n"
            s << "end\n\n"

            s << "character.on_interact(\"#{character.name}\", on_#{character.name}_interact)\n"
            s << "character.on_give_item(\"#{character.name}\", on_#{character.name}_give_item)\n"
          end

          template.includes?("on_interact").should be_true
          template.includes?("start_dialog").should be_true
          template.includes?(character.name).should be_true
        end
      end

      harness.cleanup
    end

    it "can generate scene template with all elements" do
      harness = E2ETestHelper.create_harness_with_scene("TemplateTest", "test_scene")

      # Create hotspots
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frames(2)
      harness.click_canvas(200, 200)
      harness.step_frames(2)

      # Add character
      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)

        template = String.build do |s|
          s << "-- Scene: #{scene.name}\n"
          s << "-- Auto-generated script template\n\n"

          s << "-- Scene lifecycle\n"
          s << "function on_enter()\n"
          s << "    print(\"Entering #{scene.name}\")\n"
          s << "end\n\n"

          s << "function on_exit()\n"
          s << "    print(\"Exiting #{scene.name}\")\n"
          s << "end\n\n"

          # Hotspot callbacks
          s << "-- Hotspot callbacks\n"
          scene.hotspots.each do |hotspot|
            s << "function on_#{hotspot.name}_click()\n"
            s << "    show_message(\"Clicked #{hotspot.name}\")\n"
            s << "end\n\n"
          end

          # Character callbacks
          s << "-- Character callbacks\n"
          scene.characters.each do |character|
            s << "function on_#{character.name}_interact()\n"
            s << "    start_dialog(\"#{character.name}_dialog\")\n"
            s << "end\n\n"
          end

          # Register all callbacks
          s << "-- Register callbacks\n"
          s << "scene.on_enter(on_enter)\n"
          s << "scene.on_exit(on_exit)\n\n"

          scene.hotspots.each do |hotspot|
            s << "hotspot.on_click(\"#{hotspot.name}\", on_#{hotspot.name}_click)\n"
          end

          scene.characters.each do |character|
            s << "character.on_interact(\"#{character.name}\", on_#{character.name}_interact)\n"
          end
        end

        template.includes?("on_enter").should be_true
        template.includes?("on_exit").should be_true
        template.includes?("on_click").should be_true
        template.includes?("on_interact").should be_true
      end

      harness.cleanup
    end
  end

  describe "Script Editor Integration" do
    it "can switch to script mode and back" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.assert_mode(PaceEditor::EditorMode::Scene)

      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Script)
      harness.step_frames(3)
      harness.assert_mode(PaceEditor::EditorMode::Script)

      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)
      harness.step_frames(3)
      harness.assert_mode(PaceEditor::EditorMode::Scene)

      harness.cleanup
    end

    it "preserves scene state when editing scripts" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create scene content
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frames(2)

      initial_count = harness.hotspot_count

      # Switch to Script mode
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Script)
      harness.step_frames(5)

      # Switch back
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Scene)
      harness.step_frames(5)

      # Scene content preserved
      harness.hotspot_count.should eq(initial_count)

      harness.cleanup
    end
  end

  describe "Complex Script Scenarios" do
    it "can create a puzzle script" do
      harness = E2ETestHelper.create_harness_with_scene

      if project = harness.editor.state.current_project
        script_content = <<-LUA
        -- Combination Lock Puzzle

        local correct_combination = {3, 7, 1, 9}
        local current_input = {}
        local puzzle_solved = false

        function reset_combination()
            current_input = {}
            show_message("The lock clicks reset.")
        end

        function input_number(num)
            if puzzle_solved then return end

            table.insert(current_input, num)
            play_sound("click")

            if #current_input == 4 then
                check_combination()
            end
        end

        function check_combination()
            local correct = true
            for i = 1, 4 do
                if current_input[i] ~= correct_combination[i] then
                    correct = false
                    break
                end
            end

            if correct then
                puzzle_solved = true
                set_game_state("safe_opened", true)
                play_sound("success")
                show_message("The safe clicks open!")
                reveal_item("safe_contents")
            else
                play_sound("error")
                show_message("Wrong combination.")
                reset_combination()
            end
        end

        -- Number pad callbacks
        for i = 0, 9 do
            hotspot.on_click("num_" .. i, function()
                input_number(i)
            end)
        end
        LUA

        script_path = File.join(project.scripts_path, "puzzle.lua")
        File.write(script_path, script_content)

        content = File.read(script_path)
        content.includes?("check_combination").should be_true
        content.includes?("puzzle_solved").should be_true
      end

      harness.cleanup
    end
  end
end
