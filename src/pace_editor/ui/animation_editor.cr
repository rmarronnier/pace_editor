require "raylib-cr"
require "./colors"

module PaceEditor::UI
  # Animation editor for creating and managing sprite animations
  class AnimationEditor
    property visible : Bool = false

    @character_name : String? = nil
    @sprite_sheet_path : String? = nil
    @sprite_sheet_texture : RL::Texture2D? = nil
    @animation_data : AnimationData = AnimationData.new
    @current_animation : String? = nil
    @current_frame : Int32 = 0
    @playing : Bool = false
    @playback_speed : Float32 = 1.0_f32
    @frame_timer : Float32 = 0.0_f32
    @timeline_scroll : Int32 = 0
    @selected_frame : Int32 = -1
    @zoom : Float32 = 1.0_f32
    @preview_x : Int32 = 0
    @preview_y : Int32 = 0

    # Animation data structure
    class AnimationData
      property animations : Hash(String, Animation) = {} of String => Animation
      property sprite_width : Int32 = 32
      property sprite_height : Int32 = 32
      property sheet_columns : Int32 = 8
      property sheet_rows : Int32 = 8

      def initialize
      end
    end

    class Animation
      property name : String
      property frames : Array(AnimationFrame) = [] of AnimationFrame
      property loop : Bool = true
      property fps : Float32 = 8.0_f32

      def initialize(@name : String)
      end
    end

    class AnimationFrame
      property sprite_x : Int32
      property sprite_y : Int32
      property duration : Float32 = 0.125_f32 # 8 FPS default
      property offset_x : Int32 = 0
      property offset_y : Int32 = 0

      def initialize(@sprite_x : Int32, @sprite_y : Int32)
      end
    end

    def initialize(@state : Core::EditorState)
    end

    def show(character_name : String, sprite_sheet_path : String? = nil)
      @character_name = character_name
      @visible = true
      @current_frame = 0
      @playing = false
      @frame_timer = 0.0_f32
      @timeline_scroll = 0
      @selected_frame = -1

      if sprite_sheet_path && File.exists?(sprite_sheet_path)
        load_sprite_sheet(sprite_sheet_path)
      end

      # Create default animations if none exist
      if @animation_data.animations.empty?
        create_default_animations
      end

      # Select first animation
      @current_animation = @animation_data.animations.keys.first?
    end

    def hide
      @visible = false
      @character_name = nil
      if texture = @sprite_sheet_texture
        RL.unload_texture(texture)
        @sprite_sheet_texture = nil
      end
    end

    def update
      return unless @visible

      # Handle keyboard input
      if RL.key_pressed?(RL::KeyboardKey::Escape)
        hide
      elsif RL.key_pressed?(RL::KeyboardKey::Space)
        toggle_playback
      elsif RL.key_pressed?(RL::KeyboardKey::Left)
        previous_frame
      elsif RL.key_pressed?(RL::KeyboardKey::Right)
        next_frame
      elsif RL.key_pressed?(RL::KeyboardKey::S) && (RL.key_down?(RL::KeyboardKey::LeftControl) || RL.key_down?(RL::KeyboardKey::RightControl))
        save_animation_data
      end

      # Update animation playback
      if @playing
        update_playback
      end
    end

    def draw
      return unless @visible

      # Get screen dimensions
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height

      # Dialog window dimensions
      window_width = 1000
      window_height = 750
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - window_height) // 2

      # Draw backdrop
      RL.draw_rectangle(0, 0, screen_width, screen_height, Colors::DARK_OVERLAY)

      # Draw editor window
      RL.draw_rectangle(window_x, window_y, window_width, window_height, Colors::PANEL_MEDIUM)
      RL.draw_rectangle_lines(window_x, window_y, window_width, window_height, RL::GRAY)

      # Title bar
      title_height = 35
      RL.draw_rectangle(window_x, window_y, window_width, title_height, Colors::PANEL_LIGHT)

      title_text = "Animation Editor"
      if name = @character_name
        title_text += " - #{name}"
      end

      RL.draw_text(title_text, window_x + 10, window_y + 8, 16, RL::WHITE)

      # Close button
      close_button_x = window_x + window_width - 25
      close_button_y = window_y + 5
      if draw_close_button(close_button_x, close_button_y)
        hide
        return
      end

      # Content area
      content_y = window_y + title_height
      content_height = window_height - title_height

      # Layout: Animation list (left), Preview (center), Properties (right)
      # Timeline at bottom

      list_width = 200
      properties_width = 250
      preview_width = window_width - list_width - properties_width
      timeline_height = 150
      preview_height = content_height - timeline_height

      # Animation list
      draw_animation_list(window_x, content_y, list_width, preview_height)

      # Preview area
      preview_x = window_x + list_width
      draw_preview_area(preview_x, content_y, preview_width, preview_height)

      # Properties panel
      properties_x = window_x + list_width + preview_width
      draw_properties_panel(properties_x, content_y, properties_width, preview_height)

      # Timeline
      timeline_y = content_y + preview_height
      draw_timeline(window_x, timeline_y, window_width, timeline_height)
    end

    private def draw_close_button(x : Int32, y : Int32) : Bool
      RL.draw_rectangle(x, y, 20, 20, RL::RED)
      RL.draw_text("X", x + 6, y + 4, 12, RL::WHITE)

      if RL.mouse_button_pressed?(RL::MouseButton::Left)
        mouse_pos = RL.get_mouse_position
        return mouse_pos.x >= x && mouse_pos.x <= x + 20 &&
          mouse_pos.y >= y && mouse_pos.y <= y + 20
      end
      false
    end

    private def draw_animation_list(x : Int32, y : Int32, width : Int32, height : Int32)
      # Background
      RL.draw_rectangle(x, y, width, height, Colors::WORKSPACE_BG)
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Title
      RL.draw_text("Animations", x + 10, y + 10, 14, RL::WHITE)

      # New animation button
      new_button_y = y + 35
      if draw_button("+ New", x + 10, new_button_y, 70, 25)
        create_new_animation
      end

      # Animation list
      list_y = new_button_y + 35
      item_height = 30

      @animation_data.animations.each_with_index do |(name, animation), index|
        item_y = list_y + index * item_height
        is_selected = name == @current_animation

        # Item background
        bg_color = is_selected ? Colors::NODE_SELECTED : Colors::TRANSPARENT
        if bg_color.a > 0
          RL.draw_rectangle(x + 5, item_y, width - 10, item_height, bg_color)
        end

        # Animation name
        text_color = is_selected ? RL::WHITE : RL::LIGHTGRAY
        RL.draw_text(name, x + 10, item_y + 8, 12, text_color)

        # Frame count
        frame_count_text = "#{animation.frames.size} frames"
        RL.draw_text(frame_count_text, x + 10, item_y + 20, 10, RL::GRAY)

        # Handle click
        if RL.mouse_button_pressed?(RL::MouseButton::Left)
          mouse_pos = RL.get_mouse_position
          if mouse_pos.x >= x + 5 && mouse_pos.x <= x + width - 5 &&
             mouse_pos.y >= item_y && mouse_pos.y <= item_y + item_height
            select_animation(name)
          end
        end
      end
    end

    private def draw_preview_area(x : Int32, y : Int32, width : Int32, height : Int32)
      # Background
      RL.draw_rectangle(x, y, width, height, Colors::PANEL_DARK)
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Title
      RL.draw_text("Preview", x + 10, y + 10, 14, RL::WHITE)

      # Playback controls
      controls_y = y + 35
      control_button_width = 50
      control_spacing = 10

      control_x = x + 10
      if draw_button("<<", control_x, controls_y, control_button_width, 25)
        @current_frame = 0
        @frame_timer = 0.0_f32
      end

      control_x += control_button_width + control_spacing
      play_text = @playing ? "||" : "▶"
      if draw_button(play_text, control_x, controls_y, control_button_width, 25)
        toggle_playback
      end

      control_x += control_button_width + control_spacing
      if draw_button(">>", control_x, controls_y, control_button_width, 25)
        if animation = get_current_animation
          # Only skip to last if there are frames, prevent -1 index
          @current_frame = [animation.frames.size - 1, 0].max
          @frame_timer = 0.0_f32
        end
      end

      # Speed control
      control_x += control_button_width + control_spacing + 20
      RL.draw_text("Speed:", control_x, controls_y + 5, 12, RL::LIGHTGRAY)
      speed_text = "#{@playback_speed.round(2)}x"
      RL.draw_text(speed_text, control_x + 45, controls_y + 5, 12, RL::WHITE)

      # Zoom control
      zoom_y = controls_y + 30
      RL.draw_text("Zoom:", x + 10, zoom_y + 5, 12, RL::LIGHTGRAY)
      zoom_text = "#{(@zoom * 100).to_i}%"
      RL.draw_text(zoom_text, x + 50, zoom_y + 5, 12, RL::WHITE)

      # Preview viewport
      preview_viewport_y = y + 100
      preview_viewport_height = height - 110

      draw_sprite_preview(x + 10, preview_viewport_y, width - 20, preview_viewport_height)
    end

    private def draw_sprite_preview(x : Int32, y : Int32, width : Int32, height : Int32)
      # Checkerboard background
      checker_size = 16
      (0..width // checker_size).each do |cx|
        (0..height // checker_size).each do |cy|
          if (cx + cy) % 2 == 0
            RL.draw_rectangle(x + cx * checker_size, y + cy * checker_size,
              checker_size, checker_size, RL::LIGHTGRAY)
          else
            RL.draw_rectangle(x + cx * checker_size, y + cy * checker_size,
              checker_size, checker_size, RL::GRAY)
          end
        end
      end

      # Draw current frame
      if animation = get_current_animation
        if !animation.frames.empty? && @current_frame < animation.frames.size
          draw_current_frame(x + width // 2, y + height // 2)
        end
      end

      # Frame info
      if animation = get_current_animation
        frame_info = "Frame #{@current_frame + 1} / #{animation.frames.size}"
        RL.draw_text(frame_info, x + 10, y + height - 20, 12, RL::BLACK)
      end
    end

    private def draw_current_frame(center_x : Int32, center_y : Int32)
      return unless texture = @sprite_sheet_texture
      return unless animation = get_current_animation
      return if animation.frames.empty? || @current_frame >= animation.frames.size

      frame = animation.frames[@current_frame]

      # Source rectangle on sprite sheet
      source_rect = RL::Rectangle.new(
        x: frame.sprite_x.to_f32,
        y: frame.sprite_y.to_f32,
        width: @animation_data.sprite_width.to_f32,
        height: @animation_data.sprite_height.to_f32
      )

      # Destination rectangle (scaled)
      scaled_width = @animation_data.sprite_width * @zoom
      scaled_height = @animation_data.sprite_height * @zoom

      dest_rect = RL::Rectangle.new(
        x: center_x - scaled_width / 2 + frame.offset_x * @zoom,
        y: center_y - scaled_height / 2 + frame.offset_y * @zoom,
        width: scaled_width,
        height: scaled_height
      )

      # Draw sprite
      RL.draw_texture_pro(texture, source_rect, dest_rect, RL::Vector2.new(0, 0), 0.0_f32, RL::WHITE)

      # Draw frame bounds
      RL.draw_rectangle_lines(dest_rect.x.to_i, dest_rect.y.to_i,
        dest_rect.width.to_i, dest_rect.height.to_i, RL::RED)
    end

    private def draw_properties_panel(x : Int32, y : Int32, width : Int32, height : Int32)
      # Background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 35, g: 35, b: 35, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Title
      RL.draw_text("Properties", x + 10, y + 10, 14, RL::WHITE)

      current_y = y + 40

      # Sprite sheet properties
      RL.draw_text("Sprite Sheet:", x + 10, current_y, 12, RL::LIGHTGRAY)
      current_y += 20

      RL.draw_text("Width: #{@animation_data.sprite_width}px", x + 15, current_y, 10, RL::WHITE)
      current_y += 15
      RL.draw_text("Height: #{@animation_data.sprite_height}px", x + 15, current_y, 10, RL::WHITE)
      current_y += 15
      RL.draw_text("Columns: #{@animation_data.sheet_columns}", x + 15, current_y, 10, RL::WHITE)
      current_y += 15
      RL.draw_text("Rows: #{@animation_data.sheet_rows}", x + 15, current_y, 10, RL::WHITE)
      current_y += 25

      # Animation properties
      if animation = get_current_animation
        RL.draw_text("Animation:", x + 10, current_y, 12, RL::LIGHTGRAY)
        current_y += 20

        RL.draw_text("Name: #{animation.name}", x + 15, current_y, 10, RL::WHITE)
        current_y += 15
        RL.draw_text("FPS: #{animation.fps}", x + 15, current_y, 10, RL::WHITE)
        current_y += 15
        RL.draw_text("Loop: #{animation.loop ? "Yes" : "No"}", x + 15, current_y, 10, RL::WHITE)
        current_y += 15
        RL.draw_text("Frames: #{animation.frames.size}", x + 15, current_y, 10, RL::WHITE)
        current_y += 25

        # Current frame properties
        if !animation.frames.empty? && @current_frame < animation.frames.size
          frame = animation.frames[@current_frame]
          RL.draw_text("Current Frame:", x + 10, current_y, 12, RL::LIGHTGRAY)
          current_y += 20

          RL.draw_text("Sprite X: #{frame.sprite_x}", x + 15, current_y, 10, RL::WHITE)
          current_y += 15
          RL.draw_text("Sprite Y: #{frame.sprite_y}", x + 15, current_y, 10, RL::WHITE)
          current_y += 15
          RL.draw_text("Offset X: #{frame.offset_x}", x + 15, current_y, 10, RL::WHITE)
          current_y += 15
          RL.draw_text("Offset Y: #{frame.offset_y}", x + 15, current_y, 10, RL::WHITE)
          current_y += 15
          duration_ms = (frame.duration * 1000).to_i
          RL.draw_text("Duration: #{duration_ms}ms", x + 15, current_y, 10, RL::WHITE)
        end
      end
    end

    private def draw_timeline(x : Int32, y : Int32, width : Int32, height : Int32)
      # Background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 25, g: 25, b: 25, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)

      # Title
      RL.draw_text("Timeline", x + 10, y + 10, 14, RL::WHITE)

      # Timeline area
      timeline_area_y = y + 35
      timeline_area_height = height - 45
      frame_width = 60
      frame_height = 50

      return unless animation = get_current_animation

      # Draw frames
      animation.frames.each_with_index do |frame, index|
        frame_x = x + 10 + index * (frame_width + 5) - @timeline_scroll
        frame_y = timeline_area_y + 10

        # Skip if outside visible area
        next if frame_x + frame_width < x || frame_x > x + width

        # Frame background
        bg_color = if index == @current_frame
                     RL::Color.new(r: 100, g: 100, b: 150, a: 255)
                   elsif index == @selected_frame
                     RL::Color.new(r: 150, g: 100, b: 100, a: 255)
                   else
                     RL::Color.new(r: 60, g: 60, b: 60, a: 255)
                   end

        RL.draw_rectangle(frame_x, frame_y, frame_width, frame_height, bg_color)
        RL.draw_rectangle_lines(frame_x, frame_y, frame_width, frame_height, RL::WHITE)

        # Frame thumbnail (simplified)
        if texture = @sprite_sheet_texture
          thumb_size = 30
          thumb_x = frame_x + (frame_width - thumb_size) // 2
          thumb_y = frame_y + 5

          source_rect = RL::Rectangle.new(
            x: frame.sprite_x.to_f32,
            y: frame.sprite_y.to_f32,
            width: @animation_data.sprite_width.to_f32,
            height: @animation_data.sprite_height.to_f32
          )

          dest_rect = RL::Rectangle.new(
            x: thumb_x.to_f32,
            y: thumb_y.to_f32,
            width: thumb_size.to_f32,
            height: thumb_size.to_f32
          )

          RL.draw_texture_pro(texture, source_rect, dest_rect, RL::Vector2.new(0, 0), 0.0_f32, RL::WHITE)
        end

        # Frame number
        frame_num_text = (index + 1).to_s
        text_width = RL.measure_text(frame_num_text, 10)
        RL.draw_text(frame_num_text, frame_x + (frame_width - text_width) // 2, frame_y + frame_height - 15, 10, RL::WHITE)

        # Handle frame click
        if RL.mouse_button_pressed?(RL::MouseButton::Left)
          mouse_pos = RL.get_mouse_position
          if mouse_pos.x >= frame_x && mouse_pos.x <= frame_x + frame_width &&
             mouse_pos.y >= frame_y && mouse_pos.y <= frame_y + frame_height
            @current_frame = index
            @selected_frame = index
            @frame_timer = 0.0_f32
          end
        end
      end

      # Add frame button
      add_frame_x = x + 10 + animation.frames.size * (frame_width + 5) - @timeline_scroll
      add_frame_y = timeline_area_y + 10

      if add_frame_x < x + width - frame_width
        RL.draw_rectangle(add_frame_x, add_frame_y, frame_width, frame_height, RL::Color.new(r: 40, g: 80, b: 40, a: 255))
        RL.draw_rectangle_lines(add_frame_x, add_frame_y, frame_width, frame_height, RL::GREEN)

        plus_text = "+"
        plus_width = RL.measure_text(plus_text, 20)
        RL.draw_text(plus_text, add_frame_x + (frame_width - plus_width) // 2, add_frame_y + frame_height // 2 - 10, 20, RL::WHITE)

        # Handle add frame click
        if RL.mouse_button_pressed?(RL::MouseButton::Left)
          mouse_pos = RL.get_mouse_position
          if mouse_pos.x >= add_frame_x && mouse_pos.x <= add_frame_x + frame_width &&
             mouse_pos.y >= add_frame_y && mouse_pos.y <= add_frame_y + frame_height
            add_frame_to_animation
          end
        end
      end
    end

    private def draw_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32, color : RL::Color = RL::GRAY) : Bool
      mouse_pos = RL.get_mouse_position
      is_hover = mouse_pos.x >= x && mouse_pos.x <= x + width &&
                 mouse_pos.y >= y && mouse_pos.y <= y + height

      bg_color = is_hover ? RL::Color.new(r: color.r + 30, g: color.g + 30, b: color.b + 30, a: 255) : color

      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, RL::LIGHTGRAY)

      text_width = RL.measure_text(text, 12)
      text_x = x + (width - text_width) // 2
      RL.draw_text(text, text_x, y + height // 2 - 6, 12, RL::WHITE)

      is_hover && RL.mouse_button_pressed?(RL::MouseButton::Left)
    end

    private def load_sprite_sheet(path : String)
      begin
        if texture = @sprite_sheet_texture
          RL.unload_texture(texture)
        end

        @sprite_sheet_path = path
        @sprite_sheet_texture = RL.load_texture(path)
        puts "Loaded sprite sheet: #{path}"
      rescue ex
        puts "Error loading sprite sheet: #{ex.message}"
      end
    end

    private def create_default_animations
      # Create basic animation set
      idle_animation = Animation.new("idle")
      idle_animation.frames << AnimationFrame.new(0, 0)
      idle_animation.frames << AnimationFrame.new(32, 0)
      idle_animation.fps = 2.0_f32
      @animation_data.animations["idle"] = idle_animation

      walk_animation = Animation.new("walk")
      walk_animation.frames << AnimationFrame.new(0, 32)
      walk_animation.frames << AnimationFrame.new(32, 32)
      walk_animation.frames << AnimationFrame.new(64, 32)
      walk_animation.frames << AnimationFrame.new(96, 32)
      walk_animation.fps = 8.0_f32
      @animation_data.animations["walk"] = walk_animation
    end

    private def create_new_animation
      name = "animation_#{@animation_data.animations.size + 1}"
      animation = Animation.new(name)
      animation.frames << AnimationFrame.new(0, 0)
      @animation_data.animations[name] = animation
      @current_animation = name
    end

    private def select_animation(name : String)
      @current_animation = name
      @current_frame = 0
      @frame_timer = 0.0_f32
      @playing = false
    end

    private def get_current_animation : Animation?
      if name = @current_animation
        @animation_data.animations[name]?
      end
    end

    private def toggle_playback
      @playing = !@playing
      @frame_timer = 0.0_f32
    end

    private def next_frame
      return unless animation = get_current_animation
      return if animation.frames.empty?
      @current_frame = (@current_frame + 1) % animation.frames.size
      @frame_timer = 0.0_f32
    end

    private def previous_frame
      return unless animation = get_current_animation
      return if animation.frames.empty?
      # Use explicit wrap-around to avoid negative modulo issues in Crystal
      @current_frame = (@current_frame - 1 + animation.frames.size) % animation.frames.size
      @frame_timer = 0.0_f32
    end

    private def update_playback
      return unless animation = get_current_animation
      return if animation.frames.empty?

      current_frame_data = animation.frames[@current_frame]
      frame_duration = current_frame_data.duration / @playback_speed

      @frame_timer += RL.get_frame_time

      if @frame_timer >= frame_duration
        @frame_timer = 0.0_f32
        @current_frame += 1

        if @current_frame >= animation.frames.size
          if animation.loop
            @current_frame = 0
          else
            @current_frame = animation.frames.size - 1
            @playing = false
          end
        end
      end
    end

    private def add_frame_to_animation
      return unless animation = get_current_animation

      # Add frame at next sprite sheet position
      frame_index = animation.frames.size
      sprite_x = (frame_index % @animation_data.sheet_columns) * @animation_data.sprite_width
      sprite_y = (frame_index // @animation_data.sheet_columns) * @animation_data.sprite_height

      new_frame = AnimationFrame.new(sprite_x, sprite_y)
      animation.frames << new_frame
    end

    private def save_animation_data
      return unless name = @character_name

      # TODO: Save animation data to file
      puts "Saving animation data for #{name}"
      puts "Animations: #{@animation_data.animations.keys.join(", ")}"
    end
  end
end
