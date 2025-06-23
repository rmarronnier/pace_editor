# TODO: Create and Export Minimal Game

## Mission: Create a working point-and-click game with PACE Editor

### Phase 1: Project Setup
- [ ] Create a new project structure
- [ ] Initialize project with proper paths
- [ ] Ensure all directories exist

### Phase 2: Scene Creation
- [ ] Create main scene file (YAML format)
- [ ] Set background image from assets
- [ ] Define scene properties (name, size)

### Phase 3: Add Characters
- [ ] Add Knight character from assets
  - Position at (200, 400)
  - Set sprite path
  - Add basic properties
- [ ] Add Merchant NPC from assets  
  - Position at (600, 400)
  - Set sprite path
  - Add dialog interaction

### Phase 4: Add Objects/Hotspots
- [ ] Add Door hotspot
  - Position at (400, 300)
  - Size (100, 150)
  - Click action: change scene or show message
- [ ] Add Sign hotspot
  - Position at (700, 350)
  - Size (60, 80)
  - Look action: display description

### Phase 5: Create Lua Scripts
- [ ] Create main game script
  - Initialize game
  - Handle hotspot clicks
  - Character interactions
- [ ] Create character scripts
  - Merchant dialog tree
  - Player movement

### Phase 6: Asset Management
- [ ] Copy required assets to project
  - Background images
  - Character sprites
  - UI elements
- [ ] Create asset manifest

### Phase 7: Export Game
- [ ] Generate game launcher (main.cr)
- [ ] Create shard.yml for dependencies
- [ ] Copy all assets to export directory
- [ ] Generate scene loaders

### Phase 8: Run Game
- [ ] Build the exported game
- [ ] Run with point_click_engine
- [ ] Verify all interactions work

## Technical Requirements

### Scene YAML Structure
```yaml
name: main_scene
background: background_layer_3.png
width: 800
height: 600
hotspots:
  - name: door
    position: {x: 400, y: 300}
    size: {x: 100, y: 150}
    description: "A wooden door"
    cursor_type: hand
    on_click: "open_door"
  - name: sign
    position: {x: 700, y: 350}
    size: {x: 60, y: 80}
    description: "Village sign"
    cursor_type: look
    on_look: "read_sign"
characters:
  - name: player
    type: Player
    position: {x: 200, y: 400}
    sprite: "knight/Idle.png"
    size: {x: 64, y: 128}
  - name: merchant
    type: NPC
    position: {x: 600, y: 400}
    sprite: "farmer/fbas_1body_human_00.png"
    size: {x: 64, y: 128}
    on_interact: "talk_to_merchant"
```

### Lua Script Structure
```lua
-- Game initialization
function on_game_start()
    print("Welcome to the Village!")
    show_scene("main_scene")
end

-- Hotspot interactions
function open_door()
    show_message("The door is locked. You need a key!")
end

function read_sign()
    show_message("Welcome to Oak Village - Population: 23")
end

-- Character interactions
function talk_to_merchant()
    start_dialog({
        {text = "Hello traveler! Welcome to our village.", speaker = "Merchant"},
        {text = "Do you have anything for sale?", speaker = "Player"},
        {text = "Not today, but check back tomorrow!", speaker = "Merchant"}
    })
end

-- Helper functions
function show_message(message)
    -- Display message box
    display_text(message, 3) -- Show for 3 seconds
end

function start_dialog(dialog_tree)
    -- Start dialog sequence
    for i, line in ipairs(dialog_tree) do
        show_dialog_line(line.speaker, line.text)
        wait_for_click()
    end
end
```

### Export Structure
```
exported_game/
├── main.cr              # Game launcher
├── shard.yml           # Dependencies
├── assets/
│   ├── backgrounds/
│   ├── characters/
│   ├── ui/
│   └── sounds/
├── scenes/
│   └── main_scene.yml
├── scripts/
│   └── game.lua
└── data/
    └── dialogs.yml
```

## Success Criteria
1. Game launches without errors
2. Background displays correctly
3. Characters are visible and positioned
4. Hotspots respond to clicks
5. Lua scripts execute on interactions
6. Basic dialog system works
7. Player can interact with all elements

## Common Issues to Handle
- Asset paths must be relative to game root
- Lua scripts need proper error handling
- Scene transitions must be smooth
- Memory management for textures
- Input handling conflicts
- Save/load state (optional for minimal game)