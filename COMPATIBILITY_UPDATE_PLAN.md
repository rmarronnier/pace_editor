# PACE Editor Compatibility Update Plan

## Overview
This document outlines the plan to update PACE Editor to be compatible with the new Point & Click Engine game format. The update focuses on implementing proper validation and export functionality to ensure games created with the editor work with the current engine.

## Current State Analysis
- Editor uses outdated export format
- No validation system in place
- Missing support for new game format features (quests, items, cutscenes)
- Relies on engine models directly without proper serialization

## Implementation Plan

### Phase 1: Core Infrastructure (Priority: Critical)

#### 1.1 Create New Data Models
Create models in `src/pace_editor/models/` for:
- [ ] `GameConfig` - Main game configuration
- [ ] `Quest` and `QuestObjective` - Quest system
- [ ] `DialogTree` and `DialogNode` - Dialog trees (update existing)
- [ ] `Item` - Inventory items
- [ ] `Cutscene` and `CutsceneAction` - Scripted sequences
- [ ] `Condition` and `Effect` - Game logic primitives

#### 1.2 Implement Validation System
Create `src/pace_editor/validation/` module:
- [ ] `GameConfigValidator` - Validate game configuration
- [ ] `SceneValidator` - Validate scene format and references
- [ ] `QuestValidator` - Validate quest definitions
- [ ] `DialogValidator` - Validate dialog trees
- [ ] `ItemValidator` - Validate item definitions
- [ ] `AssetValidator` - Check asset paths exist
- [ ] `ValidationResult` - Unified error reporting

### Phase 2: Export System (Priority: Critical)

#### 2.1 Update Export Functionality
Rewrite `Project#export_game` to:
- [ ] Generate `game_config.yaml` with proper structure
- [ ] Create correct directory structure
- [ ] Export scenes in new YAML format
- [ ] Generate quest/dialog/item YAML files
- [ ] Properly organize and copy assets
- [ ] Run validation before export
- [ ] Show validation errors to user

#### 2.2 Directory Structure
Ensure exported games follow this structure:
```
game_name/
├── game_config.yaml          # Main configuration
├── main.cr                   # Entry point
├── scenes/                   # Scene definitions
│   └── *.yaml
├── scripts/                  # Lua scripts
│   └── *.lua
├── dialogs/                  # Dialog trees
│   └── *.yaml
├── quests/                   # Quest definitions
│   └── *.yaml
├── items/                    # Item definitions
│   └── items.yaml
├── cutscenes/               # Cutscene definitions
│   └── *.yaml
├── assets/                  # Game assets
│   ├── backgrounds/         # Scene backgrounds
│   ├── sprites/            # Character sprites
│   ├── items/              # Item icons
│   ├── portraits/          # Character portraits
│   ├── music/              # Background music
│   └── sounds/             # Sound effects
└── saves/                   # Save files (auto-created)
```

### Phase 3: UI Updates (Priority: High)

#### 3.1 Export UI
- [ ] Add "Export Game" menu option
- [ ] Create export dialog with options
- [ ] Show validation results
- [ ] Progress indicator for export

#### 3.2 Game Configuration Editor
- [ ] Create game config dialog
- [ ] Window settings editor
- [ ] Feature toggles
- [ ] Asset path configuration

### Phase 4: Missing Editors (Priority: Medium)

#### 4.1 Quest Editor
- [ ] Visual quest designer
- [ ] Objective management
- [ ] Condition builder
- [ ] Reward configuration

#### 4.2 Item Editor
- [ ] Item property editor
- [ ] Icon selection
- [ ] Combination rules
- [ ] Effect configuration

#### 4.3 Cutscene Editor
- [ ] Timeline-based editor
- [ ] Action sequencing
- [ ] Preview functionality

### Phase 5: Enhanced Features (Priority: Low)

#### 5.1 Scene Editor Updates
- [ ] Walkable area polygon editor
- [ ] Scale zone configuration
- [ ] Walk-behind regions
- [ ] Edge exits

#### 5.2 Integration Features
- [ ] Lua script syntax highlighting
- [ ] Asset usage tracking
- [ ] Cross-reference validation
- [ ] In-editor game preview

## Testing Plan

### Test Cases
1. Export empty project - should create valid minimal game
2. Export project with scenes - validate scene format
3. Export with all asset types - check asset organization
4. Validation error handling - ensure clear error messages
5. Round-trip testing - import exported game back

### Sample Projects
Create sample projects to test:
- Minimal game (one scene, one hotspot)
- Dialog-heavy game (multiple characters, dialog trees)
- Quest-based game (main and side quests)
- Full featured game (all systems used)

## Success Criteria
- [ ] Exported games run in Point & Click Engine without errors
- [ ] All validation passes for well-formed projects
- [ ] Clear error messages for validation failures
- [ ] Maintains backward compatibility with existing projects
- [ ] Editor remains stable and responsive

## Implementation Order
1. Create data models (Week 1)
2. Implement validation system (Week 1-2)
3. Update export functionality (Week 2)
4. Add export UI with validation (Week 2-3)
5. Implement missing editors (Week 3-4)
6. Testing and refinement (Week 4)

## Notes
- Prioritize validation and export over new editing features
- Ensure exported games are immediately playable
- Maintain editor stability throughout updates
- Document any breaking changes for users