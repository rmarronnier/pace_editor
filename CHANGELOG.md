# Changelog

All notable changes to PACE Editor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1] - 2024-06-24

### Fixed
- **Modal Dialog Positioning** - All modal dialogs now properly center on screen using dynamic dimensions instead of hardcoded values
- **Tutorial UI Positioning** - Fixed multi-step tutorial panels appearing partially off-screen
- **Getting Started Panel** - Fixed positioning to always center properly on different screen sizes
- **Input Handling** - Fixed input priority so menus work correctly after closing the getting started panel
- **New Project Dialog** - Implemented missing new project dialog with proper text input and button handling
- **Tutorial Button Clicks** - Fixed tutorial Next/Skip buttons using incorrect positions
- **Progressive Menu** - Fixed menu width calculations to work properly with dynamic initialization

### Added
- **New Project Dialog Implementation** - Complete modal dialog for creating new projects with:
  - Text input for project name
  - Create/Cancel buttons with hover states
  - Keyboard shortcuts (Enter to create, Escape to cancel)
  - Proper input validation

### Changed
- **Dialog Positioning System** - All dialogs now use `RL.get_screen_width()` and `RL.get_screen_height()` for dynamic positioning
- **Input Handling Order** - Improved input priority to ensure UI elements respond correctly

### Testing
- **Fixed All Pending Tests** - Removed headless mode dependencies and fixed all UI tests to work properly
- **Test Infrastructure** - Updated test runner script to work without headless mode
- **UI Test Coverage** - All UI components now have proper test coverage with Raylib initialization

## [2.0.0] - 2024-06-23

### Added

#### New Editing Features
- **Script Editor** - Full-featured Lua script editor with syntax highlighting, validation, and real-time error checking
- **Animation Editor** - Timeline-based sprite animation system with frame management and real-time preview
- **Enhanced Hotspot Scripting** - Seamless script editing integration with automatic template generation
- **Enhanced Character Animation** - Complete animation workflow with sprite sheet detection
- **Validation System** - Comprehensive validation before export with detailed error reporting

#### New Components
- `ScriptEditor` - Complete Lua script editor with syntax highlighting
- `AnimationEditor` - Timeline-based animation editor with sprite sheet support
- `SyntaxToken` - Syntax highlighting token system for Lua
- `AnimationData` - Animation data structure with frame management
- Enhanced `HotspotEditor` with script integration
- Enhanced `CharacterEditor` with animation integration

#### Export System
- New `GameExporter` class with full validation
- Automatic `game_config.yaml` generation
- Proper directory structure creation
- Asset organization and copying
- ZIP archive support
- Entry point generation (`main.cr` and `shard.yml`)

#### Validation
- `ProjectValidator` - Overall project validation
- `GameConfigValidator` - Configuration validation
- `AssetValidator` - Asset file validation
- `ValidationResult` - Unified error/warning reporting

#### Testing
- Comprehensive specs for Script Editor functionality
- Animation Editor testing suite
- Integration tests for editor workflows
- Syntax highlighting validation tests
- File I/O operation testing for scripts and animations

### Changed

#### Export Format
- Export now generates Point & Click Engine v1.0 compatible format
- Scene files exported with proper YAML structure
- Assets organized into correct directory hierarchy
- Configuration files automatically generated

#### Project Structure
- Added `models/` directory for data models
- Added `validation/` directory for validators
- Added `export/` directory for export functionality
- Improved code organization and separation of concerns

### Fixed
- Scene file path handling now consistent with .yaml extensions
- Proper validation of all game elements before export
- Asset path resolution issues
- Cross-reference validation between game elements

### Technical Improvements
- Better error handling throughout the codebase
- Improved type safety with Crystal's type system
- More modular architecture for easier maintenance
- Enhanced test coverage for critical functionality

## [1.0.0] - Previous Release

### Initial Features
- Visual scene editor with drag-and-drop
- Character management and animation
- Hotspot creation and editing
- Dialog tree editor
- Asset browser
- Basic project management
- Simple export functionality

---

## Upgrade Notes

### From 1.x to 2.0

**Breaking Changes:**
- Export format has completely changed
- Old exported games are not compatible with the new engine format
- Scene file structure has been updated

**Migration Steps:**
1. Open existing projects in PACE 2.0
2. Review validation warnings and fix any issues
3. Re-export games using the new export system
4. Test exported games with Point & Click Engine v1.0

**New Features to Explore:**
- Use the Script Editor for advanced hotspot interactions with Lua scripting
- Create character animations with the timeline-based Animation Editor
- Take advantage of syntax highlighting and error checking for script development
- Use automatic sprite sheet detection for faster animation setup
- Leverage real-time animation preview for precise timing adjustments