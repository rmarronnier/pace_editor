# PACE Editor - Unimplemented Features TODO

This document tracks all unimplemented features, TODOs, and placeholder code found throughout the codebase.

## High Priority - Core Editor Functionality

### File Operations & Project Management
- **File Save Dialogs** (`src/pace_editor/core/editor_window.cr:159`)
  - Implement file dialog for saving projects
  - Status: TODO comment present, no implementation
  - Impact: Users cannot save projects properly

- **Project Export Directory Selection** (`src/pace_editor/ui/game_export_dialog.cr:92`)
  - Implement file browser for directory selection
  - Status: TODO comment present, placeholder button
  - Impact: Game export functionality incomplete

- **Save Confirmation Dialog** (`src/pace_editor/core/editor_window.cr:166`)
  - Implement confirmation dialog for unsaved changes
  - Status: TODO comment present
  - Impact: Risk of data loss

### Character Management System
- **Player Character Creation** (`src/pace_editor/core/editor_state.cr:331`)
  - Complete implementation of player character creation
  - Status: TODO comment, no implementation
  - Impact: Core game feature missing

- **NPC Character Creation** (`src/pace_editor/core/editor_state.cr:337`)
  - Complete implementation of NPC character creation
  - Status: TODO comment, no implementation
  - Impact: Core game feature missing

- **Character Dialog Trees** (`src/pace_editor/core/editor_window.cr:130`)
  - Load/create dialog tree system for characters
  - Status: TODO comment present
  - Impact: Character interaction system incomplete

- **Dialog Testing** (`src/pace_editor/core/editor_state.cr:344`)
  - Implement dialog testing functionality
  - Status: TODO comment present
  - Impact: Cannot test dialog flows

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

### Item & Trigger Systems
- **Item Placement** (`src/pace_editor/editors/scene_editor.cr:476`)
  - Implement item placement when item system is ready
  - Status: TODO comment, depends on item system
  - Impact: Game object interaction missing

- **Trigger Placement** (`src/pace_editor/editors/scene_editor.cr:481`)
  - Implement trigger placement when trigger system is ready
  - Status: TODO comment, depends on trigger system
  - Impact: Game logic triggers missing

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

### Phase 1 (Immediate - High Priority)
1. File save dialogs and project management
2. Character creation system (player/NPC)
3. Animation data persistence
4. Script save-as functionality

### Phase 2 (Short Term - Medium Priority)
1. Scene duplication/deletion
2. Item and trigger placement systems
3. Dialog testing system
4. Resource cleanup implementation

### Phase 3 (Long Term - Enhancement)
1. Advanced UI components (multiline text input)
2. Scene format conversion
3. Comprehensive test suite completion
4. Memory optimization and cleanup

## Dependencies & Blockers

- **Item System**: Item placement depends on item system completion
- **Trigger System**: Trigger placement depends on trigger system completion
- **File Dialog Framework**: Multiple file operations depend on file dialog implementation
- **Character Framework**: Dialog trees depend on character system completion

## Estimated Complexity

- **High Complexity**: Character creation system, dialog trees, animation persistence
- **Medium Complexity**: File dialogs, scene operations, item/trigger placement
- **Low Complexity**: Save confirmations, resource cleanup, placeholder test replacements

---

*Last Updated: 2025-06-24*
*Total TODO Items: 24 comments + numerous placeholder implementations*