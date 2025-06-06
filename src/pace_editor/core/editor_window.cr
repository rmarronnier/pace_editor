require "raylib-cr"

module PaceEditor::Core
  # Main editor window that coordinates all UI elements and editors
  class EditorWindow
    WINDOW_WIDTH          = 1400
    WINDOW_HEIGHT         =  900
    MENU_HEIGHT           =   30
    TOOL_PALETTE_WIDTH    =   80
    PROPERTY_PANEL_WIDTH  =  300
    SCENE_HIERARCHY_WIDTH =  250

    property state : EditorState
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

    # Editor viewport
    @viewport_x : Int32
    @viewport_y : Int32
    @viewport_width : Int32
    @viewport_height : Int32

    def initialize
      @state = EditorState.new

      # Calculate viewport dimensions
      @viewport_x = TOOL_PALETTE_WIDTH
      @viewport_y = MENU_HEIGHT
      @viewport_width = WINDOW_WIDTH - TOOL_PALETTE_WIDTH - PROPERTY_PANEL_WIDTH
      @viewport_height = WINDOW_HEIGHT - MENU_HEIGHT

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
    end

    def run
      # Initialize Raylib
      RL.init_window(WINDOW_WIDTH, WINDOW_HEIGHT, "PACE - Point & Click Adventure Creator Editor")
      RL.set_target_fps(60)

      # Main loop
      while !RL.close_window?
        update
        draw
      end

      cleanup
    end

    private def update
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

      # Update UI components
      @menu_bar.update
      @tool_palette.update
      @property_panel.update
      @scene_hierarchy.update
      @asset_browser.update if @state.current_mode.assets?
    end

    private def draw
      RL.begin_drawing
      RL.clear_background(RL::Color.new(r: 50, g: 50, b: 50, a: 255))

      # Draw menu bar
      @menu_bar.draw

      # Draw tool palette
      @tool_palette.draw

      # Draw main editor area
      draw_editor_viewport

      # Draw side panels
      @scene_hierarchy.draw
      @property_panel.draw

      # Draw asset browser if in assets mode
      @asset_browser.draw if @state.current_mode.assets?

      # Draw status bar
      draw_status_bar

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
      status_y = WINDOW_HEIGHT - 25
      RL.draw_rectangle(0, status_y, WINDOW_WIDTH, 25, RL::Color.new(r: 30, g: 30, b: 30, a: 255))

      status_text = build_status_text
      RL.draw_text(status_text, 10, status_y + 5, 12, RL::LIGHTGRAY)

      # Draw mode indicator
      mode_text = @state.current_mode.to_s
      mode_width = RL.measure_text(mode_text, 12)
      RL.draw_text(mode_text, WINDOW_WIDTH - mode_width - 10, status_y + 5, 12, RL::YELLOW)
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

    private def cleanup
      RL.close_window
    end
  end
end
