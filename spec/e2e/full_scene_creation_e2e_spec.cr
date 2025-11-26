# E2E Tests for Full Scene Creation
# Tests creating a complete adventure game scene similar to crystal_mystery
# Includes hotspots, characters, walkable areas, dialogs, and scripts

require "./e2e_spec_helper"

describe "Full Scene Creation E2E" do
  describe "Creating a Library Scene (like crystal_mystery)" do
    it "can create a scene with multiple hotspots" do
      harness = E2ETestHelper.create_harness_with_scene("MysteryGame", "library")

      # Create hotspots for: bookshelf, desk, door_to_lab, painting
      harness.press_key(RL::KeyboardKey::P)

      # Bookshelf hotspot (left side)
      harness.click_canvas(100, 200)
      harness.step_frames(2)

      # Desk hotspot (center)
      harness.click_canvas(400, 400)
      harness.step_frames(2)

      # Door hotspot (right side)
      harness.click_canvas(850, 300)
      harness.step_frames(2)

      # Painting hotspot (top center)
      harness.click_canvas(500, 100)
      harness.step_frames(2)

      harness.assert_hotspot_count(4)

      harness.cleanup
    end

    it "can create a scene with NPC characters" do
      harness = E2ETestHelper.create_harness_with_scene("MysteryGame", "library")

      # Add butler NPC character
      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)

        harness.assert_character_count(1)

        # Character should be selected
        harness.selected_object.should_not be_nil

        # Add second character (scientist)
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)

        harness.assert_character_count(2)
      end

      harness.cleanup
    end

    it "can create a scene with both hotspots and characters" do
      harness = E2ETestHelper.create_harness_with_scene("MysteryGame", "library")

      # Create several hotspots
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 200)
      harness.step_frames(2)
      harness.click_canvas(400, 400)
      harness.step_frames(2)
      harness.click_canvas(800, 300)
      harness.step_frames(2)

      harness.assert_hotspot_count(3)

      # Add NPC characters
      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)
      end

      harness.assert_character_count(2)

      # Verify both hotspots and characters exist
      if scene = harness.editor.state.current_scene
        scene.hotspots.size.should eq(3)
        scene.characters.size.should eq(2)
      end

      harness.cleanup
    end

    it "can save and verify scene has correct structure" do
      harness = E2ETestHelper.create_harness_with_scene("MysteryGame", "library")

      # Create hotspots
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 200)
      harness.step_frames(2)
      harness.click_canvas(400, 400)
      harness.step_frames(2)

      # Add character
      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)
      end

      # Save the scene
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)
      harness.step_frames(3)

      # Verify scene file exists and has content
      if project = harness.editor.state.current_project
        scene_path = File.join(project.scenes_path, "library.yml")
        File.exists?(scene_path).should be_true

        content = File.read(scene_path)
        content.includes?("hotspots").should be_true
        content.includes?("characters").should be_true
      end

      harness.cleanup
    end
  end

  describe "Multi-Scene Project" do
    it "can create multiple scenes in one project" do
      harness = E2ETestHelper.create_harness_with_scene("MysteryGame", "library")

      # Create some content in library scene
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frames(2)

      # Save current scene
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)
      harness.step_frames(2)

      # Create a new scene (laboratory)
      if project = harness.editor.state.current_project
        lab_scene = PointClickEngine::Scenes::Scene.new("laboratory")
        lab_scene.hotspots = [] of PointClickEngine::Scenes::Hotspot
        lab_scene.characters = [] of PointClickEngine::Characters::Character
        harness.editor.state.current_scene = lab_scene
        project.scenes << "laboratory"

        harness.step_frames(2)

        # Add hotspots to laboratory
        harness.press_key(RL::KeyboardKey::P)
        harness.click_canvas(200, 200)
        harness.step_frames(2)
        harness.click_canvas(400, 200)
        harness.step_frames(2)

        harness.assert_hotspot_count(2)

        # Save laboratory scene
        harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)
        harness.step_frames(2)

        # Verify both scene files exist
        library_path = File.join(project.scenes_path, "library.yml")
        lab_path = File.join(project.scenes_path, "laboratory.yml")

        File.exists?(library_path).should be_true
        File.exists?(lab_path).should be_true
      end

      harness.cleanup
    end

    it "can switch between scenes" do
      harness = E2ETestHelper.create_harness_with_scene("MysteryGame", "library")

      # Create content in library
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(100, 100)
      harness.step_frames(2)
      harness.assert_hotspot_count(1)

      if project = harness.editor.state.current_project
        # Save library scene
        harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)
        harness.step_frames(2)

        # Create new scene
        garden_scene = PointClickEngine::Scenes::Scene.new("garden")
        garden_scene.hotspots = [] of PointClickEngine::Scenes::Hotspot
        garden_scene.characters = [] of PointClickEngine::Characters::Character
        project.scenes << "garden"

        # Switch to garden scene
        harness.editor.state.current_scene = garden_scene
        harness.step_frames(2)

        # Garden should have no hotspots
        harness.assert_hotspot_count(0)
        harness.scene_name.should eq("garden")

        # Add hotspots to garden
        harness.press_key(RL::KeyboardKey::P)
        harness.click_canvas(300, 300)
        harness.step_frames(2)
        harness.assert_hotspot_count(1)

        # Save garden
        harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)
        harness.step_frames(2)

        # Switch back to library - need to reload it
        library_path = File.join(project.scenes_path, "library.yml")
        if File.exists?(library_path)
          if library_scene = PaceEditor::IO::SceneIO.load_scene(library_path)
            harness.editor.state.current_scene = library_scene
            harness.step_frames(2)

            harness.scene_name.should eq("library")
            # Library should still have its hotspot
            harness.assert_hotspot_count(1)
          end
        end
      end

      harness.cleanup
    end
  end

  describe "Scene Object Interactions" do
    it "can select and modify hotspot properties" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(200, 200)
      harness.step_frames(2)

      # Hotspot should be auto-selected
      harness.selected_object.should_not be_nil

      # Modify hotspot directly (simulating property panel edit)
      if scene = harness.editor.state.current_scene
        if selected = harness.selected_object
          if hotspot = scene.hotspots.find { |h| h.name == selected }
            original_size_x = hotspot.size.x

            # Change hotspot size
            hotspot.size = RL::Vector2.new(128.0_f32, 128.0_f32)
            harness.step_frame

            # Verify change
            hotspot.size.x.should eq(128.0_f32)
            hotspot.size.x.should_not eq(original_size_x)
          end
        end
      end

      harness.cleanup
    end

    it "can select and modify character properties" do
      harness = E2ETestHelper.create_harness_with_scene

      # Add an NPC
      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)

        # Character should be selected
        harness.selected_object.should_not be_nil

        # Modify character directly
        if selected = harness.selected_object
          if character = scene.characters.find { |c| c.name == selected }
            # Change character description
            character.description = "The mysterious butler"
            harness.step_frame

            # Change walking speed
            character.walking_speed = 150.0_f32
            harness.step_frame

            # Verify changes
            character.description.should eq("The mysterious butler")
            character.walking_speed.should eq(150.0_f32)
          end
        end
      end

      harness.cleanup
    end

    it "can delete objects using Delete key" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(96, 96)
      harness.step_frames(2)
      harness.assert_hotspot_count(1)

      # Select the hotspot
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(96, 96)
      harness.step_frames(2)
      harness.selected_object.should_not be_nil

      # Delete selected hotspot
      harness.press_key(RL::KeyboardKey::Delete)
      harness.step_frames(2)
      harness.assert_hotspot_count(0)

      harness.cleanup
    end
  end

  describe "Scene Persistence" do
    it "persists hotspot positions correctly" do
      harness = E2ETestHelper.create_harness_with_scene("PersistTest", "test_scene")

      # Create hotspot at specific grid-aligned position
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(160, 160)  # Should snap to grid
      harness.step_frames(2)

      # Get the hotspot position
      original_pos = nil
      if scene = harness.editor.state.current_scene
        if scene.hotspots.size > 0
          original_pos = {x: scene.hotspots.first.position.x, y: scene.hotspots.first.position.y}
        end
      end
      original_pos.should_not be_nil

      # Save the scene
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)
      harness.step_frames(3)

      # Reload the scene file and verify position
      if project = harness.editor.state.current_project
        scene_path = File.join(project.scenes_path, "test_scene.yml")
        if reloaded_scene = PaceEditor::IO::SceneIO.load_scene(scene_path)
          if reloaded_scene.hotspots.size > 0
            reloaded_pos = reloaded_scene.hotspots.first.position
            if pos = original_pos
              reloaded_pos.x.should eq(pos[:x])
              reloaded_pos.y.should eq(pos[:y])
            end
          end
        end
      end

      harness.cleanup
    end

    it "persists character data correctly" do
      harness = E2ETestHelper.create_harness_with_scene("PersistTest", "test_scene")

      # Add an NPC with modified properties
      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)

        # Modify the NPC
        if scene.characters.size > 0
          npc = scene.characters.first
          npc.description = "Test character description"
          npc.walking_speed = 200.0_f32
        end
      end

      # Save the scene
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)
      harness.step_frames(3)

      # Verify saved content
      if project = harness.editor.state.current_project
        scene_path = File.join(project.scenes_path, "test_scene.yml")
        content = File.read(scene_path)
        content.includes?("characters").should be_true
      end

      harness.cleanup
    end
  end
end

describe "Complex Scene Workflows E2E" do
  describe "Adventure Game Scene Setup" do
    it "can build a complete interactive scene" do
      harness = E2ETestHelper.create_harness_with_scene("AdventureGame", "mansion_library")

      # Step 1: Create interactive hotspots
      harness.press_key(RL::KeyboardKey::P)

      # Bookshelf - searchable
      harness.click_canvas(100, 250)
      harness.step_frames(2)

      # Desk - examine and find clue
      harness.click_canvas(400, 450)
      harness.step_frames(2)

      # Exit door - scene transition
      harness.click_canvas(850, 350)
      harness.step_frames(2)

      # Secret painting - hidden compartment
      harness.click_canvas(550, 150)
      harness.step_frames(2)

      harness.assert_hotspot_count(4)

      # Step 2: Add NPC characters
      if scene = harness.editor.state.current_scene
        # Butler NPC
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)

        # Position butler near entrance
        if butler = scene.characters.find { |c| c.name.includes?("npc") }
          butler.position = RL::Vector2.new(300.0_f32, 500.0_f32)
          butler.description = "The mysterious butler"
        end

        harness.assert_character_count(1)
      end

      # Step 3: Configure hotspot properties
      if scene = harness.editor.state.current_scene
        scene.hotspots.each_with_index do |hotspot, index|
          case index
          when 0
            hotspot.description = "Ancient books line the shelves"
          when 1
            hotspot.description = "A mahogany desk with scattered papers"
          when 2
            hotspot.description = "Door to the laboratory"
            hotspot.object_type = PointClickEngine::UI::ObjectType::Exit
          when 3
            hotspot.description = "Portrait of the mansion's founder"
          end
        end
      end

      # Step 4: Save the complete scene
      harness.key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::S)
      harness.step_frames(3)

      # Verify the scene was saved with all elements
      if project = harness.editor.state.current_project
        scene_path = File.join(project.scenes_path, "mansion_library.yml")
        File.exists?(scene_path).should be_true

        content = File.read(scene_path)
        content.includes?("hotspots").should be_true
        content.includes?("characters").should be_true
      end

      harness.cleanup
    end

    it "can modify existing scene elements" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create initial content
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(96, 96)
      harness.step_frames(2)
      harness.click_canvas(224, 96)
      harness.step_frames(2)

      if scene = harness.editor.state.current_scene
        harness.editor.state.add_npc_character(scene)
        harness.step_frames(2)
      end

      initial_character_count = harness.character_count

      # Select and move first hotspot
      harness.press_key(RL::KeyboardKey::V)
      harness.click_canvas(96, 96)
      harness.step_frames(2)

      harness.press_key(RL::KeyboardKey::M)
      harness.drag_canvas(96, 96, 160, 160)
      harness.step_frames(2)

      # Add another hotspot
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(352, 96)
      harness.step_frames(2)

      # Final counts - should have 3 hotspots (2 original + 1 new)
      harness.hotspot_count.should eq(3)
      harness.character_count.should eq(initial_character_count)

      harness.cleanup
    end
  end

  describe "Scene Navigation Testing" do
    it "handles camera during object creation" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # Pan the camera first
      harness.hold_key(RL::KeyboardKey::D)
      20.times { harness.step_frame }
      harness.release_key(RL::KeyboardKey::D)

      # Camera should have moved
      pos = harness.camera_position
      pos[:x].should be > 0

      # Create hotspot at new camera position
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(200, 200)
      harness.step_frames(2)

      harness.assert_hotspot_count(1)

      # Hotspot position should account for camera offset
      if scene = harness.editor.state.current_scene
        hotspot = scene.hotspots.first
        # World position should be offset by camera
        (hotspot.position.x > 200).should be_true
      end

      harness.cleanup
    end

    it "handles zoom during object creation" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.move_mouse(400, 300)

      # Zoom in first
      harness.scroll(2.0_f32)
      harness.step_frame
      harness.zoom.should be > 1.0

      # Create hotspot while zoomed
      harness.press_key(RL::KeyboardKey::P)
      harness.click_canvas(200, 200)
      harness.step_frames(2)
      harness.assert_hotspot_count(1)

      # Hotspot should have been created
      if scene = harness.editor.state.current_scene
        scene.hotspots.size.should eq(1)
      end

      # Reset zoom
      harness.press_key(RL::KeyboardKey::Home)
      harness.step_frame

      # Scene should still be valid
      harness.has_scene?.should be_true

      harness.cleanup
    end
  end
end
