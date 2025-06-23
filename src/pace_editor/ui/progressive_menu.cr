module PaceEditor::UI
  # Progressive menu system that shows/hides menu items based on context
  # Provides contextual tooltips for disabled items
  class ProgressiveMenu
    include PaceEditor::Constants
    
    property editor_state : Core::EditorState
    property ui_state : UIState
    property menu_items : Hash(String, MenuSection) = Hash(String, MenuSection).new
    
    # Menu positioning and layout
    property menu_bar_rect : RL::Rectangle = RL::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: 0.0_f32, height: MENU_HEIGHT.to_f32)
    property active_menu : String? = nil
    property hover_item : String? = nil
    
    def initialize(@editor_state : Core::EditorState, @ui_state : UIState)
      initialize_menu_structure
    end
    
    
    def draw(screen_width : Int32)
      @menu_bar_rect.width = screen_width.to_f32
      
      # Draw menu bar background
      RL.draw_rectangle_rec(@menu_bar_rect, RL::Color.new(r: 240_u8, g: 240_u8, b: 240_u8, a: 255_u8))
      
      # Draw menu sections
      x_offset = 10.0_f32
      @menu_items.each do |name, section|
        section_width = draw_menu_section(name, section, x_offset)
        x_offset += section_width + 20.0_f32
      end
      
      # Draw active dropdown
      if active = @active_menu
        if section = @menu_items[active]?
          draw_dropdown_menu(section)
        end
      end
      
      # Draw tooltips for disabled items
      draw_tooltips
    end
    
    def handle_input(mouse_pos : RL::Vector2, mouse_clicked : Bool) : Bool
      # Check if mouse is over menu bar
      return false unless PaceEditor::Constants.point_in_rect?(mouse_pos, @menu_bar_rect)
      
      # Check menu section clicks
      x_offset = 10.0_f32
      @menu_items.each do |name, section|
        section_rect = RL::Rectangle.new(x: x_offset, y: 0.0_f32, width: section.width, height: MENU_HEIGHT.to_f32)
        
        if PaceEditor::Constants.point_in_rect?(mouse_pos, section_rect)
          @hover_item = name
          
          if mouse_clicked && section.visible?(@editor_state, @ui_state)
            toggle_menu(name)
            return true
          end
        end
        
        x_offset += section.width + 20.0_f32
      end
      
      # Check dropdown item clicks
      if active = @active_menu
        if section = @menu_items[active]?
          if handle_dropdown_click(section, mouse_pos, mouse_clicked)
            return true
          end
        end
      end
      
      # Close menu if clicked outside
      if mouse_clicked
        close_menu
      end
      
      false
    end
    
    private def initialize_menu_structure
      # File menu
      file_items = [] of MenuItemBase
      
      file_items << MenuItem.new("new_project", "New Project", "Create a new game project") do
        @editor_state.show_new_project_dialog = true
      end.as(MenuItemBase)
      
      file_items << MenuItem.new("open_project", "Open Project", "Open an existing project") do
          if window = @editor_state.editor_window
            window.show_project_file_dialog(open: true)
          end
        end.as(MenuItemBase)
        
      file_items << MenuSeparator.new.as(MenuItemBase)
      
      file_items << MenuItem.new("save_project", "Save Project", "Save current project",
          visibility_check: ->(state : Core::EditorState, ui : UIState) { ComponentVisibility.should_show_file_save?(state) }) do
          @editor_state.save_project
        end.as(MenuItemBase)
        
      file_items << MenuItem.new("save_as", "Save As...", "Save project with new name",
          visibility_check: ->(state : Core::EditorState, ui : UIState) { state.has_project? }) do
          if window = @editor_state.editor_window
            window.show_project_file_dialog(open: false)
          end
        end.as(MenuItemBase)
        
      file_items << MenuSeparator.new.as(MenuItemBase)
      
      file_items << MenuItem.new("export_game", "Export Game", "Export playable game",
          visibility_check: ->(state : Core::EditorState, ui : UIState) { ComponentVisibility.should_show_file_export?(state) }) do
          if window = @editor_state.editor_window
            window.show_game_export_dialog
          end
        end.as(MenuItemBase)
        
      file_items << MenuSeparator.new.as(MenuItemBase)
      
      file_items << MenuItem.new("exit", "Exit", "Exit PACE Editor") do
          # Set flag to close window on next frame
          @editor_state.should_exit = true
        end.as(MenuItemBase)
      
      @menu_items["File"] = MenuSection.new("File", file_items)
      
      # Edit menu
      edit_items = [] of MenuItemBase
      
      edit_items << MenuItem.new("undo", "Undo", "Undo last action",
          visibility_check: ->(state : Core::EditorState, ui : UIState) { ComponentVisibility.should_show_edit_undo?(state) }) do
          @editor_state.undo
        end.as(MenuItemBase)
        
      edit_items << MenuItem.new("redo", "Redo", "Redo last undone action",
          visibility_check: ->(state : Core::EditorState, ui : UIState) { ComponentVisibility.should_show_edit_redo?(state) }) do
          @editor_state.redo
        end.as(MenuItemBase)
        
      edit_items << MenuSeparator.new.as(MenuItemBase)
      
      edit_items << MenuItem.new("preferences", "Preferences", "Open preferences") do
          # Show preferences dialog
        end.as(MenuItemBase)
        
      edit_items << MenuItem.new("power_mode", "Power Mode", "Toggle advanced user mode") do
          @ui_state.toggle_power_mode
        end.as(MenuItemBase)
      
      @menu_items["Edit"] = MenuSection.new("Edit", edit_items,
        visibility_check: ->(state : Core::EditorState, ui : UIState) { state.has_project? })
      
      # Scene menu
      scene_items = [] of MenuItemBase
      
      scene_items << MenuItem.new("new_scene", "New Scene", "Create a new scene") do
          if window = @editor_state.editor_window
            window.show_scene_creation_wizard
          end
        end.as(MenuItemBase)
        
      scene_items << MenuItem.new("duplicate_scene", "Duplicate Scene", "Duplicate current scene",
          visibility_check: ->(state : Core::EditorState, ui : UIState) { !state.current_scene.nil? }) do
          if scene = @editor_state.current_scene
            @editor_state.duplicate_scene(scene.name)
            @ui_state.track_action("scene_duplicated")
          end
        end.as(MenuItemBase)
        
      scene_items << MenuItem.new("delete_scene", "Delete Scene", "Delete current scene",
          visibility_check: ->(state : Core::EditorState, ui : UIState) { !state.current_scene.nil? }) do
          if scene = @editor_state.current_scene
            if window = @editor_state.editor_window
              window.show_confirm_dialog("Delete Scene", "Are you sure you want to delete scene '#{scene.name}'?") do
                @editor_state.delete_scene(scene.name)
                @ui_state.track_action("scene_deleted")
              end
            end
          end
        end.as(MenuItemBase)
        
      scene_items << MenuSeparator.new.as(MenuItemBase)
      
      scene_items << MenuItem.new("scene_properties", "Scene Properties", "Edit scene properties",
          visibility_check: ->(state : Core::EditorState, ui : UIState) { ComponentVisibility.should_show_scene_properties?(state) }) do
          # Switch to scene mode to show properties in property panel
          if window = @editor_state.editor_window
            window.switch_mode(PaceEditor::EditorMode::Scene)
          end
        end.as(MenuItemBase)
      
      @menu_items["Scene"] = MenuSection.new("Scene", scene_items,
        visibility_check: ->(state : Core::EditorState, ui : UIState) { ComponentVisibility.should_show_scene_menu?(state) })
      
      # Character menu
      character_items = [] of MenuItemBase
      
      character_items << MenuItem.new("add_player", "Add Player", "Add player character") do
          if scene = @editor_state.current_scene
            @editor_state.add_player_character(scene)
            @ui_state.track_action("player_added")
          end
        end.as(MenuItemBase)
        
      character_items << MenuItem.new("add_npc", "Add NPC", "Add non-player character") do
          if scene = @editor_state.current_scene
            @editor_state.add_npc_character(scene)
            @ui_state.track_action("npc_added")
          end
        end.as(MenuItemBase)
        
      character_items << MenuSeparator.new.as(MenuItemBase)
      
      character_items << MenuItem.new("import_character", "Import Character", "Import character sprite") do
          if window = @editor_state.editor_window
            window.show_asset_import_dialog("characters")
          end
        end.as(MenuItemBase)
        
      character_items << MenuItem.new("character_animations", "Edit Animations", "Edit character animations",
          visibility_check: ->(state : Core::EditorState, ui : UIState) { !state.selected_object.nil? }) do
          if selected = @editor_state.selected_object
            if window = @editor_state.editor_window
              window.show_animation_editor(selected)
            end
          end
        end.as(MenuItemBase)
      
      @menu_items["Character"] = MenuSection.new("Character", character_items,
        visibility_check: ->(state : Core::EditorState, ui : UIState) { ComponentVisibility.should_show_character_menu?(state) })
      
      # Dialog menu
      dialog_items = [] of MenuItemBase
      
      dialog_items << MenuItem.new("new_dialog", "New Dialog", "Create new dialog tree") do
          if window = @editor_state.editor_window
            window.switch_mode(PaceEditor::EditorMode::Dialog)
            @ui_state.track_action("new_dialog_started")
          end
        end.as(MenuItemBase)
        
      dialog_items << MenuItem.new("edit_dialog", "Edit Dialog", "Edit existing dialog",
          visibility_check: ->(state : Core::EditorState, ui : UIState) { ComponentVisibility.should_show_dialog_properties?(state) }) do
          if selected = @editor_state.selected_object
            if window = @editor_state.editor_window
              window.show_dialog_editor_for_character(selected)
            end
          end
        end.as(MenuItemBase)
        
      dialog_items << MenuItem.new("test_dialog", "Test Dialog", "Test dialog in preview",
          visibility_check: ->(state : Core::EditorState, ui : UIState) { ComponentVisibility.should_show_dialog_properties?(state) }) do
          if selected = @editor_state.selected_object
            @editor_state.test_dialog(selected)
            @ui_state.track_action("dialog_tested")
          end
        end.as(MenuItemBase)
      
      @menu_items["Dialog"] = MenuSection.new("Dialog", dialog_items,
        visibility_check: ->(state : Core::EditorState, ui : UIState) { ComponentVisibility.should_show_dialog_menu?(state) })
      
      # Tools menu
      tools_items = [] of MenuItemBase
      
      tools_items << MenuItem.new("asset_browser", "Asset Browser", "Open asset browser") do
          @editor_state.current_mode = EditorMode::Assets
        end.as(MenuItemBase)
        
      tools_items << MenuItem.new("script_editor", "Script Editor", "Open script editor") do
          @editor_state.current_mode = EditorMode::Script
        end.as(MenuItemBase)
        
      tools_items << MenuSeparator.new.as(MenuItemBase)
      
      tools_items << MenuItem.new("validate_project", "Validate Project", "Check project for errors",
          visibility_check: ->(state : Core::EditorState, ui : UIState) { state.has_project? }) do
          # Validate project logic
        end.as(MenuItemBase)
        
      tools_items << MenuItem.new("optimize_assets", "Optimize Assets", "Optimize project assets",
          visibility_check: ->(state : Core::EditorState, ui : UIState) { ComponentVisibility.should_show_asset_browser?(state) }) do
          # Optimize assets logic
        end.as(MenuItemBase)
      
      @menu_items["Tools"] = MenuSection.new("Tools", tools_items,
        visibility_check: ->(state : Core::EditorState, ui : UIState) { state.has_project? })
      
      # Help menu
      help_items = [] of MenuItemBase
      
      help_items << MenuItem.new("documentation", "Documentation", "Open documentation") do
          # Open documentation logic
        end.as(MenuItemBase)
        
      help_items << MenuItem.new("tutorials", "Tutorials", "View tutorials") do
          # Show tutorials logic
        end.as(MenuItemBase)
        
      help_items << MenuItem.new("shortcuts", "Keyboard Shortcuts", "View keyboard shortcuts") do
          # Show shortcuts logic
        end.as(MenuItemBase)
        
      help_items << MenuSeparator.new.as(MenuItemBase)
      
      help_items << MenuItem.new("about", "About", "About PACE Editor") do
          # Show about dialog
        end.as(MenuItemBase)
      
      @menu_items["Help"] = MenuSection.new("Help", help_items)
    end
    
    private def draw_menu_section(name : String, section : MenuSection, x_offset : Float32) : Float32
      section.update_layout(x_offset, 0.0_f32)
      
      # Determine if section should be visible
      visible = section.visible?(@editor_state, @ui_state)
      disabled = !visible && !@ui_state.power_mode
      
      # Choose colors based on state
      text_color = if disabled
        RL::Color.new(r: 128_u8, g: 128_u8, b: 128_u8, a: 255_u8)
      elsif @hover_item == name
        RL::Color.new(r: 50_u8, g: 50_u8, b: 50_u8, a: 255_u8)
      else
        RL::Color.new(r: 0_u8, g: 0_u8, b: 0_u8, a: 255_u8)
      end
      
      # Draw section name
      RL.draw_text(name, x_offset.to_i, 8, 14, text_color)
      
      # Show tooltip for disabled sections
      if disabled && @hover_item == name
        reason = get_section_disabled_reason(name)
        @ui_state.show_tooltip(reason, RL::Vector2.new(x_offset, MENU_HEIGHT.to_f32))
      end
      
      section.width
    end
    
    private def draw_dropdown_menu(section : MenuSection)
      return unless section.dropdown_visible
      
      # Calculate dropdown position and size
      dropdown_width = 200.0_f32
      dropdown_height = section.visible_items(@editor_state, @ui_state).size * 25.0_f32
      dropdown_x = section.x
      dropdown_y = MENU_HEIGHT.to_f32
      
      dropdown_rect = RL::Rectangle.new(x: dropdown_x, y: dropdown_y, width: dropdown_width, height: dropdown_height)
      
      # Draw dropdown background
      RL.draw_rectangle_rec(dropdown_rect, RL::Color.new(r: 250_u8, g: 250_u8, b: 250_u8, a: 255_u8))
      RL.draw_rectangle_lines_ex(dropdown_rect, 1.0_f32, RL::Color.new(r: 200_u8, g: 200_u8, b: 200_u8, a: 255_u8))
      
      # Draw menu items
      y_offset = dropdown_y + 5.0_f32
      section.visible_items(@editor_state, @ui_state).each do |item|
        item_rect = RL::Rectangle.new(x: dropdown_x + 5.0_f32, y: y_offset, width: dropdown_width - 10.0_f32, height: 20.0_f32)
        
        case item
        when MenuItem
          draw_menu_item(item.as(MenuItem), item_rect)
        when MenuSeparator
          draw_menu_separator(item_rect)
        end
        
        y_offset += 25.0_f32
      end
    end
    
    private def draw_menu_item(item : MenuItem, rect : RL::Rectangle)
      # Check if item is available
      available = item.visible?(@editor_state, @ui_state)
      
      # Hover effect
      mouse_pos = RL.get_mouse_position
      hovered = PaceEditor::Constants.point_in_rect?(mouse_pos, rect)
      
      if hovered && available
        RL.draw_rectangle_rec(rect, RL::Color.new(r: 230_u8, g: 230_u8, b: 255_u8, a: 255_u8))
      end
      
      # Text color based on availability
      text_color = if available
        RL::Color.new(r: 0_u8, g: 0_u8, b: 0_u8, a: 255_u8)
      else
        RL::Color.new(r: 128_u8, g: 128_u8, b: 128_u8, a: 255_u8)
      end
      
      # Draw item text
      RL.draw_text(item.label, (rect.x + 5).to_i, (rect.y + 2).to_i, 12, text_color)
      
      # Show tooltip for disabled items
      if hovered && !available
        reason = ComponentVisibility.get_visibility_reason(item.id, @editor_state) || "Not available in current context"
        @ui_state.show_tooltip(reason, RL::Vector2.new(rect.x + rect.width, rect.y))
      end
    end
    
    private def draw_menu_separator(rect : RL::Rectangle)
      line_y = rect.y + rect.height / 2
      RL.draw_line(
        (rect.x + 10).to_i, line_y.to_i,
        (rect.x + rect.width - 10).to_i, line_y.to_i,
        RL::Color.new(r: 200_u8, g: 200_u8, b: 200_u8, a: 255_u8)
      )
    end
    
    private def draw_tooltips
      return unless @ui_state.has_active_tooltip?
      
      if tooltip = @ui_state.active_tooltip
        if pos = @ui_state.tooltip_position
          draw_tooltip(tooltip, pos)
        end
      end
    end
    
    private def draw_tooltip(text : String, position : RL::Vector2)
      # Measure text
      text_width = RL.measure_text(text, 12)
      tooltip_width = text_width + 20
      tooltip_height = 30
      
      # Position tooltip (avoid screen edges)
      tooltip_x = Math.max(5.0_f32, Math.min(position.x, RL.get_screen_width - tooltip_width - 5))
      tooltip_y = position.y + 20.0_f32
      
      tooltip_rect = RL::Rectangle.new(x: tooltip_x, y: tooltip_y, width: tooltip_width.to_f32, height: tooltip_height.to_f32)
      
      # Draw tooltip background
      RL.draw_rectangle_rec(tooltip_rect, RL::Color.new(r: 255_u8, g: 255_u8, b: 220_u8, a: 240_u8))
      RL.draw_rectangle_lines_ex(tooltip_rect, 1.0_f32, RL::Color.new(r: 150_u8, g: 150_u8, b: 100_u8, a: 255_u8))
      
      # Draw tooltip text
      RL.draw_text(text, (tooltip_x + 10).to_i, (tooltip_y + 9).to_i, 12, RL::Color.new(r: 0_u8, g: 0_u8, b: 0_u8, a: 255_u8))
    end
    
    private def handle_dropdown_click(section : MenuSection, mouse_pos : RL::Vector2, clicked : Bool) : Bool
      return false unless section.dropdown_visible && clicked
      
      # Check each visible item
      y_offset = MENU_HEIGHT.to_f32 + 5.0_f32
      section.visible_items(@editor_state, @ui_state).each do |item|
        item_rect = RL::Rectangle.new(x: section.x + 5.0_f32, y: y_offset, width: 190.0_f32, height: 20.0_f32)
        
        if PaceEditor::Constants.point_in_rect?(mouse_pos, item_rect)
          if item.is_a?(MenuItem)
            menu_item = item.as(MenuItem)
            if menu_item.visible?(@editor_state, @ui_state)
              menu_item.action.call
              close_menu
              return true
            end
          end
        end
        
        y_offset += 25.0_f32
      end
      
      false
    end
    
    private def toggle_menu(name : String)
      if @active_menu == name
        close_menu
      else
        @active_menu = name
        if section = @menu_items[name]?
          section.dropdown_visible = true
        end
      end
    end
    
    private def close_menu
      if active = @active_menu
        if section = @menu_items[active]?
          section.dropdown_visible = false
        end
      end
      @active_menu = nil
      @ui_state.hide_tooltip
    end
    
    private def get_section_disabled_reason(section_name : String) : String
      case section_name
      when "Edit"
        "Create or open a project to access editing tools"
      when "Scene"
        "Create or open a project to work with scenes"
      when "Character"
        "Create a scene to add characters"
      when "Dialog"
        "Add NPC characters to create dialogs"
      when "Tools"
        "Create or open a project to access tools"
      else
        "Not available in current context"
      end
    end
  end
  
  # Menu structure classes
  
  class MenuSection
    property name : String
    property items : Array(MenuItemBase)
    property x : Float32 = 0.0_f32
    property y : Float32 = 0.0_f32
    property width : Float32 = 0.0_f32
    property dropdown_visible : Bool = false
    property visibility_check : Proc(Core::EditorState, UIState, Bool)?
    
    def initialize(@name : String, @items : Array(MenuItemBase), @visibility_check = nil)
      @width = RL.measure_text(@name, 14).to_f32 + 10.0_f32
    end
    
    def visible?(editor_state : Core::EditorState, ui_state : UIState) : Bool
      if check = @visibility_check
        check.call(editor_state, ui_state)
      else
        true
      end
    end
    
    def visible_items(editor_state : Core::EditorState, ui_state : UIState) : Array(MenuItemBase)
      if ui_state.power_mode
        @items
      else
        @items.select { |item| item.visible?(editor_state, ui_state) }
      end
    end
    
    def update_layout(x : Float32, y : Float32)
      @x = x
      @y = y
    end
  end
  
  abstract class MenuItemBase
    abstract def visible?(editor_state : Core::EditorState, ui_state : UIState) : Bool
  end
  
  class MenuItem < MenuItemBase
    property id : String
    property label : String
    property description : String
    property action : Proc(Nil)
    property visibility_check : Proc(Core::EditorState, UIState, Bool)?
    
    def initialize(@id : String, @label : String, @description : String, @visibility_check = nil, &@action : -> Nil)
    end
    
    def visible?(editor_state : Core::EditorState, ui_state : UIState) : Bool
      if check = @visibility_check
        check.call(editor_state, ui_state)
      else
        true
      end
    end
  end
  
  class MenuSeparator < MenuItemBase
    def visible?(editor_state : Core::EditorState, ui_state : UIState) : Bool
      true
    end
  end
end