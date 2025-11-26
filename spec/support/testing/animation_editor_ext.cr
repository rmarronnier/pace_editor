# Testing extensions for AnimationEditor
# Reopens the class to add e2e testing support methods

module PaceEditor::UI
  class AnimationEditor
    # Update with a specific input provider (for testing)
    def update_with_input(input : Testing::InputProvider)
      return unless @visible

      # Handle keyboard input
      if input.key_pressed?(RL::KeyboardKey::Escape)
        hide
      elsif input.key_pressed?(RL::KeyboardKey::Space)
        toggle_playback
      elsif input.key_pressed?(RL::KeyboardKey::Left)
        previous_frame
      elsif input.key_pressed?(RL::KeyboardKey::Right)
        next_frame
      elsif input.key_pressed?(RL::KeyboardKey::S) && (input.key_down?(RL::KeyboardKey::LeftControl) || input.key_down?(RL::KeyboardKey::RightControl))
        save_animation_data
      end

      # Update animation playback
      if @playing
        update_playback
      end
    end

    # Testing getters
    def character_name_for_test : String?
      @character_name
    end

    def current_animation_for_test : String?
      @current_animation
    end

    def current_frame_for_test : Int32
      @current_frame
    end

    def is_playing_for_test : Bool
      @playing
    end

    def playback_speed_for_test : Float32
      @playback_speed
    end

    def zoom_for_test : Float32
      @zoom
    end

    def animation_count_for_test : Int32
      @animation_data.animations.size
    end

    def animation_names_for_test : Array(String)
      @animation_data.animations.keys
    end

    def frame_count_for_test : Int32
      if name = @current_animation
        if animation = @animation_data.animations[name]?
          return animation.frames.size
        end
      end
      0
    end

    def sprite_dimensions_for_test : {Int32, Int32}
      {@animation_data.sprite_width, @animation_data.sprite_height}
    end

    def selected_frame_for_test : Int32
      @selected_frame
    end

    # Testing setters
    def set_current_animation_for_test(name : String)
      select_animation(name)
    end

    def set_current_frame_for_test(frame : Int32)
      @current_frame = frame.clamp(0, frame_count_for_test - 1)
      @frame_timer = 0.0_f32
    end

    def set_playback_speed_for_test(speed : Float32)
      @playback_speed = speed.clamp(0.1_f32, 10.0_f32)
    end

    def set_zoom_for_test(zoom : Float32)
      @zoom = zoom.clamp(0.25_f32, 4.0_f32)
    end

    # Testing actions
    def toggle_playback_for_test
      toggle_playback
    end

    def next_frame_for_test
      next_frame
    end

    def previous_frame_for_test
      previous_frame
    end

    def create_new_animation_for_test
      create_new_animation
    end

    def add_frame_for_test
      add_frame_to_animation
    end

    def show_for_test(character_name : String)
      show(character_name)
    end

    # Get button positions for click testing
    def get_play_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      window_width = 1000
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - 750) // 2
      preview_x = window_x + 200 # list_width
      {preview_x + 70, window_y + 35 + 47}
    end

    def get_new_animation_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      window_width = 1000
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - 750) // 2
      {window_x + 45, window_y + 35 + 47}
    end

    def get_animation_item_position(index : Int32, screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      window_width = 1000
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - 750) // 2
      item_height = 30
      list_y = window_y + 35 + 35 + 35
      {window_x + 100, list_y + index * item_height + 15}
    end

    def get_timeline_frame_position(frame_index : Int32, screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      window_width = 1000
      window_height = 750
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - window_height) // 2

      timeline_y = window_y + window_height - 150 + 35 + 10
      frame_width = 60
      frame_x = window_x + 10 + frame_index * (frame_width + 5) + 30

      {frame_x, timeline_y + 25}
    end

    def get_add_frame_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      frame_count = frame_count_for_test
      window_width = 1000
      window_height = 750
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - window_height) // 2

      timeline_y = window_y + window_height - 150 + 35 + 10
      frame_width = 60
      add_frame_x = window_x + 10 + frame_count * (frame_width + 5) + 30

      {add_frame_x, timeline_y + 25}
    end

    def get_close_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      window_width = 1000
      window_x = (screen_width - window_width) // 2
      window_y = (screen_height - 750) // 2
      {window_x + window_width - 15, window_y + 15}
    end
  end
end
