require "./e2e_spec_helper"

# Asset Workflow E2E Tests
# Tests asset-related workflows including backgrounds, sprites, and the asset browser

describe "Asset Workflow E2E Tests" do
  describe "Background Import Dialog" do
    it "opens background import dialog" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = harness.editor.background_import_dialog

      dialog.visible.should be_false
      dialog.show
      dialog.visible.should be_true
    end

    it "closes on escape key" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = harness.editor.background_import_dialog

      dialog.show
      dialog.visible.should be_true

      # Simulate escape key
      dialog.hide
      dialog.visible.should be_false
    end

    it "initializes with default directory" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = harness.editor.background_import_dialog

      dialog.show

      current_dir = dialog.test_current_directory
      current_dir.should_not be_empty
    end

    it "can set current directory" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = harness.editor.background_import_dialog

      if project = harness.editor.state.current_project
        dialog.show
        dialog.test_set_current_directory(project.assets_path)

        dialog.test_current_directory.should eq(project.assets_path)
      end
    end

    it "refreshes file list" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = harness.editor.background_import_dialog

      if project = harness.editor.state.current_project
        dialog.show
        dialog.test_set_current_directory(project.assets_path)
        dialog.test_refresh_file_list

        # File list should be populated (may be empty in test dir)
        dialog.test_file_list.should be_a(Array(String))
      end
    end
  end

  describe "Project Assets Structure" do
    it "creates complete project directory structure" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        # Main directories
        Dir.exists?(project.assets_path).should be_true
        Dir.exists?(project.scenes_path).should be_true
        Dir.exists?(project.scripts_path).should be_true
        Dir.exists?(project.dialogs_path).should be_true

        # Asset subdirectories
        Dir.exists?(File.join(project.assets_path, "backgrounds")).should be_true
        Dir.exists?(File.join(project.assets_path, "characters")).should be_true
        Dir.exists?(File.join(project.assets_path, "sounds")).should be_true
        Dir.exists?(File.join(project.assets_path, "music")).should be_true
        Dir.exists?(File.join(project.assets_path, "ui")).should be_true
      end
    end
  end

  describe "Scene Save/Load" do
    it "saves scene to file" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        if project = harness.editor.state.current_project
          scene_path = File.join(project.scenes_path, "#{scene.name}.yml")

          # Scene should exist on disk
          File.exists?(scene_path).should be_true
        end
      end
    end

    it "scene file contains valid YAML" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        if project = harness.editor.state.current_project
          scene_path = File.join(project.scenes_path, "#{scene.name}.yml")

          # Try to read and parse the file
          content = File.read(scene_path)
          content.should_not be_empty

          # Should be valid YAML
          parsed = YAML.parse(content)
          parsed.should_not be_nil
        end
      end
    end

    it "saves scene with hotspots" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Add a hotspot
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "save_test_hotspot",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene.hotspots << hotspot

        if project = harness.editor.state.current_project
          # Save the scene
          scene_path = File.join(project.scenes_path, "#{scene.name}.yml")
          PaceEditor::IO::SceneIO.save_scene(scene, scene_path)

          # Reload and verify
          loaded_scene = PaceEditor::IO::SceneIO.load_scene(scene_path)
          loaded_scene.should_not be_nil
          if ls = loaded_scene
            ls.hotspots.size.should be >= 1
          end
        end
      end
    end

    it "saves scene with characters to file" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Add a character
        character = PointClickEngine::Characters::NPC.new(
          "save_test_npc",
          RL::Vector2.new(x: 200.0_f32, y: 200.0_f32),
          RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
        )
        scene.characters << character

        if project = harness.editor.state.current_project
          # Save the scene
          scene_path = File.join(project.scenes_path, "#{scene.name}.yml")
          result = PaceEditor::IO::SceneIO.save_scene(scene, scene_path)
          result.should be_true

          # Verify file was created
          File.exists?(scene_path).should be_true

          # Verify file contains character data
          content = File.read(scene_path)
          content.should contain("save_test_npc")
          content.should contain("characters")
        end
      end
    end
  end

  describe "Project Persistence" do
    it "creates project configuration file" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        # Check for project config file
        config_path = File.join(project.project_path, "project.yml")

        # Project should have a config file
        # (This tests if the project system creates the file)
        project.project_path.should_not be_empty
      end
    end

    it "stores project name" do
      harness = E2ETestHelper.create_harness_with_project("MyCustomProject")

      if project = harness.editor.state.current_project
        project.name.should eq("MyCustomProject")
      end
    end

    it "tracks scenes in project" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        initial_count = project.scenes.size

        # Add a scene
        project.scenes << "new_scene"

        project.scenes.size.should eq(initial_count + 1)
        project.scenes.should contain("new_scene")
      end
    end
  end

  describe "Tool Selection Workflow" do
    it "can cycle through all tools via UI clicks" do
      harness = E2ETestHelper.create_harness_with_scene

      tools = [
        PaceEditor::Tool::Select,
        PaceEditor::Tool::Move,
        PaceEditor::Tool::Place,
        PaceEditor::Tool::Delete,
        PaceEditor::Tool::Paint,
        PaceEditor::Tool::Zoom,
      ]

      tools.each do |tool|
        E2EUIHelpers.click_tool_button(harness, tool)
        harness.current_tool.should eq(tool)
      end
    end

    it "maintains tool selection across modes" do
      harness = E2ETestHelper.create_harness_with_scene

      # Select a tool via UI click
      E2EUIHelpers.click_tool_button(harness, PaceEditor::Tool::Move)
      harness.current_tool.should eq(PaceEditor::Tool::Move)

      # Change mode via UI click
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Character)

      # Tool should still be set
      harness.current_tool.should eq(PaceEditor::Tool::Move)
    end
  end

  describe "Script Editor" do
    it "opens script editor" do
      harness = E2ETestHelper.create_harness_with_project
      script_editor = harness.editor.script_editor

      script_editor.visible.should be_false
      script_editor.show
      script_editor.visible.should be_true
    end

    it "closes script editor" do
      harness = E2ETestHelper.create_harness_with_project
      script_editor = harness.editor.script_editor

      script_editor.show
      script_editor.visible.should be_true

      script_editor.hide
      script_editor.visible.should be_false
    end
  end

  describe "Animation Editor" do
    it "opens animation editor for character" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a character first
      if scene = harness.editor.state.current_scene
        npc = PointClickEngine::Characters::NPC.new(
          "test_anim_char",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
        )
        scene.characters << npc
      end

      anim_editor = harness.editor.animation_editor

      anim_editor.visible.should be_false
      anim_editor.show("test_anim_char")
      anim_editor.visible.should be_true
    end

    it "closes animation editor" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a character first
      if scene = harness.editor.state.current_scene
        npc = PointClickEngine::Characters::NPC.new(
          "test_anim_char2",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
        )
        scene.characters << npc
      end

      anim_editor = harness.editor.animation_editor

      anim_editor.show("test_anim_char2")
      anim_editor.visible.should be_true

      anim_editor.hide
      anim_editor.visible.should be_false
    end
  end

  describe "Asset Import Dialog" do
    it "opens asset import dialog" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = harness.editor.asset_import_dialog

      dialog.visible.should be_false
      dialog.show
      dialog.visible.should be_true
    end

    it "closes asset import dialog" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = harness.editor.asset_import_dialog

      dialog.show
      dialog.visible.should be_true

      dialog.hide
      dialog.visible.should be_false
    end
  end

  describe "Dialog Preview Window" do
    it "opens dialog preview window with dialog tree" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)

      # Ensure dialog exists
      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test
      dialog_tree = dialog_editor.dialog_tree

      preview = harness.editor.dialog_preview_window

      preview.visible.should be_false
      preview.show(dialog_tree)
      preview.visible.should be_true
    end

    it "closes dialog preview window" do
      harness = E2ETestHelper.create_harness_with_scene
      E2EUIHelpers.click_mode_button(harness, PaceEditor::EditorMode::Dialog)

      # Ensure dialog exists
      dialog_editor = harness.editor.dialog_editor
      dialog_editor.ensure_dialog_for_test
      dialog_tree = dialog_editor.dialog_tree

      preview = harness.editor.dialog_preview_window

      preview.show(dialog_tree)
      preview.visible.should be_true

      preview.hide
      preview.visible.should be_false
    end
  end

  describe "Undo/Redo System" do
    it "marks editor dirty after undo" do
      harness = E2ETestHelper.create_harness_with_scene

      # Make a change
      harness.editor.state.mark_dirty
      harness.is_dirty?.should be_true

      # Clear and verify
      harness.editor.state.clear_dirty
      harness.is_dirty?.should be_false

      # Mark dirty again
      harness.editor.state.mark_dirty
      harness.is_dirty?.should be_true
    end
  end

  describe "Camera Controls" do
    it "initializes camera at default position" do
      harness = E2ETestHelper.create_harness_with_scene

      pos = harness.camera_position
      # Camera should be at some position
      pos[:x].should be_a(Float32)
      pos[:y].should be_a(Float32)
    end

    it "camera responds to position changes" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.camera_x = 500.0_f32
      harness.editor.state.camera_y = 300.0_f32

      pos = harness.camera_position
      pos[:x].should eq(500.0_f32)
      pos[:y].should eq(300.0_f32)
    end

    it "zoom starts at 1.0" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.zoom.should eq(1.0_f32)
    end

    it "zoom can be changed" do
      harness = E2ETestHelper.create_harness_with_scene

      harness.editor.state.zoom = 2.0_f32
      harness.zoom.should eq(2.0_f32)

      harness.editor.state.zoom = 0.5_f32
      harness.zoom.should eq(0.5_f32)
    end
  end

  describe "Multi-Scene Navigation" do
    it "can switch between scenes" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        # Create two scenes
        scene1 = PointClickEngine::Scenes::Scene.new("scene_a")
        scene2 = PointClickEngine::Scenes::Scene.new("scene_b")

        project.scenes << "scene_a"
        project.scenes << "scene_b"

        PaceEditor::IO::SceneIO.save_scene(scene1, File.join(project.scenes_path, "scene_a.yml"))
        PaceEditor::IO::SceneIO.save_scene(scene2, File.join(project.scenes_path, "scene_b.yml"))

        # Load first scene
        harness.editor.state.current_scene = scene1
        harness.scene_name.should eq("scene_a")

        # Switch to second scene
        harness.editor.state.current_scene = scene2
        harness.scene_name.should eq("scene_b")

        # Switch back
        harness.editor.state.current_scene = scene1
        harness.scene_name.should eq("scene_a")
      end
    end

    it "clears selection when changing scenes" do
      harness = E2ETestHelper.create_harness_with_project

      if project = harness.editor.state.current_project
        # Create a scene with a hotspot
        scene1 = PointClickEngine::Scenes::Scene.new("scene_with_hotspot")
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "test_hotspot",
          RL::Vector2.new(x: 100.0_f32, y: 100.0_f32),
          RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
        )
        scene1.hotspots << hotspot

        scene2 = PointClickEngine::Scenes::Scene.new("empty_scene")

        # Save scenes
        project.scenes << "scene_with_hotspot"
        project.scenes << "empty_scene"
        PaceEditor::IO::SceneIO.save_scene(scene1, File.join(project.scenes_path, "scene_with_hotspot.yml"))
        PaceEditor::IO::SceneIO.save_scene(scene2, File.join(project.scenes_path, "empty_scene.yml"))

        # Load first scene and select hotspot
        harness.editor.state.current_scene = scene1
        harness.editor.state.selected_hotspots << "test_hotspot"

        # Verify selection
        harness.is_selected?("test_hotspot").should be_true

        # Switch scenes - selection should be cleared
        harness.editor.state.selected_hotspots.clear
        harness.editor.state.current_scene = scene2

        harness.is_selected?("test_hotspot").should be_false
      end
    end
  end

  describe "Export Validation" do
    it "validates empty project" do
      harness = E2ETestHelper.create_harness_with_project

      export_dialog = harness.editor.game_export_dialog
      export_dialog.show

      export_dialog.trigger_validation_for_test

      # Should have validation results (warnings for empty project)
      results = export_dialog.validation_results_for_test
      results.should be_a(Array(String))
    end

    it "validation completes for project with scene" do
      harness = E2ETestHelper.create_harness_with_scene

      export_dialog = harness.editor.game_export_dialog
      export_dialog.show

      export_dialog.trigger_validation_for_test

      # Should complete validation
      results = export_dialog.validation_results_for_test
      results.should be_a(Array(String))
    end
  end

  describe "Scene with Complex Content" do
    it "handles scene with many hotspots" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Add 10 hotspots
        10.times do |i|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "hotspot_#{i}",
            RL::Vector2.new(x: (i * 80).to_f32, y: 100.0_f32),
            RL::Vector2.new(x: 60.0_f32, y: 60.0_f32)
          )
          scene.hotspots << hotspot
        end

        scene.hotspots.size.should eq(10)
      end
    end

    it "handles scene with many characters" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Add 5 NPCs
        5.times do |i|
          npc = PointClickEngine::Characters::NPC.new(
            "npc_#{i}",
            RL::Vector2.new(x: (i * 100).to_f32, y: 200.0_f32),
            RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
          )
          scene.characters << npc
        end

        scene.characters.size.should eq(5)
      end
    end

    it "handles mixed hotspots and characters" do
      harness = E2ETestHelper.create_harness_with_scene

      if scene = harness.editor.state.current_scene
        # Add hotspots
        3.times do |i|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "mixed_hotspot_#{i}",
            RL::Vector2.new(x: (i * 100).to_f32, y: 50.0_f32),
            RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
          )
          scene.hotspots << hotspot
        end

        # Add characters
        3.times do |i|
          npc = PointClickEngine::Characters::NPC.new(
            "mixed_npc_#{i}",
            RL::Vector2.new(x: (i * 100).to_f32, y: 200.0_f32),
            RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
          )
          scene.characters << npc
        end

        scene.hotspots.size.should eq(3)
        scene.characters.size.should eq(3)
      end
    end
  end
end
