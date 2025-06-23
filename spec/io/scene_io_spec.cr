require "../spec_helper"
require "../../src/pace_editor/io/scene_io"

describe PaceEditor::IO::SceneIO do
  describe ".save_scene" do
    it "saves a scene with hotspots to YAML" do
      # Create a test scene with hotspots
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.background_path = "backgrounds/test.png"
      scene.scale = 2.0_f32
      scene.enable_pathfinding = true
      scene.navigation_cell_size = 32
      
      # Add a hotspot
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "door",
        RL::Vector2.new(100.0_f32, 200.0_f32),
        RL::Vector2.new(50.0_f32, 80.0_f32)
      )
      hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
      hotspot.visible = true
      hotspot.description = "A wooden door"
      scene.hotspots << hotspot
      
      # Save the scene
      temp_file = File.tempfile("scene", ".yml")
      result = PaceEditor::IO::SceneIO.save_scene(scene, temp_file.path)
      
      result.should be_true
      File.exists?(temp_file.path).should be_true
      
      # Verify the YAML content
      yaml_content = File.read(temp_file.path)
      yaml_data = YAML.parse(yaml_content)
      
      yaml_data["name"].as_s.should eq("test_scene")
      yaml_data["background_path"].as_s.should eq("backgrounds/test.png")
      yaml_data["scale"].as_f.should eq(2.0)
      yaml_data["enable_pathfinding"].as_bool.should be_true
      yaml_data["navigation_cell_size"].as_i.should eq(32)
      
      # Check hotspot
      hotspots = yaml_data["hotspots"].as_a
      hotspots.size.should eq(1)
      hotspot_data = hotspots[0]
      hotspot_data["name"].as_s.should eq("door")
      hotspot_data["position"]["x"].as_f.should eq(100.0)
      hotspot_data["position"]["y"].as_f.should eq(200.0)
      hotspot_data["size"]["x"].as_f.should eq(50.0)
      hotspot_data["size"]["y"].as_f.should eq(80.0)
      hotspot_data["cursor_type"].as_s.should eq("Hand")
      hotspot_data["visible"].as_bool.should be_true
      hotspot_data["description"].as_s.should eq("A wooden door")
      
      temp_file.delete
    end
    
    it "saves a scene with characters to YAML" do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      
      # Add an NPC
      npc = PointClickEngine::Characters::NPC.new(
        "guard",
        RL::Vector2.new(300.0_f32, 400.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      npc.description = "A stern guard"
      npc.walking_speed = 150.0_f32
      npc.state = PointClickEngine::Characters::CharacterState::Idle
      npc.direction = PointClickEngine::Characters::Direction::Left
      npc.mood = PointClickEngine::Characters::NPCMood::Hostile
      npc.add_dialogue("Halt! Who goes there?")
      scene.characters << npc
      
      temp_file = File.tempfile("scene", ".yml")
      result = PaceEditor::IO::SceneIO.save_scene(scene, temp_file.path)
      
      result.should be_true
      
      yaml_content = File.read(temp_file.path)
      yaml_data = YAML.parse(yaml_content)
      
      characters = yaml_data["characters"].as_a
      characters.size.should eq(1)
      char_data = characters[0]
      char_data["name"].as_s.should eq("guard")
      char_data["type"].as_s.should eq("npc")
      char_data["position"]["x"].as_f.should eq(300.0)
      char_data["position"]["y"].as_f.should eq(400.0)
      char_data["description"].as_s.should eq("A stern guard")
      char_data["walking_speed"].as_f.should eq(150.0)
      char_data["state"].as_s.should eq("Idle")
      char_data["direction"].as_s.should eq("Left")
      char_data["mood"].as_s.should eq("Hostile")
      char_data["dialogues"].as_a[0].as_s.should eq("Halt! Who goes there?")
      
      temp_file.delete
    end
    
    it "creates directory if it doesn't exist" do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      
      temp_dir = File.tempfile("dir").path
      File.delete(temp_dir) if File.exists?(temp_dir)
      scene_path = File.join(temp_dir, "scenes", "test.yml")
      
      result = PaceEditor::IO::SceneIO.save_scene(scene, scene_path)
      
      result.should be_true
      Dir.exists?(File.dirname(scene_path)).should be_true
      
      FileUtils.rm_rf(temp_dir)
    end
    
    it "handles save errors gracefully" do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      
      # Try to save to an invalid path
      result = PaceEditor::IO::SceneIO.save_scene(scene, "/invalid/path/scene.yml")
      
      result.should be_false
    end
  end
  
  describe ".load_scene" do
    it "loads a scene with hotspots from YAML" do
      # Create YAML content
      yaml_content = <<-YAML
        name: loaded_scene
        background_path: bg/forest.png
        scale: 1.5
        enable_pathfinding: false
        navigation_cell_size: 24
        script_path: scripts/forest.lua
        hotspots:
          - name: tree
            position:
              x: 50.0
              y: 100.0
            size:
              x: 30.0
              y: 40.0
            cursor_type: Look
            visible: true
            description: An old oak tree
        characters: []
        walkable_areas: null
      YAML
      
      temp_file = File.tempfile("scene", ".yml")
      File.write(temp_file.path, yaml_content)
      
      scene = PaceEditor::IO::SceneIO.load_scene(temp_file.path)
      
      scene.should_not be_nil
      scene.not_nil!.name.should eq("loaded_scene")
      scene.not_nil!.background_path.should eq("bg/forest.png")
      scene.not_nil!.scale.should eq(1.5_f32)
      scene.not_nil!.enable_pathfinding.should be_false
      scene.not_nil!.navigation_cell_size.should eq(24)
      scene.not_nil!.script_path.should eq("scripts/forest.lua")
      
      # Check hotspot
      hotspots = scene.not_nil!.hotspots
      hotspots.size.should eq(1)
      hotspot = hotspots[0]
      hotspot.name.should eq("tree")
      hotspot.position.x.should eq(50.0_f32)
      hotspot.position.y.should eq(100.0_f32)
      hotspot.size.x.should eq(30.0_f32)
      hotspot.size.y.should eq(40.0_f32)
      hotspot.cursor_type.should eq(PointClickEngine::Scenes::Hotspot::CursorType::Look)
      hotspot.visible.should be_true
      hotspot.description.should eq("An old oak tree")
      
      temp_file.delete
    end
    
    it "loads a scene with characters from YAML" do
      yaml_content = <<-YAML
        name: loaded_scene
        background_path: null
        scale: 1.0
        enable_pathfinding: true
        navigation_cell_size: 16
        script_path: null
        hotspots: []
        characters:
          - name: merchant
            type: npc
            description: A traveling merchant
            position:
              x: 200.0
              y: 300.0
            size:
              x: 32.0
              y: 64.0
            state: Talking
            direction: Right
            walking_speed: 100.0
            use_pathfinding: true
            mood: Friendly
            dialogues:
              - "Welcome to my shop!"
              - "What can I get you?"
            can_repeat_dialogues: true
            interaction_distance: 75.0
        walkable_areas: null
      YAML
      
      temp_file = File.tempfile("scene", ".yml")
      File.write(temp_file.path, yaml_content)
      
      scene = PaceEditor::IO::SceneIO.load_scene(temp_file.path)
      
      scene.should_not be_nil
      
      characters = scene.not_nil!.characters
      characters.size.should eq(1)
      char = characters[0].as(PointClickEngine::Characters::NPC)
      char.name.should eq("merchant")
      char.description.should eq("A traveling merchant")
      char.position.x.should eq(200.0_f32)
      char.position.y.should eq(300.0_f32)
      char.state.should eq(PointClickEngine::Characters::CharacterState::Talking)
      char.direction.should eq(PointClickEngine::Characters::Direction::Right)
      char.mood.should eq(PointClickEngine::Characters::NPCMood::Friendly)
      char.walking_speed.should eq(100.0_f32)
      char.use_pathfinding.should be_true
      char.can_repeat_dialogues.should be_true
      char.interaction_distance.should eq(75.0_f32)
      
      temp_file.delete
    end
    
    it "loads walkable areas from YAML" do
      yaml_content = <<-YAML
        name: loaded_scene
        background_path: null
        scale: 1.0
        enable_pathfinding: true
        navigation_cell_size: 16
        script_path: null
        hotspots: []
        characters: []
        walkable_areas:
          regions:
            - name: main_area
              walkable: true
              vertices:
                - x: 0.0
                  y: 0.0
                - x: 100.0
                  y: 0.0
                - x: 100.0
                  y: 100.0
                - x: 0.0
                  y: 100.0
          scale_zones:
            - min_y: 0.0
              max_y: 100.0
              min_scale: 0.5
              max_scale: 1.0
      YAML
      
      temp_file = File.tempfile("scene", ".yml")
      File.write(temp_file.path, yaml_content)
      
      scene = PaceEditor::IO::SceneIO.load_scene(temp_file.path)
      
      scene.should_not be_nil
      walkable_area = scene.not_nil!.walkable_area
      walkable_area.should_not be_nil
      
      # Check regions
      regions = walkable_area.not_nil!.regions
      regions.size.should eq(1)
      region = regions[0]
      region.name.should eq("main_area")
      region.walkable.should be_true
      region.vertices.size.should eq(4)
      region.vertices[0].x.should eq(0.0_f32)
      region.vertices[0].y.should eq(0.0_f32)
      
      # Check scale zones
      scale_zones = walkable_area.not_nil!.scale_zones
      scale_zones.size.should eq(1)
      zone = scale_zones[0]
      zone.min_y.should eq(0.0_f32)
      zone.max_y.should eq(100.0_f32)
      zone.min_scale.should eq(0.5_f32)
      zone.max_scale.should eq(1.0_f32)
      
      temp_file.delete
    end
    
    it "returns nil for non-existent file" do
      scene = PaceEditor::IO::SceneIO.load_scene("/non/existent/file.yml")
      scene.should be_nil
    end
    
    it "handles load errors gracefully" do
      temp_file = File.tempfile("scene", ".yml")
      File.write(temp_file.path, "invalid yaml content {{{")
      
      scene = PaceEditor::IO::SceneIO.load_scene(temp_file.path)
      scene.should be_nil
      
      temp_file.delete
    end
  end
end