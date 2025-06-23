module PaceEditor::UI
  # Enhanced UI state management for progressive disclosure
  # Tracks UI-specific state separate from core editor state
  class UIState
    include PaceEditor::Constants

    # Power user preferences
    property power_mode : Bool = false
    property show_advanced_tools : Bool = false
    property show_debug_info : Bool = false

    # Onboarding and guidance
    property first_run : Bool = true
    property show_hints : Bool = true
    property completed_tutorials : Set(String) = Set(String).new

    # UI layout preferences
    property panel_layout : PanelLayout = PanelLayout::Standard
    property theme : UITheme = UITheme::Default
    property font_scale : Float32 = 1.0_f32

    # Component visibility overrides
    property visibility_overrides : Hash(String, ComponentState) = Hash(String, ComponentState).new

    # Recent actions for contextual hints
    property recent_actions : Array(String) = [] of String
    property last_mode_switch : Time? = nil

    # Tooltip and hint system
    property active_tooltip : String? = nil
    property tooltip_position : RL::Vector2? = nil
    property hint_queue : Array(UIHint) = [] of UIHint

    # Progress tracking
    property project_progress : ProjectProgress = ProjectProgress.new

    def initialize
      load_preferences
    end

    # Power mode controls
    def enable_power_mode
      @power_mode = true
      @show_advanced_tools = true
    end

    def disable_power_mode
      @power_mode = false
      @show_advanced_tools = false
    end

    def toggle_power_mode
      @power_mode ? disable_power_mode : enable_power_mode
    end

    # Component visibility with overrides
    def get_component_visibility(component : String, editor_state : Core::EditorState) : ComponentState
      # Check for user override first
      if override = @visibility_overrides[component]?
        return override
      end

      # Power mode shows everything
      if @power_mode && ComponentVisibility.should_show_in_power_mode?(component)
        return ComponentState::Visible
      end

      # Use standard visibility rules
      ComponentVisibility.get_component_state(component, editor_state)
    end

    def override_component_visibility(component : String, state : ComponentState)
      @visibility_overrides[component] = state
    end

    def clear_visibility_override(component : String)
      @visibility_overrides.delete(component)
    end

    def clear_all_overrides
      @visibility_overrides.clear
    end

    # Hint system
    def add_hint(hint : UIHint)
      return unless @show_hints

      # Don't add duplicate hints
      return if @hint_queue.any? { |h| h.id == hint.id }

      # Limit queue size
      if @hint_queue.size >= MAX_HINT_QUEUE_SIZE
        @hint_queue.shift
      end

      @hint_queue << hint
    end

    def get_next_hint : UIHint?
      @hint_queue.shift?
    end

    def dismiss_hint(hint_id : String)
      @hint_queue.reject! { |h| h.id == hint_id }
    end

    def clear_hints
      @hint_queue.clear
    end

    # Recent actions tracking
    def track_action(action : String)
      @recent_actions << action

      # Keep only recent actions
      if @recent_actions.size > MAX_RECENT_ACTIONS
        @recent_actions.shift
      end

      # Update contextual hints based on actions
      update_contextual_hints(action)
    end

    def has_recent_action?(action : String, within_seconds : Int32 = 30) : Bool
      return false if @recent_actions.empty?

      # For simplicity, just check if action exists in recent actions
      # In a more sophisticated implementation, you'd track timestamps
      @recent_actions.includes?(action)
    end

    # Tutorial and onboarding
    def mark_tutorial_completed(tutorial : String)
      @completed_tutorials.add(tutorial)
      save_preferences
    end

    def is_tutorial_completed?(tutorial : String) : Bool
      @completed_tutorials.includes?(tutorial)
    end

    def should_show_onboarding? : Bool
      @first_run && !is_tutorial_completed?("basic_workflow")
    end

    # Progress tracking
    def update_project_progress(editor_state : Core::EditorState)
      @project_progress.update(editor_state)
    end

    def get_completion_percentage : Float32
      @project_progress.completion_percentage
    end

    def get_next_suggested_action(editor_state : Core::EditorState) : String?
      @project_progress.get_next_action(editor_state)
    end

    # Mode management
    def track_mode_switch(new_mode : EditorMode)
      @last_mode_switch = Time.utc
      track_action("mode_switch_#{new_mode.to_s.downcase}")
    end

    def get_available_modes(editor_state : Core::EditorState) : Array(EditorMode)
      if @power_mode
        # In power mode, show all modes but mark unavailable ones
        EditorMode.values
      else
        ComponentVisibility.get_available_modes(editor_state)
      end
    end

    # Tooltip management
    def show_tooltip(text : String, position : RL::Vector2)
      @active_tooltip = text
      @tooltip_position = position
    end

    def hide_tooltip
      @active_tooltip = nil
      @tooltip_position = nil
    end

    def has_active_tooltip? : Bool
      !@active_tooltip.nil?
    end

    # Preferences persistence
    def save_preferences
      return unless editor_state = get_editor_state?
      return unless project = editor_state.current_project

      prefs_file = File.join(project.project_path, ".pace_ui_prefs.yml")

      preferences = {
        "power_mode"          => @power_mode,
        "show_hints"          => @show_hints,
        "panel_layout"        => @panel_layout.to_s,
        "theme"               => @theme.to_s,
        "font_scale"          => @font_scale,
        "completed_tutorials" => @completed_tutorials.to_a,
        "first_run"           => @first_run,
      }

      begin
        File.write(prefs_file, preferences.to_yaml)
      rescue
        # Silently fail if we can't save preferences
      end
    end

    def load_preferences
      return unless editor_state = get_editor_state?
      return unless project = editor_state.current_project

      prefs_file = File.join(project.project_path, ".pace_ui_prefs.yml")
      return unless File.exists?(prefs_file)

      begin
        yaml_content = File.read(prefs_file)
        preferences = YAML.parse(yaml_content)

        @power_mode = preferences["power_mode"]?.try(&.as_bool) || false
        @show_hints = preferences["show_hints"]?.try(&.as_bool) || true
        @font_scale = preferences["font_scale"]?.try(&.as_f32) || 1.0_f32
        @first_run = preferences["first_run"]?.try(&.as_bool) || true

        if layout_str = preferences["panel_layout"]?.try(&.as_s)
          @panel_layout = PanelLayout.parse?(layout_str) || PanelLayout::Standard
        end

        if theme_str = preferences["theme"]?.try(&.as_s)
          @theme = UITheme.parse?(theme_str) || UITheme::Default
        end

        if tutorials = preferences["completed_tutorials"]?.try(&.as_a)
          @completed_tutorials = tutorials.map(&.as_s).to_set
        end
      rescue
        # Use defaults if loading fails
      end
    end

    # Context-sensitive hints
    private def update_contextual_hints(action : String)
      case action
      when "project_created"
        add_hint(UIHint.new("create_scene", "Create your first scene to start building your game!", UIHintType::Suggestion))
      when "scene_created"
        add_hint(UIHint.new("add_character", "Add characters to bring your scene to life!", UIHintType::Suggestion))
      when "character_added"
        add_hint(UIHint.new("add_hotspots", "Create hotspots for interactive elements!", UIHintType::Suggestion))
      when "npc_added"
        add_hint(UIHint.new("create_dialog", "Create dialogs for your NPCs in the Dialog Editor!", UIHintType::Feature))
      end
    end

    private def get_editor_state? : Core::EditorState?
      # This would need to be injected or accessed through a global reference
      # For now, return nil to avoid circular dependencies
      nil
    end
  end

  # UI layout configurations
  enum PanelLayout
    Standard
    Compact
    Wide
    Custom
  end

  # UI themes
  enum UITheme
    Default
    Dark
    Light
    HighContrast
  end

  # UI hint system
  struct UIHint
    property id : String
    property text : String
    property type : UIHintType
    property priority : Int32
    property expires_at : Time?

    def initialize(@id : String, @text : String, @type : UIHintType = UIHintType::Info, @priority : Int32 = 0, expires_in : Time::Span? = nil)
      @expires_at = expires_in ? Time.utc + expires_in : nil
    end

    def expired? : Bool
      if expiry = @expires_at
        Time.utc > expiry
      else
        false
      end
    end
  end

  enum UIHintType
    Info
    Warning
    Success
    Error
    Suggestion
    Feature
    Tutorial
  end

  # Project progress tracking
  class ProjectProgress
    property has_project : Bool = false
    property has_scenes : Bool = false
    property has_characters : Bool = false
    property has_npcs : Bool = false
    property has_hotspots : Bool = false
    property has_dialogs : Bool = false
    property has_assets : Bool = false
    property has_scripts : Bool = false

    def update(editor_state : Core::EditorState)
      @has_project = editor_state.has_project?

      if project = editor_state.current_project
        @has_scenes = ComponentVisibility.send(:has_any_scenes?, editor_state)
        @has_assets = ComponentVisibility.send(:has_any_assets?, project)

        if scene = editor_state.current_scene
          @has_characters = scene.characters.any?
          @has_npcs = scene.characters.any? { |char| char.is_a?(PointClickEngine::Characters::NPC) }
          @has_hotspots = scene.hotspots.any?
        end

        @has_dialogs = ComponentVisibility.send(:has_npcs_in_project?, editor_state)

        # Check for scripts
        scripts_dir = File.join(project.project_path, "scripts")
        @has_scripts = Dir.exists?(scripts_dir) && !Dir.empty?(scripts_dir)
      end
    end

    def completion_percentage : Float32
      total_steps = 8.0_f32
      completed_steps = 0.0_f32

      completed_steps += 1 if @has_project
      completed_steps += 1 if @has_scenes
      completed_steps += 1 if @has_characters
      completed_steps += 1 if @has_npcs
      completed_steps += 1 if @has_hotspots
      completed_steps += 1 if @has_dialogs
      completed_steps += 1 if @has_assets
      completed_steps += 1 if @has_scripts

      (completed_steps / total_steps) * 100.0_f32
    end

    def get_next_action(editor_state : Core::EditorState) : String?
      return "Create or open a project" unless @has_project
      return "Create your first scene" unless @has_scenes
      return "Add characters to your scene" unless @has_characters
      return "Import or create assets" unless @has_assets
      return "Add interactive hotspots" unless @has_hotspots
      return "Create NPCs for dialogs" unless @has_npcs
      return "Write character dialogs" unless @has_dialogs
      return "Add custom scripts" unless @has_scripts

      "Your project is ready to export!"
    end
  end

  # Constants for UI state
  MAX_HINT_QUEUE_SIZE   =  5
  MAX_RECENT_ACTIONS    = 20
  HINT_DEFAULT_DURATION = 30.seconds
end
