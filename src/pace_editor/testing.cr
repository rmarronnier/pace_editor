# Testing support module for PACE Editor
# Provides e2e testing infrastructure similar to Cypress/Capybara

require "./testing/input_provider"
require "./testing/test_harness"

module PaceEditor::Testing
  VERSION = "1.0.0"

  # Check if we're in test mode
  class_property? test_mode : Bool = false

  # Enable test mode
  def self.enable_test_mode
    @@test_mode = true
  end

  # Disable test mode and restore normal operation
  def self.disable_test_mode
    @@test_mode = false
    use_real_input
  end
end
