# UI Components API Reference

The UI API provides the interface components that make up PACE's editor interface, including menus, panels, and interactive widgets.

## Module: PaceEditor::UI

### Class: MenuBar

The main application menu bar providing access to file operations, tools, and settings.

#### Properties

```crystal
property state : EditorState              # Reference to editor state
property file_menu : Menu                 # File operations menu
property edit_menu : Menu                 # Edit operations menu
property view_menu : Menu                 # View options menu
property tools_menu : Menu                # Tool selection menu
property mode_menu : Menu                 # Editor mode menu
property help_menu : Menu                 # Help and documentation
```

#### Instance Methods

##### `initialize(state : EditorState)`

Creates a new menu bar with all default menus.

##### `update`

Updates menu state and handles input.

##### `draw`

Renders the menu bar at the top of the window.

##### `show_new_project_dialog`

Opens the new project creation dialog.

##### `show_open_project_dialog`

Opens the project file selection dialog.

##### `show_save_dialog`

Opens the save confirmation dialog if needed.

##### `show_preferences_dialog`

Opens the application preferences window.

---

### Class: ToolPalette

The tool selection palette on the left side of the interface.

#### Properties

```crystal
property state : EditorState              # Reference to editor state
property tools : Array(ToolButton)        # Available tool buttons
property selected_tool : Tool             # Currently selected tool
property tool_size : Int32                # Size of tool buttons
property palette_width : Int32            # Total palette width
```

#### Instance Methods

##### `initialize(state : EditorState)`

Creates the tool palette with default tools.

##### `update`

Handles tool selection and input.

##### `draw`

Renders the tool palette.

##### `add_custom_tool(tool : CustomTool)`

Adds a custom tool to the palette.

**Parameters:**
- `tool` - Custom tool implementation

##### `remove_tool(tool_type : Tool)`

Removes a tool from the palette.

**Parameters:**
- `tool_type` - Type of tool to remove

##### `set_tool_enabled(tool_type : Tool, enabled : Bool)`

Enables or disables a specific tool.

**Parameters:**
- `tool_type` - Tool to modify
- `enabled` - Whether tool should be enabled

---

### Class: PropertyPanel

The property editing panel on the right side showing object and scene properties.

#### Properties

```crystal
property state : EditorState              # Reference to editor state
property current_object : GameObject?     # Currently selected object
property property_groups : Array(PropertyGroup) # Organized property sections
property scroll_offset : Int32            # Panel scroll position
property panel_width : Int32              # Panel width in pixels
```

#### Instance Methods

##### `initialize(state : EditorState)`

Creates the property panel.

##### `update`

Updates property values and handles input.

##### `draw`

Renders the property panel and all property controls.

##### `refresh_properties`

Reloads properties for the currently selected object.

##### `add_property_group(group : PropertyGroup)`

Adds a new property group to the panel.

**Parameters:**
- `group` - Property group to add

##### `set_property_value(property_name : String, value : PropertyValue)`

Sets a property value programmatically.

**Parameters:**
- `property_name` - Name of the property
- `value` - New value to set

##### `get_property_value(property_name : String) : PropertyValue?`

Gets the current value of a property.

**Parameters:**
- `property_name` - Name of the property

**Returns:** Current property value or nil

---

### Class: SceneHierarchy

The scene hierarchy tree view showing all objects in the current scene.

#### Properties

```crystal
property state : EditorState              # Reference to editor state
property scene_tree : TreeView            # Scene object tree
property selected_nodes : Array(TreeNode) # Currently selected nodes
property expanded_nodes : Set(String)     # Expanded node IDs
property hierarchy_width : Int32          # Panel width
```

#### Instance Methods

##### `initialize(state : EditorState)`

Creates the scene hierarchy panel.

##### `update`

Updates the hierarchy display and handles selection.

##### `draw`

Renders the scene hierarchy tree.

##### `refresh_hierarchy`

Rebuilds the scene tree from current scene data.

##### `select_object(object_id : String)`

Selects an object in the hierarchy.

**Parameters:**
- `object_id` - ID of object to select

##### `expand_node(node_id : String)`

Expands a hierarchy node to show children.

**Parameters:**
- `node_id` - ID of node to expand

##### `collapse_node(node_id : String)`

Collapses a hierarchy node to hide children.

**Parameters:**
- `node_id` - ID of node to collapse

##### `add_object_to_hierarchy(object : GameObject, parent_id : String?)`

Adds a new object to the hierarchy.

**Parameters:**
- `object` - Object to add
- `parent_id` - ID of parent object (nil for root level)

---

### Class: AssetBrowser

The asset management browser for importing and organizing project assets.

#### Properties

```crystal
property state : EditorState              # Reference to editor state
property current_category : String        # Currently selected category
property asset_grid : GridView            # Asset thumbnail grid
property category_list : ListView         # Asset category list
property search_filter : String           # Current search filter
property browser_width : Int32            # Browser panel width
```

#### Instance Methods

##### `initialize(state : EditorState)`

Creates the asset browser.

##### `update`

Updates the browser display and handles asset selection.

##### `draw`

Renders the asset browser interface.

##### `refresh_assets`

Reloads the asset list from the project.

##### `import_assets(file_paths : Array(String))`

Imports new assets into the project.

**Parameters:**
- `file_paths` - Array of file paths to import

##### `delete_asset(asset_path : String)`

Removes an asset from the project.

**Parameters:**
- `asset_path` - Path to asset to delete

##### `set_category_filter(category : String)`

Filters assets by category.

**Parameters:**
- `category` - Category to filter by ("all" for no filter)

##### `set_search_filter(filter : String)`

Applies a text search filter to assets.

**Parameters:**
- `filter` - Search text

##### `get_selected_assets : Array(Asset)`

Returns currently selected assets.

**Returns:** Array of selected asset objects

---

## Supporting Classes

### ToolButton

Represents a single tool button in the tool palette.

```crystal
class ToolButton
  property tool_type : Tool                # Type of tool this button represents
  property icon : Texture2D               # Tool icon texture
  property tooltip : String               # Tooltip text
  property bounds : Rectangle             # Button bounds
  property enabled : Bool                 # Whether button is enabled
  property pressed : Bool                 # Current press state
  
  def initialize(@tool_type : Tool, @icon : Texture2D, @tooltip : String)
  end
  
  def update(mouse_pos : Vector2, mouse_pressed : Bool)
    # Update button state based on mouse input
  end
  
  def draw
    # Render the tool button
  end
end
```

### PropertyGroup

Organizes related properties in the property panel.

```crystal
class PropertyGroup
  property name : String                  # Group display name
  property properties : Array(Property)   # Properties in this group
  property expanded : Bool                # Whether group is expanded
  property bounds : Rectangle             # Group bounds in panel
  
  def initialize(@name : String)
    @properties = [] of Property
    @expanded = true
  end
  
  def add_property(property : Property)
    @properties << property
  end
  
  def draw(y_offset : Int32) : Int32
    # Draw the property group and return new Y offset
  end
end
```

### Property

Represents a single editable property.

```crystal
abstract class Property
  property name : String                  # Property display name
  property value : PropertyValue          # Current value
  property bounds : Rectangle             # Control bounds
  property enabled : Bool                 # Whether property is editable
  
  def initialize(@name : String, @value : PropertyValue)
    @enabled = true
  end
  
  abstract def draw(x : Int32, y : Int32) : Int32
  abstract def handle_input(mouse_pos : Vector2, mouse_pressed : Bool)
end

# Concrete property types
class StringProperty < Property
  def draw(x : Int32, y : Int32) : Int32
    # Draw text input field
  end
end

class NumberProperty < Property
  property min_value : Float32?
  property max_value : Float32?
  
  def draw(x : Int32, y : Int32) : Int32
    # Draw number input with optional slider
  end
end

class BooleanProperty < Property
  def draw(x : Int32, y : Int32) : Int32
    # Draw checkbox
  end
end

class EnumProperty < Property
  property options : Array(String)
  
  def draw(x : Int32, y : Int32) : Int32
    # Draw dropdown selection
  end
end
```

### TreeNode

Represents a node in the scene hierarchy tree.

```crystal
class TreeNode
  property id : String                    # Unique node identifier
  property name : String                  # Display name
  property object_type : String           # Type of object this represents
  property children : Array(TreeNode)     # Child nodes
  property parent : TreeNode?             # Parent node
  property expanded : Bool                # Whether children are visible
  property selected : Bool                # Whether node is selected
  property bounds : Rectangle             # Node bounds in tree
  
  def initialize(@id : String, @name : String, @object_type : String)
    @children = [] of TreeNode
    @expanded = false
    @selected = false
  end
  
  def add_child(child : TreeNode)
    child.parent = self
    @children << child
  end
  
  def remove_child(child : TreeNode)
    child.parent = nil
    @children.delete(child)
  end
  
  def draw(x : Int32, y : Int32, indent : Int32) : Int32
    # Draw the tree node and return new Y position
  end
end
```

### GridView

Grid-based view for displaying assets with thumbnails.

```crystal
class GridView
  property items : Array(GridItem)        # Items to display
  property cell_size : Int32              # Size of each grid cell
  property columns : Int32                # Number of columns
  property scroll_offset : Vector2        # Current scroll position
  property selected_items : Array(GridItem) # Currently selected items
  
  def initialize(@cell_size : Int32)
    @items = [] of GridItem
    @selected_items = [] of GridItem
  end
  
  def add_item(item : GridItem)
    @items << item
  end
  
  def clear_items
    @items.clear
    @selected_items.clear
  end
  
  def update(mouse_pos : Vector2, mouse_pressed : Bool)
    # Handle grid interaction
  end
  
  def draw(bounds : Rectangle)
    # Render the grid view
  end
end
```

### GridItem

Represents a single item in a grid view.

```crystal
class GridItem
  property id : String                    # Unique item identifier
  property name : String                  # Display name
  property thumbnail : Texture2D?         # Item thumbnail
  property data : String                  # Associated data/path
  property selected : Bool                # Selection state
  
  def initialize(@id : String, @name : String, @data : String)
    @selected = false
  end
  
  def draw(bounds : Rectangle)
    # Draw the grid item
  end
end
```

## Dialog Systems

### Dialog

Base class for modal dialogs.

```crystal
abstract class Dialog
  property title : String                 # Dialog title
  property bounds : Rectangle             # Dialog bounds
  property modal : Bool                   # Whether dialog is modal
  property visible : Bool                 # Whether dialog is shown
  property result : DialogResult          # Dialog result when closed
  
  def initialize(@title : String, width : Int32, height : Int32)
    @modal = true
    @visible = false
    @result = DialogResult::None
    center_on_screen(width, height)
  end
  
  abstract def update
  abstract def draw
  abstract def on_ok
  abstract def on_cancel
  
  def show
    @visible = true
  end
  
  def close(result : DialogResult)
    @visible = false
    @result = result
  end
end
```

### NewProjectDialog

Dialog for creating new projects.

```crystal
class NewProjectDialog < Dialog
  property project_name : String          # Project name input
  property project_path : String          # Project location
  property template_type : String         # Selected template
  
  def initialize
    super("New Project", 500, 400)
    @project_name = ""
    @project_path = ""
    @template_type = "blank"
  end
  
  def on_ok
    if validate_inputs
      create_project(@project_name, @project_path, @template_type)
      close(DialogResult::OK)
    end
  end
end
```

### FileDialog

File selection dialog.

```crystal
class FileDialog < Dialog
  property current_path : String          # Current directory
  property selected_file : String         # Selected file
  property file_filter : String           # File extension filter
  property files : Array(String)          # Files in current directory
  
  def initialize(title : String, filter : String)
    super(title, 600, 400)
    @file_filter = filter
    @current_path = Dir.current
    refresh_files
  end
  
  def refresh_files
    # Populate files array with filtered directory contents
  end
end
```

### ExportDialog

Dialog for exporting games with validation feedback.

```crystal
class ExportDialog < Dialog
  property export_path : String           # Export destination
  property export_format : String         # Export format (folder/zip)
  property validation_result : ValidationResult? # Validation results
  property include_source : Bool          # Include source files option
  
  def initialize
    super("Export Game", 700, 500)
    @export_path = ""
    @export_format = "folder"
    @include_source = false
  end
  
  def validate_project
    # Run project validation and display results
  end
  
  def show_validation_errors(result : ValidationResult)
    # Display errors and warnings in scrollable list
  end
  
  def on_ok
    if @validation_result && @validation_result.valid?
      perform_export(@export_path, @export_format)
      close(DialogResult::OK)
    end
  end
end
```

### ValidationResultPanel

Panel for displaying validation errors and warnings.

```crystal
class ValidationResultPanel
  property result : ValidationResult      # Validation result to display
  property bounds : Rectangle             # Panel bounds
  property scroll_offset : Int32          # Scroll position
  property selected_error : ValidationError? # Selected error
  
  def initialize(@bounds : Rectangle)
    @scroll_offset = 0
  end
  
  def set_result(result : ValidationResult)
    @result = result
    @scroll_offset = 0
  end
  
  def draw
    # Draw errors and warnings with icons and descriptions
  end
  
  def handle_click(position : Vector2)
    # Handle clicking on errors to navigate to source
  end
end
```

## Usage Examples

### Creating a Custom Property Panel

```crystal
# Create property panel
property_panel = PaceEditor::UI::PropertyPanel.new(editor_state)

# Add custom property group
transform_group = PropertyGroup.new("Transform")
transform_group.add_property(NumberProperty.new("X Position", 0.0))
transform_group.add_property(NumberProperty.new("Y Position", 0.0))
transform_group.add_property(NumberProperty.new("Rotation", 0.0))

property_panel.add_property_group(transform_group)
```

### Customizing the Tool Palette

```crystal
# Create tool palette
tool_palette = PaceEditor::UI::ToolPalette.new(editor_state)

# Add custom tool
custom_tool = CustomTool.new("brush", brush_icon, "Paint Tool")
tool_palette.add_custom_tool(custom_tool)

# Disable default tool
tool_palette.set_tool_enabled(Tool::Paint, false)
```

### Working with Asset Browser

```crystal
# Create asset browser
asset_browser = PaceEditor::UI::AssetBrowser.new(editor_state)

# Import new assets
asset_paths = ["sprites/hero.png", "sounds/footstep.wav"]
asset_browser.import_assets(asset_paths)

# Filter by category
asset_browser.set_category_filter("sprites")

# Search for specific assets
asset_browser.set_search_filter("hero")
```

### Scene Hierarchy Operations

```crystal
# Create scene hierarchy
hierarchy = PaceEditor::UI::SceneHierarchy.new(editor_state)

# Add objects to hierarchy
hero_object = GameObject.new("hero", "Character")
hierarchy.add_object_to_hierarchy(hero_object, nil)

tree_object = GameObject.new("tree_01", "Environment")
hierarchy.add_object_to_hierarchy(tree_object, nil)

# Select object programmatically
hierarchy.select_object("hero")

# Expand hierarchy node
hierarchy.expand_node("environment_group")
```

The UI API provides all the components necessary to create professional game development interfaces. These components work together to provide a cohesive and efficient editing experience.