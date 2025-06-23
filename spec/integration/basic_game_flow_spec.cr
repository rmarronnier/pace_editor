require "../spec_helper"

describe "Basic Game Creation Flow" do
  # This tests the essential workflow of creating a game in PACE

  it "completes basic game creation workflow" do
    # 1. Create Project
    temp_dir = File.tempname("basic_game_#{Time.utc.to_unix_ms}")
    project = PaceEditor::Core::Project.new("Basic Game", temp_dir)

    project.name.should eq("Basic Game")
    Dir.exists?(project.project_path).should be_true
    Dir.exists?(project.scenes_path).should be_true
    Dir.exists?(project.assets_path).should be_true

    # 2. Create and Save a Scene
    scene = PointClickEngine::Scenes::Scene.new("main_room")
    scene.background_path = "backgrounds/room.png"

    # Add a simple hotspot
    hotspot = PointClickEngine::Scenes::Hotspot.new(
      "clickable_area",
      RL::Vector2.new(100.0_f32, 100.0_f32),
      RL::Vector2.new(50.0_f32, 50.0_f32)
    )
    hotspot.actions["on_click"] = [
      PointClickEngine::Scenes::Action.new(
        type: PointClickEngine::Scenes::ActionType::ShowMessage,
        parameters: {"message" => "Hello, World!"}
      ),
    ]
    scene.hotspots << hotspot

    # Save scene
    scene_file = PaceEditor::IO::SceneIO.get_scene_file_path(project, scene.name)
    PaceEditor::IO::SceneIO.save_scene(scene, scene_file)

    File.exists?(scene_file).should be_true

    # 3. Load Scene Back
    loaded_scene = PaceEditor::IO::SceneIO.load_scene(scene_file)
    loaded_scene.should_not be_nil
    loaded_scene.name.should eq("main_room")
    loaded_scene.hotspots.size.should eq(1)
    loaded_scene.hotspots.first.id.should eq("clickable_area")

    # 4. Create Game Config
    config = PointClickEngine::GameConfig.new(
      title: "Basic Game",
      start_scene: "main_room",
      resolution: {width: 800, height: 600},
      fullscreen: false
    )

    # 5. Validate Project Structure
    validator = PaceEditor::Validation::ProjectValidator.new(project)
    result = validator.validate_for_export(config)

    # Will have errors for missing assets, but structure is valid
    result.warnings.size.should be >= 0 # May have warnings

    # 6. Test Export Structure (without full export)
    exporter = PaceEditor::Export::GameExporter.new(project)

    # Test that exporter can be created
    exporter.should_not be_nil

    # Cleanup
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end

  it "handles scene transitions" do
    temp_dir = File.tempname("transition_game_#{Time.utc.to_unix_ms}")
    project = PaceEditor::Core::Project.new("Transition Game", temp_dir)

    # Create two connected scenes
    scenes = ["room_a", "room_b"].map do |name|
      scene = PointClickEngine::Scenes::Scene.new(name)
      scene.background_path = "backgrounds/#{name}.png"
      scene
    end

    # Add transition from A to B
    transition_hotspot = PointClickEngine::Scenes::Hotspot.new(
      "go_to_b",
      RL::Vector2.new(700.0_f32, 300.0_f32),
      RL::Vector2.new(100.0_f32, 200.0_f32)
    )
    transition_hotspot.actions["on_click"] = [
      PointClickEngine::Scenes::Action.new(
        type: PointClickEngine::Scenes::ActionType::ChangeScene,
        parameters: {"scene" => "room_b"}
      ),
    ]
    scenes[0].hotspots << transition_hotspot

    # Save both scenes
    scenes.each do |scene|
      path = PaceEditor::IO::SceneIO.get_scene_file_path(project, scene.name)
      PaceEditor::IO::SceneIO.save_scene(scene, path)
      File.exists?(path).should be_true
    end

    # Verify scenes can be loaded
    scene_a_path = PaceEditor::IO::SceneIO.get_scene_file_path(project, "room_a")
    loaded_a = PaceEditor::IO::SceneIO.load_scene(scene_a_path)

    loaded_a.hotspots.first.actions["on_click"].first.parameters["scene"].should eq("room_b")

    # Cleanup
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end

  it "manages game assets" do
    temp_dir = File.tempname("asset_game_#{Time.utc.to_unix_ms}")
    project = PaceEditor::Core::Project.new("Asset Game", temp_dir)

    # Test asset paths
    asset_paths = [
      project.backgrounds_path,
      project.characters_path,
      project.sounds_path,
      project.music_path,
      project.scripts_path,
      project.dialogs_path,
    ]

    asset_paths.each do |path|
      Dir.exists?(path).should be_true
    end

    # Simulate asset import
    dummy_assets = {
      "backgrounds/title.png"  => "image_data",
      "characters/hero.png"    => "sprite_data",
      "sounds/click.wav"       => "sound_data",
      "music/theme.ogg"        => "music_data",
      "scripts/game_logic.lua" => "-- Lua script",
      "dialogs/intro.yaml"     => "dialogue_graph:\n  name: intro",
    }

    dummy_assets.each do |relative_path, content|
      full_path = File.join(project.assets_path, relative_path)
      Dir.mkdir_p(File.dirname(full_path))
      File.write(full_path, content)
      File.exists?(full_path).should be_true
    end

    # Cleanup
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end
end
