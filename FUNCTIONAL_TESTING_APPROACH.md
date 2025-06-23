# Functional Testing Approach for PACE Editor

## Overview

This document outlines our systematic approach to detecting and fixing incomplete functionality in the PACE Editor. Traditional unit tests verify that individual components work, but functional workflow tests verify that complete user workflows actually function end-to-end.

## The Problem

Many UI elements appear to work (buttons exist, fields are editable) but the complete workflows are broken or incomplete. For example:
- Background import button exists but has no file browser dialog
- Asset browser displays assets but can't import new ones
- Export menu creates a directory but doesn't generate playable games

## The Solution: Functional Workflow Testing

### 1. Test Complete User Workflows

Instead of testing individual components, test entire user scenarios:

```crystal
# ❌ Component test (insufficient)
it "validates Edit Script button exists" do
  button_exists.should be_true
end

# ✅ Functional workflow test (complete)
it "allows user to edit hotspot scripts end-to-end" do
  # 1. User creates hotspot
  # 2. User clicks "Edit Script" button
  # 3. Script editor opens with auto-created file
  # 4. User edits script content
  # 5. User saves script
  # 6. Script is properly linked to hotspot
  # 7. Script executes in game engine
end
```

### 2. Document Missing Functionality

When workflows fail, document exactly what's missing:

```crystal
# MISSING FUNCTIONALITY DETECTED:
# - No script editor dialog
# - No file browser for script selection
# - No script validation
# - No script preview/testing
```

### 3. Prioritize Implementation

Categorize missing features by impact:
- **Critical**: Blocks core functionality (can't create games)
- **Important**: Reduces usability (complex workflows)
- **Quality of Life**: Nice to have (auto-save, templates)

## Implementation Process

### Phase 1: Discovery and Documentation

1. **Create functional workflow tests** for each major user scenario
2. **Run tests** to identify incomplete functionality
3. **Document missing features** with priority levels
4. **Create implementation plan** starting with critical features

### Phase 2: Implementation

1. **Implement highest priority features** first
2. **Update tests** to verify new functionality works
3. **Repeat discovery process** to find remaining issues
4. **Iterate** until all critical workflows function

### Phase 3: Continuous Validation

1. **Run functional tests** regularly during development
2. **Add new workflow tests** for new features
3. **Maintain documentation** of known missing features

## Workflow Test Categories

### Core Game Creation Workflows
- **Project Creation**: New project → Add scenes → Add assets → Export game
- **Scene Creation**: New scene → Set background → Add hotspots → Add characters
- **Asset Management**: Import assets → Organize assets → Assign to objects
- **Scripting**: Create scripts → Edit scripts → Test scripts → Link to hotspots
- **Dialog Creation**: Create NPCs → Add dialog trees → Connect dialog nodes
- **Game Export**: Complete project → Export → Generate playable game

### Editor Workflows  
- **Navigation**: Switch modes → Select objects → Edit properties
- **File Operations**: Save project → Load project → Import assets
- **Tool Usage**: Select tools → Use tools → Undo/redo actions

### Error Handling Workflows
- **Recovery**: Handle missing assets → Corrupted files → Invalid data
- **Validation**: Check project completeness → Verify asset links → Test exports

## Test Structure

Each functional workflow test should follow this pattern:

```crystal
describe "Workflow Name" do
  it "tests complete user scenario" do
    # 1. Setup: Create test environment
    # 2. Action: Simulate user workflow steps
    # 3. Verification: Check results at each step
    # 4. Documentation: Note any missing functionality
  end

  it "detects missing functionality" do
    # Document what should exist but doesn't
    # This creates a todo list for implementation
  end
end
```

## Benefits

1. **Complete Coverage**: Tests entire user experience, not just individual components
2. **User-Focused**: Validates that users can actually accomplish their goals
3. **Documentation**: Creates clear requirements for missing functionality
4. **Prioritization**: Identifies most critical issues first
5. **Regression Prevention**: Ensures workflows continue working as code changes

## Files Created

- `spec/integration/functional_workflow_spec.cr`: Main functional tests
- `MISSING_FEATURES.md`: Prioritized list of missing functionality
- `FUNCTIONAL_TESTING_APPROACH.md`: This documentation

## Next Steps

1. Review the missing features report
2. Implement background import dialog (highest priority)
3. Add asset import functionality
4. Create scene creation workflow
5. Continue with remaining critical features

This approach ensures we build functionality that actually works for users, rather than just individual components that exist in isolation.