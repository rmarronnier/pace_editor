# Game Format Guide

This guide explains the game format used by PACE Editor 2.0 and its compatibility with Point & Click Engine v1.0.

## Overview

PACE Editor 2.0 exports games in a format fully compatible with Point & Click Engine v1.0. The format consists of:

- YAML configuration files for game data
- Lua scripts for game logic
- Organized asset directories
- Proper file structure for engine compatibility

## Directory Structure

When you export a game, PACE creates the following structure:

```
game_name/
├── game_config.yaml          # Main game configuration
├── main.cr                   # Entry point (auto-generated)
├── shard.yml                # Crystal dependencies (auto-generated)
├── scenes/                   # Scene definitions
│   └── *.yaml
├── scripts/                  # Lua scripts for game logic
│   └── *.lua
├── dialogs/                  # Dialog trees
│   └── *.yaml
├── quests/                   # Quest definitions
│   └── *.yaml
├── items/                    # Item definitions
│   └── items.yaml
├── cutscenes/               # Cutscene definitions
│   └── *.yaml
├── assets/                  # Game assets
│   ├── backgrounds/         # Scene backgrounds
│   ├── sprites/            # Character sprites
│   ├── items/              # Item icons
│   ├── portraits/          # Character portraits
│   ├── music/              # Background music
│   └── sounds/             # Sound effects
│       ├── effects/
│       └── ambience/
└── saves/                   # Save files (created at runtime)
```

## File Formats

### game_config.yaml

The main configuration file contains:

```yaml
game:
  title: "Your Game Title"
  version: "1.0.0"
  author: "Your Name"

window:
  width: 1024
  height: 768
  fullscreen: false
  target_fps: 60

player:
  name: "Player"
  sprite_path: "assets/sprites/player.png"
  sprite:
    frame_width: 64
    frame_height: 64
    columns: 4
    rows: 4

features:
  - verbs
  - portraits
  - auto_save

assets:
  scenes: ["scenes/*.yaml"]
  dialogs: ["dialogs/*.yaml"]
  quests: ["quests/*.yaml"]
  audio:
    music:
      main_theme: "assets/music/theme.ogg"
    sounds:
      click: "assets/sounds/effects/click.wav"

settings:
  debug_mode: false
  master_volume: 0.8
  music_volume: 0.7
  sfx_volume: 0.9

start_scene: "intro"
```

### Scene Files

Scene files define game locations:

```yaml
name: kitchen
background_path: assets/backgrounds/kitchen.png
script_path: scripts/kitchen.lua

hotspots:
  - name: refrigerator
    type: rectangle
    x: 100
    y: 200
    width: 80
    height: 150
    description: "A large refrigerator"
    
  - name: exit_to_hallway
    type: exit
    x: 0
    y: 300
    width: 50
    height: 200
    target_scene: hallway
    target_position:
      x: 950
      y: 400

characters:
  - name: chef
    position:
      x: 500
      y: 400
    sprite_path: assets/sprites/chef.png
    dialog_tree: dialogs/chef_dialog.yaml
```

### Quest Files

Quests are defined in YAML format:

```yaml
quests:
  - id: find_recipe
    name: "Find the Secret Recipe"
    description: "The chef has lost his secret recipe. Help him find it!"
    category: main
    objectives:
      - id: talk_to_chef
        description: "Talk to the chef about the missing recipe"
        completion_conditions:
          flag: talked_to_chef_about_recipe
      - id: find_recipe_book
        description: "Find the recipe book"
        completion_conditions:
          has_item: recipe_book
    rewards:
      - type: item
        name: golden_spoon
      - type: variable
        name: experience
        value: 100
```

### Dialog Files

Dialog trees use a node-based structure:

```yaml
id: chef_dialog
nodes:
  - id: start
    speaker: Chef
    text: "Welcome to my kitchen! What can I do for you?"
    choices:
      - text: "I heard you lost something important."
        next: lost_recipe
      - text: "Just looking around."
        next: end
        
  - id: lost_recipe
    speaker: Chef
    text: "Yes! My secret recipe book is missing!"
    effects:
      - type: set_flag
        name: talked_to_chef_about_recipe
        value: true
    next: end
    
  - id: end
    speaker: Chef
    text: "Have a great day!"
    
start_node: start
```

### Item Definitions

All items are defined in a single items.yaml file:

```yaml
items:
  recipe_book:
    name: recipe_book
    display_name: "Recipe Book"
    description: "A worn cookbook filled with secret recipes"
    icon_path: assets/items/recipe_book.png
    quest_item: true
    
  golden_spoon:
    name: golden_spoon
    display_name: "Golden Spoon"
    description: "A beautiful golden spoon, a chef's prized possession"
    icon_path: assets/items/golden_spoon.png
```

## Lua Scripting

Each scene can have an associated Lua script for custom logic:

```lua
-- scripts/kitchen.lua

-- Called when entering the scene
function on_enter()
    if get_flag("first_visit_kitchen") == false then
        show_message("You enter a busy kitchen filled with delicious aromas.")
        set_flag("first_visit_kitchen", true)
    end
end

-- Handle hotspot interactions
hotspot.on_click("refrigerator", function()
    if has_item("recipe_book") then
        show_message("You already found what you were looking for.")
    else
        show_message("The refrigerator is full of ingredients.")
    end
end)

-- Handle character interactions
character.on_interact("chef", function()
    start_dialog("chef_dialog")
end)
```

## Validation

Before export, PACE validates:

1. **File References** - All referenced files exist
2. **Format Compliance** - Files match expected structure
3. **Cross-References** - All internal references are valid
4. **Asset Formats** - Images and audio files are in supported formats
5. **Logic Integrity** - No circular dependencies or orphaned elements

## Best Practices

1. **Naming Conventions**
   - Use lowercase with underscores for file names
   - Use descriptive names for scenes and items
   - Keep IDs consistent across files

2. **Asset Organization**
   - Keep related assets in appropriate directories
   - Use consistent image sizes for similar assets
   - Optimize file sizes for performance

3. **Scene Design**
   - Define clear walkable areas
   - Set appropriate scale zones
   - Test all hotspot interactions

4. **Quest Design**
   - Make objectives clear and achievable
   - Provide appropriate rewards
   - Test quest progression thoroughly

5. **Dialog Writing**
   - Keep conversations natural
   - Provide meaningful choices
   - Test all dialog branches

## Troubleshooting

### Common Validation Errors

1. **"Scene file not found"**
   - Check that the scene file exists in the scenes/ directory
   - Verify the file has a .yaml extension

2. **"Asset not found"**
   - Ensure the asset path is relative to the game root
   - Check that the file exists at the specified location

3. **"Invalid quest category"**
   - Quest categories must be: main, side, or hidden

4. **"Circular reference detected"**
   - Check dialog trees for nodes that reference each other in a loop
   - Verify quest prerequisites don't create circular dependencies

### Export Issues

1. **"Export failed: Permission denied"**
   - Ensure you have write permissions for the export directory
   - Close any files that might be open from the export location

2. **"Validation failed"**
   - Review the validation errors in the export dialog
   - Fix each issue before attempting to export again

## Migration from Old Format

If you have projects from PACE 1.x:

1. Open the project in PACE 2.0
2. The editor will update internal structures automatically
3. Review any validation warnings
4. Re-export using File → Export Game

Note: Old exported games are not compatible with the new engine format. You must re-export from PACE 2.0.