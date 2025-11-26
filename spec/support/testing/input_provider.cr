# Input abstraction layer for e2e testing
# This allows us to swap between real Raylib input and simulated test input

module PaceEditor::Testing
  # Abstract interface for input providers
  abstract class InputProvider
    # Mouse state
    abstract def get_mouse_position : RL::Vector2
    abstract def mouse_button_pressed?(button : RL::MouseButton) : Bool
    abstract def mouse_button_down?(button : RL::MouseButton) : Bool
    abstract def mouse_button_released?(button : RL::MouseButton) : Bool
    abstract def get_mouse_delta : RL::Vector2
    abstract def get_mouse_wheel_move : Float32

    # Keyboard state
    abstract def key_pressed?(key : RL::KeyboardKey) : Bool
    abstract def key_down?(key : RL::KeyboardKey) : Bool
    abstract def key_released?(key : RL::KeyboardKey) : Bool
    abstract def get_char_pressed : Int32

    # Window state
    abstract def window_resized? : Bool
    abstract def get_screen_width : Int32
    abstract def get_screen_height : Int32
    abstract def close_window? : Bool

    # Frame timing
    abstract def get_frame_time : Float32
  end

  # Real Raylib input provider - wraps actual Raylib calls
  class RaylibInputProvider < InputProvider
    def get_mouse_position : RL::Vector2
      RL.get_mouse_position
    end

    def mouse_button_pressed?(button : RL::MouseButton) : Bool
      RL.mouse_button_pressed?(button)
    end

    def mouse_button_down?(button : RL::MouseButton) : Bool
      RL.mouse_button_down?(button)
    end

    def mouse_button_released?(button : RL::MouseButton) : Bool
      RL.mouse_button_released?(button)
    end

    def get_mouse_delta : RL::Vector2
      RL.get_mouse_delta
    end

    def get_mouse_wheel_move : Float32
      RL.get_mouse_wheel_move.to_f32
    end

    def key_pressed?(key : RL::KeyboardKey) : Bool
      RL.key_pressed?(key)
    end

    def key_down?(key : RL::KeyboardKey) : Bool
      RL.key_down?(key)
    end

    def key_released?(key : RL::KeyboardKey) : Bool
      RL.key_released?(key)
    end

    def get_char_pressed : Int32
      RL.get_char_pressed
    end

    def window_resized? : Bool
      RL.window_resized?
    end

    def get_screen_width : Int32
      RL.get_screen_width
    end

    def get_screen_height : Int32
      RL.get_screen_height
    end

    def close_window? : Bool
      RL.close_window?
    end

    def get_frame_time : Float32
      RL.get_frame_time
    end
  end

  # Simulated input provider for testing
  class SimulatedInputProvider < InputProvider
    # Mouse state
    @mouse_position : RL::Vector2 = RL::Vector2.new(x: 0.0_f32, y: 0.0_f32)
    @mouse_delta : RL::Vector2 = RL::Vector2.new(x: 0.0_f32, y: 0.0_f32)
    @mouse_wheel : Float32 = 0.0_f32
    @mouse_buttons_pressed : Set(RL::MouseButton) = Set(RL::MouseButton).new
    @mouse_buttons_down : Set(RL::MouseButton) = Set(RL::MouseButton).new
    @mouse_buttons_released : Set(RL::MouseButton) = Set(RL::MouseButton).new

    # Keyboard state
    @keys_pressed : Set(RL::KeyboardKey) = Set(RL::KeyboardKey).new
    @keys_down : Set(RL::KeyboardKey) = Set(RL::KeyboardKey).new
    @keys_released : Set(RL::KeyboardKey) = Set(RL::KeyboardKey).new
    @char_queue : Array(Int32) = [] of Int32

    # Window state
    @window_resized : Bool = false
    @screen_width : Int32 = 1400
    @screen_height : Int32 = 900
    @should_close : Bool = false

    # Frame timing
    @frame_time : Float32 = 1.0_f32 / 60.0_f32

    # Mouse interface implementation
    def get_mouse_position : RL::Vector2
      @mouse_position
    end

    def mouse_button_pressed?(button : RL::MouseButton) : Bool
      @mouse_buttons_pressed.includes?(button)
    end

    def mouse_button_down?(button : RL::MouseButton) : Bool
      @mouse_buttons_down.includes?(button)
    end

    def mouse_button_released?(button : RL::MouseButton) : Bool
      @mouse_buttons_released.includes?(button)
    end

    def get_mouse_delta : RL::Vector2
      @mouse_delta
    end

    def get_mouse_wheel_move : Float32
      @mouse_wheel
    end

    # Keyboard interface implementation
    def key_pressed?(key : RL::KeyboardKey) : Bool
      @keys_pressed.includes?(key)
    end

    def key_down?(key : RL::KeyboardKey) : Bool
      @keys_down.includes?(key)
    end

    def key_released?(key : RL::KeyboardKey) : Bool
      @keys_released.includes?(key)
    end

    def get_char_pressed : Int32
      @char_queue.shift? || 0
    end

    # Window interface implementation
    def window_resized? : Bool
      @window_resized
    end

    def get_screen_width : Int32
      @screen_width
    end

    def get_screen_height : Int32
      @screen_height
    end

    def close_window? : Bool
      @should_close
    end

    def get_frame_time : Float32
      @frame_time
    end

    # === Test control methods ===

    # Move mouse to position
    def set_mouse_position(x : Float32, y : Float32)
      old_pos = @mouse_position
      @mouse_position = RL::Vector2.new(x: x, y: y)
      @mouse_delta = RL::Vector2.new(x: x - old_pos.x, y: y - old_pos.y)
    end

    def set_mouse_position(pos : RL::Vector2)
      set_mouse_position(pos.x, pos.y)
    end

    # Simulate mouse button press (pressed this frame)
    def press_mouse_button(button : RL::MouseButton)
      @mouse_buttons_pressed.add(button)
      @mouse_buttons_down.add(button)
    end

    # Simulate mouse button hold (already down from previous frame)
    def hold_mouse_button(button : RL::MouseButton)
      @mouse_buttons_down.add(button)
    end

    # Simulate mouse button release
    def release_mouse_button(button : RL::MouseButton)
      @mouse_buttons_down.delete(button)
      @mouse_buttons_released.add(button)
    end

    # Set mouse wheel movement
    def set_mouse_wheel(amount : Float32)
      @mouse_wheel = amount
    end

    # Simulate key press (pressed this frame)
    def press_key(key : RL::KeyboardKey)
      @keys_pressed.add(key)
      @keys_down.add(key)
    end

    # Simulate key hold (already down from previous frame)
    def hold_key(key : RL::KeyboardKey)
      @keys_down.add(key)
    end

    # Simulate key release
    def release_key(key : RL::KeyboardKey)
      @keys_down.delete(key)
      @keys_released.add(key)
    end

    # Queue a character for text input
    def queue_char(char : Char)
      @char_queue << char.ord
    end

    # Queue a string for text input
    def type_text(text : String)
      text.each_char { |c| queue_char(c) }
    end

    # Set window size
    def set_window_size(width : Int32, height : Int32)
      @screen_width = width
      @screen_height = height
      @window_resized = true
    end

    # Signal window should close
    def request_close
      @should_close = true
    end

    # Clear per-frame state (call at end of each simulated frame)
    def end_frame
      @mouse_buttons_pressed.clear
      @mouse_buttons_released.clear
      @keys_pressed.clear
      @keys_released.clear
      @mouse_delta = RL::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      @mouse_wheel = 0.0_f32
      @window_resized = false
    end

    # Reset all state
    def reset
      @mouse_position = RL::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      @mouse_delta = RL::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      @mouse_wheel = 0.0_f32
      @mouse_buttons_pressed.clear
      @mouse_buttons_down.clear
      @mouse_buttons_released.clear
      @keys_pressed.clear
      @keys_down.clear
      @keys_released.clear
      @char_queue.clear
      @window_resized = false
      @should_close = false
    end
  end

  # Global input provider instance - can be swapped for testing
  class_property input : InputProvider = RaylibInputProvider.new

  # Convenience method to use simulated input
  def self.use_simulated_input : SimulatedInputProvider
    sim = SimulatedInputProvider.new
    @@input = sim
    sim
  end

  # Convenience method to use real Raylib input
  def self.use_real_input
    @@input = RaylibInputProvider.new
  end
end
