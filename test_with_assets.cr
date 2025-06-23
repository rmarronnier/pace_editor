require "./src/pace_editor"

# Test program demonstrating the editor with real assets
class AssetDemoEditor
  def initialize
    @window = PaceEditor::Core::EditorWindow.new
    @textures = {} of String => Raylib::Texture2D
  end
  
  def run
    # Initialize Raylib
    RL.init_window(1400, 900, "PACE Editor - Asset Demo")
    RL.set_window_state(RL::ConfigFlags::WindowResizable)
    RL.set_target_fps(60)
    
    # Load some UI textures
    load_ui_textures
    
    # Create demo project with scenes
    setup_demo_project
    
    puts "Asset Demo Started!"
    puts "==================="
    puts "Available assets loaded from /assets directory"
    puts "- Backgrounds: Oak Woods parallax layers"
    puts "- Characters: Knight, Farmer, Soldier, Orc"
    puts "- UI: Buttons, panels, cursors, icons"
    puts "- Objects: Decorations and interactive elements"
    
    # Main loop
    while !RL.close_window?
      update
      draw
    end
    
    # Cleanup
    @textures.each_value { |texture| RL.unload_texture(texture) }
    RL.close_window
  end
  
  private def load_ui_textures
    # Load button textures
    if File.exists?("assets/ui/buttons/button_normal.png")
      @textures["button_normal"] = RL.load_texture("assets/ui/buttons/button_normal.png")
      @textures["button_hover"] = RL.load_texture("assets/ui/buttons/button_hover.png")
      @textures["button_pressed"] = RL.load_texture("assets/ui/buttons/button_pressed.png")
    end
    
    # Load panel textures
    if File.exists?("assets/ui/panels/panel_background.png")
      @textures["panel_bg"] = RL.load_texture("assets/ui/panels/panel_background.png")
    end
    
    # Load background
    if File.exists?("assets/backgrounds/background_layer_1.png")
      @textures["bg_layer1"] = RL.load_texture("assets/backgrounds/background_layer_1.png")
      @textures["bg_layer2"] = RL.load_texture("assets/backgrounds/background_layer_2.png")
      @textures["bg_layer3"] = RL.load_texture("assets/backgrounds/background_layer_3.png")
    end
    
    # Load a character
    if File.exists?("assets/characters/knight/Idle.png")
      @textures["knight_idle"] = RL.load_texture("assets/characters/knight/Idle.png")
    end
  end
  
  private def setup_demo_project
    project = PaceEditor::Core::Project.new
    project.name = "Asset Demo Project"
    project.project_path = "/tmp/asset_demo"
    
    # Reference our actual assets
    project.backgrounds << "background_layer_1.png"
    project.backgrounds << "background_layer_2.png"
    project.backgrounds << "background_layer_3.png"
    
    project.characters << "knight/Idle.png"
    project.characters << "soldier/Soldier-Idle.png"
    project.characters << "orc/Orc-Idle.png"
    
    @window.state.current_project = project
    
    # Create a demo scene
    scene = PointClickEngine::Scenes::Scene.new("demo_scene")
    scene.background_path = "background_layer_3.png"
    
    # Add some objects
    lamp = PointClickEngine::Scenes::Hotspot.new(
      "lamp",
      RL::Vector2.new(x: 200, y: 400),
      RL::Vector2.new(x: 50, y: 100)
    )
    lamp.description = "A street lamp"
    scene.hotspots << lamp
    
    sign = PointClickEngine::Scenes::Hotspot.new(
      "sign",
      RL::Vector2.new(x: 600, y: 450),
      RL::Vector2.new(x: 60, y: 80)
    )
    sign.description = "Village sign"
    scene.hotspots << sign
    
    @window.state.current_project.not_nil!.current_scene = "demo_scene"
  end
  
  private def update
    # Update window components
    @window.menu_bar.update
    @window.tool_palette.update
    @window.property_panel.update
    @window.scene_hierarchy.update
    @window.scene_editor.update
  end
  
  private def draw
    RL.begin_drawing
    RL.clear_background(RL::Color.new(r: 30, g: 30, b: 30, a: 255))
    
    # Draw background layers (parallax effect)
    if bg3 = @textures["bg_layer3"]?
      RL.draw_texture_pro(
        bg3,
        RL::Rectangle.new(x: 0, y: 0, width: bg3.width.to_f, height: bg3.height.to_f),
        RL::Rectangle.new(
          x: PaceEditor::Core::EditorWindow::TOOL_PALETTE_WIDTH.to_f,
          y: PaceEditor::Core::EditorWindow::MENU_HEIGHT.to_f,
          width: (RL.get_screen_width - PaceEditor::Core::EditorWindow::TOOL_PALETTE_WIDTH - PaceEditor::Core::EditorWindow::PROPERTY_PANEL_WIDTH).to_f,
          height: (RL.get_screen_height - PaceEditor::Core::EditorWindow::MENU_HEIGHT).to_f
        ),
        RL::Vector2.new(x: 0, y: 0),
        0.0f32,
        RL::WHITE
      )
    end
    
    # Draw UI components
    @window.menu_bar.draw_background
    @window.tool_palette.draw
    
    # Draw scene editor
    viewport_rect = RL::Rectangle.new(
      x: PaceEditor::Core::EditorWindow::TOOL_PALETTE_WIDTH.to_f,
      y: PaceEditor::Core::EditorWindow::MENU_HEIGHT.to_f,
      width: (RL.get_screen_width - PaceEditor::Core::EditorWindow::TOOL_PALETTE_WIDTH - PaceEditor::Core::EditorWindow::PROPERTY_PANEL_WIDTH).to_f,
      height: (RL.get_screen_height - PaceEditor::Core::EditorWindow::MENU_HEIGHT).to_f
    )
    
    RL.begin_scissor_mode(
      viewport_rect.x.to_i,
      viewport_rect.y.to_i,
      viewport_rect.width.to_i,
      viewport_rect.height.to_i
    )
    @window.scene_editor.draw
    
    # Draw sample character
    if knight = @textures["knight_idle"]?
      RL.draw_texture(knight, viewport_rect.x.to_i + 400, viewport_rect.y.to_i + 300, RL::WHITE)
    end
    
    RL.end_scissor_mode
    
    # Draw other panels
    @window.scene_hierarchy.draw
    @window.property_panel.draw
    
    # Draw custom button demo
    draw_button_demo
    
    # Draw menu content last
    @window.menu_bar.draw_content
    
    # Draw asset info overlay
    draw_asset_info
    
    RL.end_drawing
  end
  
  private def draw_button_demo
    # Show loaded UI buttons in action
    x = RL.get_screen_width - 350
    y = 150
    
    RL.draw_text("UI Asset Demo:", x, y, 16, RL::WHITE)
    y += 25
    
    # Draw buttons using loaded textures
    if normal = @textures["button_normal"]?
      hover = @textures["button_hover"]?
      pressed = @textures["button_pressed"]?
      
      mouse_pos = RL.get_mouse_position
      button_rect = RL::Rectangle.new(x: x.to_f, y: y.to_f, width: 200.0f32, height: 50.0f32)
      
      is_hover = mouse_pos.x >= button_rect.x && mouse_pos.x <= button_rect.x + button_rect.width &&
                 mouse_pos.y >= button_rect.y && mouse_pos.y <= button_rect.y + button_rect.height
      
      is_pressed = is_hover && RL.mouse_button_down?(RL::MouseButton::Left)
      
      texture = if is_pressed && pressed
        pressed
      elsif is_hover && hover
        hover
      else
        normal
      end
      
      RL.draw_texture_pro(
        texture,
        RL::Rectangle.new(x: 0, y: 0, width: texture.width.to_f, height: texture.height.to_f),
        button_rect,
        RL::Vector2.new(x: 0, y: 0),
        0.0f32,
        RL::WHITE
      )
      
      # Draw button text
      text = "Asset Button"
      text_width = RL.measure_text(text, 16)
      RL.draw_text(text, x + 100 - text_width//2, y + 17, 16, RL::WHITE)
    end
  end
  
  private def draw_asset_info
    # Info overlay
    info_x = RL.get_screen_width - 400
    info_y = RL.get_screen_height - 200
    
    RL.draw_rectangle(info_x - 10, info_y - 10, 390, 190, 
      RL::Color.new(r: 0, g: 0, b: 0, a: 200))
    
    RL.draw_text("Loaded Assets:", info_x, info_y, 14, RL::GREEN)
    info_y += 20
    
    RL.draw_text("✓ UI Buttons: #{@textures.keys.count { |k| k.includes?("button") }}", info_x, info_y, 12, RL::WHITE)
    info_y += 15
    RL.draw_text("✓ Backgrounds: #{@textures.keys.count { |k| k.includes?("bg_") }}", info_x, info_y, 12, RL::WHITE)
    info_y += 15
    RL.draw_text("✓ Characters: #{@textures.keys.count { |k| k.includes?("idle") }}", info_x, info_y, 12, RL::WHITE)
    info_y += 15
    RL.draw_text("✓ Panels: #{@textures.keys.count { |k| k.includes?("panel") }}", info_x, info_y, 12, RL::WHITE)
    info_y += 25
    
    RL.draw_text("Assets loaded from:", info_x, info_y, 12, RL::LIGHTGRAY)
    info_y += 15
    RL.draw_text("/assets directory", info_x, info_y, 12, RL::LIGHTGRAY)
  end
end

# Run the demo
demo = AssetDemoEditor.new
demo.run