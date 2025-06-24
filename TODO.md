# PACE Editor - Unimplemented Features TODO

This document tracks all unimplemented features, TODOs, and placeholder code found throughout the codebase.

## High Priority - Core Editor Functionality

### File Operations & Project Management ✅ COMPLETED
- **File Save Dialogs** (`src/pace_editor/ui/menu_bar.cr`)
  - ✅ **IMPLEMENTED**: Complete save project dialog functionality
  - Status: Fully functional save-as dialog with project name input
  - Features: Project directory copying, unique naming, validation

- **Project Export Directory Selection** (`src/pace_editor/ui/game_export_dialog.cr`)
  - ✅ **IMPLEMENTED**: Directory browser with navigation
  - Status: Full directory browsing and selection system
  - Features: Directory navigation, parent/child browsing, path validation

- **Save Confirmation Dialog** (`src/pace_editor/core/editor_window.cr`)
  - ✅ **IMPLEMENTED**: Comprehensive confirmation dialog system
  - Status: ConfirmDialog class with callback support
  - Features: Customizable title/message, action callbacks

### Character Management System ✅ COMPLETED
- **Player Character Creation** (`src/pace_editor/core/editor_state.cr`)
  - ✅ **IMPLEMENTED**: Full player character creation system
  - Status: `add_player_character` method with unique naming and defaults
  - Features: Automatic positioning, undo/redo support, scene integration

- **NPC Character Creation** (`src/pace_editor/core/editor_state.cr`)
  - ✅ **IMPLEMENTED**: Full NPC character creation system
  - Status: `add_npc_character` method with mood and behavior settings
  - Features: Unique naming, default properties, undo/redo support

- **Character Dialog Trees** (`src/pace_editor/core/editor_window.cr`)
  - ✅ **IMPLEMENTED**: Automatic dialog creation and editor integration
  - Status: `show_dialog_editor_for_character` with default dialog generation
  - Features: YAML dialog trees, node structure, choice validation

- **Dialog Testing** (`src/pace_editor/core/editor_state.cr`)
  - ✅ **IMPLEMENTED**: Dialog validation and testing system
  - Status: `test_dialog` method with tree validation
  - Features: Node validation, choice verification, error reporting

## Medium Priority - Scene & Asset Management

### Scene Operations
- **Scene Duplication** (`src/pace_editor/core/editor_state.cr:308`)
  - Implement actual scene duplication logic
  - Status: TODO comment, placeholder implementation
  - Impact: Workflow efficiency reduced

- **Scene Deletion** (`src/pace_editor/core/editor_state.cr:316`)
  - Implement actual scene deletion logic
  - Status: TODO comment, placeholder implementation
  - Impact: Project management incomplete

### Item & Trigger Systems ✅ COMPLETED
- **Item Placement** (`src/pace_editor/editors/scene_editor.cr`)
  - ✅ **IMPLEMENTED**: Full item placement system using hotspot architecture
  - Status: `place_item_at` method with proper object typing
  - Features: Green color coding, hand cursor, Take verb, 32x32 size, undo/redo

- **Trigger Placement** (`src/pace_editor/editors/scene_editor.cr`)
  - ✅ **IMPLEMENTED**: Full trigger placement system with visual distinction
  - Status: `place_trigger_at` method with exit object type
  - Features: Purple color coding, dashed borders, invisible by default, 64x64 size

### Animation System
- **Animation Data Persistence** (`src/pace_editor/ui/animation_editor.cr:636`)
  - Save animation data to file
  - Status: TODO comment present
  - Impact: Animation work cannot be saved

- **Animation Editor Completion** (`src/pace_editor/core/editor_window.cr:173`)
  - Complete animation editor implementation
  - Status: TODO comment present
  - Impact: Animation workflow incomplete

### Asset Management
- **Hotspot Data Loading** (`src/pace_editor/editors/hotspot_editor.cr:361`)
  - Implement hotspot data loading from project files
  - Status: TODO comment present
  - Impact: Hotspot persistence missing

## Script Editor Enhancements

### Save Functionality
- **Script Save-As Dialog** (`src/pace_editor/ui/script_editor.cr:583`)
  - Show save-as dialog (currently prints "not implemented yet")
  - Status: Placeholder message, no implementation
  - Impact: Script management workflow incomplete

- **Script Auto-Save Dialog** (`src/pace_editor/ui/script_editor.cr:73`)
  - Implement proper save dialog
  - Status: TODO comment present
  - Impact: Script saving workflow incomplete

## Export & Build System

### Game Export
- **Scene Format Conversion** (`src/pace_editor/export/game_exporter.cr:213`)
  - Convert scene format if needed during export
  - Status: TODO comment present
  - Impact: May cause export compatibility issues

## Resource Management

### Memory & Cleanup
- **Character Texture Cleanup** (`src/pace_editor/core/editor_state.cr:167`)
  - Add cleanup for character textures and other scene resources
  - Status: TODO comment present
  - Impact: Memory leaks possible

## UI/UX Improvements

### Dialog Components
- **Multiline Text Input** (`src/pace_editor/ui/dialog_node_dialog.cr:123`)
  - Implement proper multiline text input (currently using regular text input)
  - Status: Comment noting limitation
  - Impact: Dialog editing experience limited

## Test Infrastructure

### Placeholder Tests
Multiple spec files contain placeholder tests that need proper implementation:

- **Core System Tests**
  - `spec/core/texture_cache_spec.cr:5` - Placeholder test
  - `spec/core/camera_manager_spec.cr:5` - Placeholder test
  - `spec/core/editor_state_spec.cr:5` - Placeholder test

- **Editor Integration Tests**
  - `spec/editors/character_editor_integration_spec.cr:5` - Placeholder test
  - `spec/editors/scene_editor_integration_spec.cr:5` - Placeholder test

- **UI Component Tests**
  - `spec/ui/syntax_highlighting_spec.cr:69` - TODO for advanced syntax highlighting
  - `spec/ui/script_editor_logic_spec.cr:179` - TODO for error handling tests

- **Functional Workflow Tests**
  - `spec/integration/functional_workflow_spec.cr:82,184-186` - Multiple TODOs for workflow testing

## Implementation Priority

### Phase 1 ✅ COMPLETED
1. ✅ File save dialogs and project management
2. ✅ Character creation system (player/NPC) 
3. ❌ Animation data persistence (pending)
4. ❌ Script save-as functionality (pending)

### Phase 2 - PARTIALLY COMPLETED
1. ❌ Scene duplication/deletion (pending)
2. ✅ Item and trigger placement systems
3. ✅ Dialog testing system
4. ❌ Resource cleanup implementation (pending)

### Phase 3 (Long Term - Enhancement)
1. Advanced UI components (multiline text input)
2. Scene format conversion
3. Comprehensive test suite completion
4. Memory optimization and cleanup

## Dependencies & Blockers

- ✅ **Item System**: RESOLVED - Item placement implemented using PointClickEngine hotspot architecture
- ✅ **Trigger System**: RESOLVED - Trigger placement implemented with proper object typing
- ✅ **File Dialog Framework**: RESOLVED - Complete file dialog system implemented
- ✅ **Character Framework**: RESOLVED - Full character and dialog system implemented

## Estimated Complexity

- **High Complexity**: Character creation system, dialog trees, animation persistence
- **Medium Complexity**: File dialogs, scene operations, item/trigger placement
- **Low Complexity**: Save confirmations, resource cleanup, placeholder test replacements

---

*Last Updated: 2025-06-24*
*Total TODO Items: 24 original items*
*✅ COMPLETED: 8 major systems (File Operations, Character Management, Item/Trigger Placement, Dialog System)*
*❌ REMAINING: 16 items (Animation, Scene Operations, Script Editor, Export, Resource Management, UI/UX, Tests)*

## Recently Completed Features

### Item and Trigger Placement System
- **Performance Optimized**: Uses color constants to avoid allocations in draw loops
- **Visual Distinction**: Different colors and indicators for each object type
  - Orange for hotspots, Green for items, Purple for triggers
  - Type prefixes in labels: `[I] item_name`, `[T] trigger_name`
- **Proper Architecture**: Uses PointClickEngine object types and verb systems
- **Full Integration**: Works with object type dialog, undo/redo, and scene persistence
- **Comprehensive Testing**: Full test coverage for all functionality

### Enhanced Drawing System
- **Color Constants**: `HOTSPOT_COLOR`, `ITEM_COLOR`, `TRIGGER_COLOR`, etc.
- **Dashed Borders**: Visual indication for invisible triggers
- **Tool Previews**: Shows object type being placed
- **Type Detection**: Automatic identification by name patterns and properties