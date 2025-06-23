# How to Run PACE Editor

## Quick Start

### 1. Build the Editor
```bash
cd /Users/remy/dev/pace_editor
crystal build src/pace_editor.cr --release
```

### 2. Run the Editor
```bash
./pace_editor
```

Or run directly without building:
```bash
crystal run src/pace_editor.cr
```

## First Time Setup

When you first run the editor:

1. **Create a New Project**
   - The editor will open with no project loaded
   - Go to `File → New Project`
   - Enter a project name (e.g., "My First Game")
   - Choose a location to save your project
   - Click "Create"

2. **Your First Scene**
   - A default scene may be created automatically
   - If not, go to `File → New Scene`
   - The scene will appear in the main viewport

3. **Set a Background**
   - Press `B` key to open the background selector
   - If no backgrounds are available, add images to:
     `your_project/assets/backgrounds/`
   - Select a background and click OK

4. **Add Interactive Elements**
   - Press `P` to activate the Place tool
   - Click anywhere in the scene
   - Choose "Hotspot" from the dialog
   - A new hotspot will be created

5. **Edit Properties**
   - Press `V` to activate the Select tool
   - Click on the hotspot you created
   - Look at the Property Panel on the right
   - Edit the description, position, etc.

6. **Save Your Work**
   - Press `Ctrl+S` to save the scene
   - Your scene is saved as YAML in the project

## Example Workflow

```bash
# 1. Run the editor
./pace_editor

# 2. In the editor:
# - File → New Project → "Adventure Game"
# - File → New Scene (if needed)
# - Press B → Select background
# - Press P → Click → Choose "Hotspot"
# - Press V → Click hotspot → Edit properties
# - Press Ctrl+S to save

# 3. Your project structure:
Adventure Game/
├── assets/
│   ├── backgrounds/
│   ├── characters/
│   └── scripts/
├── scenes/
│   └── scene_1.yml
└── Adventure Game.pace
```

## Troubleshooting

### "No backgrounds available"
Add PNG/JPG images to `your_project/assets/backgrounds/`

### "Can't create new scene"
Make sure you have a project open first (File → New/Open Project)

### "Objects not saving"
Press `Ctrl+S` after making changes

### "Editor crashes on startup"
Make sure you have all dependencies:
```bash
shards install
```

## Tips

- Use the grid (press `G`) for precise placement
- Hold `Space` and drag to pan the camera
- Use mouse wheel to zoom in/out
- Press `Home` to reset the view
- Select multiple objects with `Ctrl+Click`

The editor is now ready for creating point-and-click adventure games!