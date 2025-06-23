require "point_click_engine"
require "file_utils"

# Simple test that creates and runs a minimal game directly
class SimpleMinimalGame < PointClickEngine::Game
  def initialize
    super(
      window_width: 800,
      window_height: 600,
      title: "Minimal Adventure - Direct Test"
    )

    setup_test_game
  end

  private def setup_test_game
    puts "Setting up minimal game..."

    # Create the main scene
    scene = PointClickEngine::Scenes::Scene.new("village")

    # Set background if it exists
    if File.exists?("assets/backgrounds/background_layer_3.png")
      scene.background_path = "assets/backgrounds/background_layer_3.png"
      puts "  ✓ Background set"
    end

    # Add door hotspot
    door = PointClickEngine::Scenes::Hotspot.new(
      "door",
      RL::Vector2.new(x: 400, y: 300),
      RL::Vector2.new(x: 100, y: 150)
    )
    door.description = "A sturdy wooden door"
    door.cursor_type = :hand
    scene.hotspots << door
    puts "  ✓ Added door hotspot"

    # Add sign hotspot
    sign = PointClickEngine::Scenes::Hotspot.new(
      "sign",
      RL::Vector2.new(x: 700, y: 350),
      RL::Vector2.new(x: 60, y: 80)
    )
    sign.description = "Village Sign - Oak Village, Population 23"
    sign.cursor_type = :look
    scene.hotspots << sign
    puts "  ✓ Added sign hotspot"

    # Add player character
    player = PointClickEngine::Characters::Player.new("hero")
    player.position = RL::Vector2.new(x: 200, y: 400)
    player.size = RL::Vector2.new(x: 64, y: 128)
    scene.characters << player
    puts "  ✓ Added player character"

    # Add merchant NPC
    merchant = PointClickEngine::Characters::NPC.new("merchant")
    merchant.position = RL::Vector2.new(x: 600, y: 400)
    merchant.size = RL::Vector2.new(x: 64, y: 128)
    scene.characters << merchant
    puts "  ✓ Added merchant NPC"

    # Add the scene and make it active
    add_scene(scene)
    change_scene("village")

    # Load a simple Lua script
    create_and_load_script

    puts ""
    puts "Game setup complete!"
    puts "Controls:"
    puts "  - Click to move player"
    puts "  - Click hotspots to interact"
    puts "  - Right-click to examine"
    puts "  - ESC to exit"
  end

  private def create_and_load_script
    script_content = <<-LUA
-- Simple game script
print("Minimal Adventure Script Loaded!")

-- Called when door is clicked
function on_door_click()
  show_message("The door is locked. You need a key!")
end

-- Called when sign is examined  
function on_sign_examine()
  show_message("Welcome to Oak Village - Population: 23")
end

-- Called when talking to merchant
function on_merchant_interact()
  show_message("Merchant: Hello traveler! I have no wares today.")
end

function show_message(text)
  print("[GAME] " .. text)
  -- In real implementation, would show dialog box
end
LUA

    # Write script to temp file
    script_path = "/tmp/minimal_game_script.lua"
    File.write(script_path, script_content)

    # Load the script
    load_script(script_path)
    puts "  ✓ Loaded game script"
  rescue ex
    puts "  ! Script loading not implemented: #{ex.message}"
  end
end

# Also create a standalone runner that doesn't inherit from Game
class MinimalGameRunner
  def self.run_test
    puts "=== Minimal Game Test Runner ==="
    puts "This will create and run a minimal point & click game"
    puts ""

    # Check for required assets
    check_assets

    # Create and run the game
    begin
      game = SimpleMinimalGame.new
      game.run
    rescue ex
      puts "Error running game: #{ex.message}"
      puts ex.backtrace.join("\n")
    end
  end

  def self.check_assets
    puts "Checking for required assets..."

    assets_found = true

    # Check backgrounds
    if File.exists?("assets/backgrounds/background_layer_3.png")
      puts "  ✓ Background found"
    else
      puts "  ✗ Background missing: assets/backgrounds/background_layer_3.png"
      assets_found = false
    end

    # Check character sprites
    if File.exists?("assets/characters/knight/Idle.png")
      puts "  ✓ Knight sprite found"
    else
      puts "  ✗ Knight sprite missing: assets/characters/knight/Idle.png"
    end

    if File.exists?("assets/characters/farmer/fbas_1body_human_00.png")
      puts "  ✓ Farmer sprite found"
    else
      puts "  ✗ Farmer sprite missing"
    end

    unless assets_found
      puts ""
      puts "Some assets are missing. The game will still run but may not display correctly."
      puts "Run create_missing_assets.sh to generate placeholder assets."
    end

    puts ""
  end
end

# If running directly
if ARGV.includes?("--run")
  MinimalGameRunner.run_test
else
  puts "Usage: crystal run test_minimal_game_simple.cr -- --run"
  puts ""
  puts "This will create and run a minimal point & click game for testing."
end
