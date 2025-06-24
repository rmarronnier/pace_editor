require "raylib-cr"
require "../core/editor_state"

module PaceEditor::UI
  class BackgroundImportDialog
    property visible : Bool = false
    property selected_file : String? = nil

    @file_list : Array(String) = [] of String
    @current_directory : String = ""
    @scroll_offset : Int32 = 0
    @selected_index : Int32 = -1
    @preview_texture : RL::Texture2D? = nil

    def initialize(@state : Core::EditorState)
      @current_directory = Dir.current
      refresh_file_list
    end

    def show
      @visible = true
      @selected_file = nil
      @selected_index = -1
      refresh_file_list
    end

    def hide
      @visible = false
      unload_preview_texture
    end

    def update
      return unless @visible

      handle_input
      handle_file_selection
    end

    def draw
      return unless @visible

      # Get screen dimensions
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height

      # Dialog background
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      # Modal background
      RL.draw_rectangle(0, 0, screen_width, screen_height,
        RL::Color.new(r: 0, g: 0, b: 0, a: 128))

      # Dialog box
      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height,
        RL::Color.new(r: 50, g: 50, b: 50, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      # Title
      RL.draw_text("Import Background", dialog_x + 20, dialog_y + 20, 20, RL::WHITE)

      # Current directory
      RL.draw_text("Directory: #{File.basename(@current_directory)}", dialog_x + 20, dialog_y + 50, 14, RL::LIGHTGRAY)

      # File list area
      list_y = dialog_y + 80
      list_height = 200
      draw_file_list(dialog_x + 20, list_y, dialog_width - 40, list_height)

      # Preview area
      preview_y = list_y + list_height + 20
      draw_preview(dialog_x + 20, preview_y, dialog_width - 40, 120)

      # Buttons
      button_y = dialog_y + dialog_height - 60
      draw_buttons(dialog_x, button_y, dialog_width)
    end

    private def refresh_file_list
      return unless Dir.exists?(@current_directory)

      @file_list.clear

      # Add parent directory option
      unless @current_directory == Dir.current
        @file_list << ".."
      end

      # Add directories first
      Dir.glob(File.join(@current_directory, "*")).each do |path|
        if Dir.exists?(path)
          @file_list << File.basename(path) + "/"
        end
      end

      # Add image files
      image_extensions = [".png", ".jpg", ".jpeg", ".bmp", ".gif"]
      Dir.glob(File.join(@current_directory, "*")).each do |path|
        if File.file?(path)
          ext = File.extname(path).downcase
          if image_extensions.includes?(ext)
            @file_list << File.basename(path)
          end
        end
      end
    end

    private def draw_file_list(x : Int32, y : Int32, width : Int32, height : Int32)
      # List background
      RL.draw_rectangle(x, y, width, height,
        RL::Color.new(r: 30, g: 30, b: 30, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Draw files
      item_height = 20
      visible_items = height // item_height
      start_index = @scroll_offset
      end_index = [@scroll_offset + visible_items, @file_list.size].min

      (start_index...end_index).each do |i|
        item_y = y + (i - start_index) * item_height

        # Highlight selected item
        if i == @selected_index
          RL.draw_rectangle(x + 2, item_y, width - 4, item_height,
            RL::Color.new(r: 70, g: 130, b: 180, a: 255))
        end

        # File/directory icon and name
        file_name = @file_list[i]
        color = file_name.ends_with?("/") || file_name == ".." ? RL::YELLOW : RL::WHITE
        RL.draw_text(file_name, x + 10, item_y + 2, 14, color)
      end
    end

    private def draw_preview(x : Int32, y : Int32, width : Int32, height : Int32)
      # Preview background
      RL.draw_rectangle(x, y, width, height,
        RL::Color.new(r: 20, g: 20, b: 20, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      if preview = @preview_texture
        # Scale image to fit preview area
        scale = [width.to_f / preview.width, height.to_f / preview.height].min
        scaled_width = (preview.width * scale).to_i
        scaled_height = (preview.height * scale).to_i

        # Center the image
        preview_x = x + (width - scaled_width) // 2
        preview_y = y + (height - scaled_height) // 2

        dest_rect = RL::Rectangle.new(
          x: preview_x.to_f32,
          y: preview_y.to_f32,
          width: scaled_width.to_f32,
          height: scaled_height.to_f32
        )

        source_rect = RL::Rectangle.new(
          x: 0.0_f32,
          y: 0.0_f32,
          width: preview.width.to_f32,
          height: preview.height.to_f32
        )

        RL.draw_texture_pro(preview, source_rect, dest_rect, RL::Vector2.new(0.0_f32, 0.0_f32), 0.0_f32, RL::WHITE)

        # Image info
        info_text = "#{preview.width}x#{preview.height}"
        RL.draw_text(info_text, x + 10, y + height - 20, 12, RL::LIGHTGRAY)
      else
        RL.draw_text("No preview", x + 10, y + 10, 14, RL::GRAY)
      end
    end

    private def draw_buttons(x : Int32, y : Int32, width : Int32)
      button_width = 100
      button_height = 30

      # Cancel button
      cancel_x = x + width - 220
      if draw_button("Cancel", cancel_x, y, button_width, button_height)
        hide
      end

      # Import button (only enabled if file selected)
      import_x = x + width - 110
      import_enabled = !@selected_file.nil?
      import_color = import_enabled ? RL::WHITE : RL::GRAY

      if draw_button("Import", import_x, y, button_width, button_height, import_color) && import_enabled
        import_selected_file
      end
    end

    private def draw_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32, color : RL::Color = RL::WHITE) : Bool
      # Button background
      bg_color = RL::Color.new(r: 60, g: 60, b: 60, a: 255)
      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, color)

      # Button text
      text_width = RL.measure_text(text, 14)
      text_x = x + (width - text_width) // 2
      text_y = y + (height - 14) // 2
      RL.draw_text(text, text_x, text_y, 14, color)

      # Check if clicked
      mouse_pos = RL.get_mouse_position
      if mouse_pos.x >= x && mouse_pos.x <= x + width &&
         mouse_pos.y >= y && mouse_pos.y <= y + height
        if RL.mouse_button_pressed?(RL::MouseButton::Left)
          return true
        end
      end

      false
    end

    private def handle_input
      # Handle mouse clicks in file list
      mouse_pos = RL.get_mouse_position

      # Get screen dimensions
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height

      # Calculate file list area
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      list_x = dialog_x + 20
      list_y = dialog_y + 80
      list_width = dialog_width - 40
      list_height = 200

      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        if mouse_pos.x >= list_x && mouse_pos.x <= list_x + list_width &&
           mouse_pos.y >= list_y && mouse_pos.y <= list_y + list_height
          # Calculate clicked item
          item_height = 20
          clicked_index = @scroll_offset + ((mouse_pos.y - list_y) / item_height).to_i

          if clicked_index >= 0 && clicked_index < @file_list.size
            @selected_index = clicked_index
            handle_item_selection
          end
        end
      end

      # Handle escape key
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        hide
      end
    end

    private def handle_item_selection
      return if @selected_index < 0 || @selected_index >= @file_list.size

      selected_item = @file_list[@selected_index]

      if selected_item == ".."
        # Go to parent directory
        parent_dir = File.dirname(@current_directory)
        if parent_dir != @current_directory
          @current_directory = parent_dir
          refresh_file_list
          @selected_index = -1
          @selected_file = nil
          unload_preview_texture
        end
      elsif selected_item.ends_with?("/")
        # Enter directory
        dir_name = selected_item.rchop
        new_dir = File.join(@current_directory, dir_name)
        if Dir.exists?(new_dir)
          @current_directory = new_dir
          refresh_file_list
          @selected_index = -1
          @selected_file = nil
          unload_preview_texture
        end
      else
        # Select file
        @selected_file = File.join(@current_directory, selected_item)
        load_preview_texture
      end
    end

    private def handle_file_selection
      # Handle double-click to import
      if RL.mouse_button_pressed?(RL::MouseButton::Left) && @selected_file
        # This is a simple implementation - in a full version you'd track double-clicks
      end
    end

    private def load_preview_texture
      return unless file_path = @selected_file
      return unless File.exists?(file_path)

      unload_preview_texture

      begin
        @preview_texture = RL.load_texture(file_path)
      rescue
        # If loading fails, just don't show preview
        @preview_texture = nil
      end
    end

    private def unload_preview_texture
      if preview = @preview_texture
        RL.unload_texture(preview)
        @preview_texture = nil
      end
    end

    private def import_selected_file
      return unless file_path = @selected_file
      return unless project = @state.current_project
      return unless scene = @state.current_scene

      # Copy file to project's backgrounds directory
      bg_dir = File.join(project.project_path, "assets", "backgrounds")
      Dir.mkdir_p(bg_dir) unless Dir.exists?(bg_dir)

      filename = File.basename(file_path)
      dest_path = File.join(bg_dir, filename)

      begin
        File.copy(file_path, dest_path)

        # Set scene background
        scene.background_path = "backgrounds/#{filename}"

        # Close dialog
        hide

        puts "Background imported successfully: #{filename}"
      rescue ex : Exception
        puts "Failed to import background: #{ex.message}"
      end
    end
  end
end
