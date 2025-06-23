# PACE - Point & Click Adventure Creator Editor

PACE is a visual editor for creating point-and-click adventure games using the PointClickEngine. It provides an intuitive interface for designing scenes, characters, hotspots, and dialog trees without requiring extensive programming knowledge.

## 🎉 New in Version 2.0

- **Full compatibility with Point & Click Engine v1.0 game format**
- **Advanced validation system** - Catch errors before export
- **Complete scene serialization** - Save and load scenes with full YAML support
- **Enhanced object placement** - Hotspot and character placement with grid snapping
- **Comprehensive undo/redo system** - Full support for all editing operations
- **Dynamic property editing** - Real-time property updates with validation
- **Hotspot action system** - 7 action types with visual parameter editing
- **Dialog node creation** - Visual dialog tree editor with node management
- **Scene background management** - Background selector with thumbnails
- **Asset import system** - Multi-format support with auto-discovery
- **Enhanced export** - Generate fully playable games with proper structure
- **🆕 Script Editor** - Full-featured Lua script editor with syntax highlighting
- **🆕 Animation Editor** - Timeline-based sprite animation system
- **🆕 Hotspot Scripting** - Seamless script editing for interactive objects
- **🆕 Character Animation** - Complete animation workflow for characters

### 🔧 Core Implementation Status
- ✅ **Complete scene persistence** - Full YAML save/load with all object types
- ✅ **Working undo/redo** - Support for move, create, and property changes
- ✅ **Functional object placement** - Hotspot and character creation tools
- ✅ **Property editing** - Real-time updates with validation
- ✅ **Action system** - 7 action types with parameter configuration
- ✅ **Dialog editing** - Node creation and visual tree management
- ✅ **Asset management** - Import, categorization, and preview
- ✅ **Background selection** - Visual selector with thumbnails
- ✅ **Grid snapping** - Precise object placement
- ✅ **Scene validation** - Comprehensive error checking
- ✅ **Script editing** - Lua script editor with syntax highlighting
- ✅ **Animation system** - Timeline-based character animation editor
- ✅ **Hotspot scripting** - Integrated script editing for interactions
- ✅ **Dialog preview** - Test dialog trees with interactive preview

## Features

### 🎨 Visual Scene Editor
- Drag-and-drop scene creation
- Background image support with visual selector
- Real-time preview with zoom and pan controls
- Multi-layer object management
- Grid snapping and alignment tools (fixed precision)
- Walkable area definition with YAML persistence
- Scale zones for character perspective
- Walk-behind regions
- Complete scene serialization/deserialization
- Automatic scene saving on modifications

### 👥 Character Management
- Character sprite management
- NPC character placement tool
- Character positioning with grid snapping
- Character state management (idle, walking, talking, etc.)
- Direction and mood configuration
- Interactive character placement with undo support
- Dialog tree integration
- Portrait support for conversations
- Full character serialization with properties

### 🎯 Hotspot System
- Visual hotspot creation with placement tool
- Multiple interaction types (look, use, talk, click)
- Comprehensive action system with 7 action types:
  - ShowMessage - Display text to player
  - ChangeScene - Navigate between scenes
  - PlaySound - Trigger audio effects
  - GiveItem - Add items to inventory
  - RunScript - Execute Lua scripts
  - SetVariable - Modify game state
  - StartDialog - Initiate conversations
- Visual action editor with parameter configuration
- Hotspot visualization and debugging
- Dynamic cursor type management
- Event-based actions (on_click, on_look, on_use, on_talk)
- Full YAML serialization support

### 💬 Dialog Tree Editor
- Visual dialog tree creation with node placement
- Dialog node creation/editing dialog with ID, character, and text fields
- Branching conversation support with visual connections
- Conditional dialog options and end node flags
- Character expression management
- Effects and consequences system
- Portrait integration
- Double-click editing for existing nodes
- Automatic node positioning for new nodes
- Full YAML serialization support

### 📦 Quest System (NEW)
- Visual quest designer
- Objective management
- Prerequisites and dependencies
- Reward configuration
- Journal entry system
- Quest categories (main/side/hidden)

### 🎒 Item System (NEW)
- Item property editor
- Stackable and consumable items
- Item combinations
- Use effects configuration
- Quest item support
- Item states management

### 🎬 Cutscene Editor (NEW)
- Timeline-based editor
- Multiple action types
- Character movements
- Camera effects
- Audio synchronization
- Conditional sequences

### 📝 Script Editor (NEW)
- Full-featured Lua script editor with syntax highlighting
- Real-time syntax validation and error checking
- Function extraction and code navigation
- Auto-completion hints for Lua keywords
- Integrated with hotspot and character interactions
- Automatic script file creation with templates
- Save/load functionality with modification tracking
- Text editing features: cut, copy, paste, undo/redo
- Customizable editor settings (font size, tab size)

### 🎬 Animation Editor (NEW)
- Timeline-based sprite animation system
- Visual frame-by-frame editing with preview
- Animation playback controls (play, pause, speed adjustment)
- Sprite sheet support with automatic frame detection
- Multiple animation management (idle, walk, run, etc.)
- Frame properties editing (duration, offset, sprite coordinates)
- Animation properties (FPS, looping, frame count)
- Real-time animation preview with zoom controls
- Export animations compatible with Point & Click Engine
- Integration with character editor for seamless workflow

### 🔧 Enhanced Hotspot Scripting (NEW)
- Seamless script editing directly from hotspot properties
- Automatic script file generation for each hotspot
- Template scripts with all interaction functions (on_click, on_look, etc.)
- Integration with script editor for advanced editing
- Script validation and error reporting
- Hot-reloading of scripts during development

### 🎭 Enhanced Character Animation (NEW)
- Character-specific animation editing
- Automatic sprite sheet detection and loading
- Multiple animation state management
- Animation preview integration in character editor
- Sprite path resolution with multiple naming conventions
- Character animation properties synchronized with engine

### 📁 Asset Management
- Centralized asset browser with category tabs
- Multi-format import functionality (PNG, JPG, WAV, OGG, MP3, LUA, etc.)
- Automatic asset discovery in common directories
- File copying to appropriate project directories
- Asset categorization (backgrounds, characters, sounds, music, scripts)
- Preview support for images with thumbnails
- Asset validation and duplicate detection
- Error handling for import failures
- Integration with scene editor for asset assignment

### 🏗️ Project Management
- Complete project structure with proper directory organization
- Scene file management with automatic saving
- Export to Point & Click Engine v1.0 compatible games
- Comprehensive validation system before export
- Proper game format generation with YAML configuration
- Entry point creation (main.cr and shard.yml)
- Asset organization and copying during export
- ZIP packaging option for distribution

## System Requirements

- **Operating System**: Windows 10+, macOS 10.15+, or Linux
- **Crystal**: Version 1.16.3 or higher
- **Memory**: 4GB RAM minimum, 8GB recommended
- **Graphics**: OpenGL 3.3 compatible graphics card
- **Storage**: 500MB free space for installation

## Installation

### From Source

1. **Install Dependencies:**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install libasound2-dev mesa-common-dev libx11-dev libxrandr-dev libxi-dev xorg-dev libgl1-mesa-dev libglu1-mesa-dev build-essential libluajit-5.1-dev pkg-config git cmake
   
   # macOS
   brew install raylib luajit pkg-config
   ```

2. **Clone and Build:**
   ```bash
   git clone [repository-url]
   cd pace_editor
   shards install
   crystal build src/pace_editor.cr --release
   ```

3. **Run PACE:**
   ```bash
   ./pace_editor
   ```

For detailed installation instructions, see [Installation Guide](documentation/guides/installation.md).

## Quick Start

1. **Create Your First Project:**
   ```bash
   pace_editor new my_first_game
   cd my_first_game
   pace_editor
   ```

2. **Follow the Tutorial:**
   - Complete the [Getting Started Guide](documentation/guides/getting-started.md)
   - Try the [Beginner Tutorial](documentation/tutorials/beginner-tutorial.md)

3. **Explore Examples:**
   - Browse [Example Projects](documentation/examples/)
   - Use project templates for quick setup

## Documentation

### 📖 User Guides
- **[Installation Guide](documentation/guides/installation.md)** - Complete setup instructions
- **[Getting Started](documentation/guides/getting-started.md)** - Your first adventure game
- **[User Interface Guide](documentation/guides/user-interface.md)** - Complete UI reference

### 🎓 Tutorials
- **[Beginner Tutorial](documentation/tutorials/beginner-tutorial.md)** - "The Mysterious Library"
- **[Advanced Tutorial](documentation/tutorials/advanced-tutorial.md)** - "The Detective's Case"

### 🔧 API Reference
- **[Core API](documentation/api/core.md)** - Project and editor state management
- **[Editors API](documentation/api/editors.md)** - Scene, character, and dialog editors
- **[UI Components](documentation/api/ui.md)** - Interface components and widgets

### 📁 Examples
- **[Sample Projects](documentation/examples/)** - Complete example games
- **[Templates](documentation/examples/templates/)** - Project templates to get started

## Editor Modes

PACE operates in several distinct modes, each optimized for different aspects of game creation:

- **Scene Mode** - Design game scenes with backgrounds, objects, and layouts
- **Character Mode** - Create and animate characters with advanced animation editor
- **Hotspot Mode** - Define interactive areas with integrated script editing
- **Dialog Mode** - Create branching conversations with interactive preview
- **Assets Mode** - Manage project resources and imports
- **Project Mode** - Configure game settings and export options
- **Quest Mode** (NEW) - Design quests with objectives and rewards
- **Item Mode** (NEW) - Create inventory items and interactions
- **Cutscene Mode** (NEW) - Script cinematic sequences
- **Script Editing** (NEW) - Full-featured Lua script editor accessible from any mode
- **Animation Editing** (NEW) - Timeline-based sprite animation system

## Exporting Your Game

PACE now includes a comprehensive export system that generates games compatible with Point & Click Engine v1.0:

### Export Features
- **Automatic validation** - Ensures your game is error-free before export
- **Proper file structure** - Generates the correct directory layout
- **Asset optimization** - Organizes and copies all required assets
- **Configuration generation** - Creates `game_config.yaml` with all settings
- **Entry point creation** - Generates `main.cr` and `shard.yml` files
- **ZIP packaging** - Optional compression for easy distribution

### Export Process
1. Click **File → Export Game** in the menu bar
2. Review validation results - fix any errors before proceeding
3. Choose export location and format (folder or ZIP)
4. Click Export to generate your playable game

### Validation System
The editor validates:
- All scene files and references
- Asset paths and file formats
- Quest and dialog structures
- Item definitions and combinations
- Game configuration settings
- Cross-references between game elements

## Keyboard Shortcuts

### General
- `Ctrl+N` - New scene
- `Ctrl+O` - Open scene
- `Ctrl+S` - Save scene
- `Ctrl+Z` - Undo last action
- `Ctrl+Y` / `Ctrl+Shift+Z` - Redo action
- `Ctrl+Q` - Quit editor

### Tools
- `V` - Select tool (click to select objects)
- `M` - Move tool (drag objects with undo support)
- `P` - Place tool (create hotspots)
- `C` - Character tool (place NPCs)
- `D` - Delete tool
- `H` - Hotspot tool
- `W` - Walkable area tool

### View
- `G` - Toggle grid snapping
- `Shift+H` - Toggle hotspot visibility
- `Space+Mouse` - Pan camera
- `Mouse Wheel` - Zoom in/out
- `F` - Focus on selected object
- `Home` - Reset camera view

### Script Editor
- `Ctrl+S` - Save script
- `F5` - Validate syntax
- `Ctrl+Z` / `Ctrl+Y` - Undo/Redo in script
- `Esc` - Close script editor
- `Tab` - Insert tab (configurable spaces)
- `Ctrl+F` - Find text (planned)

### Animation Editor
- `Space` - Play/pause animation
- `Left/Right Arrow` - Previous/next frame
- `Ctrl+S` - Save animation data
- `Esc` - Close animation editor

## Development

### Building from Source

1. **Prerequisites:**
   - Crystal 1.16.3+
   - Raylib dependencies
   - LuaJIT development libraries

2. **Development Setup:**
   ```bash
   git clone [repository-url]
   cd pace_editor
   shards install
   ```

3. **Run Development Version:**
   ```bash
   crystal run src/pace_editor.cr
   ```

4. **Run Tests:**
   ```bash
   crystal spec
   ```
   
   All specs should pass. The test suite covers:
   - Scene serialization/deserialization
   - Object placement and manipulation
   - Undo/redo functionality
   - Asset import system
   - Property editing
   - Export system
   - UI components

### Project Structure

```
pace_editor/
├── src/                    # Source code
│   ├── pace_editor/        # Editor modules
│   │   ├── core/          # Core functionality
│   │   ├── editors/       # Editor components
│   │   └── ui/            # User interface
│   └── pace_editor.cr     # Main entry point
├── spec/                   # Test files
├── documentation/          # Complete documentation
├── lib/                    # Dependencies
└── shard.yml              # Project configuration
```

## Upgrading from Previous Versions

If you're upgrading from PACE 1.x, here's what you need to know:

### Breaking Changes
- Export format has changed to match Point & Click Engine v1.0
- Scene files now use the new YAML structure
- Project files remain compatible but export differently

### Migration Steps
1. Open your existing project in PACE 2.0
2. The editor will automatically update internal structures
3. Review any validation warnings
4. Re-export your game using the new export system

### New Requirements
- Exported games now require a `game_config.yaml` file (auto-generated)
- Scene files must include proper navigation data
- Asset paths must follow the new directory structure

For detailed migration instructions, see [Migration Guide](docs/migration/MIGRATION_GUIDE.md).

## Contributing

We welcome contributions to PACE! Here's how to get started:

1. **Fork the Repository**
   ```bash
   git clone [your-fork-repository-url]
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b my-new-feature
   ```

3. **Make Your Changes**
   - Follow Crystal coding conventions
   - Add tests for new functionality
   - Update documentation as needed

4. **Submit a Pull Request**
   ```bash
   git commit -am 'Add some feature'
   git push origin my-new-feature
   ```

### Development Guidelines

- **Code Style**: Follow Crystal conventions
- **Testing**: Add specs for new features
- **Documentation**: Update relevant docs
- **Commits**: Use clear, descriptive commit messages

### Development Status

See [MISSING_IMPLEMENTATIONS.md](MISSING_IMPLEMENTATIONS.md) for a detailed list of features that have been completed and those still pending. Major features like scene I/O, object placement, undo/redo, property editing, and asset management are fully implemented and tested.

## License

PACE is released under the MIT License. See [LICENSE](LICENSE) for details.

## Support

- **Documentation**: Complete guides in [documentation/](documentation/)
- **Issues**: Report bugs via GitHub Issues
- **Community**: Join our Discord server for real-time help
- **Email**: Contact support@pace-editor.com

## Contributors

- Remy Marronnier - creator and maintainer

## Acknowledgments

- Built with [Crystal](https://crystal-lang.org/)
- Graphics powered by [Raylib](https://www.raylib.com/)
- Scripting support via [LuaJIT](https://luajit.org/)
- Based on the [PointClickEngine](../point_click_engine/)
