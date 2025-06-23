require "spec"
require "../src/pace_editor"
require "./support/test_character"

# Check if we should use headless mode for UI tests
HEADLESS_MODE = ENV["HEADLESS_SPECS"]? == "true" || ENV["CI"]? == "true"

# Helper module for tests that require Raylib
module RaylibTestHelper
  @@initialized = false

  # Initialize Raylib in headless mode for tests
  def self.init
    return if @@initialized

    unless HEADLESS_MODE
      # Set config flags before window initialization
      RL.set_config_flags(RL::ConfigFlags::WindowHidden)

      # Create a minimal window for testing
      RL.init_window(100, 100, "Test Window")

      # Set target FPS to something reasonable for tests
      RL.set_target_fps(60)
    end

    @@initialized = true
  end

  # Clean up Raylib after tests
  def self.cleanup
    if @@initialized && !HEADLESS_MODE
      RL.close_window if RL.window_ready?
      @@initialized = false
    end
  end

  # Check if Raylib is initialized
  def self.initialized?
    if HEADLESS_MODE
      false # In headless mode, we don't initialize Raylib
    else
      @@initialized && RL.window_ready?
    end
  end
end

# Set up hooks for Raylib tests
Spec.before_suite do
  # Tests that need Raylib will call RaylibTestHelper.init explicitly
end

Spec.after_suite do
  RaylibTestHelper.cleanup
end
