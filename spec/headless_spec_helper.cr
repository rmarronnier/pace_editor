require "spec"

# Minimal requires for headless testing
# Don't load the full pace_editor which includes raylib

# Just require the specific modules we need for testing
require "../src/pace_editor/core/editor_state"
require "../src/pace_editor/core/project"
require "../src/pace_editor/models"

# Mock Raylib types for headless testing
module Raylib
  struct Color
    property r : UInt8
    property g : UInt8
    property b : UInt8
    property a : UInt8

    def initialize(@r : UInt8, @g : UInt8, @b : UInt8, @a : UInt8)
    end
  end

  struct Vector2
    property x : Float32
    property y : Float32

    def initialize(@x : Float32, @y : Float32)
    end
  end

  struct Rectangle
    property x : Float32
    property y : Float32
    property width : Float32
    property height : Float32

    def initialize(@x : Float32, @y : Float32, @width : Float32, @height : Float32)
    end
  end
end

# Create RL alias
alias RL = Raylib

# Define some color constants
module Raylib
  WHITE     = Color.new(255_u8, 255_u8, 255_u8, 255_u8)
  BLACK     = Color.new(0_u8, 0_u8, 0_u8, 255_u8)
  GRAY      = Color.new(130_u8, 130_u8, 130_u8, 255_u8)
  LIGHTGRAY = Color.new(200_u8, 200_u8, 200_u8, 255_u8)
  DARKGRAY  = Color.new(80_u8, 80_u8, 80_u8, 255_u8)
end

# Don't include test_character as it depends on Character class
