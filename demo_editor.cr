require "./src/pace_editor"

# Simple demo to show the editor functionality
puts "Starting PACE Editor Demo..."
puts "================================"
puts ""
puts "Controls:"
puts "  - Mouse: Click and drag to interact"
puts "  - Space + Drag: Pan camera"
puts "  - Mouse Wheel: Zoom in/out"
puts "  - G: Toggle grid"
puts "  - H: Toggle hotspot visibility"
puts "  - V: Select tool"
puts "  - M: Move tool"
puts "  - P: Place tool"
puts "  - D: Delete tool"
puts "  - F11: Toggle fullscreen"
puts "  - ESC: Exit"
puts ""
puts "Starting editor..."

# Create and run the editor
window = PaceEditor::Core::EditorWindow.new

# Create a demo project
project = PaceEditor::Core::Project.new
project.name = "Demo Project"
project.project_path = "/tmp/pace_demo"

# Add some demo content
project.scenes << "intro"
project.scenes << "main_menu"
project.scenes << "level1"

window.state.current_project = project
window.state.current_mode = PaceEditor::EditorMode::Scene

# Run the editor
window.run
