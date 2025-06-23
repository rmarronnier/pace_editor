# PACE Editor Documentation

Welcome to the comprehensive documentation for PACE (Point & Click Adventure Creator Editor) version 2.0.

## What's New in Version 2.0

PACE 2.0 brings full compatibility with Point & Click Engine v1.0, along with powerful new features:

- **Quest System** - Design complex game progression with objectives and rewards
- **Item Management** - Create inventory items with states and interactions
- **Cutscene Editor** - Script cinematic sequences with timeline-based editing
- **Validation System** - Catch errors before export with comprehensive validation
- **Enhanced Export** - Generate properly structured games ready to play

## Features

### 🎨 Visual Scene Editor
- Drag-and-drop scene creation
- Background image support
- Real-time preview
- Multi-layer object management
- Grid snapping and alignment tools
- **NEW:** Walkable area definition
- **NEW:** Scale zones for perspective
- **NEW:** Walk-behind regions

### 👥 Character Management
- Character sprite management
- Animation timeline editor
- Character positioning and scaling
- Interactive character placement
- **NEW:** Dialog tree integration
- **NEW:** Portrait support

### 🎯 Hotspot System
- Visual hotspot creation and editing
- Multiple interaction types (look, use, talk, etc.)
- Custom action scripting
- Hotspot visualization and debugging
- **NEW:** Dynamic state management
- **NEW:** Conditional visibility

### 💬 Dialog Tree Editor
- Visual dialog tree creation
- Branching conversation support
- Conditional dialog options
- Character expression management
- **NEW:** Effects and consequences
- **NEW:** Portrait integration

### 📦 Quest System (NEW)
- Visual quest designer
- Objective management
- Prerequisites and dependencies
- Reward configuration
- Journal entry system
- Quest categories

### 🎒 Item System (NEW)
- Item property editor
- Stackable and consumable items
- Item combinations
- Use effects configuration
- Quest item support
- Item states

### 🎬 Cutscene Editor (NEW)
- Timeline-based editing
- Multiple action types
- Character movements
- Camera effects
- Audio synchronization
- Conditional sequences

### 📁 Asset Management
- Centralized asset browser
- Import/export functionality
- Asset categorization
- Preview support for images and sounds
- **NEW:** Asset validation
- **NEW:** Usage tracking

### 🏗️ Project Management
- Complete project structure
- Version control integration
- Export to playable games
- Cross-platform compilation
- **NEW:** Validation before export
- **NEW:** Proper game format generation

## System Requirements

- **Operating System**: Windows 10+, macOS 10.15+, or Linux
- **Crystal**: Version 1.16.3 or higher
- **Memory**: 4GB RAM minimum, 8GB recommended
- **Graphics**: OpenGL 3.3 compatible graphics card
- **Storage**: 500MB free space for installation

## Quick Start

1. **Installation**: See [Installation Guide](guides/installation.md)
2. **First Project**: Follow the [Getting Started Guide](guides/getting-started.md)
3. **Basic Tutorial**: Complete the [Beginner Tutorial](tutorials/beginner-tutorial.md)

## Documentation Structure

- **[Installation Guide](guides/installation.md)** - How to install and set up PACE
- **[Getting Started](guides/getting-started.md)** - Your first adventure game
- **[User Interface Guide](guides/user-interface.md)** - Complete UI reference
- **[Game Format Guide](guides/game-format.md)** - Understanding PACE game format

### Tutorials
- **[Beginner Tutorial](tutorials/beginner-tutorial.md)** - Create your first simple game
- **[Advanced Tutorial](tutorials/advanced-tutorial.md)** - Complex scenes and interactions

### API Reference
- **[Core API](api/core.md)** - Project and editor state management
- **[Editors API](api/editors.md)** - Scene, character, and dialog editors
- **[UI Components](api/ui.md)** - Interface components and widgets

### Examples
- **[Sample Projects](examples/)** - Complete example games
- **[Templates](examples/templates/)** - Project templates to get started

## Editor Modes

PACE operates in several distinct modes, each optimized for different aspects of game creation:

### Scene Mode
The primary mode for designing game scenes:
- Place and arrange objects
- Set up backgrounds
- Create hotspots
- Position characters
- Define walkable areas
- Configure scale zones

### Character Mode
Dedicated character editing:
- Import and manage sprites
- Create animation sequences
- Set character properties
- Design interaction behaviors
- Link dialog trees
- Manage portraits

### Hotspot Mode
Interactive area creation:
- Define clickable regions
- Set up interaction types
- Configure custom actions
- Test hotspot behaviors
- Manage hotspot states
- Set visibility conditions

### Dialog Mode
Conversation design:
- Create dialog trees
- Design branching conversations
- Set character expressions
- Test dialog flow
- Configure effects
- Add conditions

### Quest Mode (NEW)
Quest system management:
- Design quest structures
- Create objectives
- Set prerequisites
- Configure rewards
- Manage journal entries
- Define completion conditions

### Item Mode (NEW)
Inventory item creation:
- Design item properties
- Configure combinations
- Set use effects
- Manage item states
- Define stackability
- Create quest items

### Cutscene Mode (NEW)
Cinematic sequence editor:
- Timeline-based editing
- Script character movements
- Add dialog sequences
- Configure camera effects
- Synchronize audio
- Create conditional branches

### Assets Mode
Asset management:
- Browse project assets
- Import new resources
- Organize files
- Preview content
- Validate assets
- Track usage

### Project Mode
High-level project settings:
- Configure game properties
- Manage build settings
- Export options
- Version control
- Validation settings
- Game configuration

## Export and Validation

### Export System

PACE 2.0 includes a completely rewritten export system that generates games compatible with Point & Click Engine v1.0:

1. **Pre-Export Validation** - Automatically validates your entire project
2. **Configuration Generation** - Creates `game_config.yaml` with all settings
3. **Asset Organization** - Properly structures all game assets
4. **File Generation** - Creates entry points and dependency files
5. **Packaging Options** - Export as folder or ZIP archive

### Validation System

The comprehensive validation system checks:

- **Scene Validation**
  - Background images exist
  - Hotspot references are valid
  - Character positions are correct
  - Navigation data is complete

- **Asset Validation**
  - All referenced files exist
  - File formats are correct
  - Asset paths are valid
  - No missing dependencies

- **Quest Validation**
  - Objectives are properly defined
  - Prerequisites exist
  - Rewards are valid
  - No circular dependencies

- **Dialog Validation**
  - All nodes are reachable
  - No circular references
  - Portrait files exist
  - Effects are valid

- **Item Validation**
  - Unique item names
  - Valid combinations
  - Icon files exist
  - Effects are properly defined

- **Cross-Reference Validation**
  - All internal references are valid
  - No orphaned elements
  - Consistent data types
  - Complete dependency chains

## Keyboard Shortcuts

### General
- `Ctrl+N` - New project
- `Ctrl+O` - Open project
- `Ctrl+S` - Save project
- `Ctrl+Z` - Undo
- `Ctrl+Y` - Redo

### Tools
- `V` - Select tool
- `M` - Move tool
- `P` - Place tool
- `D` - Delete tool

### View
- `G` - Toggle grid
- `H` - Toggle hotspot visibility
- `Space+Mouse` - Pan camera
- `Mouse Wheel` - Zoom in/out

## Contributing

We welcome contributions to PACE! Please see our [Contributing Guidelines](../CONTRIBUTING.md) for details on:

- Setting up the development environment
- Code style and conventions
- Submitting bug reports
- Proposing new features

## License

PACE is released under the MIT License. See [LICENSE](../LICENSE) for details.

## Support

- **Documentation**: Browse the complete documentation in this folder
- **Issues**: Report bugs or request features via GitHub Issues
- **Community**: Join our Discord server for community support
- **Email**: Contact us at support@pace-editor.com

## Changelog

See [CHANGELOG.md](../CHANGELOG.md) for version history and updates.