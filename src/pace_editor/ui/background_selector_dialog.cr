require "./ui_helpers"

module PaceEditor::UI
  # Dialog for selecting and assigning background images to scenes
  class BackgroundSelectorDialog
    property visible : Bool = false

    @selected_background : String? = nil
    @scroll_offset : Float32 = 0.0_f32

    def initialize(@state : Core::EditorState)
    end

    def show
      @visible = true
      @selected_background = nil
      @scroll_offset = 0.0_f32
    end

    def hide
      @visible = false
    end

    def update
      return unless @visible

      # Handle escape key
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        hide
      end

      # Handle scroll
      mouse_wheel = RL.get_mouse_wheel_move
      @scroll_offset -= mouse_wheel * 30
      @scroll_offset = Math.max(0.0_f32, @scroll_offset)
    end

    def draw
      return unless @visible

      # Get screen dimensions
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height

      # Draw modal background
      RL.draw_rectangle(0, 0, screen_width, screen_height,
        RL::Color.new(r: 0, g: 0, b: 0, a: 180))

      # Dialog window
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      # Window background
      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height,
        RL::Color.new(r: 60, g: 60, b: 60, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      # Title
      title = "Select Background"
      title_width = RL.measure_text(title, 20)
      RL.draw_text(title, dialog_x + (dialog_width - title_width) // 2, dialog_y + 20, 20, RL::WHITE)

      # Background list area
      list_y = dialog_y + 60
      list_height = dialog_height - 120

      # Get available backgrounds
      backgrounds = get_available_backgrounds

      if backgrounds.empty?
        # No backgrounds message
        no_bg_text = "No backgrounds available"
        text_width = RL.measure_text(no_bg_text, 16)
        RL.draw_text(no_bg_text, dialog_x + (dialog_width - text_width) // 2,
          list_y + list_height // 2 - 8, 16, RL::GRAY)
      else
        # Draw background list with thumbnails
        draw_background_list(dialog_x + 20, list_y, dialog_width - 40, list_height - 20, backgrounds)
      end

      # Buttons
      button_width = 100
      button_height = 30
      button_y = dialog_y + dialog_height - 50
      button_spacing = 20

      # OK button (only enabled if background selected)
      ok_x = dialog_x + dialog_width - button_width * 2 - button_spacing - 20
      ok_enabled = !@selected_background.nil?

      if ok_enabled
        if UIHelpers.button(ok_x, button_y, button_width, button_height, "OK")
          assign_background
          hide
        end
      else
        # Draw disabled button
        RL.draw_rectangle(ok_x, button_y, button_width, button_height,
          RL::Color.new(r: 40, g: 40, b: 40, a: 255))
        RL.draw_rectangle_lines(ok_x, button_y, button_width, button_height, RL::DARKGRAY)
        text_width = RL.measure_text("OK", 16)
        RL.draw_text("OK", ok_x + (button_width - text_width) // 2,
          button_y + (button_height - 16) // 2, 16, RL::DARKGRAY)
      end

      # Cancel button
      cancel_x = dialog_x + dialog_width - button_width - 20
      if UIHelpers.button(cancel_x, button_y, button_width, button_height, "Cancel")
        hide
      end

      # Import button
      import_x = dialog_x + 20
      if UIHelpers.button(import_x, button_y, button_width, button_height, "Import...")
        # Switch to asset browser
        @state.show_new_project_dialog = true # Repurpose as asset browser trigger
        hide
      end
    end

    private def get_available_backgrounds : Array(String)
      return [] of String unless project = @state.current_project

      backgrounds = [] of String

      # Get all image files from backgrounds directory
      bg_path = project.backgrounds_path
      if Dir.exists?(bg_path)
        Dir.glob(File.join(bg_path, "*.{png,jpg,jpeg,bmp,tga}")).each do |file|
          backgrounds << File.basename(file)
        end
      end

      backgrounds.sort
    end

    private def draw_background_list(x : Int32, y : Int32, width : Int32, height : Int32, backgrounds : Array(String))
      # Thumbnail settings
      thumb_size = 120
      padding = 10
      cols = (width + padding) // (thumb_size + padding)

      # Scissor mode for scrolling
      RL.begin_scissor_mode(x, y, width, height)

      # Calculate visible range
      row_height = thumb_size + padding + 30 # Extra space for filename
      total_rows = (backgrounds.size + cols - 1) // cols
      total_height = total_rows * row_height
      max_scroll = Math.max(0, total_height - height)
      @scroll_offset = Math.min(@scroll_offset, max_scroll.to_f32)

      # Draw backgrounds
      backgrounds.each_with_index do |bg_name, index|
        col = index % cols
        row = index // cols

        item_x = x + col * (thumb_size + padding)
        item_y = y + row * row_height - @scroll_offset.to_i

        # Skip if outside visible area
        next if item_y + row_height < y || item_y > y + height

        # Check if selected
        is_selected = @selected_background == bg_name

        # Draw thumbnail background
        bg_color = if is_selected
                     RL::Color.new(r: 100, g: 150, b: 200, a: 255)
                   else
                     RL::Color.new(r: 80, g: 80, b: 80, a: 255)
                   end

        RL.draw_rectangle(item_x, item_y, thumb_size, thumb_size, bg_color)
        RL.draw_rectangle_lines(item_x, item_y, thumb_size, thumb_size, RL::WHITE)

        # Draw thumbnail (placeholder for now)
        RL.draw_text("IMG", item_x + thumb_size // 2 - 15,
          item_y + thumb_size // 2 - 8, 16, RL::LIGHTGRAY)

        # Draw filename
        display_name = if bg_name.size > 15
                         bg_name[0...12] + "..."
                       else
                         bg_name
                       end

        name_width = RL.measure_text(display_name, 12)
        RL.draw_text(display_name, item_x + (thumb_size - name_width) // 2,
          item_y + thumb_size + 5, 12, RL::WHITE)

        # Handle click
        mouse_pos = RL.get_mouse_position
        if mouse_pos.x >= item_x && mouse_pos.x <= item_x + thumb_size &&
           mouse_pos.y >= item_y && mouse_pos.y <= item_y + thumb_size + 20
          if RL.mouse_button_pressed?(RL::MouseButton::Left)
            @selected_background = bg_name
          end
        end
      end

      RL.end_scissor_mode

      # Draw scrollbar if needed
      if total_height > height
        scrollbar_x = x + width - 10
        scrollbar_height = (height * height / total_height).to_i
        scrollbar_y = y + (@scroll_offset * height / total_height).to_i

        RL.draw_rectangle(scrollbar_x, y, 10, height, RL::Color.new(r: 40, g: 40, b: 40, a: 255))
        RL.draw_rectangle(scrollbar_x, scrollbar_y, 10, scrollbar_height, RL::GRAY)
      end
    end

    private def assign_background
      return unless bg = @selected_background
      return unless scene = @state.current_scene
      return unless project = @state.current_project

      # Set the background path relative to project
      scene.background_path = "backgrounds/#{bg}"

      # Save the scene
      IO::SceneIO.save_scene(scene, IO::SceneIO.get_scene_file_path(project, scene.name))

      @state.mark_dirty

      puts "Assigned background: #{bg} to scene: #{scene.name}"
    end
  end
end
