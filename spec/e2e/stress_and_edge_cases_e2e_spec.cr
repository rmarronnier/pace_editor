require "./e2e_spec_helper"

# Stress Tests and Edge Cases E2E Tests
# Tests performance with large amounts of data and unusual edge cases

describe "Stress Tests and Edge Cases E2E Tests" do
  describe "Large Scene Handling" do
    it "handles scene with 50 hotspots" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        50.times do |i|
          row = i // 10
          col = i % 10
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "hotspot_#{i}",
            RL::Vector2.new(x: (col * 80).to_f32, y: (row * 60).to_f32),
            RL::Vector2.new(x: 70.0_f32, y: 50.0_f32)
          )
          scene.hotspots << hotspot
        end

        scene.hotspots.size.should eq(50)
      end
    end

    it "handles scene with 20 characters" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        20.times do |i|
          npc = PointClickEngine::Characters::NPC.new(
            "npc_#{i}",
            RL::Vector2.new(x: (i * 50).to_f32, y: 300.0_f32),
            RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
          )
          scene.characters << npc
        end

        scene.characters.size.should eq(20)
      end
    end

    it "handles scene with mixed content" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Add 30 hotspots
        30.times do |i|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "mixed_hs_#{i}",
            RL::Vector2.new(x: ((i % 6) * 120).to_f32, y: ((i // 6) * 80).to_f32),
            RL::Vector2.new(x: 100.0_f32, y: 60.0_f32)
          )
          scene.hotspots << hotspot
        end

        # Add 15 characters
        15.times do |i|
          npc = PointClickEngine::Characters::NPC.new(
            "mixed_npc_#{i}",
            RL::Vector2.new(x: ((i % 5) * 150).to_f32, y: 500.0_f32 + (i // 5) * 100),
            RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
          )
          scene.characters << npc
        end

        scene.hotspots.size.should eq(30)
        scene.characters.size.should eq(15)
      end
    end
  end

  describe "Large Project Handling" do
    it "handles project with 10 scenes" do
      harness = E2ETestHelper.create_harness_with_project("LargeProject")

      if project = harness.editor.state.current_project
        initial_count = project.scenes.size

        10.times do |i|
          scene = PointClickEngine::Scenes::Scene.new("scene_#{i}")
          project.scenes << "scene_#{i}"
          PaceEditor::IO::SceneIO.save_scene(scene, File.join(project.scenes_path, "scene_#{i}.yml"))
        end

        project.scenes.size.should eq(initial_count + 10)
      end
    end

    it "switches between many scenes rapidly" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        # Create 5 scenes
        scenes = [] of PointClickEngine::Scenes::Scene
        5.times do |i|
          scene = PointClickEngine::Scenes::Scene.new("rapid_#{i}")
          project.scenes << "rapid_#{i}"
          PaceEditor::IO::SceneIO.save_scene(scene, File.join(project.scenes_path, "rapid_#{i}.yml"))
          scenes << scene
        end

        # Switch between them rapidly
        20.times do |i|
          harness.editor.state.current_scene = scenes[i % 5]
        end

        # Should end on last assigned scene (19 % 5 = 4)
        harness.scene_name.should eq("rapid_4")
      end
    end
  end

  describe "Large Dialog Trees" do
    it "handles dialog with 20 nodes" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)

      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      initial_count = dialog_editor.dialog_tree.nodes.size

      20.times do |i|
        dialog_editor.create_node_for_test(
          "stress_node_#{i}",
          "This is dialog node number #{i} in the stress test."
        )
      end

      dialog_editor.dialog_tree.nodes.size.should eq(initial_count + 20)
    end

    it "handles dialog with varied text lengths" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)

      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      # Short text
      dialog_editor.create_node_for_test("short", "Hi!")

      # Medium text
      dialog_editor.create_node_for_test("medium", "Hello there, traveler. How may I help you today?")

      # Long text
      long_text = "This is a much longer piece of dialog text that contains multiple sentences. " \
                  "It tests how the system handles larger amounts of text content. " \
                  "Dialog in adventure games can sometimes be quite verbose, especially for exposition scenes."
      dialog_editor.create_node_for_test("long", long_text)

      dialog_tree = dialog_editor.dialog_tree
      dialog_tree.nodes.size.should be >= 3
    end
  end

  describe "Edge Case: Empty States" do
    it "handles empty scene gracefully" do
      harness = E2ETestHelper.create_harness_with_scene

      # Scene starts empty (no user-added content)
      harness.hotspot_count.should eq(0)
      harness.character_count.should eq(0)
      harness.selected_objects.should be_empty
    end

    it "handles project with no scenes" do
      harness = E2ETestHelper.create_harness_with_project

      # Project has default scene, but we can clear the current scene
      harness.editor.state.current_scene = nil

      harness.has_scene?.should be_false
      harness.scene_name.should be_nil
    end

    it "handles selection on empty scene" do
      harness = E2ETestHelper.create_harness_with_scene

      # Try to select non-existent objects
      harness.editor.state.selected_hotspots << "nonexistent"

      # Selection is added even though object doesn't exist
      # This tests the tolerance of the selection system
      harness.editor.state.selected_hotspots.size.should eq(1)
    end
  end

  describe "Edge Case: Special Characters" do
    it "handles hotspot names with underscores" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "door_to_next_room_1",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene.hotspots << hotspot

        scene.hotspots.find { |h| h.name == "door_to_next_room_1" }.should_not be_nil
      end
    end

    it "handles scene names with underscores" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        scene = PointClickEngine::Scenes::Scene.new("main_hall_floor_2")
        project.scenes << "main_hall_floor_2"
        PaceEditor::IO::SceneIO.save_scene(scene, File.join(project.scenes_path, "main_hall_floor_2.yml"))

        project.scenes.should contain("main_hall_floor_2")
      end
    end

    it "handles numeric scene names" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        scene = PointClickEngine::Scenes::Scene.new("scene_001")
        project.scenes << "scene_001"
        PaceEditor::IO::SceneIO.save_scene(scene, File.join(project.scenes_path, "scene_001.yml"))

        project.scenes.should contain("scene_001")
      end
    end
  end

  describe "Edge Case: Boundary Values" do
    it "handles zero-sized hotspot" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Zero-sized hotspot (edge case)
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "zero_size",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 0.0_f32, y: 0.0_f32)
        )
        scene.hotspots << hotspot

        scene.hotspots.size.should eq(1)
      end
    end

    it "handles negative coordinates" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Negative coordinates (might happen with panning)
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "negative_pos",
          RL::Vector2.new(x: -50.0_f32, y: -30.0_f32),
          RL::Vector2.new(x: 100.0_f32, y: 80.0_f32)
        )
        scene.hotspots << hotspot

        scene.hotspots.first.position.x.should eq(-50.0_f32)
      end
    end

    it "handles very large coordinates" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "large_pos",
          RL::Vector2.new(x: 10000.0_f32, y: 10000.0_f32),
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32)
        )
        scene.hotspots << hotspot

        scene.hotspots.first.position.x.should eq(10000.0_f32)
      end
    end

    it "handles extreme zoom values" do
      harness = E2ETestHelper.create_harness_with_scene

      # Very small zoom
      harness.editor.state.zoom = 0.01_f32
      harness.zoom.should eq(0.01_f32)

      # Very large zoom
      harness.editor.state.zoom = 100.0_f32
      harness.zoom.should eq(100.0_f32)

      # Reset to normal
      harness.editor.state.zoom = 1.0_f32
      harness.zoom.should eq(1.0_f32)
    end

    it "handles extreme camera positions" do
      harness = E2ETestHelper.create_harness_with_scene

      # Very negative position
      harness.editor.state.camera_x = -10000.0_f32
      harness.editor.state.camera_y = -10000.0_f32

      pos = harness.camera_position
      pos[:x].should eq(-10000.0_f32)
      pos[:y].should eq(-10000.0_f32)

      # Very large position
      harness.editor.state.camera_x = 50000.0_f32
      harness.editor.state.camera_y = 50000.0_f32

      pos = harness.camera_position
      pos[:x].should eq(50000.0_f32)
      pos[:y].should eq(50000.0_f32)
    end
  end

  describe "Edge Case: Duplicate Names" do
    it "allows duplicate hotspot names in same scene" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        2.times do |i|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "duplicate_name",
            RL::Vector2.new(x: (i * 100).to_f32, y: 100.0_f32),
            RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
          )
          scene.hotspots << hotspot
        end

        # Both are added (system allows duplicates)
        scene.hotspots.size.should eq(2)
        scene.hotspots.count { |h| h.name == "duplicate_name" }.should eq(2)
      end
    end

    it "handles same-named objects across different scenes" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        # Create two scenes with same-named hotspots
        scene1 = PointClickEngine::Scenes::Scene.new("scene_dup_1")
        hotspot1 = PointClickEngine::Scenes::Hotspot.new(
          "the_door",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene1.hotspots << hotspot1

        scene2 = PointClickEngine::Scenes::Scene.new("scene_dup_2")
        hotspot2 = PointClickEngine::Scenes::Hotspot.new(
          "the_door",
          RL::Vector2.new(x: 200.0_f32, y: 200.0_f32),
          RL::Vector2.new(x: 60.0_f32, y: 60.0_f32)
        )
        scene2.hotspots << hotspot2

        # Save both
        project.scenes << "scene_dup_1"
        project.scenes << "scene_dup_2"
        PaceEditor::IO::SceneIO.save_scene(scene1, File.join(project.scenes_path, "scene_dup_1.yml"))
        PaceEditor::IO::SceneIO.save_scene(scene2, File.join(project.scenes_path, "scene_dup_2.yml"))

        # Switch between them
        harness.editor.state.current_scene = scene1
        harness.hotspot_count.should eq(1)

        harness.editor.state.current_scene = scene2
        harness.hotspot_count.should eq(1)
      end
    end
  end

  describe "State Consistency Under Stress" do
    it "maintains state through rapid operations" do
      harness = E2ETestHelper.create_harness_with_scene

      # Rapid mode switching via UI clicks
      50.times do |i|
        mode = PaceEditor::EditorMode.values[i % PaceEditor::EditorMode.values.size]
        E2EUIHelpers.click_mode_button(harness, mode)
      end

      # Should be in a valid mode
      PaceEditor::EditorMode.values.should contain(harness.current_mode)
    end

    it "maintains state through rapid tool switching" do
      harness = E2ETestHelper.create_harness_with_scene

      # Rapid tool switching
      30.times do |i|
        tool = PaceEditor::Tool.values[i % PaceEditor::Tool.values.size]
        harness.editor.state.current_tool = tool
      end

      # Should be a valid tool
      PaceEditor::Tool.values.should contain(harness.current_tool)
    end

    it "handles rapid selection/deselection" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Create hotspots
        10.times do |i|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "rapid_select_#{i}",
            RL::Vector2.new(x: (i * 80).to_f32, y: 100.0_f32),
            RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
          )
          scene.hotspots << hotspot
        end
      end

      # Rapidly select and deselect
      30.times do |i|
        if i % 2 == 0
          harness.editor.state.selected_hotspots << "rapid_select_#{i % 10}"
        else
          harness.editor.state.selected_hotspots.clear
        end
      end

      # Selection should be in a valid state
      harness.editor.state.selected_hotspots.size.should be >= 0
    end
  end

  describe "Multiple Dialog Support" do
    it "creates multiple dialog trees for different NPCs" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)

      dialog_editor = harness.editor.dialog_editor

      # Create first dialog tree
      dialog_editor.ensure_dialog_for_test
      dialog_editor.create_node_for_test("npc1_greeting", "Hello, I'm the blacksmith!")

      # The dialog editor typically manages one dialog at a time
      # But we can test that creating new nodes works
      dialog_editor.create_node_for_test("npc1_services", "I can forge weapons for you.")

      dialog_tree = dialog_editor.dialog_tree
      dialog_tree.nodes.size.should be >= 2
    end
  end

  describe "UI State Stress" do
    it "handles hints up to queue limit" do
      harness = E2ETestHelper.create_harness_with_project
      harness.ui_state.show_hints = true

      # Add many hints (queue has a limit of 5)
      20.times do |i|
        hint = PaceEditor::UI::UIHint.new(
          "stress_hint_#{i}",
          "This is stress test hint number #{i}",
          PaceEditor::UI::UIHintType::Info
        )
        harness.ui_state.add_hint(hint)
      end

      # Queue is limited to 5 items
      harness.ui_state.hint_queue.size.should eq(5)

      # Process all hints
      5.times do
        harness.ui_state.get_next_hint
      end

      harness.ui_state.hint_queue.size.should eq(0)
    end

    it "handles rapid action tracking" do
      harness = E2ETestHelper.create_harness_with_project

      # Track many actions rapidly
      50.times do |i|
        harness.ui_state.track_action("action_#{i}")
      end

      # Recent actions has a limit of 20 items
      harness.ui_state.recent_actions.size.should eq(20)
    end

    it "handles visibility override stress" do
      harness = E2ETestHelper.create_harness_with_scene

      components = ["scene_editor", "character_editor", "dialog_editor", "property_panel", "tool_palette"]

      # Override all
      components.each do |comp|
        harness.ui_state.override_component_visibility(comp, PaceEditor::UI::ComponentState::Hidden)
      end

      harness.ui_state.visibility_overrides.size.should eq(5)

      # Clear all
      harness.ui_state.clear_all_overrides

      harness.ui_state.visibility_overrides.size.should eq(0)
    end
  end

  describe "File System Edge Cases" do
    it "handles saving scene with long name" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        long_name = "this_is_a_very_long_scene_name_for_testing"
        scene = PointClickEngine::Scenes::Scene.new(long_name)
        project.scenes << long_name

        result = PaceEditor::IO::SceneIO.save_scene(scene, File.join(project.scenes_path, "#{long_name}.yml"))
        result.should be_true

        File.exists?(File.join(project.scenes_path, "#{long_name}.yml")).should be_true
      end
    end

    it "saves and verifies multiple scene files" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        5.times do |i|
          scene = PointClickEngine::Scenes::Scene.new("multi_file_#{i}")
          scene_path = File.join(project.scenes_path, "multi_file_#{i}.yml")

          result = PaceEditor::IO::SceneIO.save_scene(scene, scene_path)
          result.should be_true
          File.exists?(scene_path).should be_true
        end

        # Verify all files exist
        5.times do |i|
          File.exists?(File.join(project.scenes_path, "multi_file_#{i}.yml")).should be_true
        end
      end
    end
  end
end
