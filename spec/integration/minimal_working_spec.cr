require "../spec_helper"

describe "Minimal Working Integration" do
  it "creates a project" do
    temp_dir = File.tempname("minimal_#{Time.utc.to_unix_ms}")
    project = PaceEditor::Core::Project.new("Minimal", temp_dir)

    project.name.should eq("Minimal")
    Dir.exists?(temp_dir).should be_true

    FileUtils.rm_rf(temp_dir)
  end

  it "has editor state" do
    state = PaceEditor::Core::EditorState.new
    state.should_not be_nil

    # Set a project
    temp_dir = File.tempname("state_#{Time.utc.to_unix_ms}")
    project = PaceEditor::Core::Project.new("State Test", temp_dir)
    state.current_project = project

    state.current_project.not_nil!.name.should eq("State Test")

    FileUtils.rm_rf(temp_dir)
  end

  it "creates scenes" do
    scene = PointClickEngine::Scenes::Scene.new("test_scene")
    scene.name.should eq("test_scene")

    # Add basic properties we know exist
    scene.background_path = "test.png"
    scene.background_path.should eq("test.png")
  end

  it "creates hotspots" do
    hotspot = PointClickEngine::Scenes::Hotspot.new(
      "test_hotspot",
      RL::Vector2.new(100.0_f32, 200.0_f32),
      RL::Vector2.new(50.0_f32, 50.0_f32)
    )

    hotspot.name.should eq("test_hotspot")
    hotspot.position.x.should eq(100.0_f32)
    hotspot.size.x.should eq(50.0_f32)
  end

  it "saves scenes to YAML" do
    temp_dir = File.tempname("yaml_#{Time.utc.to_unix_ms}")
    project = PaceEditor::Core::Project.new("YAML Test", temp_dir)

    scene = PointClickEngine::Scenes::Scene.new("yaml_scene")
    scene.background_path = "bg.png"

    # Save scene
    scene_path = File.join(project.scenes_path, "yaml_scene.yaml")
    PaceEditor::IO::SceneIO.save_scene(scene, scene_path)

    File.exists?(scene_path).should be_true

    # Load it back
    loaded = PaceEditor::IO::SceneIO.load_scene(scene_path)
    loaded.should_not be_nil
    if loaded
      loaded.name.should eq("yaml_scene")
      loaded.background_path.should eq("bg.png")
    end

    FileUtils.rm_rf(temp_dir)
  end
end
