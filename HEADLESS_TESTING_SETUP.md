# Headless Testing Setup for PACE Editor

## Overview

This document describes the headless testing infrastructure set up for PACE Editor UI components, allowing tests to run without requiring a graphics window (essential for CI/CD environments).

## Problem

Many UI component specs were failing due to:
- Raylib graphics initialization requirements
- Drawing calls that crash without a window context
- CI environments lacking display capabilities

## Solution

We implemented a multi-tiered approach to enable headless testing:

### 1. Test Categorization

Tests are now organized into categories:

- **Core/Logic Tests**: Pure logic tests that don't require any UI
  - `spec/core/**/*_spec.cr`
  - `spec/models/**/*_spec.cr`
  - `spec/validation/**/*_spec.cr`
  - `spec/export/**/*_spec.cr`

- **UI Logic Tests**: UI component logic without drawing
  - `spec/ui/*_logic_spec.cr`
  - `spec/ui/*_fixed_spec.cr`

- **Headless UI Tests**: UI tests that work without graphics
  - `spec/ui/*_headless_spec.cr`

- **Graphics UI Tests**: Tests requiring actual graphics rendering
  - Other `spec/ui/*_spec.cr` files

### 2. Headless Test Files Created

- `spec/ui/ui_helpers_headless_spec.cr` - Tests UI helper constants and method existence
- `spec/ui/script_editor_headless_spec.cr` - Tests script editor logic without drawing
- `spec/ui/animation_editor_headless_spec.cr` - Tests animation editor functionality

### 3. Test Runners

#### For Development
```bash
./run_all_specs.sh              # Run all non-graphics tests
./run_all_specs.sh --with-graphics  # Include graphics tests
```

#### For CI/CD
```bash
./run_ci_specs.sh               # Run only CI-safe tests
# OR
HEADLESS_SPECS=true crystal spec spec/ui/*_headless_spec.cr
```

### 4. Environment Variables

- `HEADLESS_SPECS=true` - Enables headless mode
- `CI=true` - Also enables headless mode (for CI environments)

## Current Test Status

### ✅ Passing (276+ examples)
- All core system specs
- All model specs
- All validation specs
- All export specs
- All UI logic specs
- All headless UI specs

### ⚠️ Requires Graphics Window
- Full UI component drawing tests
- Integration tests with visual elements

## Writing Headless UI Tests

When creating new UI tests that should run in CI:

1. Create a `*_headless_spec.cr` file
2. Test only the logic, not the drawing:
   ```crystal
   # Good - tests logic
   editor.visible.should be_false
   editor.show("character")
   editor.visible.should be_true
   
   # Avoid - requires drawing
   # editor.draw
   # editor.update
   ```

3. Mock file operations when needed:
   ```crystal
   temp_dir = File.tempname("test_project")
   temp_dir = "#{temp_dir}_#{Time.utc.to_unix_ms}"
   project = PaceEditor::Core::Project.new("test", temp_dir)
   ```

## Future Improvements

1. **Full Raylib Mock**: Create a complete mock implementation that records all drawing calls for verification
2. **Visual Regression Testing**: Capture rendered output for comparison
3. **Integration Test Suite**: Separate suite for full UI integration tests

## Conclusion

The headless testing setup enables:
- ✅ CI/CD compatibility
- ✅ Faster test execution
- ✅ Better test organization
- ✅ Clearer separation of concerns

All critical functionality can now be tested without requiring a graphics environment, while still maintaining the ability to run full graphics tests during development.