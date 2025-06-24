# Getting Started with PACE

This guide will walk you through creating your first point-and-click adventure game using PACE. By the end of this tutorial, you'll have a working game with multiple scenes, characters, and interactive elements.

## Prerequisites

Before starting, make sure you have:
- PACE installed and running (see [Installation Guide](installation.md))
- Basic understanding of point-and-click adventure games
- Some image assets (backgrounds, characters, objects) - we'll provide sample assets if needed

## Creating Your First Project

### 1. Launch PACE

Start PACE from your terminal:
```bash
cd /path/to/pace_editor
./run.sh src/pace_editor.cr
```

Or if you have it compiled:
```bash
./pace_editor
```

### 2. Welcome Screen

When PACE starts, you'll see the **Welcome to PACE Editor** panel with three options:
- **New Project** - Create a new adventure game
- **Open Project** - Open an existing project
- **Start Tutorial** - Begin the interactive tutorial

### 3. Create a New Project

1. Click **New Project** on the welcome screen (or use **File → New Project**)
2. In the New Project dialog:
   - Enter a **Project Name** (e.g., "My First Adventure")
   - Click **Create** or press Enter
   - Click **Cancel** or press Escape to cancel

3. PACE will create your project in the current directory

PACE will create a project structure like this:
```
my_first_adventure/
├── assets/
│   ├── backgrounds/
│   ├── characters/
│   ├── sounds/
│   ├── music/
│   └── ui/
├── scenes/
│   └── main_scene.yml
├── scripts/
├── dialogs/
├── exports/
└── my_first_adventure.pace
```

## Understanding the Interface

### Main Areas

1. **Menu Bar** (top) - File operations, tools, and settings
2. **Tool Palette** (left) - Selection, move, place, delete tools
3. **Scene Hierarchy** (bottom-left) - Tree view of scene objects
4. **Main Viewport** (center) - Your scene editing area
5. **Property Panel** (right) - Properties of selected objects
6. **Asset Browser** (bottom-right in Assets mode)

### Editor Modes

Switch between modes using the toolbar or keyboard shortcuts:
- **Scene Mode** - Design your game scenes
- **Character Mode** - Manage character sprites and animations
- **Hotspot Mode** - Create interactive areas
- **Dialog Mode** - Design conversations
- **Assets Mode** - Manage project resources
- **Project Mode** - Configure game settings

## Building Your First Scene

### 1. Setting Up a Background

1. Switch to **Assets Mode** by clicking the Assets tab
2. Click **Import Asset** and select a background image
3. Choose the **backgrounds** category
4. Switch back to **Scene Mode**
5. In the Scene Hierarchy, select "main_scene"
6. In the Property Panel, click **Browse** next to Background
7. Select your imported background image

Your scene now has a background!

### 2. Adding Objects

1. Switch to **Assets Mode** and import some object images (like a key, door, book, etc.)
2. Return to **Scene Mode**
3. Select the **Place Tool** (`P` key)
4. In the Asset Browser (visible in Scene Mode), drag an object into the scene
5. Position it where you want using the **Move Tool** (`M` key)

### 3. Creating Interactive Hotspots

1. Switch to **Hotspot Mode**
2. Select the **Place Tool**
3. Click and drag to create a rectangular hotspot over an object
4. In the Property Panel, configure the hotspot:
   - **Name**: "examine_key"
   - **Interaction Type**: "Examine"
   - **Description**: "A rusty old key"
   - **Action**: "You found a mysterious key!"

## Adding a Character

### 1. Import Character Sprites

1. Go to **Assets Mode**
2. Import character sprite images to the **characters** category
3. For best results, use multiple images for different poses/animations

### 2. Create a Character

1. Switch to **Character Mode**
2. Click **Add Character**
3. Configure the character:
   - **Name**: "Player"
   - **Sprite**: Select your character image
   - **Default Position**: Set where the character starts

### 3. Place Character in Scene

1. Return to **Scene Mode**
2. The character should appear in your scene
3. Use the **Move Tool** to adjust positioning

## Creating Dialog

### 1. Simple Interactions

1. Switch to **Dialog Mode**
2. Click **New Dialog Tree**
3. Name it "key_dialog"
4. Create a simple conversation:
   ```
   Player: "What's this?"
   → Narrator: "It's an old key. It might be useful."
   ```

### 2. Link Dialog to Hotspots

1. Go back to **Hotspot Mode**
2. Select your hotspot
3. In the Property Panel, set **Dialog**: "key_dialog"

## Adding Scripts to Hotspots (NEW)

### 1. Create Interactive Scripts

1. Switch to **Hotspot Mode** and select your hotspot
2. In the Property Panel, click **Edit Scripts**
3. The **Script Editor** will open with a template script
4. Modify the interaction functions:
   ```lua
   function on_click()
       show_message("You found a mysterious key!")
       give_item("old_key")
   end
   
   function on_look()
       show_message("It's an old, rusty key.")
   end
   ```
5. Press `Ctrl+S` to save the script
6. Press `F5` to validate syntax
7. Press `Esc` to close the script editor

### 2. Script Editor Features

- **Syntax Highlighting** - Lua keywords, functions, and strings are color-coded
- **Error Checking** - Real-time validation with error messages
- **Auto-completion** - Hints for Lua syntax and functions
- **File Management** - Automatic script creation and organization

## Adding Character Animations (NEW)

### 1. Prepare Sprite Sheets

1. Create or obtain sprite sheets for your character
2. Name them using the pattern: `character_name.png` or `character_name_spritesheet.png`
3. Place them in your project's `assets/characters/` folder

### 2. Edit Character Animations

1. Switch to **Character Mode** and select your character
2. In the Property Panel, click **Edit Animations**
3. The **Animation Editor** will open
4. Create animations:
   - Click **+ New** to create a new animation
   - Name it (e.g., "walk", "idle", "run")
   - Add frames by clicking the **+** button in the timeline
   - Adjust frame duration and properties
5. Use playback controls to preview animations:
   - **Play/Pause** button or `Space` key
   - **Speed** slider to adjust playback speed
   - **Previous/Next Frame** buttons or arrow keys

### 3. Animation Editor Features

- **Timeline** - Visual frame-by-frame editing
- **Real-time Preview** - See animations as you create them
- **Frame Properties** - Adjust duration, offset, and sprite coordinates
- **Multiple Animations** - Manage idle, walk, run, and custom animations
- **Sprite Sheet Support** - Automatic frame detection from sprite sheets

## Testing Your Game

### 1. Test Basic Interactions

1. Switch to **Project Mode**
2. Click **Test Game** to run your scene
3. Click on hotspots to test interactions
4. Use `Esc` to return to the editor

### 2. Test Dialog Trees (NEW)

1. Switch to **Dialog Mode**
2. Select your dialog tree
3. Click **Test Dialog** in the toolbar
4. Navigate through the conversation using:
   - **Up/Down arrows** to select choices
   - **Enter** to choose an option
   - **Esc** to close the preview

### 3. Test Hotspot Interactions (NEW)

1. Switch to **Hotspot Mode**
2. Select a hotspot
3. Click **Test Interaction** in the properties
4. Try different interaction types (click, look, use, talk)
5. Review the simulation log for script execution results
6. Use **Clear Log** to reset the test session

### 4. Preview Character Animations (NEW)

1. Switch to **Character Mode**
2. Select a character with animations
3. In the Animation Editor:
   - Use **Play** button to preview animations
   - Adjust **Speed** to test different playback rates
   - Switch between animations to test all states
   - Verify smooth transitions and timing

## Saving and Exporting

### Saving Your Project

- **Auto-save**: PACE automatically saves every few minutes
- **Manual save**: Press `Ctrl+S` or **File → Save**

### Exporting Your Game

1. Go to **Project Mode**
2. Click **Export Game**
3. Choose export options:
   - **Format**: Executable, Web, or Source
   - **Include Assets**: Check this option
   - **Output Location**: Choose where to save

4. Click **Export**

Your game will be compiled and ready to share!

## Next Steps

Congratulations! You've created your first adventure game. Here are some next steps:

### Expand Your Game
- Add more scenes using **File → New Scene**
- Create scene transitions with **exit hotspots**
- Add an inventory system
- Include sound effects and music

### Learn Advanced Features
- **Character Animation**: Create walking cycles and expressions
- **Complex Dialogs**: Branching conversations with conditions
- **Custom Scripts**: Write Lua scripts for complex interactions
- **Puzzle Mechanics**: Combine objects and solve puzzles

### Recommended Tutorials
- [Beginner Tutorial](../tutorials/beginner-tutorial.md) - More detailed walkthrough
- [Advanced Tutorial](../tutorials/advanced-tutorial.md) - Complex scenes and mechanics

### Get Help
- Check the [User Interface Guide](user-interface.md) for detailed UI explanations
- Browse the [API Reference](../api/) for technical details
- Look at [Example Projects](../examples/) for inspiration

## Tips for Success

### Asset Organization
- Use consistent naming conventions
- Organize assets in subfolders by scene or category
- Keep source files (like Photoshop documents) separate from game assets

### Scene Design
- Plan your scenes on paper first
- Use a consistent art style
- Consider the flow between scenes

### Testing
- Test frequently during development
- Play through your game completely before exporting
- Get feedback from others

### Performance
- Optimize images for web if targeting browser deployment
- Use appropriate file formats (PNG for transparency, JPG for backgrounds)
- Keep file sizes reasonable

## Troubleshooting

### Common Issues

**"Cannot find asset file"**
- Check that asset paths are correct
- Ensure files weren't moved outside of PACE
- Try re-importing the asset

**"Scene won't load"**
- Check the scene file for syntax errors
- Ensure all referenced assets exist
- Try creating a new scene and copying elements

**"Export failed"**
- Verify Crystal is installed and in PATH
- Check that all dependencies are available
- Ensure sufficient disk space

**"Game runs slowly"**
- Reduce image sizes
- Limit number of objects per scene
- Check for infinite loops in scripts

Need more help? Check the documentation or contact support.