# Point & Click Adventure Creator Editor (PACE)
# A visual editor for creating point-and-click adventure games using the PointClickEngine

require "point_click_engine"

# Aliases defined in point_click_engine

module PaceEditor
  VERSION = "0.1.0"

  # Main editor window modes
  enum EditorMode
    Scene
    Character
    Hotspot
    Dialog
    Assets
    Project
  end

  # Tool types for different editing modes
  enum Tool
    Select
    Move
    Place
    Delete
    Paint
    Zoom
  end
end

# Core modules
require "./pace_editor/core/project"
require "./pace_editor/core/editor_state"
require "./pace_editor/core/editor_window"

# UI modules
require "./pace_editor/ui/menu_bar"
require "./pace_editor/ui/tool_palette"
require "./pace_editor/ui/property_panel"
require "./pace_editor/ui/scene_hierarchy"
require "./pace_editor/ui/asset_browser"

# Editor modules
require "./pace_editor/editors/scene_editor"
require "./pace_editor/editors/character_editor"
require "./pace_editor/editors/hotspot_editor"
require "./pace_editor/editors/dialog_editor"

# Main entry point
module PaceEditor
  def self.run
    editor = Core::EditorWindow.new
    editor.run
  end
end

# Auto-run if this is the main file
if PROGRAM_NAME.ends_with?("pace_editor") || PROGRAM_NAME.ends_with?("pace_editor.cr")
  PaceEditor.run
end
