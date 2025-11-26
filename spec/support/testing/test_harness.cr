# Test harness for e2e testing of PACE Editor
# Provides Cypress/Capybara-style API for testing UI interactions

module PaceEditor::Testing
  # Screenshot capture for visual regression testing
  class Screenshot
    getter pixels : Array(UInt8)
    getter width : Int32
    getter height : Int32
    getter timestamp : Time

    def initialize(@pixels : Array(UInt8), @width : Int32, @height : Int32)
      @timestamp = Time.utc
    end

    # Save screenshot to PNG file
    def save(path : String)
      # Use Raylib's image export
      image = RL::Image.new
      image.data = @pixels.to_unsafe.as(Void*)
      image.width = @width
      image.height = @height
      image.format = RL::PixelFormat::UncompressedR8g8b8a8
      image.mipmaps = 1
      RL.export_image(image, path)
    end

    # Compare with another screenshot (returns similarity 0.0-1.0)
    def compare(other : Screenshot) : Float64
      return 0.0 if width != other.width || height != other.height

      matching_pixels = 0
      total_pixels = width * height

      (0...total_pixels).each do |i|
        offset = i * 4
        if @pixels[offset] == other.pixels[offset] &&
           @pixels[offset + 1] == other.pixels[offset + 1] &&
           @pixels[offset + 2] == other.pixels[offset + 2]
          matching_pixels += 1
        end
      end

      matching_pixels.to_f64 / total_pixels.to_f64
    end
  end

  # Action recording for debugging test failures
  record TestAction,
    type : String,
    details : String,
    timestamp : Time = Time.utc

  # Test harness for controlling the editor in tests
  class TestHarness
    getter editor : Core::EditorWindow
    getter input : SimulatedInputProvider
    getter actions : Array(TestAction) = [] of TestAction
    getter screenshots : Array(Screenshot) = [] of Screenshot

    # Layout constants (should match EditorWindow)
    MENU_HEIGHT        =  30
    TOOL_PALETTE_WIDTH =  80
    PROPERTY_PANEL_WIDTH = 300

    # Default window size
    DEFAULT_WIDTH  = 1400
    DEFAULT_HEIGHT = 900

    @frame_count : Int32 = 0
    @render_texture : RL::RenderTexture2D?
    @initialized : Bool = false

    def initialize(window_width : Int32 = DEFAULT_WIDTH, window_height : Int32 = DEFAULT_HEIGHT)
      # Set up simulated input
      @input = PaceEditor::Testing.use_simulated_input
      @input.set_window_size(window_width, window_height)

      # Create the editor window (but don't run the main loop)
      @editor = Core::EditorWindow.new
    end

    # Initialize Raylib for rendering (needed for visual tests)
    def init_graphics(hidden : Bool = true)
      return if @initialized

      if hidden
        RL.set_config_flags(RL::ConfigFlags::WindowHidden)
      end

      RL.init_window(@input.get_screen_width, @input.get_screen_height, "PACE Editor - Test Mode")
      RL.set_target_fps(60)

      # Create render texture for capturing screenshots
      @render_texture = RL.load_render_texture(@input.get_screen_width, @input.get_screen_height)

      @initialized = true
    end

    # Clean up resources
    def cleanup
      if rt = @render_texture
        RL.unload_render_texture(rt)
      end

      if @initialized
        RL.close_window
        @initialized = false
      end

      # Restore real input
      PaceEditor::Testing.use_real_input
    end

    # === Frame Control ===

    # Advance one frame
    def step_frame
      @editor.update_for_test(@input)
      @input.end_frame
      @frame_count += 1
    end

    # Advance multiple frames
    def step_frames(count : Int32)
      count.times { step_frame }
    end

    # Step frames until condition is met or timeout
    def step_until(max_frames : Int32 = 60, &block : -> Bool)
      max_frames.times do
        return true if block.call
        step_frame
      end
      false
    end

    # === Mouse Actions ===

    # Click at screen coordinates
    def click(x : Int32, y : Int32, button : RL::MouseButton = RL::MouseButton::Left)
      record_action("click", "#{x}, #{y} button=#{button}")

      @input.set_mouse_position(x.to_f32, y.to_f32)
      step_frame  # Move mouse

      @input.press_mouse_button(button)
      step_frame  # Press

      @input.release_mouse_button(button)
      step_frame  # Release
    end

    # Click at a named UI element position
    def click_at(element : Symbol)
      pos = get_element_position(element)
      click(pos[:x], pos[:y])
    end

    # Double click at coordinates
    def double_click(x : Int32, y : Int32)
      record_action("double_click", "#{x}, #{y}")
      click(x, y)
      click(x, y)
    end

    # Right click at coordinates
    def right_click(x : Int32, y : Int32)
      click(x, y, RL::MouseButton::Right)
    end

    # Drag from one position to another
    def drag(from_x : Int32, from_y : Int32, to_x : Int32, to_y : Int32, steps : Int32 = 10)
      record_action("drag", "from #{from_x},#{from_y} to #{to_x},#{to_y}")

      @input.set_mouse_position(from_x.to_f32, from_y.to_f32)
      step_frame

      @input.press_mouse_button(RL::MouseButton::Left)
      step_frame

      # Interpolate movement
      steps.times do |i|
        progress = (i + 1).to_f32 / steps.to_f32
        current_x = from_x + ((to_x - from_x) * progress)
        current_y = from_y + ((to_y - from_y) * progress)
        @input.set_mouse_position(current_x, current_y)
        @input.hold_mouse_button(RL::MouseButton::Left)
        step_frame
      end

      @input.release_mouse_button(RL::MouseButton::Left)
      step_frame
    end

    # Move mouse to position (without clicking)
    def move_mouse(x : Int32, y : Int32)
      @input.set_mouse_position(x.to_f32, y.to_f32)
      step_frame
    end

    # Scroll mouse wheel
    def scroll(amount : Float32)
      record_action("scroll", amount.to_s)
      @input.set_mouse_wheel(amount)
      step_frame
    end

    # === Keyboard Actions ===

    # Press and release a key
    def press_key(key : RL::KeyboardKey)
      record_action("key_press", key.to_s)
      @input.press_key(key)
      step_frame
      @input.release_key(key)
      step_frame
    end

    # Hold a key down (for modifier combinations)
    def hold_key(key : RL::KeyboardKey)
      @input.hold_key(key)
    end

    # Release a held key
    def release_key(key : RL::KeyboardKey)
      @input.release_key(key)
      step_frame
    end

    # Press a key combination (e.g., Ctrl+S)
    def key_combo(*keys : RL::KeyboardKey)
      record_action("key_combo", keys.map(&.to_s).join("+"))

      # Hold all modifier keys
      keys[0...-1].each { |key| @input.hold_key(key) }

      # Press the final key
      @input.press_key(keys.last)
      step_frame

      # Release all keys
      keys.reverse_each { |key| @input.release_key(key) }
      step_frame
    end

    # Type text into focused input
    def type_text(text : String)
      record_action("type", text)
      @input.type_text(text)

      # Process one character per frame
      text.size.times { step_frame }
    end

    # Clear text input (select all + delete)
    def clear_text
      key_combo(RL::KeyboardKey::LeftControl, RL::KeyboardKey::A)
      press_key(RL::KeyboardKey::Delete)
    end

    # === High-Level UI Actions ===

    # Click a menu item by name
    def click_menu(menu_name : String)
      record_action("click_menu", menu_name)

      # Calculate menu position based on menu name
      # Menu items are positioned horizontally starting at x=10
      menu_positions = {
        "File"     => 30,
        "Edit"     => 80,
        "View"     => 130,
        "Scene"    => 180,
        "Project"  => 240,
        "Tools"    => 310,
        "Help"     => 370,
      }

      x = menu_positions[menu_name]? || 30
      y = MENU_HEIGHT // 2

      click(x, y)
    end

    # Click a menu dropdown item
    def click_menu_item(item_name : String, menu_y_offset : Int32 = 0)
      record_action("click_menu_item", item_name)

      # Menu items are in dropdown below menu bar
      # Each item is approximately 25 pixels high
      x = 50  # Approximate center of dropdown
      y = MENU_HEIGHT + 15 + (menu_y_offset * 25)

      click(x, y)
    end

    # Select a tool from the tool palette
    def select_tool(tool : Tool)
      record_action("select_tool", tool.to_s)

      tool_positions = {
        Tool::Select => 40,
        Tool::Move   => 90,
        Tool::Place  => 140,
        Tool::Delete => 190,
        Tool::Paint  => 240,
        Tool::Zoom   => 290,
      }

      y = tool_positions[tool]? || 40
      x = TOOL_PALETTE_WIDTH // 2

      click(x, y)
    end

    # Click in the scene viewport at world coordinates
    def click_canvas(world_x : Int32, world_y : Int32)
      screen_pos = world_to_screen(world_x, world_y)
      click(screen_pos[:x], screen_pos[:y])
    end

    # Drag in the scene viewport between world coordinates
    def drag_canvas(from_world_x : Int32, from_world_y : Int32, to_world_x : Int32, to_world_y : Int32)
      from_screen = world_to_screen(from_world_x, from_world_y)
      to_screen = world_to_screen(to_world_x, to_world_y)
      drag(from_screen[:x], from_screen[:y], to_screen[:x], to_screen[:y])
    end

    # Type into a text field in the property panel
    def type_in_property(property_name : String, value : String)
      record_action("type_in_property", "#{property_name}=#{value}")

      # Click on property field (approximate positions in property panel)
      property_x = @input.get_screen_width - PROPERTY_PANEL_WIDTH + 150

      # Would need to calculate Y based on property name
      # For now, just type the text
      clear_text
      type_text(value)
    end

    # Click a button in a dialog
    def click_button(button_text : String)
      record_action("click_button", button_text)

      # Button positions depend on the dialog
      # This is a simplified implementation
      screen_center_x = @input.get_screen_width // 2
      screen_center_y = @input.get_screen_height // 2

      case button_text.downcase
      when "ok", "create", "save", "yes"
        click(screen_center_x - 50, screen_center_y + 80)
      when "cancel", "no", "close"
        click(screen_center_x + 50, screen_center_y + 80)
      else
        # Default to center of dialog
        click(screen_center_x, screen_center_y + 80)
      end
    end

    # === State Assertions ===

    # Get current editor mode
    def current_mode : EditorMode
      @editor.state.current_mode
    end

    # Get current tool
    def current_tool : Tool
      @editor.state.current_tool
    end

    # Check if a project is loaded
    def has_project? : Bool
      !@editor.state.current_project.nil?
    end

    # Get project name
    def project_name : String?
      @editor.state.current_project.try(&.name)
    end

    # Check if a scene is loaded
    def has_scene? : Bool
      !@editor.state.current_scene.nil?
    end

    # Get scene name
    def scene_name : String?
      @editor.state.current_scene.try(&.name)
    end

    # Get hotspot count in current scene
    def hotspot_count : Int32
      @editor.state.current_scene.try(&.hotspots.size) || 0
    end

    # Get character count in current scene
    def character_count : Int32
      @editor.state.current_scene.try(&.characters.size) || 0
    end

    # Get selected object name
    def selected_object : String?
      @editor.state.selected_object
    end

    # Check if object is selected
    def is_selected?(name : String) : Bool
      @editor.state.selected_object == name ||
        @editor.state.selected_hotspots.includes?(name) ||
        @editor.state.selected_characters.includes?(name)
    end

    # Get all selected objects
    def selected_objects : Array(String)
      result = [] of String
      if obj = @editor.state.selected_object
        result << obj
      end
      result.concat(@editor.state.selected_hotspots)
      result.concat(@editor.state.selected_characters)
      result.uniq
    end

    # Check if editor has unsaved changes
    def is_dirty? : Bool
      @editor.state.is_dirty
    end

    # Get camera position
    def camera_position : {x: Float32, y: Float32}
      {x: @editor.state.camera_x, y: @editor.state.camera_y}
    end

    # Get zoom level
    def zoom : Float32
      @editor.state.zoom
    end

    # Check if a dialog is visible
    def dialog_visible?(dialog_name : String) : Bool
      case dialog_name.downcase
      when "new_project"
        @editor.state.show_new_project_dialog
      when "hotspot_action"
        @editor.hotspot_action_dialog.visible
      when "script_editor"
        @editor.script_editor.visible
      when "background_import"
        @editor.background_import_dialog.visible
      when "game_export"
        @editor.game_export_dialog.visible
      when "scene_wizard"
        @editor.scene_creation_wizard.visible
      else
        false
      end
    end

    # Get UI state
    def ui_state : UI::UIState
      @editor.ui_state
    end

    # === Visual Testing ===

    # Capture current frame as screenshot
    def capture_screenshot : Screenshot?
      return nil unless @initialized
      return nil unless rt = @render_texture

      # Render to texture
      RL.begin_texture_mode(rt)
      @editor.draw_for_test
      RL.end_texture_mode

      # Get pixels from texture
      image = RL.load_image_from_texture(rt.texture)

      # Convert to pixel array
      width = image.width
      height = image.height
      pixels = Array(UInt8).new(width * height * 4, 0_u8)

      # Copy pixel data
      data_ptr = image.data.as(UInt8*)
      (width * height * 4).times do |i|
        pixels[i] = data_ptr[i]
      end

      RL.unload_image(image)

      screenshot = Screenshot.new(pixels, width, height)
      @screenshots << screenshot
      screenshot
    end

    # Compare current frame with a reference screenshot
    def compare_with_reference(reference_path : String, threshold : Float64 = 0.99) : Bool
      current = capture_screenshot
      return false unless current

      # Load reference image
      ref_image = RL.load_image(reference_path)
      return false if ref_image.width == 0

      # Create reference screenshot
      ref_pixels = Array(UInt8).new(ref_image.width * ref_image.height * 4, 0_u8)
      ref_data_ptr = ref_image.data.as(UInt8*)
      (ref_image.width * ref_image.height * 4).times do |i|
        ref_pixels[i] = ref_data_ptr[i]
      end

      reference = Screenshot.new(ref_pixels, ref_image.width, ref_image.height)
      RL.unload_image(ref_image)

      similarity = current.compare(reference)
      similarity >= threshold
    end

    # Save current frame to file
    def save_screenshot(path : String)
      if screenshot = capture_screenshot
        screenshot.save(path)
      end
    end

    # === Utility Methods ===

    # Convert world coordinates to screen coordinates
    def world_to_screen(world_x : Int32, world_y : Int32) : {x: Int32, y: Int32}
      state = @editor.state
      viewport_x = TOOL_PALETTE_WIDTH
      viewport_y = MENU_HEIGHT

      screen_x = ((world_x - state.camera_x) * state.zoom + viewport_x).to_i
      screen_y = ((world_y - state.camera_y) * state.zoom + viewport_y).to_i

      {x: screen_x, y: screen_y}
    end

    # Convert screen coordinates to world coordinates
    def screen_to_world(screen_x : Int32, screen_y : Int32) : {x: Int32, y: Int32}
      state = @editor.state
      viewport_x = TOOL_PALETTE_WIDTH
      viewport_y = MENU_HEIGHT

      world_x = ((screen_x - viewport_x) / state.zoom + state.camera_x).to_i
      world_y = ((screen_y - viewport_y) / state.zoom + state.camera_y).to_i

      {x: world_x, y: world_y}
    end

    # Get approximate position of a UI element
    private def get_element_position(element : Symbol) : {x: Int32, y: Int32}
      width = @input.get_screen_width
      height = @input.get_screen_height

      case element
      when :menu_file
        {x: 30, y: 15}
      when :menu_edit
        {x: 80, y: 15}
      when :menu_view
        {x: 130, y: 15}
      when :tool_select
        {x: 40, y: 60}
      when :tool_move
        {x: 40, y: 110}
      when :tool_place
        {x: 40, y: 160}
      when :canvas_center
        {x: TOOL_PALETTE_WIDTH + (width - TOOL_PALETTE_WIDTH - PROPERTY_PANEL_WIDTH) // 2,
         y: MENU_HEIGHT + (height - MENU_HEIGHT) // 2}
      when :property_panel
        {x: width - PROPERTY_PANEL_WIDTH // 2, y: height // 2}
      else
        {x: width // 2, y: height // 2}
      end
    end

    # Record an action for debugging
    private def record_action(type : String, details : String)
      @actions << TestAction.new(type: type, details: details)
    end

    # Get action history as string (for debugging)
    def action_log : String
      @actions.map { |a| "[#{a.timestamp}] #{a.type}: #{a.details}" }.join("\n")
    end

    # Clear action history
    def clear_actions
      @actions.clear
    end
  end
end
