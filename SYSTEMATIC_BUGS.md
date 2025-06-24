# Systematic Bugs in PACE Editor Codebase

This document lists systematic bugs and potential issues found in the PACE Editor codebase. These are patterns that could lead to bugs, memory leaks, or performance issues.

## 1. Resource Leak - Background Textures Never Unloaded

**Location:** `src/pace_editor/editors/scene_editor.cr` (lines 98-112)

**Issue:** When loading background textures for scenes, the code uses `RL.load_texture` but never calls `RL.unload_texture` on the old texture when:
- The scene changes
- A new background is loaded to replace the old one
- The editor is closed

```crystal
if File.exists?(full_path)
  begin
    texture = RL.load_texture(full_path)
    scene.background = texture  # Old texture (if any) is never freed
  rescue ex
    puts "Failed to load background texture: #{ex.message}"
  end
end
```

**Impact:** Memory leak that accumulates each time a scene is loaded or background is changed.

**Fix:** Store the old texture reference and call `RL.unload_texture` before assigning a new one.

## 2. Duplicate State Management - current_scene

**Location:** 
- `src/pace_editor/core/editor_state.cr` - property `current_scene` (Scene object)
- `src/pace_editor/core/project.cr` - property `current_scene` (String name)

**Issue:** Both `EditorState` and `Project` classes maintain their own version of the current scene, creating potential for state desynchronization.

**Impact:** The EditorState might be editing one scene while the Project thinks a different scene is current, leading to confusion and potential data loss.

**Fix:** Remove `current_scene` from Project class and only maintain it in EditorState. Use methods to query the current scene name when needed.

## 3. Unsafe nil Assertion Usage

**Location:** `src/pace_editor/core/editor_state.cr` (line 103)

**Issue:** Uses `.not_nil!` without proper nil checking:
```crystal
@current_project.not_nil!.add_scene("main.yml")
```

**Impact:** Application crash if `@current_project` is nil (e.g., if project creation fails).

**Fix:** Use proper nil checking pattern:
```crystal
if project = @current_project
  project.add_scene("main.yml")
end
```

## 4. Performance - Object Allocations in Draw Methods

**Location:** Multiple UI files create new objects in draw methods

**Issue:** Many UI components create new Color and Rectangle objects every frame:
```crystal
def draw
  RL.draw_rectangle(x, y, width, height, 
    RL::Color.new(r: 30, g: 30, b: 30, a: 255))  # New allocation every frame
end
```

**Impact:** Unnecessary garbage collection pressure from allocations happening 60+ times per second.

**Fix:** Cache commonly used colors and rectangles as constants or instance variables:
```crystal
BACKGROUND_COLOR = RL::Color.new(r: 30, g: 30, b: 30, a: 255)

def draw
  RL.draw_rectangle(x, y, width, height, BACKGROUND_COLOR)
end
```

## 5. Missing Viewport Updates on Window Resize

**Location:** `src/pace_editor/core/editor_window.cr` (line 489)

**Issue:** When the window is resized, only the scene_editor's viewport is updated:
```crystal
# Update scene editor with new viewport (only editor that supports viewport updates)
@scene_editor.update_viewport(@viewport_x, @viewport_y, @viewport_width, @viewport_height)
```

**Impact:** Other editors (character, hotspot, dialog) don't adapt to window resizing properly.

**Fix:** Implement viewport update methods for all editors or use a common base class.

## 6. Input Event Propagation Issues

**Location:** `src/pace_editor/core/editor_window.cr` (update method)

**Issue:** Input handling returns early when events are consumed, but some components might still check for the same events in their update methods, leading to duplicate or missed input handling.

**Impact:** Potential for input events to be handled multiple times or not at all in certain scenarios.

**Fix:** Implement a proper event system where components register for events rather than checking input state directly.

## 7. Path Construction Issues

**Location:** Multiple files use string concatenation for paths

**Issue:** Some places use string concatenation with "/" instead of `File.join`:
```crystal
"backgrounds/#{filename}"  # Works on Unix but not Windows
relative_path = "backgrounds/#{filename}"  # in background_import_dialog.cr
```

**Impact:** Path issues on Windows where backslashes are expected.

**Fix:** Always use `File.join` for path construction:
```crystal
File.join("backgrounds", filename)
```

## 8. Hardcoded Window Dimensions (FIXED)

**Status:** ✅ Fixed

**Issue:** UI components were using hardcoded window constants instead of actual screen dimensions, causing layout issues when windows were resized.

**Files Fixed:**
- menu_bar.cr
- tool_palette.cr
- asset_browser.cr
- scene_hierarchy.cr
- character_editor.cr
- hotspot_editor.cr
- dialog_editor.cr

## Additional Notes

### Good Practices Found:
- File operations in `scene_io.cr` properly use try/catch blocks
- TextureCache class properly manages resource cleanup
- Most file paths use `File.join` correctly

### Recommendations:
1. Implement a centralized resource manager for textures and other assets
2. Create a proper event system for input handling
3. Use dependency injection to avoid duplicate state
4. Profile the application to identify other performance bottlenecks
5. Add unit tests to catch these issues early