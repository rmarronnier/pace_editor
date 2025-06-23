# Editors API Reference

The Editors API provides specialized editing interfaces for different aspects of game creation including scenes, characters, hotspots, dialogs, quests, items, and cutscenes.

## Module: PaceEditor::Editors

### Class: SceneEditor

The Scene Editor handles the main scene editing functionality, allowing users to place objects, manage backgrounds, and arrange scene elements.

#### Properties

```crystal
property state : EditorState              # Reference to editor state
property viewport_x : Int32               # Viewport X position
property viewport_y : Int32               # Viewport Y position
property viewport_width : Int32           # Viewport width
property viewport_height : Int32          # Viewport height
property background_texture : Texture2D? # Loaded background texture
property scene_objects : Array(SceneObject) # Objects in current scene
```

#### Instance Methods

##### `initialize(state : EditorState, x : Int32, y : Int32, width : Int32, height : Int32)`

Creates a new scene editor with the specified viewport dimensions.

**Parameters:**
- `state` - Reference to the main editor state
- `x, y` - Viewport position
- `width, height` - Viewport dimensions

##### `update`

Updates the scene editor, handling input and object manipulation.

##### `draw`

Renders the current scene including background, objects, and editor overlays.

##### `load_scene(scene_path : String)`

Loads a scene file for editing.

**Parameters:**
- `scene_path` - Path to the scene YAML file

##### `save_scene`

Saves the current scene to its file.

##### `add_object(object_type : String, position : Vector2)`

Adds a new object to the scene.

**Parameters:**
- `object_type` - Type of object to create
- `position` - World position for the object

##### `delete_selected_objects`

Removes all currently selected objects from the scene.

##### `duplicate_selected_objects`

Creates copies of all selected objects.

##### `world_to_screen(world_pos : Vector2) : Vector2`

Converts world coordinates to screen coordinates.

**Parameters:**
- `world_pos` - Position in world space

**Returns:** Position in screen space

##### `screen_to_world(screen_pos : Vector2) : Vector2`

Converts screen coordinates to world coordinates.

**Parameters:**
- `screen_pos` - Position in screen space

**Returns:** Position in world space

---

### Class: CharacterEditor

Handles character creation, sprite management, and animation editing.

#### Properties

```crystal
property state : EditorState              # Reference to editor state
property current_character : Character?   # Currently editing character
property sprite_frames : Array(Texture2D) # Character sprite frames
property animation_timeline : Array(Frame) # Animation sequence
property preview_playing : Bool           # Animation preview state
```

#### Instance Methods

##### `initialize(state : EditorState)`

Creates a new character editor.

##### `update`

Updates character editor input and animation preview.

##### `draw`

Renders character editing interface and preview.

##### `load_character(character_path : String)`

Loads a character definition for editing.

**Parameters:**
- `character_path` - Path to character file

##### `save_character`

Saves current character to file.

##### `import_sprite_sheet(image_path : String, frame_width : Int32, frame_height : Int32)`

Imports a sprite sheet and splits it into frames.

**Parameters:**
- `image_path` - Path to sprite sheet image
- `frame_width` - Width of each frame
- `frame_height` - Height of each frame

##### `add_animation(name : String, frame_indices : Array(Int32), duration : Float32)`

Creates a new animation sequence.

**Parameters:**
- `name` - Animation name
- `frame_indices` - Array of frame indices to use
- `duration` - Animation duration in seconds

##### `play_animation_preview(animation_name : String)`

Starts playing an animation in the preview.

**Parameters:**
- `animation_name` - Name of animation to preview

##### `stop_animation_preview`

Stops the current animation preview.

---

### Class: HotspotEditor

Manages interactive hotspot creation and editing.

#### Properties

```crystal
property state : EditorState              # Reference to editor state
property current_hotspot : Hotspot?       # Currently editing hotspot
property hotspot_list : Array(Hotspot)    # All hotspots in scene
property show_hotspot_outlines : Bool     # Outline visibility
property hotspot_opacity : Float32        # Overlay opacity
```

#### Instance Methods

##### `initialize(state : EditorState)`

Creates a new hotspot editor.

##### `update`

Updates hotspot editor with input handling and selection.

##### `draw`

Renders hotspots and editing interface.

##### `create_hotspot(bounds : Rectangle, interaction_type : String)`

Creates a new hotspot with specified bounds and type.

**Parameters:**
- `bounds` - Rectangular area of the hotspot
- `interaction_type` - Type of interaction ("examine", "use", "talk", etc.)

##### `delete_hotspot(hotspot_id : String)`

Removes a hotspot from the scene.

**Parameters:**
- `hotspot_id` - ID of hotspot to delete

##### `get_hotspot_at_position(position : Vector2) : Hotspot?`

Returns the hotspot at the specified position, if any.

**Parameters:**
- `position` - World position to check

**Returns:** Hotspot at position or nil

##### `resize_hotspot(hotspot : Hotspot, new_bounds : Rectangle)`

Changes the bounds of an existing hotspot.

**Parameters:**
- `hotspot` - Hotspot to resize
- `new_bounds` - New rectangular bounds

##### `set_hotspot_action(hotspot : Hotspot, action : String)`

Sets the action script for a hotspot.

**Parameters:**
- `hotspot` - Target hotspot
- `action` - Action script or message

##### `test_hotspot_interaction(hotspot : Hotspot)`

Tests a hotspot's interaction in preview mode.

**Parameters:**
- `hotspot` - Hotspot to test

---

### Class: DialogEditor

Visual dialog tree editor for creating conversations and branching narratives.

#### Properties

```crystal
property state : EditorState              # Reference to editor state
property current_dialog_tree : DialogTree? # Currently editing dialog
property dialog_nodes : Array(DialogNode) # All nodes in current tree
property selected_node : DialogNode?      # Currently selected node
property connection_mode : Bool           # Whether connecting nodes
property node_positions : Hash(String, Vector2) # Node layout positions
```

#### Instance Methods

##### `initialize(state : EditorState)`

Creates a new dialog editor.

##### `update`

Updates dialog editor with node manipulation and connection handling.

##### `draw`

Renders dialog tree visualization and editing interface.

##### `create_dialog_tree(name : String)`

Creates a new empty dialog tree.

**Parameters:**
- `name` - Name for the new dialog tree

##### `load_dialog_tree(tree_path : String)`

Loads an existing dialog tree for editing.

**Parameters:**
- `tree_path` - Path to dialog tree file

##### `save_dialog_tree`

Saves current dialog tree to file.

##### `add_dialog_node(text : String, speaker : String, position : Vector2) : DialogNode`

Adds a new dialog node to the tree.

**Parameters:**
- `text` - Dialog text content
- `speaker` - Character speaking the line
- `position` - Position in editor view

**Returns:** The created dialog node

##### `delete_dialog_node(node : DialogNode)`

Removes a dialog node and all its connections.

**Parameters:**
- `node` - Node to delete

##### `connect_nodes(from_node : DialogNode, to_node : DialogNode, choice_text : String?)`

Creates a connection between two dialog nodes.

**Parameters:**
- `from_node` - Source node
- `to_node` - Destination node
- `choice_text` - Text for choice option (nil for automatic progression)

##### `disconnect_nodes(from_node : DialogNode, to_node : DialogNode)`

Removes a connection between nodes.

**Parameters:**
- `from_node` - Source node
- `to_node` - Destination node

##### `set_node_position(node : DialogNode, position : Vector2)`

Updates a node's position in the editor.

**Parameters:**
- `node` - Node to move
- `position` - New position

##### `auto_layout_nodes`

Automatically arranges all nodes in a readable layout.

##### `preview_dialog_tree`

Runs the dialog tree in preview mode for testing.

---

### Class: QuestEditor

The Quest Editor provides a visual interface for creating and managing game quests with objectives, prerequisites, and rewards.

#### Properties

```crystal
property state : EditorState              # Reference to editor state
property quest_list : Array(Quest)        # All quests in the project
property selected_quest : Quest?          # Currently selected quest
property selected_objective : QuestObjective? # Currently selected objective
```

#### Instance Methods

##### `initialize(state : EditorState)`

Creates a new quest editor.

##### `update`

Updates the quest editor, handling quest and objective management.

##### `draw`

Renders the quest editor interface with quest hierarchy and properties.

##### `create_quest(name : String, category : String = "main") : Quest`

Creates a new quest.

**Parameters:**
- `name` - Quest display name
- `category` - Quest category (main, side, or hidden)

**Returns:** The created quest

##### `add_objective(quest : Quest, description : String) : QuestObjective`

Adds an objective to a quest.

**Parameters:**
- `quest` - Parent quest
- `description` - Objective description

**Returns:** The created objective

##### `set_objective_condition(objective : QuestObjective, condition : Condition)`

Sets the completion condition for an objective.

**Parameters:**
- `objective` - Target objective
- `condition` - Completion condition

##### `add_reward(quest : Quest, reward : Reward)`

Adds a reward to a quest.

**Parameters:**
- `quest` - Target quest
- `reward` - Reward to add

---

### Class: ItemEditor

The Item Editor manages inventory items with properties, states, and interactions.

#### Properties

```crystal
property state : EditorState              # Reference to editor state
property items : Hash(String, Item)       # All items in the project
property selected_item : Item?            # Currently selected item
```

#### Instance Methods

##### `initialize(state : EditorState)`

Creates a new item editor.

##### `update`

Updates the item editor with item property management.

##### `draw`

Renders the item editor interface.

##### `create_item(name : String, display_name : String) : Item`

Creates a new inventory item.

**Parameters:**
- `name` - Internal item ID
- `display_name` - Display name

**Returns:** The created item

##### `set_item_icon(item : Item, icon_path : String)`

Sets the icon for an item.

**Parameters:**
- `item` - Target item
- `icon_path` - Path to icon image

##### `add_item_state(item : Item, state_name : String, icon_path : String?)`

Adds a state to an item.

**Parameters:**
- `item` - Target item
- `state_name` - State name
- `icon_path` - Optional icon for this state

##### `create_item_combination(item1 : Item, item2 : Item, result : Item)`

Creates an item combination rule.

**Parameters:**
- `item1` - First item
- `item2` - Second item
- `result` - Resulting item

---

### Class: CutsceneEditor

The Cutscene Editor provides timeline-based editing for creating cinematic sequences.

#### Properties

```crystal
property state : EditorState              # Reference to editor state
property cutscenes : Array(Cutscene)      # All cutscenes in the project
property current_cutscene : Cutscene?     # Currently edited cutscene
property timeline_position : Float32      # Current position in timeline
property playing : Bool                   # Whether preview is playing
```

#### Instance Methods

##### `initialize(state : EditorState)`

Creates a new cutscene editor.

##### `update`

Updates the cutscene editor with timeline manipulation.

##### `draw`

Renders the cutscene editor with timeline interface.

##### `create_cutscene(name : String) : Cutscene`

Creates a new cutscene.

**Parameters:**
- `name` - Cutscene name

**Returns:** The created cutscene

##### `add_action(cutscene : Cutscene, action : CutsceneAction, time : Float32)`

Adds an action to the cutscene timeline.

**Parameters:**
- `cutscene` - Target cutscene
- `action` - Action to add
- `time` - Time in seconds

##### `play_preview`

Starts cutscene preview playback.

##### `stop_preview`

Stops cutscene preview.

##### `seek_to(time : Float32)`

Seeks to a specific time in the timeline.

**Parameters:**
- `time` - Time in seconds

---

## Supporting Classes

### SceneObject

Represents an object placed in a scene.

```crystal
class SceneObject
  property id : String                    # Unique object ID
  property name : String                  # Display name
  property texture_path : String          # Path to object texture
  property position : Vector2             # World position
  property scale : Vector2                # Object scale
  property rotation : Float32             # Rotation in degrees
  property layer : Int32                  # Rendering layer
  property visible : Bool                 # Visibility flag
  property interactive : Bool             # Whether object responds to clicks
end
```

### Character

Represents a game character with sprites and animations.

```crystal
class Character
  property name : String                  # Character name
  property sprite_path : String           # Path to sprite sheet
  property frame_width : Int32            # Width of sprite frames
  property frame_height : Int32           # Height of sprite frames
  property animations : Hash(String, Animation) # Character animations
  property default_animation : String     # Default animation name
  property scale : Float32                # Character scale
end
```

### Hotspot

Represents an interactive area in a scene.

```crystal
class Hotspot
  property id : String                    # Unique hotspot ID
  property name : String                  # Display name
  property bounds : Rectangle             # Interactive area
  property interaction_type : String      # Type of interaction
  property action : String                # Action script or message
  property condition : String?            # Optional condition script
  property enabled : Bool                 # Whether hotspot is active
  property visible_in_editor : Bool       # Editor visibility
end
```

### DialogNode

Represents a single node in a dialog tree.

```crystal
class DialogNode
  property id : String                    # Unique node ID
  property text : String                  # Dialog text
  property speaker : String               # Character speaking
  property choices : Array(DialogChoice)  # Available choices
  property conditions : Array(String)     # Conditions to show node
  property actions : Array(String)        # Actions to execute
  property is_root : Bool                 # Whether this is starting node
end
```

### DialogChoice

Represents a choice option in a dialog node.

```crystal
class DialogChoice
  property text : String                  # Choice text
  property target_node_id : String        # ID of node to jump to
  property condition : String?            # Optional condition
  property action : String?               # Optional action to execute
end
```

### Quest

Represents a game quest with objectives and rewards.

```crystal
class Quest
  property id : String                    # Unique quest ID
  property name : String                  # Display name
  property description : String           # Quest description
  property category : String              # Quest category (main/side/hidden)
  property objectives : Array(QuestObjective) # Quest objectives
  property rewards : Array(Reward)        # Quest rewards
  property prerequisites : Array(String)  # Required quest IDs
  property auto_start : Bool              # Whether quest starts automatically
end
```

### QuestObjective

Represents a single objective within a quest.

```crystal
class QuestObjective
  property id : String                    # Unique objective ID
  property description : String           # Objective description
  property completion_conditions : Condition # Conditions to complete
  property optional : Bool                # Whether objective is optional
  property hidden : Bool                  # Whether objective is hidden initially
end
```

### Item

Represents an inventory item.

```crystal
class Item
  property name : String                  # Internal item ID
  property display_name : String          # Display name
  property description : String           # Item description
  property icon_path : String             # Path to item icon
  property states : Hash(String, ItemState) # Item states
  property current_state : String         # Current state name
  property stackable : Bool               # Whether item can stack
  property max_stack : Int32              # Maximum stack size
  property quest_item : Bool              # Whether item is quest item
  property consumable : Bool              # Whether item is consumable
  property combinable_with : Array(String) # Items this can combine with
end
```

### Cutscene

Represents a cinematic sequence.

```crystal
class Cutscene
  property id : String                    # Unique cutscene ID
  property name : String                  # Cutscene name
  property actions : Array(CutsceneAction) # Timeline actions
  property duration : Float32             # Total duration in seconds
  property skippable : Bool               # Whether player can skip
  property trigger_condition : Condition? # Optional trigger condition
end
```

### CutsceneAction

Represents an action in a cutscene timeline.

```crystal
class CutsceneAction
  property type : String                  # Action type
  property time : Float32                 # Time in seconds
  property duration : Float32             # Duration for timed actions
  property target : String?               # Target object/character
  property parameters : Hash(String, String) # Action parameters
end
```

## Usage Examples

### Scene Editing

```crystal
# Create scene editor
scene_editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)

# Load a scene
scene_editor.load_scene("scenes/forest.yml")

# Add an object at mouse position
mouse_pos = RL.get_mouse_position
world_pos = scene_editor.screen_to_world(mouse_pos)
scene_editor.add_object("tree", world_pos)

# Save the scene
scene_editor.save_scene
```

### Character Animation

```crystal
# Create character editor
char_editor = PaceEditor::Editors::CharacterEditor.new(state)

# Import sprite sheet
char_editor.import_sprite_sheet("hero_sprites.png", 32, 48)

# Create walking animation
char_editor.add_animation("walk_right", [0, 1, 2, 1], 0.8)

# Preview the animation
char_editor.play_animation_preview("walk_right")
```

### Hotspot Creation

```crystal
# Create hotspot editor
hotspot_editor = PaceEditor::Editors::HotspotEditor.new(state)

# Create examination hotspot
door_bounds = RL::Rectangle.new(x: 200, y: 100, width: 80, height: 120)
hotspot_editor.create_hotspot(door_bounds, "examine")

# Set hotspot action
door_hotspot = hotspot_editor.get_hotspot_at_position(Vector2.new(240, 160))
if door_hotspot
  hotspot_editor.set_hotspot_action(door_hotspot, "The door is locked.")
end
```

### Dialog Tree Creation

```crystal
# Create dialog editor
dialog_editor = PaceEditor::Editors::DialogEditor.new(state)

# Create new dialog tree
dialog_editor.create_dialog_tree("merchant_conversation")

# Add dialog nodes
greeting = dialog_editor.add_dialog_node("Hello there, traveler!", "Merchant", Vector2.new(100, 100))
response1 = dialog_editor.add_dialog_node("I'd like to buy something.", "Player", Vector2.new(300, 50))
response2 = dialog_editor.add_dialog_node("Just looking around.", "Player", Vector2.new(300, 150))

# Connect nodes
dialog_editor.connect_nodes(greeting, response1, "Buy something")
dialog_editor.connect_nodes(greeting, response2, "Just browsing")

# Save dialog tree
dialog_editor.save_dialog_tree
```

### Quest Creation

```crystal
# Create quest editor
quest_editor = PaceEditor::Editors::QuestEditor.new(state)

# Create a main quest
main_quest = quest_editor.create_quest("Find the Lost Artifact", "main")

# Add objectives
obj1 = quest_editor.add_objective(main_quest, "Talk to the village elder")
obj2 = quest_editor.add_objective(main_quest, "Search the ancient ruins")
obj3 = quest_editor.add_objective(main_quest, "Retrieve the artifact")

# Set completion conditions
quest_editor.set_objective_condition(obj1, Condition.new(
  type: "flag",
  name: "talked_to_elder",
  value: true
))

# Add rewards
quest_editor.add_reward(main_quest, Reward.new(
  type: "item",
  name: "ancient_key"
))
```

### Item Management

```crystal
# Create item editor
item_editor = PaceEditor::Editors::ItemEditor.new(state)

# Create inventory items
key = item_editor.create_item("ancient_key", "Ancient Key")
item_editor.set_item_icon(key, "assets/items/key_ancient.png")

# Create combinable items
rope = item_editor.create_item("rope", "Sturdy Rope")
hook = item_editor.create_item("hook", "Metal Hook")
grappling_hook = item_editor.create_item("grappling_hook", "Grappling Hook")

# Set up item combination
item_editor.create_item_combination(rope, hook, grappling_hook)
```

### Cutscene Creation

```crystal
# Create cutscene editor
cutscene_editor = PaceEditor::Editors::CutsceneEditor.new(state)

# Create opening cutscene
opening = cutscene_editor.create_cutscene("intro_cutscene")

# Add camera pan
pan_action = CutsceneAction.new(
  type: "camera_pan",
  time: 0.0,
  duration: 3.0,
  parameters: {"from_x" => "0", "from_y" => "0", "to_x" => "500", "to_y" => "300"}
)
cutscene_editor.add_action(opening, pan_action, 0.0)

# Add character entrance
enter_action = CutsceneAction.new(
  type: "character_move",
  time: 2.0,
  duration: 2.0,
  target: "hero",
  parameters: {"from_x" => "-100", "to_x" => "400", "y" => "400"}
)
cutscene_editor.add_action(opening, enter_action, 2.0)

# Add dialog
dialog_action = CutsceneAction.new(
  type: "show_dialog",
  time: 4.0,
  duration: 3.0,
  parameters: {"text" => "At last, I've found the ancient temple...", "speaker" => "Hero"}
)
cutscene_editor.add_action(opening, dialog_action, 4.0)

# Preview the cutscene
cutscene_editor.play_preview
```

## Editor Integration

All editors work together through the shared `EditorState`:

```crystal
# Switch between editors based on mode
case state.current_mode
when .scene?
  scene_editor.update
  scene_editor.draw
when .character?
  character_editor.update
  character_editor.draw
when .hotspot?
  hotspot_editor.update
  hotspot_editor.draw
when .dialog?
  dialog_editor.update
  dialog_editor.draw
when .quest?
  quest_editor.update
  quest_editor.draw
when .item?
  item_editor.update
  item_editor.draw
when .cutscene?
  cutscene_editor.update
  cutscene_editor.draw
end
```

The editors automatically sync with the current project and maintain consistency across mode switches.

## Validation Integration

All editors support validation for export compatibility:

```crystal
# Validate before saving
if quest_editor.validate_quest(quest).valid?
  quest_editor.save_quest(quest)
else
  # Show validation errors to user
end

# Validate entire project
validator = PaceEditor::Validation::ProjectValidator.new(state.current_project)
result = validator.validate_for_export(game_config)

if result.has_errors?
  # Display errors in UI
  result.errors.each do |error|
    puts "Error: #{error.message} at #{error.path}"
  end
end
```