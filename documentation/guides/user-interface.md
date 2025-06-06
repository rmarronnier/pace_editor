# User Interface Guide

This comprehensive guide covers every aspect of PACE's user interface, helping you become proficient with all the editor's tools and features.

## Interface Overview

PACE uses a multi-panel layout optimized for game development workflow:

```
┌─────────────── Menu Bar ───────────────┐
├─Tool─┬──────── Main Viewport ──────┬─Prop─┤
│Palette│                            │Panel │
│      │                            │     │
├──────┤                            │     │
│Scene │                            │     │
│Hier. │                            │     │
├──────┴────────────────────────────┴─────┤
└─────────────── Status Bar ──────────────┘
```

### Main Areas

1. **Menu Bar** - File operations and application commands
2. **Tool Palette** - Quick access to editing tools
3. **Main Viewport** - Primary editing canvas
4. **Property Panel** - Object and scene properties
5. **Scene Hierarchy** - Tree view of scene contents
6. **Status Bar** - Current status and mode information

## Menu Bar

### File Menu

**New Project (Ctrl+N)**
- Creates a new PACE project
- Opens project creation wizard
- Sets up default directory structure

**Open Project (Ctrl+O)**
- Opens existing .pace project files
- Recent projects submenu
- Import from other formats

**Save Project (Ctrl+S)**
- Saves current project state
- Auto-save indicator
- Backup creation options

**Import Assets**
- Batch asset import
- Supported formats: PNG, JPG, WAV, MP3, OGG
- Automatic categorization

**Export Game**
- Export to executable
- Web export (HTML5)
- Source code export

**Recent Projects**
- Quick access to recent work
- Pin favorites
- Clear history option

### Edit Menu

**Undo (Ctrl+Z)**
- Multi-level undo support
- Visual undo history
- Branch navigation

**Redo (Ctrl+Y)**
- Redo previously undone actions
- Maintains undo branch integrity

**Cut/Copy/Paste (Ctrl+X/C/V)**
- Object and asset operations
- Cross-scene copying
- Clipboard preview

**Select All (Ctrl+A)**
- Selects all objects in current mode
- Mode-aware selection

**Duplicate (Ctrl+D)**
- Duplicates selected objects
- Smart positioning
- Maintains relationships

### View Menu

**Zoom In/Out (Ctrl++/-)**
- Viewport zoom controls
- Fit to window option
- Reset zoom (Ctrl+0)

**Show Grid (G)**
- Toggleable alignment grid
- Customizable grid size
- Snap to grid option

**Show Hotspots (H)**
- Visualize interaction areas
- Hotspot overlay modes
- Debug information

**Camera Controls**
- Reset camera position
- Follow selected object
- Lock camera movement

**UI Panels**
- Show/hide individual panels
- Panel arrangement presets
- Custom layouts

### Tools Menu

**Select Tool (V)**
- Default selection mode
- Multi-selection support
- Marquee selection

**Move Tool (M)**
- Object positioning
- Constrained movement
- Precision controls

**Place Tool (P)**
- Asset placement mode
- Preview while placing
- Auto-snapping

**Delete Tool (D)**
- Quick deletion mode
- Confirmation options
- Undo support

### Mode Menu

**Scene Mode**
- Primary scene editing
- Object placement and arrangement
- Background management

**Character Mode**
- Character creation and editing
- Animation timeline
- Sprite management

**Hotspot Mode**
- Interactive area creation
- Behavior configuration
- Testing tools

**Dialog Mode**
- Conversation tree editor
- Character dialog management
- Branching logic

**Assets Mode**
- Asset browser and management
- Import/export tools
- Organization features

**Project Mode**
- Project-wide settings
- Build configuration
- Export options

### Help Menu

**Documentation**
- Opens built-in help
- Links to online resources
- Video tutorials

**Keyboard Shortcuts**
- Complete shortcut reference
- Customization options
- Print-friendly format

**About PACE**
- Version information
- Credits and licensing
- Update checker

## Tool Palette

Located on the left side, provides quick access to frequently used tools.

### Selection Tools

**Select Tool (V)**
- **Icon**: Arrow cursor
- **Function**: Select and manipulate objects
- **Modifiers**:
  - Shift+Click: Add to selection
  - Ctrl+Click: Toggle selection
  - Alt+Drag: Duplicate while moving

**Marquee Select**
- **Function**: Draw selection rectangle
- **Usage**: Click and drag to select multiple objects
- **Modifiers**:
  - Shift: Add to existing selection
  - Alt: Remove from selection

### Manipulation Tools

**Move Tool (M)**
- **Icon**: Four-directional arrow
- **Function**: Move selected objects
- **Features**:
  - Constrained movement (hold Shift)
  - Pixel-perfect positioning
  - Multi-object movement

**Scale Tool (S)**
- **Icon**: Resize handles
- **Function**: Resize objects proportionally
- **Modifiers**:
  - Shift: Maintain aspect ratio
  - Alt: Scale from center
  - Ctrl: Non-uniform scaling

**Rotate Tool (R)**
- **Icon**: Circular arrow
- **Function**: Rotate objects around center
- **Features**:
  - 15-degree snap increments
  - Visual rotation guide
  - Numeric input option

### Creation Tools

**Place Tool (P)**
- **Icon**: Crosshair
- **Function**: Place new objects from assets
- **Usage**: Select asset, then click in scene
- **Features**:
  - Preview before placement
  - Auto-layering
  - Smart snapping

**Paint Tool (B)**
- **Icon**: Brush
- **Function**: Paint tiles or textures
- **Modes**:
  - Single tile
  - Pattern brush
  - Texture painting

### Utility Tools

**Delete Tool (D)**
- **Icon**: Trash can
- **Function**: Quick object deletion
- **Usage**: Click objects to delete immediately
- **Safety**: Confirmation for multiple objects

**Zoom Tool (Z)**
- **Icon**: Magnifying glass
- **Function**: Zoom viewport
- **Usage**:
  - Click: Zoom in
  - Alt+Click: Zoom out
  - Drag: Zoom to rectangle

**Pan Tool (Space)**
- **Icon**: Hand
- **Function**: Move viewport camera
- **Usage**: Hold Space+drag or select tool and drag
- **Feature**: Smooth momentum scrolling

## Main Viewport

The central editing area where you design your game scenes.

### Viewport Controls

**Camera Navigation**
- **Pan**: Space+drag or middle mouse button
- **Zoom**: Mouse wheel or zoom tool
- **Reset**: Double-click viewport or Ctrl+0

**Grid System**
- **Toggle**: Press G or View menu
- **Size**: Configurable in preferences
- **Snap**: Hold Shift while moving objects

**Rulers and Guides**
- **Rulers**: Show pixel measurements
- **Guides**: Drag from rulers to create snap lines
- **Smart Guides**: Automatic alignment helpers

### Visual Indicators

**Selection Handles**
- Corner handles for scaling
- Edge handles for stretching
- Rotation handle at top
- Center pivot point

**Object Overlays**
- Hotspot boundaries (red rectangles)
- Character paths (blue lines)
- Interaction areas (green circles)
- Layer indicators (colored borders)

**Status Information**
- Object coordinates
- Size dimensions
- Layer depth
- Selected object count

### Context Menus

**Right-click Object**
- Properties
- Duplicate
- Delete
- Send to Front/Back
- Lock/Unlock

**Right-click Empty Space**
- Paste
- Select All
- Clear Selection
- Camera Reset

## Property Panel

Located on the right side, shows detailed properties of selected objects.

### Object Properties

**Transform**
- Position (X, Y coordinates)
- Size (Width, Height)
- Rotation (degrees)
- Scale (percentage)
- Anchor point

**Appearance**
- Texture/Sprite
- Color tint
- Opacity/Alpha
- Blend mode
- Layer order

**Behavior**
- Collision detection
- Physics properties
- Animation settings
- Script references

### Scene Properties

**General**
- Scene name
- Description
- Background image
- Ambient lighting

**Camera**
- Default position
- Zoom level
- Follow target
- Boundaries

**Settings**
- Grid size
- Snap tolerance
- Layer visibility
- Debug options

### Character Properties

**Sprite Configuration**
- Sprite sheet path
- Frame dimensions
- Frame count
- Pivot point

**Animations**
- Animation list
- Current animation
- Playback speed
- Loop settings

**Movement**
- Walking speed
- Turn rate
- Path finding
- Collision size

### Hotspot Properties

**Area Definition**
- Boundary rectangle
- Shape type (rectangle, circle, polygon)
- Active area percentage

**Interaction**
- Interaction type (examine, use, talk, etc.)
- Cursor change
- Priority level
- Enabled state

**Actions**
- Script reference
- Dialog tree
- Inventory effects
- Scene transitions

**Conditions**
- Visibility conditions
- Activation requirements
- State dependencies

## Scene Hierarchy

Shows the tree structure of all objects in the current scene.

### Hierarchy Tree

**Scene Root**
- Background layer
- Object layers
- UI layer
- Debug layer

**Object Organization**
- Drag to reorder
- Nested grouping
- Layer management
- Visibility toggles

**Layer Controls**
- Show/hide layers
- Lock layers
- Layer opacity
- Blend modes

### Hierarchy Operations

**Selection**
- Click to select objects
- Shift+click for multi-selection
- Ctrl+click to toggle selection

**Organization**
- Drag objects between layers
- Create groups for organization
- Rename objects for clarity

**Context Menu**
- Duplicate objects
- Delete objects
- Create groups
- Manage layers

## Status Bar

Provides real-time information about the editor state.

### Information Display

**Project Status**
- Current project name
- Scene name
- Unsaved changes indicator

**Tool Information**
- Active tool name
- Tool-specific options
- Modifier key hints

**Selection Details**
- Number of selected objects
- Object types
- Total area/bounds

**View Information**
- Current zoom level
- Camera position
- Viewport size

### Quick Actions

**Mode Buttons**
- Quick mode switching
- Mode-specific options
- Workflow indicators

**Progress Indicators**
- Asset loading progress
- Save/export progress
- Background operations

## Mode-Specific Interfaces

### Scene Mode Interface

**Main Viewport**
- Full scene editing
- Object placement and manipulation
- Background and layer management

**Tool Options**
- Object snapping options
- Layer filtering
- Grid configuration

**Property Focus**
- Object transform properties
- Material and texture settings
- Layer and depth controls

### Character Mode Interface

**Character Preview**
- Large character display
- Animation playback
- Frame-by-frame stepping

**Animation Timeline**
- Frame sequence editor
- Keyframe management
- Timing controls

**Sprite Management**
- Sprite sheet import
- Frame extraction
- Animation creation

### Hotspot Mode Interface

**Hotspot Visualization**
- All hotspots highlighted
- Interaction type indicators
- Overlap detection

**Behavior Configuration**
- Action script editor
- Condition builder
- Testing interface

### Dialog Mode Interface

**Dialog Tree View**
- Node-based editor
- Connection visualization
- Flow validation

**Character Assignment**
- Speaker selection
- Portrait management
- Voice settings

**Preview System**
- Dialog playback
- Branch testing
- Timing validation

### Assets Mode Interface

**Asset Browser**
- Thumbnail grid view
- Category filtering
- Search functionality

**Import Tools**
- Batch import wizard
- Format conversion
- Organization helpers

**Management Tools**
- Asset dependencies
- Usage tracking
- Cleanup utilities

## Customization Options

### Interface Themes

**Built-in Themes**
- Dark theme (default)
- Light theme
- High contrast
- Custom themes

**Color Customization**
- Panel colors
- Text colors
- Highlight colors
- Grid and guide colors

### Layout Management

**Panel Arrangement**
- Dock panels anywhere
- Floating panels
- Multi-monitor support
- Saved layouts

**Toolbar Customization**
- Add/remove tools
- Custom tool groups
- Icon size options
- Text labels

### Keyboard Shortcuts

**Customizable Shortcuts**
- Reassign any shortcut
- Create tool macros
- Context-sensitive bindings
- Import/export shortcuts

**Shortcut Categories**
- File operations
- Edit commands
- Tool selection
- View controls
- Mode switching

## Accessibility Features

### Visual Accessibility

**High Contrast Mode**
- Enhanced visibility
- Clear panel boundaries
- Readable text

**Zoom and Scale**
- Interface scaling
- Text size options
- Icon enlargement

**Color Blind Support**
- Alternative color schemes
- Pattern overlays
- Shape indicators

### Keyboard Navigation

**Full Keyboard Access**
- Tab navigation
- Keyboard shortcuts
- Menu access keys
- Focus indicators

**Screen Reader Support**
- Object descriptions
- Status announcements
- Progress updates

## Performance Optimization

### Interface Responsiveness

**Viewport Optimization**
- Level-of-detail rendering
- Culling for large scenes
- Smooth animation playback
- Efficient redraws

**Memory Management**
- Asset streaming
- Texture compression
- Garbage collection
- Memory monitoring

### Workflow Efficiency

**Smart Defaults**
- Context-aware tools
- Automatic mode switching
- Predictive placement
- Intelligent snapping

**Batch Operations**
- Multi-object editing
- Bulk property changes
- Asset processing
- Export optimization

This comprehensive interface guide should help you master PACE's interface and work efficiently on your adventure game projects. For specific workflow examples, see the [Getting Started Guide](getting-started.md) and [Tutorials](../tutorials/).