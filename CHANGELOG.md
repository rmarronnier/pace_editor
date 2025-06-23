# Changelog

All notable changes to PACE Editor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-01-23

### Added

#### New Game Systems
- **Quest System** - Complete quest creation with objectives, rewards, and dependencies
- **Item System** - Inventory item management with states, combinations, and effects
- **Cutscene Editor** - Timeline-based cutscene creation with multiple action types
- **Validation System** - Comprehensive validation before export with detailed error reporting

#### New Models
- `GameConfig` - Complete game configuration model matching engine format
- `Quest`, `QuestObjective`, `Reward` - Quest system models
- `Item`, `ItemState` - Inventory item models
- `DialogTree`, `DialogNode`, `DialogChoice` - Enhanced dialog models
- `Cutscene`, `CutsceneAction` - Cutscene definition models
- `Condition`, `Effect` - Game logic primitives

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
- Comprehensive specs for all new models
- Validation system specs
- Export functionality specs
- 136 new tests ensuring reliability

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
- Try the quest system for complex game progression
- Use the item system for inventory puzzles
- Create cutscenes for dramatic moments
- Leverage validation to catch errors early