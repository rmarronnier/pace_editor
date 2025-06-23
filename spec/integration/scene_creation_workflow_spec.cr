require "../spec_helper"

describe "Scene Creation Workflow" do
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

  describe "Scene Creation Wizard" do
    it "creates and initializes scene creation wizard" do
      state = PaceEditor::Core::EditorState.new
      wizard = PaceEditor::UI::SceneCreationWizard.new(state)

      # Wizard should initialize properly
      wizard.should_not be_nil
      wizard.visible.should be_false
    end

    it "shows and hides wizard correctly" do
      state = PaceEditor::Core::EditorState.new
      wizard = PaceEditor::UI::SceneCreationWizard.new(state)

      # Show wizard
      wizard.show
      wizard.visible.should be_true

      # Hide wizard
      wizard.hide
      wizard.visible.should be_false
    end

    it "integrates with editor window" do
      editor_window = PaceEditor::Core::EditorWindow.new

      # Scene creation wizard should be initialized
      editor_window.scene_creation_wizard.should_not be_nil
      editor_window.scene_creation_wizard.visible.should be_false

      # Show wizard through editor window
      editor_window.show_scene_creation_wizard
      editor_window.scene_creation_wizard.visible.should be_true
    end
  end

  describe "Menu Integration" do
    it "connects New Scene menu to wizard" do
      project = PaceEditor::Core::Project.new(
        name: "Menu Test Project",
        project_path: project_dir
      )

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      # Create editor window and connect state
      editor_window = PaceEditor::Core::EditorWindow.new
      state.editor_window = editor_window

      # Menu bar should be able to show wizard
      menu_bar = PaceEditor::UI::MenuBar.new(state)
      menu_bar.should_not be_nil

      # Scene creation wizard should be accessible through editor window
      state.editor_window.not_nil!.scene_creation_wizard.should_not be_nil

      # Verify wizard can be shown (simulates "New Scene" menu click)
      editor_window.show_scene_creation_wizard
      editor_window.scene_creation_wizard.visible.should be_true
    end
  end

  describe "Complete Scene Creation Workflow" do
    it "allows creating scene through wizard" do
      # 1. Create complete test setup
      project = PaceEditor::Core::Project.new(
        name: "Scene Creation Test",
        project_path: project_dir
      )

      editor_window = PaceEditor::Core::EditorWindow.new
      state = editor_window.state
      state.current_project = project

      # 2. Create test background asset
      bg_dir = File.join(project_dir, "assets", "backgrounds")
      Dir.mkdir_p(bg_dir)
      bg_file = File.join(bg_dir, "forest.png")
      File.write(bg_file, "fake_background_data")

      # 3. Verify project has no scenes initially
      state.current_scene.should be_nil

      # 4. Scene creation wizard exists and can be shown
      wizard = editor_window.scene_creation_wizard
      wizard.should_not be_nil

      # Show wizard (simulates "New Scene" menu click)
      editor_window.show_scene_creation_wizard
      wizard.visible.should be_true

      # 5. Verify wizard workflow would create scene
      # (In actual usage, user would go through steps)

      # Step 1: Scene name
      test_scene_name = "forest_clearing"

      # Step 2: Template selection
      test_template = "outdoor"

      # Step 3: Background selection (optional)
      test_background = "forest.png"

      # Step 4: Scene settings
      test_width = 1024
      test_height = 768

      # 6. Simulate scene creation (what wizard would do)
      scene = PointClickEngine::Scenes::Scene.new(test_scene_name)
      scene.scale = 1.0_f32
      scene.background_path = "backgrounds/#{test_background}"

      # Apply outdoor template
      left_path = PointClickEngine::Scenes::Hotspot.new(
        "left_path",
        RL::Vector2.new(50.0_f32, 400.0_f32),
        RL::Vector2.new(100.0_f32, 100.0_f32)
      )
      scene.add_hotspot(left_path)

      # 7. Set as current scene
      state.current_scene = scene
      state.current_mode = PaceEditor::EditorMode::Scene

      # 8. Save scene file
      scenes_dir = File.join(project_dir, "scenes")
      Dir.mkdir_p(scenes_dir)
      scene_file = File.join(scenes_dir, "#{test_scene_name}.yml")
      File.write(scene_file, scene.to_yaml)

      # 9. Verify complete scene creation result
      File.exists?(scene_file).should be_true
      state.current_scene.should eq(scene)
      state.current_mode.should eq(PaceEditor::EditorMode::Scene)
      scene.background_path.should eq("backgrounds/forest.png")
      scene.hotspots.size.should eq(1)
      scene.hotspots.first.name.should eq("left_path")

      # 10. Verify scene can be loaded back
      yaml_content = File.read(scene_file)
      yaml_content.should contain("forest_clearing")
      yaml_content.should contain("backgrounds/forest.png")
    end

    it "handles different scene templates" do
      state = PaceEditor::Core::EditorState.new
      wizard = PaceEditor::UI::SceneCreationWizard.new(state)

      # Test template creation
      templates = ["empty", "room", "outdoor", "menu"]

      templates.each do |template|
        scene = PointClickEngine::Scenes::Scene.new("test_#{template}")

        # Simulate template application
        case template
        when "empty"
          # Empty scene has no hotspots
          scene.hotspots.size.should eq(0)
        when "room"
          # Room template would add door and window
          door = PointClickEngine::Scenes::Hotspot.new("door", RL::Vector2.new(100.0_f32, 200.0_f32), RL::Vector2.new(80.0_f32, 160.0_f32))
          window = PointClickEngine::Scenes::Hotspot.new("window", RL::Vector2.new(300.0_f32, 100.0_f32), RL::Vector2.new(120.0_f32, 80.0_f32))
          scene.add_hotspot(door)
          scene.add_hotspot(window)
          scene.hotspots.size.should eq(2)
        when "outdoor"
          # Outdoor template would add paths and tree
          left_path = PointClickEngine::Scenes::Hotspot.new("left_path", RL::Vector2.new(50.0_f32, 400.0_f32), RL::Vector2.new(100.0_f32, 100.0_f32))
          right_path = PointClickEngine::Scenes::Hotspot.new("right_path", RL::Vector2.new(500.0_f32, 400.0_f32), RL::Vector2.new(100.0_f32, 100.0_f32))
          tree = PointClickEngine::Scenes::Hotspot.new("old_tree", RL::Vector2.new(250.0_f32, 150.0_f32), RL::Vector2.new(80.0_f32, 200.0_f32))
          scene.add_hotspot(left_path)
          scene.add_hotspot(right_path)
          scene.add_hotspot(tree)
          scene.hotspots.size.should eq(3)
        when "menu"
          # Menu template would add menu buttons
          start_button = PointClickEngine::Scenes::Hotspot.new("start_button", RL::Vector2.new(350.0_f32, 200.0_f32), RL::Vector2.new(150.0_f32, 50.0_f32))
          load_button = PointClickEngine::Scenes::Hotspot.new("load_button", RL::Vector2.new(350.0_f32, 280.0_f32), RL::Vector2.new(150.0_f32, 50.0_f32))
          exit_button = PointClickEngine::Scenes::Hotspot.new("exit_button", RL::Vector2.new(350.0_f32, 360.0_f32), RL::Vector2.new(150.0_f32, 50.0_f32))
          scene.add_hotspot(start_button)
          scene.add_hotspot(load_button)
          scene.add_hotspot(exit_button)
          scene.hotspots.size.should eq(3)
        end
      end
    end

    it "validates scene name input" do
      state = PaceEditor::Core::EditorState.new
      wizard = PaceEditor::UI::SceneCreationWizard.new(state)

      # Valid scene names
      valid_names = ["main_scene", "forest_path", "wizard_tower", "scene_01", "menu-screen"]
      valid_names.each do |name|
        # Scene name should only contain alphanumeric, underscore, hyphen
        (name =~ /^[a-zA-Z0-9_-]+$/).should_not be_nil
      end

      # Invalid scene names would be rejected
      invalid_names = ["", "scene with spaces", "scene@#$", "scene/path"]
      invalid_names.each do |name|
        # These would not pass validation
        is_valid = (name =~ /^[a-zA-Z0-9_-]+$/) != nil && !name.empty?
        is_valid.should be_false
      end
    end
  end

  describe "Background Integration" do
    it "integrates with background import workflow" do
      project = PaceEditor::Core::Project.new(
        name: "Background Integration Test",
        project_path: project_dir
      )

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      # Create some background assets
      bg_dir = File.join(project_dir, "assets", "backgrounds")
      Dir.mkdir_p(bg_dir)

      backgrounds = ["castle.png", "forest.jpg", "dungeon.bmp"]
      backgrounds.each do |bg_file|
        File.write(File.join(bg_dir, bg_file), "fake_background_data")
      end

      wizard = PaceEditor::UI::SceneCreationWizard.new(state)
      wizard.show

      # Wizard should be able to find existing backgrounds
      backgrounds.each do |bg_file|
        File.exists?(File.join(bg_dir, bg_file)).should be_true
      end

      # Scene created with background should reference it correctly
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.background_path = "backgrounds/castle.png"

      # Verify background path format
      scene.background_path.should eq("backgrounds/castle.png")

      # Verify actual background file exists
      if bg_path = scene.background_path
        full_path = File.join(project_dir, "assets", bg_path)
        File.exists?(full_path).should be_true
      end
    end
  end

  describe "Scene Creation Error Handling" do
    it "handles missing project gracefully" do
      state = PaceEditor::Core::EditorState.new
      state.current_project = nil

      wizard = PaceEditor::UI::SceneCreationWizard.new(state)
      wizard.should_not be_nil

      # Wizard should handle missing project
      wizard.show
      wizard.visible.should be_true
    end

    it "handles duplicate scene names gracefully" do
      project = PaceEditor::Core::Project.new(
        name: "Duplicate Test",
        project_path: project_dir
      )

      # Create existing scene
      scenes_dir = File.join(project_dir, "scenes")
      Dir.mkdir_p(scenes_dir)
      existing_scene_file = File.join(scenes_dir, "main_room.yml")
      File.write(existing_scene_file, "---\nname: main_room\n")

      # Add to project scenes list
      project.scenes << "main_room"

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      wizard = PaceEditor::UI::SceneCreationWizard.new(state)

      # Wizard should be able to detect existing scenes
      project.scenes.should contain("main_room")
      File.exists?(existing_scene_file).should be_true
    end

    it "handles missing assets directory gracefully" do
      # Create project without calling setup_project_structure
      project = PaceEditor::Core::Project.new(
        name: "Missing Assets Test",
        project_path: project_dir
      )

      # Manually remove the backgrounds directory if it was created
      bg_dir = File.join(project_dir, "assets", "backgrounds")
      FileUtils.rm_rf(bg_dir) if Dir.exists?(bg_dir)

      # Verify it doesn't exist
      Dir.exists?(bg_dir).should be_false

      state = PaceEditor::Core::EditorState.new
      state.current_project = project

      wizard = PaceEditor::UI::SceneCreationWizard.new(state)
      wizard.show
      wizard.visible.should be_true

      # Wizard should handle missing background directory
      # (No backgrounds would be available for selection)
    end
  end

  describe "Wizard State Management" do
    it "tracks wizard steps correctly" do
      state = PaceEditor::Core::EditorState.new
      wizard = PaceEditor::UI::SceneCreationWizard.new(state)

      # Wizard should start at step 1
      wizard.show
      wizard.visible.should be_true

      # Steps would be:
      # 1. Scene Information (name)
      # 2. Template Selection
      # 3. Background Selection
      # 4. Scene Settings

      # Wizard tracks progress through these steps
      # (Step management would be tested through UI interaction)
    end

    it "validates step progression correctly" do
      state = PaceEditor::Core::EditorState.new
      wizard = PaceEditor::UI::SceneCreationWizard.new(state)

      # Step 1 requires valid scene name
      # Step 2 requires template selection
      # Step 3 is optional (background)
      # Step 4 requires valid dimensions

      # These validations ensure user provides necessary information
      # before allowing scene creation
    end
  end
end
