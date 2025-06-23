require "../spec_helper"

describe "Create Adventure Game" do
  # Create a simple but complete adventure game
  it "creates a two-room adventure with puzzle" do
    temp_dir = File.tempname("adventure_#{Time.utc.to_unix_ms}")
    project = PaceEditor::Core::Project.new("Key Quest", temp_dir)
    state = PaceEditor::Core::EditorState.new
    state.current_project = project

    # === Room 1: Living Room ===
    living_room = PointClickEngine::Scenes::Scene.new("living_room")
    living_room.background_path = "backgrounds/living_room.png"

    # Add door to bedroom
    door = PointClickEngine::Scenes::Hotspot.new(
      "bedroom_door",
      RL::Vector2.new(600.0_f32, 200.0_f32),
      RL::Vector2.new(100.0_f32, 200.0_f32)
    )
    door.description = "A door to the bedroom"
    door.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
    living_room.hotspots << door

    # Add key on table
    key = PointClickEngine::Scenes::Hotspot.new(
      "golden_key",
      RL::Vector2.new(300.0_f32, 400.0_f32),
      RL::Vector2.new(32.0_f32, 32.0_f32)
    )
    key.description = "A shiny golden key"
    key.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
    living_room.hotspots << key

    # Add NPC
    butler = PointClickEngine::Characters::NPC.new(
      "butler",
      RL::Vector2.new(150.0_f32, 350.0_f32),
      RL::Vector2.new(64.0_f32, 128.0_f32)
    )
    # Butler will use dialog system - the engine links by character name
    butler.add_dialogue("Good evening! I am Jeeves, the butler.")
    living_room.characters << butler

    # Save living room
    living_room_path = PaceEditor::IO::SceneIO.get_scene_file_path(project, "living_room")
    PaceEditor::IO::SceneIO.save_scene(living_room, living_room_path)

    # === Room 2: Bedroom ===
    bedroom = PointClickEngine::Scenes::Scene.new("bedroom")
    bedroom.background_path = "backgrounds/bedroom.png"

    # Add door back
    door_back = PointClickEngine::Scenes::Hotspot.new(
      "living_room_door",
      RL::Vector2.new(100.0_f32, 200.0_f32),
      RL::Vector2.new(100.0_f32, 200.0_f32)
    )
    door_back.description = "Back to the living room"
    door_back.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
    bedroom.hotspots << door_back

    # Add treasure chest
    chest = PointClickEngine::Scenes::Hotspot.new(
      "treasure_chest",
      RL::Vector2.new(500.0_f32, 400.0_f32),
      RL::Vector2.new(128.0_f32, 96.0_f32)
    )
    chest.description = "A locked treasure chest"
    chest.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Use
    bedroom.hotspots << chest

    # Save bedroom
    bedroom_path = PaceEditor::IO::SceneIO.get_scene_file_path(project, "bedroom")
    PaceEditor::IO::SceneIO.save_scene(bedroom, bedroom_path)

    # === Create Scripts ===
    # Door interaction script
    door_script = <<-LUA
    function on_click()
        change_scene("bedroom")
    end
    LUA

    door_script_path = File.join(project.scripts_path, "door_to_bedroom.lua")
    File.write(door_script_path, door_script)

    # Key pickup script
    key_script = <<-LUA
    function on_click()
        show_message("You picked up the golden key!")
        give_item("golden_key")
        remove_hotspot("golden_key")
    end
    LUA

    key_script_path = File.join(project.scripts_path, "pickup_key.lua")
    File.write(key_script_path, key_script)

    # Chest interaction script
    chest_script = <<-LUA
    function on_use()
        if has_item("golden_key") then
            show_message("You unlock the chest with the golden key!")
            show_message("You found the treasure! You win!")
            remove_item("golden_key")
        else
            show_message("The chest is locked. You need a key.")
        end
    end
    
    function on_look()
        show_message("An ornate treasure chest with a golden lock.")
    end
    LUA

    chest_script_path = File.join(project.scripts_path, "chest_interaction.lua")
    File.write(chest_script_path, chest_script)

    # === Create Dialog ===
    butler_dialog = <<-YAML
    dialogue_graph:
      name: butler_intro
      starting_node: greeting
      nodes:
        - id: greeting
          character: butler
          text: "Good evening! I am Jeeves, the butler."
          choices:
            - text: "Have you seen a key?"
              target: about_key
            - text: "What's in the bedroom?"
              target: about_bedroom
            - text: "Goodbye."
              target: goodbye
        
        - id: about_key
          character: butler
          text: "Ah yes, the master left a golden key on the table in this very room."
          choices:
            - text: "Thank you!"
              target: goodbye
        
        - id: about_bedroom
          character: butler  
          text: "The master keeps his treasure chest in there. It's locked, of course."
          choices:
            - text: "Interesting..."
              target: goodbye
        
        - id: goodbye
          character: butler
          text: "Have a pleasant evening!"
          is_end: true
    YAML

    dialog_path = File.join(project.dialogs_path, "butler_intro.yaml")
    File.write(dialog_path, butler_dialog)

    # === Create placeholder assets ===
    ["living_room.png", "bedroom.png"].each do |bg|
      File.write(File.join(project.backgrounds_path, bg), "dummy_image")
    end

    File.write(File.join(project.characters_path, "butler.png"), "dummy_sprite")

    # === Verify game structure ===
    # Scenes exist
    File.exists?(living_room_path).should be_true
    File.exists?(bedroom_path).should be_true

    # Scripts exist
    File.exists?(door_script_path).should be_true
    File.exists?(key_script_path).should be_true
    File.exists?(chest_script_path).should be_true

    # Dialog exists
    File.exists?(dialog_path).should be_true

    # Can load scenes back
    loaded_living = PaceEditor::IO::SceneIO.load_scene(living_room_path)
    loaded_bedroom = PaceEditor::IO::SceneIO.load_scene(bedroom_path)

    loaded_living.should_not be_nil
    loaded_bedroom.should_not be_nil

    if loaded_living
      loaded_living.hotspots.size.should eq(2)   # door and key
      loaded_living.characters.size.should eq(1) # butler
    end

    if loaded_bedroom
      loaded_bedroom.hotspots.size.should eq(2) # door back and chest
    end

    # === Create game config ===
    config_yaml = <<-YAML
    title: "Key Quest"
    start_scene: "living_room"
    resolution:
      width: 1024
      height: 768
    fullscreen: false
    debug_mode: false
    YAML

    config_path = File.join(project.project_path, "game_config.yaml")
    File.write(config_path, config_yaml)

    # === Summary ===
    puts "\nAdventure Game Created Successfully!"
    puts "- 2 Scenes: living_room, bedroom"
    puts "- 4 Hotspots: doors, key, chest"
    puts "- 1 NPC: butler with dialog tree"
    puts "- 3 Scripts: door transition, key pickup, chest puzzle"
    puts "- Simple puzzle: find key to open chest"

    # Cleanup
    FileUtils.rm_rf(temp_dir)
  end
end
