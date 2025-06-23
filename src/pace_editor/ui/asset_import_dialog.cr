require "raylib-cr"
require "../core/editor_state"

module PaceEditor::UI
  class AssetImportDialog
    property visible : Bool = false
    property selected_files : Array(String) = [] of String
    property asset_category : String = "backgrounds"
    
    @file_list : Array(String) = [] of String
    @current_directory : String = ""
    @scroll_offset : Int32 = 0
    @selected_indices : Array(Int32) = [] of Int32
    @preview_textures : Hash(String, RL::Texture2D) = {} of String => RL::Texture2D

    def initialize(@state : Core::EditorState)
      @current_directory = Dir.current
      refresh_file_list
    end

    def show(category : String = "backgrounds")
      @visible = true
      @asset_category = category
      @selected_files.clear
      @selected_indices.clear
      refresh_file_list
    end

    def hide
      @visible = false
      unload_preview_textures
    end

    def update
      return unless @visible
      
      handle_input
    end

    def draw
      return unless @visible

      # Dialog background
      dialog_width = 700
      dialog_height = 600
      dialog_x = (Core::EditorWindow::WINDOW_WIDTH - dialog_width) // 2
      dialog_y = (Core::EditorWindow::WINDOW_HEIGHT - dialog_height) // 2

      # Modal background
      RL.draw_rectangle(0, 0, Core::EditorWindow::WINDOW_WIDTH, Core::EditorWindow::WINDOW_HEIGHT,
        RL::Color.new(r: 0, g: 0, b: 0, a: 128))

      # Dialog box
      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height,
        RL::Color.new(r: 50, g: 50, b: 50, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      # Title
      title = "Import #{@asset_category.capitalize} Assets"
      RL.draw_text(title, dialog_x + 20, dialog_y + 20, 20, RL::WHITE)

      # Current directory
      RL.draw_text("Directory: #{File.basename(@current_directory)}", dialog_x + 20, dialog_y + 50, 14, RL::LIGHTGRAY)

      # File list area
      list_y = dialog_y + 80
      list_height = 300
      draw_file_list(dialog_x + 20, list_y, dialog_width - 40, list_height)

      # Selected files info
      info_y = list_y + list_height + 10
      draw_selected_info(dialog_x + 20, info_y, dialog_width - 40)

      # Preview area (for images)
      if @asset_category == "backgrounds" || @asset_category == "characters"
        preview_y = info_y + 40
        draw_preview_grid(dialog_x + 20, preview_y, dialog_width - 40, 80)
      end

      # Buttons
      button_y = dialog_y + dialog_height - 60
      draw_buttons(dialog_x, button_y, dialog_width)
    end

    private def get_supported_extensions : Array(String)
      case @asset_category
      when "backgrounds", "characters"
        [".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tga"]
      when "sounds"
        [".wav", ".ogg", ".mp3", ".flac"]
      when "music"
        [".ogg", ".mp3", ".wav", ".flac"]
      when "scripts"
        [".lua", ".cr"]
      else
        [] of String
      end
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
      
      # Add supported files
      supported_extensions = get_supported_extensions
      Dir.glob(File.join(@current_directory, "*")).each do |path|
        if File.file?(path)
          ext = File.extname(path).downcase
          if supported_extensions.includes?(ext)
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
        
        # Highlight selected items
        if @selected_indices.includes?(i)
          RL.draw_rectangle(x + 2, item_y, width - 4, item_height,
            RL::Color.new(r: 70, g: 130, b: 180, a: 255))
        end
        
        # File/directory icon and name
        file_name = @file_list[i]
        color = file_name.ends_with?("/") || file_name == ".." ? RL::YELLOW : RL::WHITE
        
        # Add file type icon
        icon = get_file_icon(file_name)
        RL.draw_text(icon, x + 5, item_y + 2, 14, color)
        RL.draw_text(file_name, x + 25, item_y + 2, 14, color)
      end

      # Scroll indicator
      if @file_list.size > visible_items
        scroll_height = (visible_items.to_f / @file_list.size * height).to_i
        scroll_y = (@scroll_offset.to_f / (@file_list.size - visible_items) * (height - scroll_height)).to_i
        
        RL.draw_rectangle(x + width - 10, y + scroll_y, 8, scroll_height,
          RL::Color.new(r: 150, g: 150, b: 150, a: 255))
      end
    end

    private def get_file_icon(filename : String) : String
      return "📁" if filename.ends_with?("/")
      return "⬆️" if filename == ".."
      
      ext = File.extname(filename).downcase
      case ext
      when ".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tga"
        "🖼️"
      when ".wav", ".ogg", ".mp3", ".flac"
        "🎵"
      when ".lua", ".cr"
        "📝"
      else
        "📄"
      end
    end

    private def draw_selected_info(x : Int32, y : Int32, width : Int32)
      if @selected_files.empty?
        RL.draw_text("No files selected", x, y, 14, RL::LIGHTGRAY)
      else
        text = "Selected: #{@selected_files.size} file#{@selected_files.size > 1 ? "s" : ""}"
        RL.draw_text(text, x, y, 14, RL::WHITE)
        
        # Show first few filenames
        if @selected_files.size <= 3
          @selected_files.each_with_index do |file, index|
            filename = File.basename(file)
            RL.draw_text("• #{filename}", x + 10, y + 18 + index * 16, 12, RL::LIGHTGRAY)
          end
        else
          RL.draw_text("• #{File.basename(@selected_files[0])}", x + 10, y + 18, 12, RL::LIGHTGRAY)
          RL.draw_text("• #{File.basename(@selected_files[1])}", x + 10, y + 34, 12, RL::LIGHTGRAY)
          RL.draw_text("• ... and #{@selected_files.size - 2} more", x + 10, y + 50, 12, RL::LIGHTGRAY)
        end
      end
    end

    private def draw_preview_grid(x : Int32, y : Int32, width : Int32, height : Int32)
      return if @selected_files.empty?
      
      # Preview background
      RL.draw_rectangle(x, y, width, height,
        RL::Color.new(r: 20, g: 20, b: 20, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Show previews for first few selected image files
      preview_size = height - 10
      preview_x = x + 5
      max_previews = (width - 10) // (preview_size + 5)
      
      shown = 0
      @selected_files.each do |file_path|
        break if shown >= max_previews
        
        ext = File.extname(file_path).downcase
        if [".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tga"].includes?(ext)
          draw_file_preview(file_path, preview_x, y + 5, preview_size - 10)
          preview_x += preview_size + 5
          shown += 1
        end
      end
      
      if shown == 0
        RL.draw_text("No image preview available", x + 10, y + height//2 - 7, 14, RL::GRAY)
      end
    end

    private def draw_file_preview(file_path : String, x : Int32, y : Int32, size : Int32)
      # Load texture if not cached
      unless @preview_textures.has_key?(file_path)
        begin
          @preview_textures[file_path] = RL.load_texture(file_path)
        rescue
          # If loading fails, show placeholder
          RL.draw_rectangle(x, y, size, size, RL::Color.new(r: 100, g: 100, b: 100, a: 255))
          RL.draw_text("?", x + size//2 - 5, y + size//2 - 7, 14, RL::WHITE)
          return
        end
      end

      texture = @preview_textures[file_path]
      
      # Scale to fit preview area
      scale = [size.to_f / texture.width, size.to_f / texture.height].min
      scaled_width = (texture.width * scale).to_i
      scaled_height = (texture.height * scale).to_i
      
      # Center the image
      img_x = x + (size - scaled_width) // 2
      img_y = y + (size - scaled_height) // 2
      
      dest_rect = RL::Rectangle.new(
        x: img_x.to_f32,
        y: img_y.to_f32,
        width: scaled_width.to_f32,
        height: scaled_height.to_f32
      )
      
      source_rect = RL::Rectangle.new(
        x: 0.0_f32,
        y: 0.0_f32,
        width: texture.width.to_f32,
        height: texture.height.to_f32
      )
      
      RL.draw_texture_pro(texture, source_rect, dest_rect, RL::Vector2.new(0.0_f32, 0.0_f32), 0.0_f32, RL::WHITE)
    end

    private def draw_buttons(x : Int32, y : Int32, width : Int32)
      button_width = 100
      button_height = 30
      
      # Cancel button
      cancel_x = x + width - 220
      if draw_button("Cancel", cancel_x, y, button_width, button_height)
        hide
      end
      
      # Import button (only enabled if files selected)
      import_x = x + width - 110
      import_enabled = !@selected_files.empty?
      import_color = import_enabled ? RL::WHITE : RL::GRAY
      
      if draw_button("Import", import_x, y, button_width, button_height, import_color) && import_enabled
        import_selected_files
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
      
      # Calculate file list area
      dialog_width = 700
      dialog_height = 600
      dialog_x = (Core::EditorWindow::WINDOW_WIDTH - dialog_width) // 2
      dialog_y = (Core::EditorWindow::WINDOW_HEIGHT - dialog_height) // 2
      
      list_x = dialog_x + 20
      list_y = dialog_y + 80
      list_width = dialog_width - 40
      list_height = 300
      
      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        if mouse_pos.x >= list_x && mouse_pos.x <= list_x + list_width &&
           mouse_pos.y >= list_y && mouse_pos.y <= list_y + list_height
          
          # Calculate clicked item
          item_height = 20
          clicked_index = @scroll_offset + ((mouse_pos.y - list_y) / item_height).to_i
          
          if clicked_index >= 0 && clicked_index < @file_list.size
            handle_item_click(clicked_index)
          end
        end
      end
      
      # Handle scroll wheel
      wheel_move = RL.get_mouse_wheel_move
      if wheel_move != 0
        @scroll_offset = [@scroll_offset - wheel_move.to_i, 0].max
        max_scroll = [@file_list.size - 15, 0].max
        @scroll_offset = [@scroll_offset, max_scroll].min
      end
      
      # Handle escape key
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        hide
      end
    end

    private def handle_item_click(index : Int32)
      return if index < 0 || index >= @file_list.size
      
      selected_item = @file_list[index]
      
      if selected_item == ".."
        # Go to parent directory
        parent_dir = File.dirname(@current_directory)
        if parent_dir != @current_directory
          @current_directory = parent_dir
          refresh_file_list
          @selected_indices.clear
          @selected_files.clear
          unload_preview_textures
        end
      elsif selected_item.ends_with?("/")
        # Enter directory
        dir_name = selected_item.rchop
        new_dir = File.join(@current_directory, dir_name)
        if Dir.exists?(new_dir)
          @current_directory = new_dir
          refresh_file_list
          @selected_indices.clear
          @selected_files.clear
          unload_preview_textures
        end
      else
        # Toggle file selection
        if @selected_indices.includes?(index)
          @selected_indices.delete(index)
          file_path = File.join(@current_directory, selected_item)
          @selected_files.delete(file_path)
        else
          @selected_indices << index
          file_path = File.join(@current_directory, selected_item)
          @selected_files << file_path
        end
      end
    end

    private def import_selected_files
      return if @selected_files.empty?
      return unless project = @state.current_project
      
      # Create target directory
      target_dir = File.join(project.project_path, "assets", @asset_category)
      Dir.mkdir_p(target_dir) unless Dir.exists?(target_dir)
      
      imported_count = 0
      
      @selected_files.each do |file_path|
        begin
          filename = File.basename(file_path)
          dest_path = File.join(target_dir, filename)
          
          # Check if file already exists
          if File.exists?(dest_path)
            puts "File already exists: #{filename} (skipping)"
            next
          end
          
          # Copy file
          File.copy(file_path, dest_path)
          imported_count += 1
          puts "Imported: #{filename}"
          
        rescue ex : Exception
          puts "Failed to import #{File.basename(file_path)}: #{ex.message}"
        end
      end
      
      # Refresh project assets
      project.refresh_assets
      
      # Close dialog
      hide
      
      puts "Import complete: #{imported_count} file#{imported_count != 1 ? "s" : ""} imported"
    end

    private def unload_preview_textures
      @preview_textures.each_value do |texture|
        RL.unload_texture(texture)
      end
      @preview_textures.clear
    end
  end
end