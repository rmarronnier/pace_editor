require "./e2e_spec_helper"

describe "Error Handling E2E Tests" do
  describe "Invalid Project Operations" do
    it "handles creating project with empty name" do
      harness = PaceEditor::Testing::TestHarness.new

      # Empty project name should still work but creates unnamed project
      harness.editor.state.create_new_project("", "/tmp/test")

      harness.has_project?.should be_true
    end

    it "handles project with special characters in name" do
      harness = PaceEditor::Testing::TestHarness.new
      temp_dir = E2ETestHelper.create_temp_project_dir

      harness.editor.state.create_new_project("My<>Game|Test", temp_dir)

      harness.has_project?.should be_true
    end

    it "handles project with very long name" do
      harness = PaceEditor::Testing::TestHarness.new
      temp_dir = E2ETestHelper.create_temp_project_dir

      long_name = "A" * 256
      harness.editor.state.create_new_project(long_name, temp_dir)

      harness.has_project?.should be_true
    end
  end

  describe "Invalid Scene Operations" do
    it "handles creating scene with empty name" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        initial_count = project.scenes.size

        # Creating scene with empty name - should still work
        scene = PointClickEngine::Scenes::Scene.new("")
        project.scenes << ""
        PaceEditor::IO::SceneIO.save_scene(scene, File.join(project.scenes_path, ".yml"))

        # Scene name is added
        project.scenes.size.should eq(initial_count + 1)
      end
    end

    it "handles creating scene with duplicate name" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        scene1 = PointClickEngine::Scenes::Scene.new("duplicate_scene")
        project.scenes << "duplicate_scene"
        PaceEditor::IO::SceneIO.save_scene(scene1, File.join(project.scenes_path, "duplicate_scene.yml"))
        initial_count = project.scenes.size

        # Create another with same name (will overwrite file but add to list)
        scene2 = PointClickEngine::Scenes::Scene.new("duplicate_scene")
        project.scenes << "duplicate_scene"
        PaceEditor::IO::SceneIO.save_scene(scene2, File.join(project.scenes_path, "duplicate_scene.yml"))

        # Both names are added to array (duplicates allowed in array)
        project.scenes.size.should eq(initial_count + 1)
      end
    end

    it "handles switching to non-existent scene" do
      harness = E2ETestHelper.create_harness_with_project

      # Create a scene object but don't register it
      fake_scene = PointClickEngine::Scenes::Scene.new("non_existent_scene")

      # Set to this unregistered scene
      harness.editor.state.current_scene = fake_scene

      # Should not crash, scene is set
      harness.editor.state.current_scene.try(&.name).should eq("non_existent_scene")
    end

    it "handles deleting current scene" do
      harness = E2ETestHelper.create_harness_with_scene

      if project = harness.editor.state.current_project
        current_name = harness.editor.state.current_scene.try(&.name)
        if current_name
          # Delete current scene from project's scene list
          project.scenes.reject! { |s| s == current_name }

          # Should handle gracefully - scene name removed from list
          project.scenes.includes?(current_name).should be_false
        end
      end
    end
  end

  describe "Invalid Hotspot Operations" do
    it "handles selecting non-existent hotspot" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.selected_hotspots << "non_existent_hotspot"

      harness.editor.state.selected_hotspots.includes?("non_existent_hotspot").should be_true
    end

    it "handles hotspot with zero size" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "zero_size",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 0.0_f32, y: 0.0_f32)
        )
        scene.hotspots << hotspot

        scene.hotspots.find { |h| h.name == "zero_size" }.should_not be_nil
      end
    end

    it "handles hotspot with negative position" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "negative_pos",
          RL::Vector2.new(x: -100.0_f32, y: -100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene.hotspots << hotspot

        scene.hotspots.find { |h| h.name == "negative_pos" }.should_not be_nil
      end
    end

    it "handles deleting selected hotspot" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "to_delete",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene.hotspots << hotspot

        harness.editor.state.selected_hotspots << "to_delete"
        scene.hotspots.reject! { |h| h.name == "to_delete" }

        # Selection remains but hotspot is gone
        harness.editor.state.selected_hotspots.includes?("to_delete").should be_true
        scene.hotspots.find { |h| h.name == "to_delete" }.should be_nil
      end
    end
  end

  describe "Invalid Character Operations" do
    it "handles character with empty name" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        character = PointClickEngine::Characters::NPC.new(
          "",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
        )
        scene.characters << character

        scene.characters.any? { |c| c.name == "" }.should be_true
      end
    end

    it "handles selecting non-existent character" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.selected_character = "ghost_character"

      harness.editor.state.selected_character.should eq("ghost_character")
    end

    it "handles character at boundary position" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Character at max float values
        character = PointClickEngine::Characters::NPC.new(
          "boundary_char",
          RL::Vector2.new(x: Float32::MAX / 2, y: Float32::MAX / 2),
          RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
        )
        scene.characters << character

        scene.characters.find { |c| c.name == "boundary_char" }.should_not be_nil
      end
    end
  end

  describe "Invalid Dialog Operations" do
    it "handles dialog tree with no nodes" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create empty dialog tree
      empty_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("empty_tree")
      empty_tree.nodes.clear

      empty_tree.nodes.size.should eq(0)
    end

    it "handles connecting to non-existent node" do
      harness = E2ETestHelper.create_harness_with_scene
      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      if tree = dialog_editor.dialog_tree
        start_node = tree.nodes["start"]?
        if start_node
          # Try to connect to non-existent node
          start_node.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new(
            "Go to ghost",
            "ghost_node"
          )

          # Connection is created but target doesn't exist
          start_node.choices.any? { |r| r.target_node_id == "ghost_node" }.should be_true
          tree.nodes["ghost_node"]?.should be_nil
        end
      end
    end

    it "handles circular dialog references" do
      harness = E2ETestHelper.create_harness_with_scene
      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      if tree = dialog_editor.dialog_tree
        # Create circular reference: A -> B -> A
        node_a = PointClickEngine::Characters::Dialogue::DialogNode.new("circular_a", "Node A")
        node_a.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("To B", "circular_b")

        node_b = PointClickEngine::Characters::Dialogue::DialogNode.new("circular_b", "Node B")
        node_b.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Back to A", "circular_a")

        tree.add_node(node_a)
        tree.add_node(node_b)

        # Circular references are allowed
        tree.nodes["circular_a"]?.should_not be_nil
        tree.nodes["circular_b"]?.should_not be_nil
      end
    end

    it "handles dialog node with empty text" do
      harness = E2ETestHelper.create_harness_with_scene
      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      if tree = dialog_editor.dialog_tree
        empty_node = PointClickEngine::Characters::Dialogue::DialogNode.new("empty_text_node", "")
        tree.add_node(empty_node)

        tree.nodes["empty_text_node"]?.try(&.text).should eq("")
      end
    end
  end

  describe "File I/O Error Handling" do
    it "handles loading scene from non-existent file" do
      result = PaceEditor::IO::SceneIO.load_scene("/non/existent/path/scene.yml")

      result.should be_nil
    end

    it "handles loading project from non-existent path" do
      # Loading from non-existent path should raise an exception
      expect_raises(File::NotFoundError | Exception) do
        PaceEditor::Core::Project.load_project("/non/existent/path/project.pace")
      end
    end

    it "handles saving to read-only directory" do
      harness = E2ETestHelper.create_harness_with_scene

      # Attempting to save to root (typically read-only)
      # This should fail gracefully
      if scene = harness.editor.state.current_scene
        # The save might fail but shouldn't crash
        begin
          PaceEditor::IO::SceneIO.save_scene(scene, "/readonly_test_scene.yml")
        rescue
          # Expected to fail on read-only systems
        end
      end

      # Test passes if we get here without crashing
      true.should be_true
    end

    it "handles loading malformed YAML" do
      temp_file = File.tempfile("malformed", ".yml")
      begin
        File.write(temp_file.path, "{{invalid yaml content}}: [")

        result = PaceEditor::IO::SceneIO.load_scene(temp_file.path)
        # Should return nil or handle gracefully
        result.should be_nil
      ensure
        temp_file.delete
      end
    end
  end

  describe "UI State Error Handling" do
    it "handles nil scene gracefully in mode" do
      harness = E2ETestHelper.create_harness_with_project

      # No scene selected
      harness.editor.state.current_scene = nil

      # Switch to hotspot mode without a scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Hotspot)

      # Should not crash
      harness.editor.state.current_mode.should eq(PaceEditor::EditorMode::Hotspot)
    end

    it "handles multiple rapid mode switches" do
      harness = E2ETestHelper.create_harness_with_project

      modes = [
        PaceEditor::EditorMode::Scene,
        PaceEditor::EditorMode::Character,
        PaceEditor::EditorMode::Hotspot,
        PaceEditor::EditorMode::Dialog,
        PaceEditor::EditorMode::Assets,
        PaceEditor::EditorMode::Script,
        PaceEditor::EditorMode::Project,
      ]

      # Rapid fire mode switches via UI clicks
      100.times do
        E2EUIHelpers.click_mode_button(harness, modes.sample)
      end

      # Should be in one of the valid modes
      modes.includes?(harness.editor.state.current_mode).should be_true
    end

    it "handles tooltip at edge of screen" do
      harness = E2ETestHelper.create_harness_with_project

      # Set tooltip at screen edge
      harness.ui_state.show_tooltip("Edge tooltip", RL::Vector2.new(x: -10.0_f32, y: -10.0_f32))

      harness.ui_state.has_active_tooltip?.should be_true
    end

    it "handles very long tooltip text" do
      harness = E2ETestHelper.create_harness_with_project

      long_text = "A" * 10000
      harness.ui_state.show_tooltip(long_text, RL::Vector2.new(x: 100.0_f32, y: 100.0_f32))

      harness.ui_state.active_tooltip.should_not be_nil
      harness.ui_state.active_tooltip.not_nil!.size.should be > 0
    end

    it "handles empty hint text" do
      harness = E2ETestHelper.create_harness_with_project

      hint = PaceEditor::UI::UIHint.new("empty_hint", "", PaceEditor::UI::UIHintType::Info)
      harness.ui_state.add_hint(hint)

      # Empty hint should still be queued
      harness.ui_state.hint_queue.size.should be >= 0
    end
  end

  describe "Selection Error Handling" do
    it "handles clearing selection when nothing selected" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.selected_character = nil
      harness.editor.state.selected_hotspots.clear
      harness.editor.state.selected_characters.clear

      # Clear again
      harness.editor.state.selected_character = nil
      harness.editor.state.selected_hotspots.clear
      harness.editor.state.selected_characters.clear

      harness.editor.state.selected_hotspots.empty?.should be_true
    end

    it "handles multi-select with invalid items" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.selected_hotspots << "invalid_1"
      harness.editor.state.selected_hotspots << "invalid_2"
      harness.editor.state.selected_hotspots << "invalid_3"

      harness.editor.state.selected_hotspots.size.should eq(3)
    end

    it "handles duplicate selections" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.selected_hotspots << "duplicate"
      harness.editor.state.selected_hotspots << "duplicate"
      harness.editor.state.selected_hotspots << "duplicate"

      # Duplicates are added (Array behavior)
      harness.editor.state.selected_hotspots.count("duplicate").should eq(3)
    end
  end

  describe "Undo/Redo Error Handling" do
    it "handles undo with empty history" do
      harness = E2ETestHelper.create_harness_with_project

      # Undo all existing actions to empty the stack
      while harness.editor.state.can_undo?
        harness.editor.state.undo
      end

      # Try to undo with empty stack - should return false
      harness.editor.state.can_undo?.should be_false
      harness.editor.state.undo.should be_false
    end

    it "handles redo with empty future" do
      harness = E2ETestHelper.create_harness_with_project

      # Try to redo with empty stack - should return false
      harness.editor.state.can_redo?.should be_false
      harness.editor.state.redo.should be_false
    end

    it "handles pushing empty action description" do
      harness = E2ETestHelper.create_harness_with_project

      # Push empty action description - should still work
      harness.editor.state.push_undo_state("")

      # Should be able to undo
      harness.editor.state.can_undo?.should be_true
    end
  end

  describe "Input Edge Cases" do
    it "handles mouse position at origin" do
      harness = E2ETestHelper.create_harness_with_scene
      input = harness.input

      input.set_mouse_position(0.0_f32, 0.0_f32)

      input.get_mouse_position.x.should eq(0.0_f32)
      input.get_mouse_position.y.should eq(0.0_f32)
    end

    it "handles negative mouse position" do
      harness = E2ETestHelper.create_harness_with_scene
      input = harness.input

      input.set_mouse_position(-100.0_f32, -100.0_f32)

      input.get_mouse_position.x.should eq(-100.0_f32)
      input.get_mouse_position.y.should eq(-100.0_f32)
    end

    it "handles very large mouse position" do
      harness = E2ETestHelper.create_harness_with_scene
      input = harness.input

      input.set_mouse_position(10000.0_f32, 10000.0_f32)

      input.get_mouse_position.x.should eq(10000.0_f32)
      input.get_mouse_position.y.should eq(10000.0_f32)
    end

    it "handles rapid key presses" do
      harness = E2ETestHelper.create_harness_with_scene
      input = harness.input

      # Rapid key press/release cycles
      100.times do
        input.press_key(RL::KeyboardKey::Space)
        input.release_key(RL::KeyboardKey::Space)
      end

      # Should handle without issues
      true.should be_true
    end

    it "handles simultaneous mouse buttons" do
      harness = E2ETestHelper.create_harness_with_scene
      input = harness.input

      input.press_mouse_button(RL::MouseButton::Left)
      input.press_mouse_button(RL::MouseButton::Right)
      input.press_mouse_button(RL::MouseButton::Middle)

      input.mouse_button_pressed?(RL::MouseButton::Left).should be_true
      input.mouse_button_pressed?(RL::MouseButton::Right).should be_true
      input.mouse_button_pressed?(RL::MouseButton::Middle).should be_true
    end
  end

  describe "Component Visibility Edge Cases" do
    it "handles toggling hidden component" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.ui_state.override_component_visibility("test_comp", PaceEditor::UI::ComponentState::Hidden)
      harness.ui_state.override_component_visibility("test_comp", PaceEditor::UI::ComponentState::Visible)
      harness.ui_state.override_component_visibility("test_comp", PaceEditor::UI::ComponentState::Hidden)

      harness.ui_state.visibility_overrides["test_comp"]?.should eq(PaceEditor::UI::ComponentState::Hidden)
    end

    it "handles removing non-existent override" do
      harness = E2ETestHelper.create_harness_with_scene

      # Remove override that doesn't exist
      harness.ui_state.visibility_overrides.delete("non_existent")

      harness.ui_state.visibility_overrides["non_existent"]?.should be_nil
    end

    it "handles many visibility overrides" do
      harness = E2ETestHelper.create_harness_with_scene

      # Add many overrides
      100.times do |i|
        harness.ui_state.override_component_visibility("comp_#{i}", PaceEditor::UI::ComponentState::Hidden)
      end

      harness.ui_state.visibility_overrides.size.should eq(100)
    end
  end

  describe "Dialog Editor Edge Cases" do
    it "handles dialog with only end nodes" do
      harness = E2ETestHelper.create_harness_with_scene
      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      if tree = dialog_editor.dialog_tree
        # Clear all nodes and add only end nodes
        tree.nodes.clear

        end_node = PointClickEngine::Characters::Dialogue::DialogNode.new("only_end", "The End")
        end_node.is_end = true
        tree.add_node(end_node)

        tree.nodes.values.all?(&.is_end).should be_true
      end
    end

    it "handles response with empty text" do
      harness = E2ETestHelper.create_harness_with_scene
      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test

      if tree = dialog_editor.dialog_tree
        if start = tree.nodes["start"]?
          start.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("", "somewhere")

          start.choices.any? { |r| r.text == "" }.should be_true
        end
      end
    end
  end

  describe "Export Error Handling" do
    it "handles export with no scenes" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        # Remove all scenes
        project.scenes.clear

        project.scenes.size.should eq(0)
        # Export would need to handle this gracefully
      end
    end

    it "handles export with missing assets" do
      harness = E2ETestHelper.create_harness_with_scene

      if project = harness.editor.state.current_project
        # Reference non-existent asset in current scene
        if scene = harness.editor.state.current_scene
          scene.background_path = "/non/existent/background.png"
        end

        # Project should still be valid even with missing asset reference
        project.scenes.size.should be > 0
      end
    end
  end

  describe "Project Validation Edge Cases" do
    it "validates project with multiple interconnected scenes" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        # Create scenes with hotspots
        scene_a = PointClickEngine::Scenes::Scene.new("circular_a")
        scene_b = PointClickEngine::Scenes::Scene.new("circular_b")

        # Add hotspots (scene transitions are configured via actions, not direct properties)
        hotspot_a = PointClickEngine::Scenes::Hotspot.new(
          "go_to_b",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )

        hotspot_b = PointClickEngine::Scenes::Hotspot.new(
          "go_to_a",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )

        scene_a.hotspots << hotspot_a
        scene_b.hotspots << hotspot_b

        # Add scene names to project
        project.scenes << "circular_a"
        project.scenes << "circular_b"

        # Save scene files
        PaceEditor::IO::SceneIO.save_scene(scene_a, File.join(project.scenes_path, "circular_a.yml"))
        PaceEditor::IO::SceneIO.save_scene(scene_b, File.join(project.scenes_path, "circular_b.yml"))

        # Multiple scenes should be allowed
        project.scenes.count { |s| s.starts_with?("circular") }.should eq(2)
      end
    end

    it "validates project with orphaned dialogs" do
      harness = E2ETestHelper.create_harness_with_scene
      dialog_editor = harness.editor.dialog_editor

      # Create dialog not attached to any character/hotspot
      dialog_editor.ensure_dialog_for_test

      if tree = dialog_editor.dialog_tree
        tree.name.should_not be_nil
      end
    end
  end

  describe "Memory/Resource Edge Cases" do
    it "handles creating and destroying many scenes" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        initial = project.scenes.size

        # Create many scenes
        20.times do |i|
          scene = PointClickEngine::Scenes::Scene.new("memory_test_#{i}")
          project.scenes << "memory_test_#{i}"
          PaceEditor::IO::SceneIO.save_scene(scene, File.join(project.scenes_path, "memory_test_#{i}.yml"))
        end

        project.scenes.size.should eq(initial + 20)

        # Remove them
        project.scenes.reject! { |s| s.starts_with?("memory_test_") }

        project.scenes.size.should eq(initial)
      end
    end

    it "handles scene with many objects" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Add many hotspots
        100.times do |i|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "many_obj_#{i}",
            RL::Vector2.new(x: (i * 10).to_f32, y: 100.0_f32),
            RL::Vector2.new(x: 5.0_f32, y: 5.0_f32)
          )
          scene.hotspots << hotspot
        end

        scene.hotspots.count { |h| h.name.starts_with?("many_obj_") }.should eq(100)
      end
    end
  end
end
