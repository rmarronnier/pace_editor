# PACE Editor 2.0.1 Release Notes

Released: June 24, 2024

## Overview

PACE Editor 2.0.1 is a maintenance release that fixes several important UI issues discovered in version 2.0.0. This release focuses on improving the user experience by ensuring all UI elements work correctly across different screen sizes and configurations.

## What's Fixed

### Modal Dialog Positioning
- **Issue**: Modal dialogs were appearing in incorrect positions, sometimes partially off-screen
- **Fix**: All dialogs now use dynamic screen dimensions (`RL.get_screen_width()` and `RL.get_screen_height()`) instead of hardcoded values
- **Affected Dialogs**: 
  - Dialog Node Dialog
  - Game Export Dialog
  - Background Import/Selector Dialogs
  - Scene Creation Wizard
  - Asset Import Dialog
  - Script Editor
  - Animation Editor
  - And 5 more dialogs

### Tutorial and Getting Started UI
- **Issue**: The welcome panel and tutorial instructions appeared partially off-screen
- **Fix**: Both panels now dynamically center themselves based on current screen size
- **Impact**: New users can now properly see and interact with the onboarding experience

### Button Click Handling
- **Issue**: Buttons in modal dialogs weren't responding to clicks
- **Fix**: 
  - Tutorial Next/Skip buttons now use correct dynamic positions
  - Getting started panel buttons work properly
  - Implemented the missing New Project dialog

### Menu System
- **Issue**: File menu wasn't responding after closing the getting started panel
- **Fix**: Improved input handling priority to ensure menus work correctly in all states

### New Project Creation
- **Issue**: "New Project" button did nothing (missing implementation)
- **Fix**: Added complete New Project dialog with:
  - Text input for project name
  - Create/Cancel buttons with visual feedback
  - Keyboard shortcuts (Enter to create, Escape to cancel)
  - Input validation

## Testing Improvements

### Test Suite Updates
- Removed dependency on headless mode for UI tests
- Fixed all 18 pending tests
- All 600 tests now pass successfully
- Updated test runner script for better compatibility

### Test Categories
- **Core and Logic specs**: 347 tests ✓
- **UI specs**: 253 tests ✓

## Technical Details

### Code Changes
- Updated 12 dialog files to use dynamic positioning
- Fixed `GuidedWorkflow` tutorial positioning calculations
- Improved `EditorWindow` input handling order
- Added complete `draw_new_project_dialog` implementation
- Fixed `ProgressiveMenu` width calculations

### Dependencies
No dependency changes in this release.

## Upgrading

To upgrade to PACE 2.0.1:

1. Pull the latest changes:
   ```bash
   git pull origin master
   ```

2. Rebuild the editor:
   ```bash
   ./build.sh src/pace_editor.cr --release
   ```

3. Run the updated editor:
   ```bash
   ./pace_editor
   ```

## Known Issues

None at this time. All known UI issues from 2.0.0 have been resolved.

## Credits

- UI positioning fixes and test improvements by the PACE development team
- Thanks to users who reported the modal positioning issues

## What's Next

The next release will focus on:
- Implementing the Open Project dialog
- Adding more project templates
- Enhancing the asset import workflow
- Additional UI polish and improvements

---

For questions or issues, please visit: https://github.com/anthropics/pace-editor/issues