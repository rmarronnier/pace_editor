require "raylib-cr"

module PaceEditor::UI
  # Pre-allocated color constants to avoid performance issues
  # from creating new color objects in draw loops
  module Colors
    # Basic colors
    TRANSPARENT  = RL::Color.new(r: 0, g: 0, b: 0, a: 0)
    DARK_OVERLAY = RL::Color.new(r: 0, g: 0, b: 0, a: 150)

    # Panel colors
    PANEL_DARK    = RL::Color.new(r: 30, g: 30, b: 30, a: 255)
    PANEL_MEDIUM  = RL::Color.new(r: 40, g: 40, b: 40, a: 255)
    PANEL_LIGHT   = RL::Color.new(r: 50, g: 50, b: 50, a: 255)
    PANEL_LIGHTER = RL::Color.new(r: 60, g: 60, b: 60, a: 255)

    # Workspace colors
    WORKSPACE_BG = RL::Color.new(r: 35, g: 35, b: 35, a: 255)
    GRID_COLOR   = RL::Color.new(r: 60, g: 60, b: 60, a: 255)

    # Selection colors
    SELECTION_FILL    = RL::Color.new(r: 100, g: 150, b: 200, a: 100)
    SELECTION_OUTLINE = RL::Color.new(r: 100, g: 150, b: 200, a: 255)

    # Node colors
    NODE_DEFAULT  = RL::Color.new(r: 80, g: 80, b: 80, a: 255)
    NODE_SELECTED = RL::Color.new(r: 100, g: 150, b: 200, a: 255)
    NODE_HOVER    = RL::Color.new(r: 90, g: 90, b: 90, a: 255)

    # Button colors
    BUTTON_NORMAL  = RL::Color.new(r: 60, g: 60, b: 60, a: 255)
    BUTTON_HOVER   = RL::Color.new(r: 70, g: 70, b: 70, a: 255)
    BUTTON_PRESSED = RL::Color.new(r: 50, g: 50, b: 50, a: 255)

    # Text colors
    TEXT_PRIMARY   = RL::WHITE
    TEXT_SECONDARY = RL::Color.new(r: 200, g: 200, b: 200, a: 255)
    TEXT_MUTED     = RL::Color.new(r: 150, g: 150, b: 150, a: 255)

    # Hotspot colors
    HOTSPOT_NORMAL   = RL::Color.new(r: 255, g: 255, b: 0, a: 100)
    HOTSPOT_SELECTED = RL::Color.new(r: 255, g: 165, b: 0, a: 150)
    HOTSPOT_OUTLINE  = RL::Color.new(r: 255, g: 255, b: 0, a: 255)

    # Character colors
    CHARACTER_BOUNDS = RL::Color.new(r: 0, g: 255, b: 0, a: 100)

    # Tool preview colors
    TOOL_PREVIEW = RL::Color.new(r: 255, g: 255, b: 255, a: 100)

    # Creation overlay
    CREATION_OVERLAY = RL::Color.new(r: 0, g: 0, b: 0, a: 180)
  end
end
