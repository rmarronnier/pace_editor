# E2E Test Helper for PACE Editor
# Provides setup and teardown for e2e tests

require "../spec_helper"
require "../support/testing"

# E2E tests need a different setup than unit tests
module E2ETestHelper
  # Create a temporary project directory for testing
  def self.create_temp_project_dir : String
    temp_dir = File.tempname("pace_e2e_test")
    Dir.mkdir_p(temp_dir)
    Dir.mkdir_p(File.join(temp_dir, "assets"))
    Dir.mkdir_p(File.join(temp_dir, "assets", "backgrounds"))
    Dir.mkdir_p(File.join(temp_dir, "assets", "characters"))
    Dir.mkdir_p(File.join(temp_dir, "assets", "sounds"))
    Dir.mkdir_p(File.join(temp_dir, "scenes"))
    Dir.mkdir_p(File.join(temp_dir, "scripts"))
    Dir.mkdir_p(File.join(temp_dir, "dialogs"))
    temp_dir
  end

  # Clean up temporary project directory
  def self.cleanup_temp_dir(dir : String)
    FileUtils.rm_rf(dir) if Dir.exists?(dir)
  end

  # Create a test harness with a pre-configured project
  def self.create_harness_with_project(project_name : String = "TestProject") : PaceEditor::Testing::TestHarness
    harness = PaceEditor::Testing::TestHarness.new

    # Create a temporary project directory
    project_dir = create_temp_project_dir

    # Create the project through the editor state
    harness.editor.state.create_new_project(project_name, project_dir)

    harness
  end

  # Create a test harness with a project and a scene
  def self.create_harness_with_scene(
    project_name : String = "TestProject",
    scene_name : String = "test_scene"
  ) : PaceEditor::Testing::TestHarness
    harness = create_harness_with_project(project_name)

    # Create a new scene
    if project = harness.editor.state.current_project
      scene = PointClickEngine::Scenes::Scene.new(scene_name)
      project.scenes << scene_name

      # Save the scene file
      scene_path = File.join(project.scenes_path, "#{scene_name}.yml")
      PaceEditor::IO::SceneIO.save_scene(scene, scene_path)

      # Set as current scene
      harness.editor.state.current_scene = scene
      harness.editor.state.current_mode = PaceEditor::EditorMode::Scene
    end

    harness
  end
end

# Matchers for e2e tests
module E2EMatchers
  # Check if the editor is in a specific mode
  def be_in_mode(expected_mode : PaceEditor::EditorMode)
    E2EModeMatcher.new(expected_mode)
  end

  # Check if a specific tool is selected
  def have_tool_selected(expected_tool : PaceEditor::Tool)
    E2EToolMatcher.new(expected_tool)
  end

  # Check if the editor has a project loaded
  def have_project_loaded
    E2EProjectLoadedMatcher.new
  end

  # Check if a specific object is selected
  def have_selected(object_name : String)
    E2ESelectedMatcher.new(object_name)
  end

  struct E2EModeMatcher
    def initialize(@expected : PaceEditor::EditorMode)
    end

    def matches?(harness : PaceEditor::Testing::TestHarness) : Bool
      harness.current_mode == @expected
    end

    def failure_message(harness : PaceEditor::Testing::TestHarness) : String
      "Expected mode #{@expected}, got #{harness.current_mode}"
    end
  end

  struct E2EToolMatcher
    def initialize(@expected : PaceEditor::Tool)
    end

    def matches?(harness : PaceEditor::Testing::TestHarness) : Bool
      harness.current_tool == @expected
    end

    def failure_message(harness : PaceEditor::Testing::TestHarness) : String
      "Expected tool #{@expected}, got #{harness.current_tool}"
    end
  end

  struct E2EProjectLoadedMatcher
    def matches?(harness : PaceEditor::Testing::TestHarness) : Bool
      harness.has_project?
    end

    def failure_message(harness : PaceEditor::Testing::TestHarness) : String
      "Expected project to be loaded, but no project is loaded"
    end
  end

  struct E2ESelectedMatcher
    def initialize(@expected : String)
    end

    def matches?(harness : PaceEditor::Testing::TestHarness) : Bool
      harness.is_selected?(@expected)
    end

    def failure_message(harness : PaceEditor::Testing::TestHarness) : String
      "Expected '#{@expected}' to be selected, but selected objects are: #{harness.selected_objects}"
    end
  end
end

# UI interaction helpers for E2E tests
module E2EUIHelpers
  # Click on a mode button in the menu bar
  def self.click_mode_button(harness : PaceEditor::Testing::TestHarness, mode : PaceEditor::EditorMode)
    menu_bar = harness.editor.menu_bar
    bounds = menu_bar.test_mode_button_bounds(mode)

    click_x = bounds[:x] + bounds[:width] // 2
    click_y = bounds[:y] + bounds[:height] // 2

    harness.input.set_mouse_position(click_x.to_f32, click_y.to_f32)
    harness.input.press_mouse_button(RL::MouseButton::Left)
    menu_bar.test_handle_mode_button_click(harness.input)
    harness.input.release_mouse_button(RL::MouseButton::Left)
    # Clear input state so subsequent operations aren't affected
    harness.input.end_frame
  end

  # Click on a tool button in the tool palette
  # Note: toggle_button_with_input checks for mouse_button_released?, so we need to
  # set up the release state before calling update_with_input
  def self.click_tool_button(harness : PaceEditor::Testing::TestHarness, tool : PaceEditor::Tool)
    tool_palette = harness.editor.tool_palette
    x, y = tool_palette.get_tool_button_position(tool)

    # Click in center of button (60x60)
    click_x = x + 30
    click_y = y + 30

    harness.input.set_mouse_position(click_x.to_f32, click_y.to_f32)
    # toggle_button checks for released, so set released state before update
    harness.input.release_mouse_button(RL::MouseButton::Left)
    tool_palette.update_with_input(harness.input)
    # Clear input state so subsequent operations aren't affected
    harness.input.end_frame
  end

  # Switch to a mode via UI click
  def self.switch_to_mode(harness : PaceEditor::Testing::TestHarness, mode : PaceEditor::EditorMode)
    click_mode_button(harness, mode)
  end

  # Select a tool via UI click
  def self.select_tool(harness : PaceEditor::Testing::TestHarness, tool : PaceEditor::Tool)
    click_tool_button(harness, tool)
  end
end

# Add assertion helpers
class PaceEditor::Testing::TestHarness
  # Assert that the editor is in a specific mode
  def assert_mode(expected : PaceEditor::EditorMode)
    raise "Expected mode #{expected}, got #{current_mode}" unless current_mode == expected
  end

  # Assert that a specific tool is selected
  def assert_tool(expected : PaceEditor::Tool)
    raise "Expected tool #{expected}, got #{current_tool}" unless current_tool == expected
  end

  # Assert that an object is selected
  def assert_selected(object_name : String)
    raise "Expected '#{object_name}' to be selected" unless is_selected?(object_name)
  end

  # Assert hotspot count
  def assert_hotspot_count(expected : Int32)
    actual = hotspot_count
    raise "Expected #{expected} hotspots, got #{actual}" unless actual == expected
  end

  # Assert character count
  def assert_character_count(expected : Int32)
    actual = character_count
    raise "Expected #{expected} characters, got #{actual}" unless actual == expected
  end

  # Assert a project is loaded
  def assert_has_project
    raise "Expected a project to be loaded" unless has_project?
  end

  # Assert a scene is loaded
  def assert_has_scene
    raise "Expected a scene to be loaded" unless has_scene?
  end

  # Assert camera position (with tolerance)
  def assert_camera_position(expected_x : Float32, expected_y : Float32, tolerance : Float32 = 1.0_f32)
    pos = camera_position
    dx = (pos[:x] - expected_x).abs
    dy = (pos[:y] - expected_y).abs
    if dx > tolerance || dy > tolerance
      raise "Expected camera at (#{expected_x}, #{expected_y}), got (#{pos[:x]}, #{pos[:y]})"
    end
  end

  # Assert zoom level (with tolerance)
  def assert_zoom(expected : Float32, tolerance : Float32 = 0.01_f32)
    actual = zoom
    if (actual - expected).abs > tolerance
      raise "Expected zoom #{expected}, got #{actual}"
    end
  end
end
