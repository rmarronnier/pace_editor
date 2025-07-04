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

    # Dialog systems
    property confirm_dialog : ConfirmDialog?

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

      # Initialize dialogs
      @confirm_dialog = nil

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
      return unless project = @state.current_project
      
      # Switch to dialog mode and set the dialog editor to edit this character's dialog
      switch_mode(PaceEditor::EditorMode::Dialog)
      @ui_state.track_action("dialog_editor_opened")
      
      # Load or create dialog tree for the character
      dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
      
      # Create dialogs directory if it doesn't exist
      Dir.mkdir_p(project.dialogs_path) unless Dir.exists?(project.dialogs_path)
      
      # If dialog file doesn't exist, create a default one
      unless File.exists?(dialog_path)
        create_default_dialog_for_character(character_name, dialog_path)
      end
      
      # Load the dialog into the dialog editor
      begin
        yaml_content = File.read(dialog_path)
        @dialog_editor.current_dialog = PointClickEngine::Characters::Dialogue::DialogTree.from_yaml(yaml_content)
      rescue ex : Exception
        puts "Error loading dialog file #{dialog_path}: #{ex.message}"
        # Create a new dialog as fallback
        @dialog_editor.current_dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("#{character_name}_dialog")
      end
      
      puts "Opened dialog editor for character: #{character_name}"
      puts "Dialog file: #{dialog_path}"
    end

    private def create_default_dialog_for_character(character_name : String, dialog_path : String)
      # Create a simple default dialog tree
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("#{character_name}_dialog")
      
      # Create start node
      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "start", 
        "Hello! I'm #{character_name}. What can I do for you?"
      )
      
      # Create goodbye node
      goodbye_node = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "goodbye",
        "See you later!"
      )
      
      # Create info node
      info_node = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "info",
        "I'm just a character in this game. Feel free to talk to me anytime!"
      )
      
      # Add choices to start node
      choice_goodbye = PointClickEngine::Characters::Dialogue::DialogChoice.new(
        "Goodbye",
        "goodbye"
      )
      choice_info = PointClickEngine::Characters::Dialogue::DialogChoice.new(
        "Tell me about yourself",
        "info"
      )
      
      start_node.choices << choice_goodbye
      start_node.choices << choice_info
      
      # Add choice from info back to start
      choice_continue = PointClickEngine::Characters::Dialogue::DialogChoice.new(
        "That's interesting. What else?",
        "start"
      )
      info_node.choices << choice_continue
      info_node.choices << choice_goodbye
      
      # Add nodes to dialog tree
      dialog_tree.nodes["start"] = start_node
      dialog_tree.nodes["goodbye"] = goodbye_node
      dialog_tree.nodes["info"] = info_node
      
      # Save to file
      File.write(dialog_path, dialog_tree.to_yaml)
      
      puts "Created default dialog file for character '#{character_name}' at #{dialog_path}"
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

    def show_project_file_dialog(open : Bool)
      # Show file dialog for opening or saving projects
      if open
        puts "EditorWindow: Showing open project dialog"
        @menu_bar.show_open_project_dialog
        @ui_state.track_action("open_project_dialog_shown")
      else
        puts "EditorWindow: Showing save project dialog"
        @menu_bar.show_save_project_dialog
        @ui_state.track_action("save_as_dialog_shown")
      end
    end

    def show_confirm_dialog(title : String, message : String, &callback : -> Nil)
      @confirm_dialog = ConfirmDialog.new(title, message, callback)
    end

    def show_animation_editor(character_name : String)
      # TODO: Implement animation editor
      puts "Animation editor would open for character: #{character_name}"
      @ui_state.track_action("animation_editor_opened")
    end

    def run
      # Initialize Raylib
      RL.init_window(@window_width, @window_height, "PACE - Point & Click Adventure Creator Editor")
      RL.set_window_state(RL::ConfigFlags::WindowResizable)
      RL.set_target_fps(60)

      # Main loop
      while !RL.close_window? && !@state.should_exit
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

      # Check guided workflow input (handles both getting started panel and tutorials)
      if @guided_workflow.handle_input(mouse_pos, mouse_clicked)
        return # Input consumed by guided workflow
      end

      # Check progressive menu input
      if @progressive_menu.handle_input(mouse_pos, mouse_clicked)
        return # Input consumed by progressive menu
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

      # Clean up finished confirm dialog
      if dialog = @confirm_dialog
        unless dialog.visible?
          @confirm_dialog = nil
        end
      end
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

      # Draw new project dialog if needed
      if @state.show_new_project_dialog
        draw_new_project_dialog
      end

      # Draw menu bar dialogs (open project, etc)
      @menu_bar.draw

      # Draw confirm dialog if active
      if dialog = @confirm_dialog
        dialog.draw
      end

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
        if scene = @state.current_scene
          parts << "Scene: #{scene.name}"
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

      # Update all editor viewports if they exist
      if @scene_editor
        @scene_editor.update_viewport(@viewport_x, @viewport_y, @viewport_width, @viewport_height)
      end
      if @character_editor
        @character_editor.update_viewport(@viewport_x, @viewport_y, @viewport_width, @viewport_height)
      end
      if @hotspot_editor
        @hotspot_editor.update_viewport(@viewport_x, @viewport_y, @viewport_width, @viewport_height)
      end
      if @dialog_editor
        @dialog_editor.update_viewport(@viewport_x, @viewport_y, @viewport_width, @viewport_height)
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

      # Update all editors with new viewport
      @scene_editor.update_viewport(@viewport_x, @viewport_y, @viewport_width, @viewport_height)
      @character_editor.update_viewport(@viewport_x, @viewport_y, @viewport_width, @viewport_height)
      @hotspot_editor.update_viewport(@viewport_x, @viewport_y, @viewport_width, @viewport_height)
      @dialog_editor.update_viewport(@viewport_x, @viewport_y, @viewport_width, @viewport_height)
    end

    private def cleanup
      # Clean up current scene resources
      @state.cleanup_current_scene

      # Clean up texture cache
      Core::TextureCache.cleanup if @state.current_project

      RL.close_window
    end

    private def draw_new_project_dialog
      # Get screen dimensions
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height

      # Draw modal background
      RL.draw_rectangle(0, 0, screen_width, screen_height, RL::Color.new(r: 0, g: 0, b: 0, a: 180))

      # Dialog dimensions
      dialog_width = 400
      dialog_height = 200
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      # Draw dialog background
      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height, RL::Color.new(r: 60, g: 60, b: 60, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      # Title
      title = "New Project"
      title_width = RL.measure_text(title, 20)
      RL.draw_text(title, dialog_x + (dialog_width - title_width) // 2, dialog_y + 20, 20, RL::WHITE)

      # Project name input
      RL.draw_text("Project Name:", dialog_x + 20, dialog_y + 60, 16, RL::WHITE)

      # Simple text display for now (input handling would be added)
      name_box_y = dialog_y + 85
      RL.draw_rectangle(dialog_x + 20, name_box_y, dialog_width - 40, 30, RL::Color.new(r: 40, g: 40, b: 40, a: 255))
      RL.draw_rectangle_lines(dialog_x + 20, name_box_y, dialog_width - 40, 30, RL::LIGHTGRAY)

      if @state.new_project_name.empty?
        RL.draw_text("Enter project name...", dialog_x + 25, name_box_y + 8, 14, RL::GRAY)
      else
        RL.draw_text(@state.new_project_name, dialog_x + 25, name_box_y + 8, 14, RL::WHITE)
      end

      # Buttons
      button_width = 80
      button_height = 30
      button_y = dialog_y + dialog_height - 50

      # Create button
      create_button_x = dialog_x + dialog_width - button_width * 2 - 30
      create_button_rect = RL::Rectangle.new(x: create_button_x.to_f32, y: button_y.to_f32,
        width: button_width.to_f32, height: button_height.to_f32)

      mouse_pos = RL.get_mouse_position
      create_hovered = PaceEditor::Constants.point_in_rect?(mouse_pos, create_button_rect)

      RL.draw_rectangle_rec(create_button_rect, create_hovered ? RL::Color.new(r: 100, g: 150, b: 255, a: 255) : RL::Color.new(r: 80, g: 120, b: 200, a: 255))
      RL.draw_text("Create", create_button_x + 20, button_y + 8, 14, RL::WHITE)

      # Cancel button
      cancel_button_x = dialog_x + dialog_width - button_width - 20
      cancel_button_rect = RL::Rectangle.new(x: cancel_button_x.to_f32, y: button_y.to_f32,
        width: button_width.to_f32, height: button_height.to_f32)

      cancel_hovered = PaceEditor::Constants.point_in_rect?(mouse_pos, cancel_button_rect)

      RL.draw_rectangle_rec(cancel_button_rect, cancel_hovered ? RL::LIGHTGRAY : RL::GRAY)
      RL.draw_text("Cancel", cancel_button_x + 20, button_y + 8, 14, RL::WHITE)

      # Handle input
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        if create_hovered && !@state.new_project_name.empty?
          # Create the project
          if @state.create_new_project(@state.new_project_name, Dir.current)
            @state.show_new_project_dialog = false
            @state.new_project_name = ""
            @ui_state.track_action("project_created")
          end
        elsif cancel_hovered
          @state.show_new_project_dialog = false
          @state.new_project_name = ""
        end
      end

      # Handle text input
      key = RL.get_char_pressed
      while key > 0
        if key >= 32 && key <= 126 # Printable characters
          @state.new_project_name += key.chr
        end
        key = RL.get_char_pressed
      end

      # Handle backspace
      if RL.key_pressed?(RL::KeyboardKey::Backspace) && !@state.new_project_name.empty?
        @state.new_project_name = @state.new_project_name[0...-1]
      end

      # Handle enter key
      if RL.key_pressed?(RL::KeyboardKey::Enter) && !@state.new_project_name.empty?
        if @state.create_new_project(@state.new_project_name, Dir.current)
          @state.show_new_project_dialog = false
          @state.new_project_name = ""
          @ui_state.track_action("project_created")
        end
      end

      # Handle escape key
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        @state.show_new_project_dialog = false
        @state.new_project_name = ""
      end
    end
  end

  # Simple confirmation dialog class
  class ConfirmDialog
    def initialize(@title : String, @message : String, @callback : -> Nil)
      @visible = true
    end

    def draw
      return unless @visible

      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      dialog_width = 400
      dialog_height = 200
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      # Modal overlay
      RL.draw_rectangle(0, 0, screen_width, screen_height,
        RL::Color.new(r: 0, g: 0, b: 0, a: 128))

      # Dialog background
      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height,
        RL::Color.new(r: 60, g: 60, b: 60, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      # Title
      RL.draw_text(@title, dialog_x + 20, dialog_y + 20, 18, RL::WHITE)

      # Message
      RL.draw_text(@message, dialog_x + 20, dialog_y + 60, 14, RL::LIGHTGRAY)

      # Buttons
      if draw_button("OK", dialog_x + dialog_width - 160, dialog_y + dialog_height - 50, 70, 30, RL::GREEN)
        @callback.call
        @visible = false
      end

      if draw_button("Cancel", dialog_x + dialog_width - 80, dialog_y + dialog_height - 50, 70, 30, RL::RED)
        @visible = false
      end

      # Handle Escape key
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        @visible = false
      end
    end

    def visible?
      @visible
    end

    private def draw_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32, color : RL::Color) : Bool
      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      button_color = is_hover ? RL::Color.new(r: color.r + 20, g: color.g + 20, b: color.b + 20, a: 255) : color
      RL.draw_rectangle(x, y, width, height, button_color)
      RL.draw_rectangle_lines(x, y, width, height, RL::WHITE)

      text_width = RL.measure_text(text, 14)
      text_x = x + (width - text_width) // 2
      text_y = y + (height - 14) // 2
      RL.draw_text(text, text_x, text_y, 14, RL::WHITE)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end
  end
end
