module PaceEditor::UI
  # Central system for determining UI component visibility based on project state
  # Implements progressive disclosure patterns for better UX
  class ComponentVisibility
    include PaceEditor::Constants
    
    # Core visibility rules for major editor components
    
    # Project-level tools (save, export, etc.)
    def self.should_show_project_tools?(state : Core::EditorState) : Bool
      state.has_project?
    end
    
    # Scene editor - requires active project and scene
    def self.should_show_scene_editor?(state : Core::EditorState) : Bool
      state.has_project? && !state.current_scene.nil?
    end
    
    # Character editor - requires scene with potential for characters
    def self.should_show_character_editor?(state : Core::EditorState) : Bool
      state.has_project? && !state.current_scene.nil?
    end
    
    # Hotspot editor - requires scenes to exist (not necessarily current scene)
    def self.should_show_hotspot_editor?(state : Core::EditorState) : Bool
      state.has_project? && has_any_scenes?(state)
    end
    
    # Dialog editor - requires NPCs to exist in project
    def self.should_show_dialog_editor?(state : Core::EditorState) : Bool
      state.has_project? && has_npcs_in_project?(state)
    end
    
    # Script editor - available once project exists
    def self.should_show_script_editor?(state : Core::EditorState) : Bool
      state.has_project?
    end
    
    # Asset browser - available once project exists
    def self.should_show_asset_browser?(state : Core::EditorState) : Bool
      state.has_project?
    end
    
    # Export functionality - requires valid project with content
    def self.should_show_export_tools?(state : Core::EditorState) : Bool
      state.has_project? && has_exportable_content?(state)
    end
    
    # Menu item visibility rules
    
    def self.should_show_file_save?(state : Core::EditorState) : Bool
      state.has_project? && state.is_dirty
    end
    
    def self.should_show_file_export?(state : Core::EditorState) : Bool
      should_show_export_tools?(state)
    end
    
    def self.should_show_edit_undo?(state : Core::EditorState) : Bool
      state.has_project? && state.can_undo?
    end
    
    def self.should_show_edit_redo?(state : Core::EditorState) : Bool
      state.has_project? && state.can_redo?
    end
    
    def self.should_show_scene_menu?(state : Core::EditorState) : Bool
      state.has_project?
    end
    
    def self.should_show_character_menu?(state : Core::EditorState) : Bool
      should_show_character_editor?(state)
    end
    
    def self.should_show_dialog_menu?(state : Core::EditorState) : Bool
      should_show_dialog_editor?(state)
    end
    
    # Property panel rules
    
    def self.should_show_scene_properties?(state : Core::EditorState) : Bool
      !state.current_scene.nil?
    end
    
    def self.should_show_character_properties?(state : Core::EditorState) : Bool
      !state.current_scene.nil? && !state.selected_object.nil?
    end
    
    def self.should_show_hotspot_properties?(state : Core::EditorState) : Bool
      !state.current_scene.nil? && !state.selected_object.nil?
    end
    
    def self.should_show_dialog_properties?(state : Core::EditorState) : Bool
      has_npcs_in_current_scene?(state) && !state.selected_object.nil?
    end
    
    # Tool palette rules
    
    def self.should_show_scene_tools?(state : Core::EditorState) : Bool
      should_show_scene_editor?(state)
    end
    
    def self.should_show_character_tools?(state : Core::EditorState) : Bool
      should_show_character_editor?(state)
    end
    
    def self.should_show_hotspot_tools?(state : Core::EditorState) : Bool
      should_show_hotspot_editor?(state)
    end
    
    # Mode availability
    
    def self.get_available_modes(state : Core::EditorState) : Array(EditorMode)
      modes = [] of EditorMode
      
      # Project mode is always available
      modes << EditorMode::Project
      
      if state.has_project?
        modes << EditorMode::Assets
        
        if !state.current_scene.nil?
          modes << EditorMode::Scene
          modes << EditorMode::Character
        end
        
        if has_any_scenes?(state)
          modes << EditorMode::Hotspot
        end
        
        if has_npcs_in_project?(state)
          modes << EditorMode::Dialog
        end
        
        if state.has_project?
          modes << EditorMode::Script
        end
      end
      
      modes
    end
    
    def self.is_mode_available?(state : Core::EditorState, mode : EditorMode) : Bool
      get_available_modes(state).includes?(mode)
    end
    
    # Get the best fallback mode when current mode becomes unavailable
    def self.get_fallback_mode(state : Core::EditorState, current_mode : EditorMode) : EditorMode
      available = get_available_modes(state)
      
      # If current mode is still available, keep it
      return current_mode if available.includes?(current_mode)
      
      # Priority order for fallback
      fallback_priority = [
        EditorMode::Scene,
        EditorMode::Assets,
        EditorMode::Character,
        EditorMode::Hotspot,
        EditorMode::Dialog,
        EditorMode::Script,
        EditorMode::Project
      ]
      
      fallback_priority.each do |mode|
        return mode if available.includes?(mode)
      end
      
      # Should never happen, but Project mode is always available
      EditorMode::Project
    end
    
    # Reasons for component being hidden (for tooltips/hints)
    
    def self.get_visibility_reason(component : String, state : Core::EditorState) : String?
      case component
      when "scene_editor"
        return "Create or open a project first" unless state.has_project?
        return "Create a scene to enable the scene editor" unless state.current_scene
      when "character_editor"
        return "Create or open a project first" unless state.has_project?
        return "Create a scene to enable character editing" unless state.current_scene
      when "hotspot_editor"
        return "Create or open a project first" unless state.has_project?
        return "Create at least one scene to enable hotspot editing" unless has_any_scenes?(state)
      when "dialog_editor"
        return "Create or open a project first" unless state.has_project?
        return "Add NPC characters to enable dialog editing" unless has_npcs_in_project?(state)
      when "export_tools"
        return "Create or open a project first" unless state.has_project?
        return "Add content to your project before exporting" unless has_exportable_content?(state)
      end
      
      nil
    end
    
    # Helper methods for content checking
    
    private def self.has_any_scenes?(state : Core::EditorState) : Bool
      return false unless project = state.current_project
      
      # Check if project has any scene files
      scenes_dir = File.join(project.project_path, "scenes")
      return false unless Dir.exists?(scenes_dir)
      
      # Look for .yml scene files
      Dir.glob(File.join(scenes_dir, "*.yml")).any?
    end
    
    private def self.has_npcs_in_project?(state : Core::EditorState) : Bool
      return false unless project = state.current_project
      
      # Check current scene first
      return true if has_npcs_in_current_scene?(state)
      
      # Check all scenes in project for NPCs
      scenes_dir = File.join(project.project_path, "scenes")
      return false unless Dir.exists?(scenes_dir)
      
      Dir.glob(File.join(scenes_dir, "*.yml")).any? do |scene_file|
        scene_has_npcs?(scene_file)
      end
    end
    
    private def self.has_npcs_in_current_scene?(state : Core::EditorState) : Bool
      return false unless scene = state.current_scene
      
      scene.characters.any? { |char| char.is_a?(PointClickEngine::Characters::NPC) }
    end
    
    private def self.scene_has_npcs?(scene_file : String) : Bool
      begin
        # Parse YAML to check for NPCs
        # This is a simplified check - in a real implementation,
        # you'd parse the scene file and check character types
        content = File.read(scene_file)
        content.includes?("NPC") || content.includes?("npc")
      rescue
        false
      end
    end
    
    private def self.has_exportable_content?(state : Core::EditorState) : Bool
      return false unless project = state.current_project
      
      # Project has exportable content if it has:
      # 1. At least one scene
      # 2. At least one asset or character
      
      has_scenes = has_any_scenes?(state)
      has_assets = has_any_assets?(project)
      
      has_scenes && has_assets
    end
    
    private def self.has_any_assets?(project : Core::Project) : Bool
      assets_dir = File.join(project.project_path, "assets")
      return false unless Dir.exists?(assets_dir)
      
      # Check for any asset files
      ASSET_CATEGORIES.any? do |category|
        category_dir = File.join(assets_dir, category)
        Dir.exists?(category_dir) && !Dir.empty?(category_dir)
      end
    end
    
    # UI state helpers
    
    def self.get_component_state(component : String, state : Core::EditorState) : ComponentState
      case component
      when "scene_editor"
        if should_show_scene_editor?(state)
          ComponentState::Visible
        else
          ComponentState::Hidden
        end
      when "character_editor"
        if should_show_character_editor?(state)
          ComponentState::Visible
        else
          ComponentState::Hidden
        end
      when "hotspot_editor"
        if should_show_hotspot_editor?(state)
          ComponentState::Visible
        else
          ComponentState::Hidden
        end
      when "dialog_editor"
        if should_show_dialog_editor?(state)
          ComponentState::Visible
        else
          ComponentState::Hidden
        end
      else
        ComponentState::Visible  # Default to visible for unknown components
      end
    end
    
    # Power user mode - shows all components regardless of state
    def self.should_show_in_power_mode?(component : String) : Bool
      # In power mode, show everything except fundamentally impossible things
      case component
      when "project_tools"
        false  # Still need a project for project tools
      else
        true
      end
    end
  end
  
  # Component visibility states
  enum ComponentState
    Visible
    Hidden
    Disabled
  end
  
  # Visibility context for components
  struct VisibilityContext
    property component : String
    property state : ComponentState
    property reason : String?
    property hint : String?
    
    def initialize(@component : String, @state : ComponentState, @reason : String? = nil, @hint : String? = nil)
    end
    
    def visible?
      @state == ComponentState::Visible
    end
    
    def hidden?
      @state == ComponentState::Hidden
    end
    
    def disabled?
      @state == ComponentState::Disabled
    end
  end
end