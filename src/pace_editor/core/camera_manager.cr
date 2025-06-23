module PaceEditor::Core
  # Manages camera state and transformations for the editor
  class CameraManager
    include PaceEditor::Constants

    property x : Float32 = 0.0_f32
    property y : Float32 = 0.0_f32
    property zoom : Float32 = DEFAULT_ZOOM
    property target_x : Float32 = 0.0_f32
    property target_y : Float32 = 0.0_f32
    property target_zoom : Float32 = DEFAULT_ZOOM
    property smooth_movement : Bool = true

    # Viewport dimensions
    property viewport_width : Int32 = 0
    property viewport_height : Int32 = 0

    def initialize(@viewport_width : Int32 = 0, @viewport_height : Int32 = 0)
    end

    # Update camera position with smooth movement
    def update(delta_time : Float32)
      if smooth_movement
        # Smooth camera movement
        @x += (@target_x - @x) * CAMERA_SMOOTH_FACTOR
        @y += (@target_y - @y) * CAMERA_SMOOTH_FACTOR
        @zoom += (@target_zoom - @zoom) * CAMERA_SMOOTH_FACTOR
      else
        # Instant movement
        @x = @target_x
        @y = @target_y
        @zoom = @target_zoom
      end

      # Clamp zoom to valid range
      @zoom = @zoom.clamp(MIN_ZOOM, MAX_ZOOM)
      @target_zoom = @target_zoom.clamp(MIN_ZOOM, MAX_ZOOM)
    end

    # Pan the camera by a relative amount
    def pan(delta_x : Float32, delta_y : Float32)
      @target_x += delta_x / @zoom
      @target_y += delta_y / @zoom
    end

    # Set camera position directly
    def set_position(x : Float32, y : Float32)
      @target_x = x
      @target_y = y
    end

    # Zoom in/out at a specific point
    def zoom_at_point(screen_x : Float32, screen_y : Float32, zoom_delta : Float32)
      # Get world position before zoom
      world_pos_before = screen_to_world(RL::Vector2.new(screen_x, screen_y))

      # Apply zoom
      new_zoom = (@target_zoom + zoom_delta).clamp(MIN_ZOOM, MAX_ZOOM)
      @target_zoom = new_zoom

      # Get world position after zoom
      world_pos_after = screen_to_world(RL::Vector2.new(screen_x, screen_y))

      # Adjust camera to keep the same world point under cursor
      @target_x += world_pos_before.x - world_pos_after.x
      @target_y += world_pos_before.y - world_pos_after.y
    end

    # Set zoom level directly
    def set_zoom(new_zoom : Float32)
      @target_zoom = new_zoom.clamp(MIN_ZOOM, MAX_ZOOM)
    end

    # Convert screen coordinates to world coordinates
    def screen_to_world(screen_pos : RL::Vector2) : RL::Vector2
      world_x = (screen_pos.x - @viewport_width / 2) / @zoom + @x
      world_y = (screen_pos.y - @viewport_height / 2) / @zoom + @y
      RL::Vector2.new(world_x, world_y)
    end

    # Convert world coordinates to screen coordinates
    def world_to_screen(world_pos : RL::Vector2) : RL::Vector2
      screen_x = (world_pos.x - @x) * @zoom + @viewport_width / 2
      screen_y = (world_pos.y - @y) * @zoom + @viewport_height / 2
      RL::Vector2.new(screen_x, screen_y)
    end

    # Get the camera transformation matrix
    def get_transform_matrix : RL::Matrix
      # Create transformation matrix for camera
      translation = RL::Matrix.translate(-@x, -@y, 0.0_f32)
      scale = RL::Matrix.scale(@zoom, @zoom, 1.0_f32)
      viewport_offset = RL::Matrix.translate(@viewport_width / 2, @viewport_height / 2, 0.0_f32)

      viewport_offset * scale * translation
    end

    # Get the inverse transformation matrix
    def get_inverse_transform_matrix : RL::Matrix
      get_transform_matrix.invert
    end

    # Check if a world rectangle is visible in the current view
    def is_visible?(world_rect : RL::Rectangle) : Bool
      # Convert world bounds to screen bounds
      top_left = world_to_screen(RL::Vector2.new(world_rect.x, world_rect.y))
      bottom_right = world_to_screen(RL::Vector2.new(world_rect.x + world_rect.width, world_rect.y + world_rect.height))

      # Check if any part is within screen bounds
      !(bottom_right.x < 0 || top_left.x > @viewport_width ||
        bottom_right.y < 0 || top_left.y > @viewport_height)
    end

    # Get the visible world bounds
    def get_visible_world_bounds : RL::Rectangle
      top_left = screen_to_world(RL::Vector2.new(0.0_f32, 0.0_f32))
      bottom_right = screen_to_world(RL::Vector2.new(@viewport_width.to_f32, @viewport_height.to_f32))

      RL::Rectangle.new(
        top_left.x,
        top_left.y,
        bottom_right.x - top_left.x,
        bottom_right.y - top_left.y
      )
    end

    # Focus on a specific world point
    def focus_on(world_x : Float32, world_y : Float32)
      @target_x = world_x
      @target_y = world_y
    end

    # Focus on a rectangle in world space
    def focus_on_bounds(bounds : RL::Rectangle, padding : Float32 = 50.0_f32)
      # Calculate required zoom to fit the bounds
      zoom_x = (@viewport_width - padding * 2) / bounds.width
      zoom_y = (@viewport_height - padding * 2) / bounds.height
      required_zoom = Math.min(zoom_x, zoom_y).clamp(MIN_ZOOM, MAX_ZOOM)

      # Set zoom and center on bounds
      @target_zoom = required_zoom
      @target_x = bounds.x + bounds.width / 2
      @target_y = bounds.y + bounds.height / 2
    end

    # Reset camera to default position
    def reset
      @target_x = 0.0_f32
      @target_y = 0.0_f32
      @target_zoom = DEFAULT_ZOOM
    end

    # Update viewport dimensions
    def set_viewport_size(width : Int32, height : Int32)
      @viewport_width = width
      @viewport_height = height
    end

    # Get current camera state as a hash for serialization
    def to_hash : Hash(String, Float32)
      {
        "x"    => @x,
        "y"    => @y,
        "zoom" => @zoom,
      }
    end

    # Restore camera state from a hash
    def from_hash(hash : Hash(String, Float32))
      @x = @target_x = hash["x"]? || 0.0_f32
      @y = @target_y = hash["y"]? || 0.0_f32
      @zoom = @target_zoom = hash["zoom"]? || DEFAULT_ZOOM
    end

    # Get a formatted string representation of camera state
    def to_s(io : IO) : Nil
      io << "Camera(x=#{@x.round(2)}, y=#{@y.round(2)}, zoom=#{@zoom.round(2)})"
    end
  end
end
