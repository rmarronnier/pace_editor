# PACE - Point & Click Adventure Creator Editor

PACE is a visual editor for creating point-and-click adventure games using the PointClickEngine. It provides an intuitive interface for designing scenes, characters, hotspots, and dialog trees without requiring extensive programming knowledge.

## Features

### 🎨 Visual Scene Editor
- Drag-and-drop scene creation
- Background image support
- Real-time preview
- Multi-layer object management
- Grid snapping and alignment tools

### 👥 Character Management
- Character sprite management
- Animation timeline editor
- Character positioning and scaling
- Interactive character placement

### 🎯 Hotspot System
- Visual hotspot creation and editing
- Multiple interaction types (look, use, talk, etc.)
- Custom action scripting
- Hotspot visualization and debugging

### 💬 Dialog Tree Editor
- Visual dialog tree creation
- Branching conversation support
- Conditional dialog options
- Character expression management

### 📁 Asset Management
- Centralized asset browser
- Import/export functionality
- Asset categorization
- Preview support for images and sounds

### 🏗️ Project Management
- Complete project structure
- Version control integration
- Export to playable games
- Cross-platform compilation

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
   git clone https://github.com/yourusername/pace_editor.git
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
- **Character Mode** - Create and animate characters with sprite management
- **Hotspot Mode** - Define interactive areas and behaviors
- **Dialog Mode** - Create branching conversations and character interactions
- **Assets Mode** - Manage project resources and imports
- **Project Mode** - Configure game settings and export options

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

## Development

### Building from Source

1. **Prerequisites:**
   - Crystal 1.16.3+
   - Raylib dependencies
   - LuaJIT development libraries

2. **Development Setup:**
   ```bash
   git clone https://github.com/yourusername/pace_editor.git
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

## Contributing

We welcome contributions to PACE! Here's how to get started:

1. **Fork the Repository**
   ```bash
   git clone https://github.com/your-fork/pace_editor.git
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

## License

PACE is released under the MIT License. See [LICENSE](LICENSE) for details.

## Support

- **Documentation**: Complete guides in [documentation/](documentation/)
- **Issues**: Report bugs on [GitHub Issues](https://github.com/yourusername/pace_editor/issues)
- **Community**: Join our Discord server for real-time help
- **Email**: Contact support@pace-editor.com

## Contributors

- [Remy Marronnier](https://github.com/your-github-user) - creator and maintainer

## Acknowledgments

- Built with [Crystal](https://crystal-lang.org/)
- Graphics powered by [Raylib](https://www.raylib.com/)
- Scripting support via [LuaJIT](https://luajit.org/)
- Based on the [PointClickEngine](../point_click_engine/)
