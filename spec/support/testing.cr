# Testing support module for PACE Editor
# Provides e2e testing infrastructure similar to Cypress/Capybara
#
# This module is only loaded during tests, keeping production code clean.

require "./testing/input_provider"
require "./testing/ui_helpers_ext"
require "./testing/editor_window_ext"
require "./testing/scene_editor_ext"
require "./testing/dialog_editor_ext"
require "./testing/character_editor_ext"
require "./testing/property_panel_ext"
require "./testing/scene_hierarchy_ext"
require "./testing/tool_palette_ext"
require "./testing/progressive_menu_ext"
require "./testing/asset_browser_ext"
require "./testing/hotspot_action_dialog_ext"
require "./testing/scene_creation_wizard_ext"
require "./testing/dialog_node_dialog_ext"
require "./testing/game_export_dialog_ext"
require "./testing/animation_editor_ext"
require "./testing/script_editor_ext"
require "./testing/background_import_dialog_ext"
require "./testing/object_type_dialog_ext"
require "./testing/background_selector_dialog_ext"
require "./testing/hotspot_interaction_preview_ext"
require "./testing/guided_workflow_ext"
require "./testing/dialog_preview_window_ext"
require "./testing/menu_bar_ext"
require "./testing/test_harness"

module PaceEditor::Testing
  VERSION = "1.0.0"

  # Check if we're in test mode
  class_property? test_mode : Bool = false

  # Enable test mode
  def self.enable_test_mode
    @@test_mode = true
  end

  # Disable test mode and restore normal operation
  def self.disable_test_mode
    @@test_mode = false
    use_real_input
  end
end
