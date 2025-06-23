module PaceEditor::Core
  # Main editor window that coordinates all UI elements and editors
  class EditorWindow
    DEFAULT_WINDOW_WIDTH  = 1400
    DEFAULT_WINDOW_HEIGHT =  900
    MENU_HEIGHT           =   30
    TOOL_PALETTE_WIDTH    =   80
    PROPERTY_PANEL_WIDTH  =  300
    SCENE_HIERARCHY_WIDTH =  250

    # Keep old constants for compatibility with other files
    WINDOW_WIDTH  = 1400
    WINDOW_HEIGHT =  900

    @window_width : Int32
    @window_height : Int32
    @is_fullscreen : Bool

    property state : EditorState
    property ui_state : UI::UIState
    property progressive_menu : UI::ProgressiveMenu
    property guided_workflow : UI::GuidedWorkflow
    property menu_bar : UI::MenuBar
    property tool_palette : UI::ToolPalette
    property property_panel : UI::PropertyPanel
    property scene_hierarchy : UI::SceneHierarchy
    property asset_browser : UI::AssetBrowser

    # Editors for different modes
    property scene_editor : Editors::SceneEditor
    property character_editor : Editors::CharacterEditor
    property hotspot_editor : Editors::HotspotEditor
    property dialog_editor : Editors::DialogEditor
    property width : Int32
    property height : Int32

    # Dialogs
    property hotspot_action_dialog : UI::HotspotActionDialog
    property script_editor : UI::ScriptEditor
    property background_import_dialog : UI::BackgroundImportDialog
    property asset_import_dialog : UI::AssetImportDialog
    property scene_creation_wizard : UI::SceneCreationWizard
    property game_export_dialog : UI::GameExportDialog

    # Editor viewport
    @viewport_x : Int32
    @viewport_y : Int32
    @viewport_width : Int32
    @viewport_height : Int32

    def initialize
      @state = EditorState.new
      @window_width = DEFAULT_WINDOW_WIDTH
      @window_height = DEFAULT_WINDOW_HEIGHT
      @is_fullscreen = false

      # Initialize viewport dimensions
      @viewport_x = TOOL_PALETTE_WIDTH
      @viewport_y = MENU_HEIGHT
      @viewport_width = @window_width - TOOL_PALETTE_WIDTH - PROPERTY_PANEL_WIDTH
      @viewport_height = @window_height - MENU_HEIGHT

      # Initialize UI state for progressive disclosure
      @ui_state = UI::UIState.new
      
      # Initialize progressive UI components
      @progressive_menu = UI::ProgressiveMenu.new(@state, @ui_state)
      @guided_workflow = UI::GuidedWorkflow.new(@state, @ui_state)

      # Initialize UI components
      @menu_bar = UI::MenuBar.new(@state)
      @tool_palette = UI::ToolPalette.new(@state)
      @property_panel = UI::PropertyPanel.new(@state)
      @scene_hierarchy = UI::SceneHierarchy.new(@state)
      @asset_browser = UI::AssetBrowser.new(@state)

      # Initialize editors
      @scene_editor = Editors::SceneEditor.new(@state, @viewport_x, @viewport_y, @viewport_width, @viewport_height)
      @character_editor = Editors::CharacterEditor.new(@state)
      @hotspot_editor = Editors::HotspotEditor.new(@state)
      @dialog_editor = Editors::DialogEditor.new(@state)

      # Initialize dialogs
      @hotspot_action_dialog = UI::HotspotActionDialog.new(@state)
      @script_editor = UI::ScriptEditor.new(@state)
      @background_import_dialog = UI::BackgroundImportDialog.new(@state)
      @asset_import_dialog = UI::AssetImportDialog.new(@state)
      @scene_creation_wizard = UI::SceneCreationWizard.new(@state)
      @game_export_dialog = UI::GameExportDialog.new(@state)

      # Initialize dimensions
      @width = @window_width
      @height = @window_height

      # Store reference to window in state
      @state.editor_window = self
    end

    # Switch editor mode with progressive disclosure validation
    def switch_mode(new_mode : PaceEditor::EditorMode)
      # Check if mode is available
      unless UI::ComponentVisibility.is_mode_available?(@state, new_mode)
        # Show hint about why mode is not available
        reason = UI::ComponentVisibility.get_visibility_reason("#{new_mode.to_s.downcase}_editor", @state)
        if reason
          @ui_state.add_hint(UI::UIHint.new("mode_unavailable", reason, UI::UIHintType::Warning))
        end
        return
      end

      # Track mode switch
      @ui_state.track_mode_switch(new_mode)
      
      # Set new mode
      @state.current_mode = new_mode
    end

    def show_hotspot_action_dialog(hotspot_name : String)
      @hotspot_action_dialog.show(hotspot_name)
    end

    def show_script_editor(script_path : String? = nil)
      @script_editor.show(script_path)
    end

    def show_dialog_editor_for_character(character_name : String)
      # Switch to dialog mode and set the dialog editor to edit this character's dialog
      switch_mode(PaceEditor::EditorMode::Dialog)
      @ui_state.track_action("dialog_editor_opened")
      # TODO: Load/create dialog tree for the character
      puts "Opening dialog editor for character: #{character_name}"
    end

    def show_background_import_dialog
      @background_import_dialog.show
    end

    def show_asset_import_dialog(category : String = "backgrounds")
      @asset_import_dialog.show(category)
    end

    def show_scene_creation_wizard
      @scene_creation_wizard.show
      @ui_state.track_action("scene_creation_wizard_opened")
    end

    def show_game_export_dialog
      @game_export_dialog.show
      @ui_state.track_action("export_dialog_opened")
    end

    def run
      # Initialize Raylib
      RL.init_window(@window_width, @window_height, "PACE - Point & Click Adventure Creator Editor")
      RL.set_window_state(RL::ConfigFlags::WindowResizable)
      RL.set_target_fps(60)

      # Main loop
      while !RL.close_window?
        update
        draw
      end

      cleanup
    end

    private def update
      # Check for window resize
      if RL.window_resized?
        @window_width = RL.get_screen_width
        @window_height = RL.get_screen_height
        calculate_viewport_dimensions
      end

      # Handle progressive UI input first (highest priority)
      mouse_pos = RL.get_mouse_position
      mouse_clicked = RL.mouse_button_pressed?(RL::MouseButton::Left)
      
      # Check progressive menu input
      if @progressive_menu.handle_input(mouse_pos, mouse_clicked)
        return  # Input consumed by progressive menu
      end
      
      # Check guided workflow input
      if @guided_workflow.handle_input(mouse_pos, mouse_clicked)
        return  # Input consumed by guided workflow
      end

      # Handle global shortcuts
      handle_shortcuts

      # Update current editor based on mode
      case @state.current_mode
      when .scene?
        @scene_editor.update
      when .character?
        @character_editor.update
      when .hotspot?
        @hotspot_editor.update
      when .dialog?
        @dialog_editor.update
      when .assets?
        @asset_browser.update
      when .project?
        # Project settings handled by property panel
      end

      # Update progressive UI state
      @ui_state.update_project_progress(@state)
      @guided_workflow.update

      # Update UI components
      @menu_bar.update
      @tool_palette.update
      @property_panel.update
      @scene_hierarchy.update
      @asset_browser.update if @state.current_mode.assets?

      # Update dialogs
      @hotspot_action_dialog.update
      @script_editor.update
      @background_import_dialog.update
      @asset_import_dialog.update
      @scene_creation_wizard.update
      @game_export_dialog.update
    end

    private def draw
      RL.begin_drawing
      RL.clear_background(RL::Color.new(r: 50, g: 50, b: 50, a: 255))

      # Draw progressive menu instead of old menu bar
      @progressive_menu.draw(@window_width)

      # Draw tool palette if visible
      if @ui_state.get_component_visibility("tool_palette", @state).visible?
        @tool_palette.draw
      end

      # Draw main editor area
      draw_editor_viewport

      # Draw side panels with visibility checks
      if @ui_state.get_component_visibility("scene_hierarchy", @state).visible?
        @scene_hierarchy.draw
      end
      
      if @ui_state.get_component_visibility("property_panel", @state).visible?
        @property_panel.draw
      end

      # Draw asset browser if in assets mode and visible
      if @state.current_mode.assets? && @ui_state.get_component_visibility("asset_browser", @state).visible?
        @asset_browser.draw
      end

      # Draw status bar
      draw_status_bar

      # Draw guided workflow (getting started, hints, tutorials)
      @guided_workflow.draw

      # Draw dialogs on top of everything
      @hotspot_action_dialog.draw
      @script_editor.draw
      @background_import_dialog.draw
      @asset_import_dialog.draw
      @scene_creation_wizard.draw
      @game_export_dialog.draw

      RL.end_drawing
    end

    private def draw_editor_viewport
      # Define viewport area
      viewport_rect = RL::Rectangle.new(
        x: @viewport_x.to_f,
        y: @viewport_y.to_f,
        width: @viewport_width.to_f,
        height: @viewport_height.to_f
      )

      # Draw viewport background
      RL.draw_rectangle_rec(viewport_rect, RL::Color.new(r: 40, g: 40, b: 40, a: 255))

      # Set scissor for viewport clipping
      RL.begin_scissor_mode(@viewport_x, @viewport_y, @viewport_width, @viewport_height)

      # Draw current editor
      case @state.current_mode
      when .scene?
        @scene_editor.draw
      when .character?
        @character_editor.draw
      when .hotspot?
        @hotspot_editor.draw
      when .dialog?
        @dialog_editor.draw
      when .project?
        draw_project_overview
      end

      RL.end_scissor_mode

      # Draw viewport border
      RL.draw_rectangle_lines_ex(viewport_rect, 1, RL::GRAY)
    end

    private def draw_project_overview
      if project = @state.current_project
        y = @viewport_y + 20
        RL.draw_text("Project: #{project.name}", @viewport_x + 20, y, 24, RL::WHITE)
        y += 40
        RL.draw_text("Scenes: #{project.scenes.size}", @viewport_x + 20, y, 18, RL::LIGHTGRAY)
        y += 25
        RL.draw_text("Assets: #{project.backgrounds.size + project.characters.size + project.sounds.size}", @viewport_x + 20, y, 18, RL::LIGHTGRAY)
      else
        RL.draw_text("No project loaded", @viewport_x + 20, @viewport_y + 20, 24, RL::LIGHTGRAY)
        RL.draw_text("Create a new project or open an existing one", @viewport_x + 20, @viewport_y + 60, 16, RL::LIGHTGRAY)
      end
    end

    private def draw_status_bar
      status_y = @window_height - 25
      RL.draw_rectangle(0, status_y, @window_width, 25, RL::Color.new(r: 30, g: 30, b: 30, a: 255))

      status_text = build_status_text
      RL.draw_text(status_text, 10, status_y + 5, 12, RL::LIGHTGRAY)

      # Draw mode indicator
      mode_text = @state.current_mode.to_s
      mode_width = RL.measure_text(mode_text, 12)
      RL.draw_text(mode_text, @window_width - mode_width - 10, status_y + 5, 12, RL::YELLOW)
    end

    private def build_status_text : String
      parts = [] of String

      if project = @state.current_project
        parts << "Project: #{project.name}"
        if scene_name = project.current_scene
          parts << "Scene: #{scene_name}"
        end
      else
        parts << "No project"
      end

      parts << "Tool: #{@state.current_tool}"
      parts << "Zoom: #{(@state.zoom * 100).to_i}%"

      parts.join(" | ")
    end

    private def handle_shortcuts
      # File operations
      if RL.key_down?(RL::KeyboardKey::LeftControl) || RL.key_down?(RL::KeyboardKey::RightControl)
        if RL.key_pressed?(RL::KeyboardKey::N)
          @menu_bar.show_new_project_dialog
        elsif RL.key_pressed?(RL::KeyboardKey::O)
          @menu_bar.show_open_project_dialog
        elsif RL.key_pressed?(RL::KeyboardKey::S)
          @state.save_project
        elsif RL.key_pressed?(RL::KeyboardKey::Z)
          @state.undo
        elsif RL.key_pressed?(RL::KeyboardKey::Y)
          @state.redo
        end
      end

      # Fullscreen toggle with F11
      if RL.key_pressed?(RL::KeyboardKey::F11)
        toggle_fullscreen
      end

      # Tool shortcuts
      if RL.key_pressed?(RL::KeyboardKey::V)
        @state.current_tool = Tool::Select
      elsif RL.key_pressed?(RL::KeyboardKey::M)
        @state.current_tool = Tool::Move
      elsif RL.key_pressed?(RL::KeyboardKey::P)
        @state.current_tool = Tool::Place
      elsif RL.key_pressed?(RL::KeyboardKey::D)
        @state.current_tool = Tool::Delete
      end

      # View shortcuts
      if RL.key_pressed?(RL::KeyboardKey::G)
        @state.show_grid = !@state.show_grid
      elsif RL.key_pressed?(RL::KeyboardKey::H)
        @state.show_hotspots = !@state.show_hotspots
      end

      # Camera controls
      if RL.key_down?(RL::KeyboardKey::Space)
        if RL.mouse_button_down?(RL::MouseButton::Left)
          delta = RL.get_mouse_delta
          @state.camera_x -= delta.x / @state.zoom
          @state.camera_y -= delta.y / @state.zoom
        end
      end

      # Zoom with mouse wheel
      wheel_move = RL.get_mouse_wheel_move
      if wheel_move != 0
        mouse_pos = RL.get_mouse_position
        if mouse_pos.x >= @viewport_x && mouse_pos.x < @viewport_x + @viewport_width &&
           mouse_pos.y >= @viewport_y && mouse_pos.y < @viewport_y + @viewport_height
          if wheel_move > 0
            @state.zoom_in
          else
            @state.zoom_out
          end
        end
      end
    end

    private def calculate_viewport_dimensions
      @viewport_x = TOOL_PALETTE_WIDTH
      @viewport_y = MENU_HEIGHT
      @viewport_width = @window_width - TOOL_PALETTE_WIDTH - PROPERTY_PANEL_WIDTH
      @viewport_height = @window_height - MENU_HEIGHT

      # Update scene editor viewport if it exists
      if @scene_editor
        @scene_editor.update_viewport(@viewport_x, @viewport_y, @viewport_width, @viewport_height)
      end
    end

    private def toggle_fullscreen
      @is_fullscreen = !@is_fullscreen

      if @is_fullscreen
        RL.toggle_fullscreen
        @window_width = RL.get_monitor_width(RL.get_current_monitor)
        @window_height = RL.get_monitor_height(RL.get_current_monitor)
      else
        RL.toggle_fullscreen
        @window_width = DEFAULT_WINDOW_WIDTH
        @window_height = DEFAULT_WINDOW_HEIGHT
      end

      calculate_viewport_dimensions
      @width = @window_width
      @height = @window_height
    end

    def handle_resize(new_width : Int32, new_height : Int32)
      @window_width = new_width
      @window_height = new_height
      @width = new_width
      @height = new_height
      calculate_viewport_dimensions

      # Update scene editor with new viewport (only editor that supports viewport updates)
      @scene_editor.update_viewport(@viewport_x, @viewport_y, @viewport_width, @viewport_height)
    end

    private def cleanup
      RL.close_window
    end
  end
end
