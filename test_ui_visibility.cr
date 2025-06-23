require "./src/pace_editor"
require "./spec/support/test_character"

# Test runner to visually verify UI elements are rendering
class UIVisibilityTest
  def initialize
    @window = PaceEditor::Core::EditorWindow.new
    @test_mode = true
    @test_messages = [] of String
  end
  
  def run
    # Initialize Raylib
    RL.init_window(1400, 900, "PACE Editor - UI Visibility Test")
    RL.set_window_state(RL::ConfigFlags::WindowResizable)
    RL.set_target_fps(60)
    
    # Create test project
    setup_test_project
    
    # Add test messages
    @test_messages << "UI Visibility Test Mode"
    @test_messages << "Press ESC to exit"
    @test_messages << ""
    @test_messages << "Things to verify:"
    @test_messages << "1. Menu bar at top"
    @test_messages << "2. Tool palette on left"
    @test_messages << "3. Property panel on right"
    @test_messages << "4. Scene hierarchy bottom-left"
    @test_messages << "5. Main viewport in center"
    @test_messages << ""
    @test_messages << "Press 1-6 to test tool buttons"
    @test_messages << "Press G to toggle grid"
    @test_messages << "Press H to toggle hotspot visibility"
    
    # Main test loop
    while !RL.close_window?
      update
      draw
    end
    
    RL.close_window
  end
  
  private def setup_test_project
    # Create a test project with some content
    project = PaceEditor::Core::Project.new
    project.name = "UI Test Project"
    project.project_path = "/tmp/ui_test"
    
    # Add some test scenes
    project.scenes << "main_menu"
    project.scenes << "level_1"
    project.scenes << "level_2"
    
    # Add some test assets
    project.backgrounds << "bg_forest.png"
    project.backgrounds << "bg_castle.png"
    project.characters << "hero.png"
    project.characters << "enemy.png"
    
    @window.state.current_project = project
    
    # Create a test scene with objects
    if scene = create_test_scene
      @window.state.current_project.not_nil!.current_scene = "test_scene"
      # In real app, would save scene
    end
  end
  
  private def create_test_scene
    scene = PointClickEngine::Scenes::Scene.new("test_scene")
    
    # Add test hotspots
    hotspot1 = PointClickEngine::Scenes::Hotspot.new(
      "door",
      RL::Vector2.new(x: 200, y: 300),
      RL::Vector2.new(x: 100, y: 150)
    )
    hotspot1.description = "A wooden door"
    scene.hotspots << hotspot1
    
    hotspot2 = PointClickEngine::Scenes::Hotspot.new(
      "window",
      RL::Vector2.new(x: 400, y: 200),
      RL::Vector2.new(x: 80, y: 100)
    )
    hotspot2.description = "A glass window"
    scene.hotspots << hotspot2
    
    # Add test character
    character = PointClickEngine::Characters::TestCharacter.new("test_npc")
    character.position = RL::Vector2.new(x: 500, y: 350)
    character.size = RL::Vector2.new(x: 64, y: 128)
    scene.characters << character
    
    scene
  end
  
  private def update
    # Handle test shortcuts
    if RL.key_pressed?(RL::KeyboardKey::One)
      @window.state.current_tool = PaceEditor::Tool::Select
      @test_messages << "Tool: Select"
    elsif RL.key_pressed?(RL::KeyboardKey::Two)
      @window.state.current_tool = PaceEditor::Tool::Move
      @test_messages << "Tool: Move"
    elsif RL.key_pressed?(RL::KeyboardKey::Three)
      @window.state.current_tool = PaceEditor::Tool::Place
      @test_messages << "Tool: Place"
    elsif RL.key_pressed?(RL::KeyboardKey::Four)
      @window.state.current_tool = PaceEditor::Tool::Delete
      @test_messages << "Tool: Delete"
    elsif RL.key_pressed?(RL::KeyboardKey::Five)
      @window.state.current_tool = PaceEditor::Tool::Paint
      @test_messages << "Tool: Paint"
    elsif RL.key_pressed?(RL::KeyboardKey::Six)
      @window.state.current_tool = PaceEditor::Tool::Zoom
      @test_messages << "Tool: Zoom"
    end
    
    if RL.key_pressed?(RL::KeyboardKey::G)
      @window.state.show_grid = !@window.state.show_grid
      @test_messages << "Grid: #{@window.state.show_grid ? "ON" : "OFF"}"
    end
    
    if RL.key_pressed?(RL::KeyboardKey::H)
      @window.state.show_hotspots = !@window.state.show_hotspots
      @test_messages << "Hotspots: #{@window.state.show_hotspots ? "VISIBLE" : "HIDDEN"}"
    end
    
    # Keep only recent messages
    @test_messages = @test_messages.last(15) if @test_messages.size > 15
    
    # Update window components
    @window.menu_bar.update
    @window.tool_palette.update
    @window.property_panel.update
    @window.scene_hierarchy.update
    @window.scene_editor.update
  end
  
  private def draw
    RL.begin_drawing
    RL.clear_background(RL::Color.new(r: 50, g: 50, b: 50, a: 255))
    
    # Draw all UI components
    @window.menu_bar.draw_background
    @window.tool_palette.draw
    
    # Draw viewport background
    viewport_rect = RL::Rectangle.new(
      x: PaceEditor::Core::EditorWindow::TOOL_PALETTE_WIDTH.to_f,
      y: PaceEditor::Core::EditorWindow::MENU_HEIGHT.to_f,
      width: (RL.get_screen_width - PaceEditor::Core::EditorWindow::TOOL_PALETTE_WIDTH - PaceEditor::Core::EditorWindow::PROPERTY_PANEL_WIDTH).to_f,
      height: (RL.get_screen_height - PaceEditor::Core::EditorWindow::MENU_HEIGHT).to_f
    )
    RL.draw_rectangle_rec(viewport_rect, RL::Color.new(r: 40, g: 40, b: 40, a: 255))
    
    # Draw scene editor content
    RL.begin_scissor_mode(
      viewport_rect.x.to_i,
      viewport_rect.y.to_i,
      viewport_rect.width.to_i,
      viewport_rect.height.to_i
    )
    @window.scene_editor.draw
    RL.end_scissor_mode
    
    # Draw other panels
    @window.scene_hierarchy.draw
    @window.property_panel.draw
    
    # Draw menu bar content last (on top)
    @window.menu_bar.draw_content
    
    # Draw test overlay
    draw_test_overlay
    
    RL.end_drawing
  end
  
  private def draw_test_overlay
    # Semi-transparent background for test messages
    overlay_x = RL.get_screen_width - 400
    overlay_y = 100
    overlay_width = 380
    overlay_height = @test_messages.size * 20 + 20
    
    RL.draw_rectangle(overlay_x, overlay_y, overlay_width, overlay_height,
      RL::Color.new(r: 0, g: 0, b: 0, a: 200))
    RL.draw_rectangle_lines(overlay_x, overlay_y, overlay_width, overlay_height, RL::GREEN)
    
    # Draw test messages
    y = overlay_y + 10
    @test_messages.each do |msg|
      color = if msg.starts_with?("Tool:") || msg.starts_with?("Grid:") || msg.starts_with?("Hotspots:")
        RL::YELLOW
      elsif msg.empty?
        RL::WHITE
      else
        RL::WHITE
      end
      
      RL.draw_text(msg, overlay_x + 10, y, 14, color)
      y += 20
    end
  end
end

# Run the test
test = UIVisibilityTest.new
test.run