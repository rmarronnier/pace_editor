require "./src/pace_editor"
require "file_utils"
require "yaml"

# Test to create, export and run a minimal game
class MinimalGameTest
  property project_path : String
  property export_path : String
  
  def initialize
    @project_path = "/tmp/minimal_game_project"
    @export_path = "/tmp/minimal_game_export"
    @editor_state = PaceEditor::Core::EditorState.new
  end
  
  def run
    puts "=== PACE Editor Minimal Game Test ==="
    puts "Creating a complete game project..."
    puts ""
    
    # Phase 1: Setup
    setup_project
    
    # Phase 2: Create scene
    create_main_scene
    
    # Phase 3: Create scripts
    create_lua_scripts
    
    # Phase 4: Copy assets
    copy_game_assets
    
    # Phase 5: Export game
    export_game
    
    # Phase 6: Build and run
    build_and_run_game
    
    puts ""
    puts "=== Test Complete! ==="
    puts "Game exported to: #{@export_path}"
    puts "To run manually: cd #{@export_path} && crystal run main.cr"
  end
  
  private def setup_project
    puts "1. Setting up project structure..."
    
    # Clean up old test
    FileUtils.rm_rf(@project_path) if Dir.exists?(@project_path)
    FileUtils.rm_rf(@export_path) if Dir.exists?(@export_path)
    
    # Create project
    project = PaceEditor::Core::Project.new
    project.name = "Minimal Adventure"
    project.project_path = @project_path
    project.title = "Minimal Adventure Game"
    project.window_width = 800
    project.window_height = 600
    
    # Create directories
    Dir.mkdir_p(@project_path)
    Dir.mkdir_p("#{@project_path}/scenes")
    Dir.mkdir_p("#{@project_path}/scripts")
    Dir.mkdir_p("#{@project_path}/assets/backgrounds")
    Dir.mkdir_p("#{@project_path}/assets/characters/knight")
    Dir.mkdir_p("#{@project_path}/assets/characters/farmer")
    Dir.mkdir_p("#{@project_path}/assets/ui")
    
    # Save project
    project.save_project
    @editor_state.current_project = project
    
    puts "  ✓ Project created at: #{@project_path}"
  end
  
  private def create_main_scene
    puts "2. Creating main scene..."
    
    # Create scene YAML manually for compatibility
    scene_data = {
      "name" => "main_scene",
      "background" => "backgrounds/background_layer_3.png",
      "width" => 800,
      "height" => 600,
      "hotspots" => [
        {
          "name" => "door",
          "position" => {"x" => 400, "y" => 300},
          "size" => {"x" => 100, "y" => 150},
          "description" => "A wooden door",
          "cursor_type" => "hand",
          "on_click" => "open_door"
        },
        {
          "name" => "sign",
          "position" => {"x" => 700, "y" => 350},
          "size" => {"x" => 60, "y" => 80},
          "description" => "Village sign - click to read",
          "cursor_type" => "look",
          "on_click" => "read_sign"
        }
      ],
      "characters" => [
        {
          "name" => "player",
          "type" => "Player",
          "position" => {"x" => 200, "y" => 400},
          "sprite" => "characters/knight/Idle.png",
          "size" => {"x" => 64, "y" => 128}
        },
        {
          "name" => "merchant",
          "type" => "NPC",
          "position" => {"x" => 600, "y" => 400},
          "sprite" => "characters/farmer/fbas_1body_human_00.png",
          "size" => {"x" => 64, "y" => 128},
          "on_interact" => "talk_to_merchant"
        }
      ]
    }
    
    File.write("#{@project_path}/scenes/main_scene.yml", scene_data.to_yaml)
    puts "  ✓ Scene created: main_scene.yml"
  end
  
  private def create_lua_scripts
    puts "3. Creating Lua scripts..."
    
    game_script = <<-LUA
-- Minimal Adventure Game Script

-- Game initialization
function on_game_start()
    print("Welcome to the Minimal Adventure!")
    -- Game starts with main_scene by default
end

-- Hotspot interactions
function open_door()
    show_message("The door is locked. You need a key!")
end

function read_sign()
    show_message("Welcome to Oak Village\\nPopulation: 23\\nFounded: 1823")
end

-- Character interactions  
function talk_to_merchant()
    -- Simple dialog
    show_message("Merchant: Hello traveler! Welcome to our village.")
    show_message("Merchant: I don't have anything for sale today, but check back tomorrow!")
end

-- Helper functions
function show_message(text)
    -- This will be handled by the engine
    print("[MESSAGE] " .. text)
end
LUA
    
    File.write("#{@project_path}/scripts/game.lua", game_script)
    puts "  ✓ Lua script created: game.lua"
  end
  
  private def copy_game_assets
    puts "4. Copying game assets..."
    
    # Copy backgrounds
    if File.exists?("assets/backgrounds/background_layer_3.png")
      FileUtils.cp("assets/backgrounds/background_layer_3.png", 
                   "#{@project_path}/assets/backgrounds/")
      puts "  ✓ Copied background"
    end
    
    # Copy knight sprite
    if File.exists?("assets/characters/knight/Idle.png")
      FileUtils.cp("assets/characters/knight/Idle.png",
                   "#{@project_path}/assets/characters/knight/")
      puts "  ✓ Copied knight sprite"
    end
    
    # Copy farmer sprite  
    if File.exists?("assets/characters/farmer/fbas_1body_human_00.png")
      FileUtils.cp("assets/characters/farmer/fbas_1body_human_00.png",
                   "#{@project_path}/assets/characters/farmer/")
      puts "  ✓ Copied farmer sprite"
    end
    
    # Copy UI elements (optional)
    Dir.glob("assets/ui/cursors/*.png").each do |cursor|
      FileUtils.cp(cursor, "#{@project_path}/assets/ui/")
    end
    puts "  ✓ Copied UI elements"
  end
  
  private def export_game
    puts "5. Exporting game..."
    
    Dir.mkdir_p(@export_path)
    
    # Copy entire project to export
    FileUtils.cp_r("#{@project_path}/.", @export_path)
    
    # Create main.cr launcher
    launcher_code = <<-CRYSTAL
require "point_click_engine"
require "yaml"

# Minimal Adventure Game Launcher
class MinimalAdventure
  def initialize
    @engine = PointClickEngine::Core::Engine.new(
      window_width: 800,
      window_height: 600,
      title: "Minimal Adventure"
    )
    
    # Load the main scene
    load_scene("main_scene")
  end
  
  def run
    @engine.run
  end
  
  def load_scene(scene_name : String)
    scene_file = "scenes/\#{scene_name}.yml"
    if File.exists?(scene_file)
      scene_data = YAML.parse(File.read(scene_file))
      
      # Create scene
      scene = PointClickEngine::Scenes::Scene.new(scene_data["name"].as_s)
      
      # Set background
      if bg = scene_data["background"]?
        scene.background_path = bg.as_s
      end
      
      # Add hotspots
      if hotspots = scene_data["hotspots"]?
        hotspots.as_a.each do |h|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            h["name"].as_s,
            RL::Vector2.new(
              x: h["position"]["x"].as_i.to_f32,
              y: h["position"]["y"].as_i.to_f32
            ),
            RL::Vector2.new(
              x: h["size"]["x"].as_i.to_f32,
              y: h["size"]["y"].as_i.to_f32
            )
          )
          hotspot.description = h["description"].as_s
          
          # Set cursor type
          cursor = h["cursor_type"].as_s
          hotspot.cursor_type = case cursor
          when "hand" then PointClickEngine::Scenes::Hotspot::CursorType::Hand
          when "look" then PointClickEngine::Scenes::Hotspot::CursorType::Look
          when "talk" then PointClickEngine::Scenes::Hotspot::CursorType::Talk
          when "use" then PointClickEngine::Scenes::Hotspot::CursorType::Use
          else PointClickEngine::Scenes::Hotspot::CursorType::Default
          end
          
          scene.hotspots << hotspot
        end
      end
      
      # Add characters
      if characters = scene_data["characters"]?
        characters.as_a.each do |c|
          char_type = c["type"].as_s
          
          position = RL::Vector2.new(
            x: c["position"]["x"].as_i.to_f32,
            y: c["position"]["y"].as_i.to_f32
          )
          
          size = RL::Vector2.new(
            x: c["size"]["x"].as_i.to_f32,
            y: c["size"]["y"].as_i.to_f32  
          )
          
          character = if char_type == "Player"
            PointClickEngine::Characters::Player.new(c["name"].as_s, position, size)
          else
            PointClickEngine::Characters::NPC.new(c["name"].as_s, position, size)
          end
          
          if sprite = c["sprite"]?
            # In a real implementation, would load sprite texture
            puts "Would load sprite: \#{sprite}"
          end
          
          scene.characters << character
        end
      end
      
      # Load into engine
      @engine.scenes[scene_name] = scene
      @engine.change_scene(scene_name)
      
      # Load Lua scripts
      if File.exists?("scripts/game.lua")
        # Script loading would be done here if implemented
        puts "Would load script: scripts/game.lua"
      end
      
      puts "Scene loaded: \#{scene_name}"
    else
      puts "Scene file not found: \#{scene_file}"
    end
  end
end

# Run the game
game = MinimalAdventure.new
game.run
CRYSTAL
    
    File.write("#{@export_path}/main.cr", launcher_code)
    
    # Create shard.yml
    shard_yml = <<-YAML
name: minimal_adventure
version: 1.0.0

dependencies:
  point_click_engine:
    path: #{File.expand_path("../point_click_engine", Dir.current)}

targets:
  minimal_adventure:
    main: main.cr

crystal: ">= 1.16.3"
YAML
    
    File.write("#{@export_path}/shard.yml", shard_yml)
    
    puts "  ✓ Game exported to: #{@export_path}"
    puts "  ✓ Created launcher: main.cr"
    puts "  ✓ Created dependencies: shard.yml"
  end
  
  private def build_and_run_game
    puts "6. Building exported game..."
    
    Dir.cd(@export_path) do
      # Install dependencies
      puts "  → Installing dependencies..."
      result = `shards install 2>&1`
      if $?.success?
        puts "  ✓ Dependencies installed"
      else
        puts "  ✗ Failed to install dependencies:"
        puts result
        return
      end
      
      # Build the game
      puts "  → Building game..."
      result = `crystal build main.cr -o minimal_adventure 2>&1`
      if $?.success?
        puts "  ✓ Game built successfully!"
        puts ""
        puts "To run the game:"
        puts "  cd #{@export_path}"
        puts "  ./minimal_adventure"
      else
        puts "  ✗ Build failed:"
        puts result
      end
    end
  end
end

# Run the test
test = MinimalGameTest.new
test.run