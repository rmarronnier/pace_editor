# Editor Integration TODO

Based on the working core functionality, here's what needs to be connected in the editor UI:

## ✅ Working Core Features
1. Project creation and management
2. Scene YAML serialization/deserialization  
3. Hotspot creation with properties
4. NPC creation and placement
5. Script file management
6. Dialog file management
7. Asset organization

## 🔧 Integration Tasks

### 1. Scene Editor
- [ ] Connect "New Scene" to actually create a Scene object
- [ ] Wire up background selector to set scene.background_path
- [ ] Make save button call SceneIO.save_scene()
- [ ] Load existing scenes into editor on project open

### 2. Hotspot Tool
- [ ] Connect hotspot placement tool to scene.hotspots array
- [ ] Wire property panel to modify hotspot properties:
  - name
  - description  
  - cursor_type
  - position/size
- [ ] Link "Edit Script" button to open script editor with hotspot script

### 3. Character/NPC Placement
- [ ] Connect character tool to scene.characters array
- [ ] Wire property panel for NPC properties:
  - name
  - position
  - dialogue array
  - mood
- [ ] Link to dialog editor for complex dialogues

### 4. Script Editor
- [ ] Auto-create script files for hotspots (e.g., "hotspot_name.lua")
- [ ] Load/save scripts to project scripts directory
- [ ] Provide templates for common actions:
  ```lua
  function on_click()
      -- Your code here
  end
  
  function on_look()
      show_message("Description")
  end
  
  function on_use()
      -- Item use logic
  end
  ```

### 5. Dialog Editor
- [ ] Save dialog trees to project dialogs directory as YAML
- [ ] Link NPCs to their dialog trees by name
- [ ] Provide visual node editor

### 6. Export Integration
- [ ] Create game_config.yaml from project settings
- [ ] Validate all assets exist
- [ ] Copy all required files to export directory
- [ ] Generate main.cr entry point

## Example Integration Code

```crystal
# In scene_editor.cr
def save_current_scene
  return unless @current_scene && @state.current_project
  
  scene_path = PaceEditor::IO::SceneIO.get_scene_file_path(
    @state.current_project.not_nil!, 
    @current_scene.not_nil!.name
  )
  
  PaceEditor::IO::SceneIO.save_scene(@current_scene.not_nil!, scene_path)
  puts "Scene saved!"
end

def add_hotspot(position : RL::Vector2, size : RL::Vector2)
  return unless @current_scene
  
  hotspot = PointClickEngine::Scenes::Hotspot.new(
    "hotspot_#{@current_scene.not_nil!.hotspots.size + 1}",
    position,
    size
  )
  
  @current_scene.not_nil!.hotspots << hotspot
  @state.selected_object = hotspot.name
  
  # Create default script
  create_hotspot_script(hotspot.name)
end

def create_hotspot_script(hotspot_name : String)
  return unless @state.current_project
  
  script_content = <<-LUA
  -- Script for #{hotspot_name}
  
  function on_click()
      show_message("You clicked #{hotspot_name}")
  end
  
  function on_look()
      show_message("You examine #{hotspot_name}")
  end
  LUA
  
  script_path = File.join(
    @state.current_project.not_nil!.scripts_path,
    "#{hotspot_name}.lua"
  )
  
  File.write(script_path, script_content)
end
```

## Testing Integration

Create integration tests that simulate the full editor workflow:

```crystal
it "creates game through editor actions" do
  state = PaceEditor::Core::EditorState.new
  project = PaceEditor::Core::Project.new("Test", temp_dir)
  state.current_project = project
  
  # Simulate editor actions
  scene_editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)
  
  # Create new scene
  scene_editor.create_new_scene("main_room")
  scene_editor.set_background("backgrounds/room.png")
  
  # Add hotspot
  scene_editor.select_tool(EditorTool::Hotspot)
  scene_editor.place_hotspot(RL::Vector2.new(100, 100), RL::Vector2.new(50, 50))
  
  # Save
  scene_editor.save_current_scene
  
  # Verify
  scene_file = File.join(project.scenes_path, "main_room.yml")
  File.exists?(scene_file).should be_true
end
```

## Priority Order

1. **Scene Save/Load** - Get basic scene editing working
2. **Hotspot Placement** - Core interaction system
3. **Script Integration** - Make hotspots functional
4. **NPC/Dialog** - Add characters and conversations
5. **Export** - Package complete games

The core engine is solid. Focus on wiring up the UI to use it properly.