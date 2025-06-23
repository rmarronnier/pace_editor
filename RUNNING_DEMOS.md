# Running PACE Editor Demos

## Build the Editor

```bash
crystal build src/pace_editor.cr -o pace_editor
```

## Run the Main Editor

```bash
./pace_editor
```

## Run Demo Modes

### 1. UI Visibility Test
Tests that all UI components are rendering correctly:

```bash
crystal build test_ui_visibility.cr -o test_ui_visibility
./test_ui_visibility
```

This shows:
- Menu bar at top
- Tool palette on left  
- Property panel on right
- Scene hierarchy bottom-left
- Main viewport in center
- Test overlay with instructions

### 2. Simple Demo
Basic editor demonstration:

```bash
crystal build demo_editor.cr -o demo_editor
./demo_editor
```

## Known Working Features

✅ **UI Rendering**
- All panels render in correct positions
- Tool palette shows tool buttons
- Menu bar displays at top
- Property panel on right side
- Scene editor viewport in center

✅ **Basic Interactions**
- Tool switching (keyboard shortcuts 1-6)
- Grid toggle (G key)
- Hotspot visibility toggle (H key)
- Camera panning (Space + drag)
- Zoom (mouse wheel)
- Window resizing
- Fullscreen toggle (F11)

✅ **Project Management**
- Create new projects
- Load existing projects
- Save projects
- Track scenes and assets

## Features In Progress

⚠️ **Scene Editing**
- Add Character button now creates characters
- Add Hotspot button creates hotspots
- Background loading needs asset picker
- Object selection and manipulation

⚠️ **Tool Actions**
- Many tool palette buttons show placeholder messages
- Animation editor not implemented
- Script editor not implemented
- Dialog editor not implemented

## Testing UI Visibility

To verify UI elements are visible:

1. Run the UI visibility test
2. Check that all panels are rendered
3. Press number keys to switch tools
4. Press G to toggle grid
5. Press H to toggle hotspot visibility
6. Observe the test overlay for feedback

## Troubleshooting

If nothing appears:
- Check that Raylib initialized correctly
- Verify window size is reasonable (1400x900)
- Check console for error messages

If UI is not interactive:
- Many buttons currently only print to console
- Check terminal output for action confirmations
- Some features are placeholders