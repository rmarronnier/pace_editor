# Point & Click Adventure Creator Editor (PACE)
# A visual editor for creating point-and-click adventure games using the PointClickEngine

require "point_click_engine"

# RL alias is already defined in point_click_engine

# Core foundation modules (required first)
require "./pace_editor/constants"
require "./pace_editor/errors"

# Core system modules
require "./pace_editor/core/dirty_flag"
require "./pace_editor/core/camera_manager"
require "./pace_editor/core/selection_manager"
require "./pace_editor/core/texture_cache"

# Require models module
require "./pace_editor/models"

# Require validation module
require "./pace_editor/validation"

# Require export module
require "./pace_editor/export"

# Require IO module
require "./pace_editor/io/scene_io"

module PaceEditor
  VERSION = "0.1.0"

  # Main editor window modes
  enum EditorMode
    Scene
    Character
    Hotspot
    Dialog
    Assets
    Script
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
require "./pace_editor/ui/ui_helpers"
require "./pace_editor/ui/component_visibility"
require "./pace_editor/ui/ui_state"
require "./pace_editor/ui/progressive_menu"
require "./pace_editor/ui/guided_workflow"
require "./pace_editor/ui/menu_bar"
require "./pace_editor/ui/tool_palette"
require "./pace_editor/ui/property_panel"
require "./pace_editor/ui/scene_hierarchy"
require "./pace_editor/ui/asset_browser"
require "./pace_editor/ui/hotspot_action_dialog"
require "./pace_editor/ui/script_editor"
require "./pace_editor/ui/animation_editor"
require "./pace_editor/ui/background_import_dialog"
require "./pace_editor/ui/asset_import_dialog"
require "./pace_editor/ui/scene_creation_wizard"
require "./pace_editor/ui/game_export_dialog"

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
program_basename = File.basename(PROGRAM_NAME)
is_pace_editor = program_basename.includes?("pace_editor") ||
                 program_basename.includes?("crystal-run") ||
                 PROGRAM_NAME.ends_with?("pace_editor") ||
                 PROGRAM_NAME.ends_with?("pace_editor.cr")

if is_pace_editor
  begin
    PaceEditor.run
  rescue ex
    puts "Error running PACE Editor: #{ex.message}"
    puts ex.backtrace.join("\n")
  end
end
