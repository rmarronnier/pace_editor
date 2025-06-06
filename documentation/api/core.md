# Core API Reference

The Core API provides the fundamental classes and modules for PACE editor functionality, including project management, editor state, and the main editor window.

## Module: PaceEditor::Core

### Class: Project

The `Project` class represents a complete game project with all its assets, scenes, and configuration.

#### Properties

```crystal
property name : String                    # Project name
property version : String                 # Project version (default: "1.0.0")
property description : String             # Project description
property author : String                  # Project author

# Project paths
property project_path : String            # Root project directory
property assets_path : String             # Assets directory
property scenes_path : String             # Scenes directory
property scripts_path : String            # Scripts directory
property dialogs_path : String            # Dialog files directory
property exports_path : String            # Export output directory

# Game settings
property window_width : Int32             # Game window width (default: 1024)
property window_height : Int32            # Game window height (default: 768)
property title : String                   # Game window title
property target_fps : Int32               # Target framerate (default: 60)

# Asset tracking
property scenes : Array(String)           # List of scene files
property characters : Array(String)       # List of character assets
property backgrounds : Array(String)      # List of background images
property sounds : Array(String)           # List of sound files
property music : Array(String)            # List of music files
property scripts : Array(String)          # List of script files

# Current scene being edited
property current_scene : String?          # Currently active scene
```

#### Class Methods

##### `Project.new(name : String, project_path : String)`

Creates a new project with the specified name and path. Automatically sets up the project directory structure.

**Parameters:**
- `name` - The project name
- `project_path` - Path where the project will be created

**Example:**
```crystal
project = PaceEditor::Core::Project.new("My Game", "/path/to/projects/my_game")
```

##### `Project.load(project_file : String) : Project`

Loads an existing project from a `.pace` file.

**Parameters:**
- `project_file` - Path to the `.pace` project file

**Returns:** The loaded `Project` instance

**Example:**
```crystal
project = PaceEditor::Core::Project.load("/path/to/my_game.pace")
```

##### `Project.create_new(name : String, path : String) : Project`

Creates a new project with default settings.

**Parameters:**
- `name` - Project name
- `path` - Project directory path

**Returns:** New `Project` instance

#### Instance Methods

##### `save`

Saves the project to a `.pace` file in the project directory.

**Example:**
```crystal
project.save
```

##### `setup_project_structure`

Creates the directory structure for the project including assets, scenes, scripts, dialogs, and exports folders.

##### `add_scene(scene_name : String)`

Adds a scene to the project's scene list.

**Parameters:**
- `scene_name` - Name of the scene file (e.g., "living_room.yml")

##### `remove_scene(scene_name : String)`

Removes a scene from the project.

**Parameters:**
- `scene_name` - Name of the scene to remove

##### `add_asset(asset_path : String, category : String)`

Adds an asset to the appropriate category.

**Parameters:**
- `asset_path` - Relative path to the asset file
- `category` - Asset category ("backgrounds", "characters", "sounds", "music", "scripts")

##### `get_scene_file_path(scene_name : String) : String`

Returns the full path to a scene file.

**Parameters:**
- `scene_name` - Scene filename

**Returns:** Full file path

##### `get_asset_file_path(asset_name : String, category : String) : String`

Returns the full path to an asset file.

**Parameters:**
- `asset_name` - Asset filename
- `category` - Asset category

**Returns:** Full file path

##### `export_game(output_path : String, include_source : Bool = false)`

Exports the project as a playable game.

**Parameters:**
- `output_path` - Where to export the game
- `include_source` - Whether to include Crystal source files

---

### Class: EditorState

Manages the current state of the editor including the active project, current mode, selected objects, and editor settings.

#### Properties

```crystal
property current_project : Project?       # Currently loaded project
property current_mode : EditorMode        # Active editor mode
property current_tool : Tool              # Currently selected tool
property selected_objects : Array(String) # IDs of selected objects
property clipboard : Array(String)        # Copied objects

# Camera and view settings
property camera_x : Float32               # Camera X position
property camera_y : Float32               # Camera Y position
property zoom : Float32                   # Current zoom level
property show_grid : Bool                 # Grid visibility
property show_hotspots : Bool             # Hotspot visibility
property grid_size : Int32                # Grid cell size

# Undo/Redo system
property undo_stack : Array(EditorAction) # Undo history
property redo_stack : Array(EditorAction) # Redo history
property max_undo_levels : Int32          # Maximum undo levels
```

#### Instance Methods

##### `load_project(project_path : String)`

Loads a project and sets it as current.

**Parameters:**
- `project_path` - Path to the project file

##### `save_project`

Saves the current project if one is loaded.

##### `create_new_project(name : String, path : String)`

Creates and loads a new project.

**Parameters:**
- `name` - Project name
- `path` - Project path

##### `switch_mode(mode : EditorMode)`

Changes the current editor mode.

**Parameters:**
- `mode` - New editor mode

##### `select_object(object_id : String)`

Selects an object in the current scene.

**Parameters:**
- `object_id` - ID of the object to select

##### `deselect_all`

Clears all object selections.

##### `zoom_in`

Increases the zoom level by 25%.

##### `zoom_out`

Decreases the zoom level by 25%.

##### `reset_camera`

Resets camera position and zoom to defaults.

##### `undo`

Undoes the last action if possible.

##### `redo`

Redoes the last undone action if possible.

##### `push_action(action : EditorAction)`

Adds an action to the undo stack.

**Parameters:**
- `action` - The action to record

---

### Class: EditorWindow

The main editor window that coordinates all UI elements and manages the application lifecycle.

#### Constants

```crystal
WINDOW_WIDTH          = 1400  # Main window width
WINDOW_HEIGHT         = 900   # Main window height
MENU_HEIGHT           = 30    # Menu bar height
TOOL_PALETTE_WIDTH    = 80    # Tool palette width
PROPERTY_PANEL_WIDTH  = 300   # Property panel width
SCENE_HIERARCHY_WIDTH = 250   # Scene hierarchy width
```

#### Properties

```crystal
property state : EditorState              # Editor state manager
property menu_bar : UI::MenuBar           # Menu bar component
property tool_palette : UI::ToolPalette   # Tool palette component
property property_panel : UI::PropertyPanel # Property panel component
property scene_hierarchy : UI::SceneHierarchy # Scene hierarchy component
property asset_browser : UI::AssetBrowser # Asset browser component

# Editors for different modes
property scene_editor : Editors::SceneEditor
property character_editor : Editors::CharacterEditor
property hotspot_editor : Editors::HotspotEditor
property dialog_editor : Editors::DialogEditor
```

#### Instance Methods

##### `initialize`

Sets up the editor window with all UI components and calculates viewport dimensions.

##### `run`

Starts the main editor loop. This method initializes Raylib, runs the update/draw loop, and handles cleanup.

**Example:**
```crystal
editor = PaceEditor::Core::EditorWindow.new
editor.run
```

---

## Enums

### EditorMode

Defines the different modes the editor can operate in.

```crystal
enum EditorMode
  Scene      # Scene editing mode
  Character  # Character editing mode
  Hotspot    # Hotspot editing mode
  Dialog     # Dialog editing mode
  Assets     # Asset management mode
  Project    # Project settings mode
end
```

### Tool

Defines the available editing tools.

```crystal
enum Tool
  Select  # Selection tool
  Move    # Move tool
  Place   # Place/create tool
  Delete  # Delete tool
  Paint   # Paint tool (future use)
  Zoom    # Zoom tool
end
```

## Usage Examples

### Creating a New Project

```crystal
# Create a new project
project = PaceEditor::Core::Project.create_new("Adventure Game", "/projects/adventure")

# Add some assets
project.add_asset("forest_bg.png", "backgrounds")
project.add_asset("hero_sprite.png", "characters")

# Add a scene
project.add_scene("forest_scene.yml")

# Save the project
project.save
```

### Working with Editor State

```crystal
# Create editor state
state = PaceEditor::Core::EditorState.new

# Load a project
state.load_project("/projects/adventure/adventure.pace")

# Switch to scene editing mode
state.switch_mode(PaceEditor::EditorMode::Scene)

# Select an object
state.select_object("tree_001")

# Zoom in on the scene
state.zoom_in
```

### Running the Editor

```crystal
# Create and run the main editor window
editor = PaceEditor::Core::EditorWindow.new
editor.run
```

## Error Handling

The Core API uses Crystal's exception system for error handling. Common exceptions include:

- `File::NotFoundError` - When trying to load a non-existent project
- `YAML::ParseException` - When project files are corrupted
- `ArgumentError` - When invalid parameters are passed

Always wrap file operations in appropriate exception handling:

```crystal
begin
  project = PaceEditor::Core::Project.load("my_project.pace")
rescue File::NotFoundError
  puts "Project file not found"
rescue YAML::ParseException
  puts "Project file is corrupted"
end
```