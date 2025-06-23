require "raylib-cr"
require "../core/editor_state"

module PaceEditor::UI
  class GameExportDialog
    property visible : Bool = false
    
    @export_path : String = ""
    @export_name : String = ""
    @export_format : String = "standalone"
    @include_source : Bool = false
    @compress_assets : Bool = true
    @validate_project : Bool = true
    @export_progress : Float32 = 0.0_f32
    @export_status : String = ""
    @is_exporting : Bool = false
    @validation_results : Array(String) = [] of String

    def initialize(@state : Core::EditorState)
    end

    def show
      @visible = true
      @export_progress = 0.0_f32
      @export_status = ""
      @is_exporting = false
      @validation_results.clear
      
      if project = @state.current_project
        @export_name = project.name.downcase.gsub(/[^a-z0-9_]/, "_")
        @export_path = File.join(project.project_path, "exports", @export_name)
      end
    end

    def hide
      @visible = false
    end

    def update
      return unless @visible
      handle_input
    end

    def draw
      return unless @visible

      # Dialog background
      dialog_width = 600
      dialog_height = 500
      dialog_x = (Core::EditorWindow::WINDOW_WIDTH - dialog_width) // 2
      dialog_y = (Core::EditorWindow::WINDOW_HEIGHT - dialog_height) // 2

      # Modal background
      RL.draw_rectangle(0, 0, Core::EditorWindow::WINDOW_WIDTH, Core::EditorWindow::WINDOW_HEIGHT,
        RL::Color.new(r: 0, g: 0, b: 0, a: 128))

      # Dialog box
      RL.draw_rectangle(dialog_x, dialog_y, dialog_width, dialog_height,
        RL::Color.new(r: 50, g: 50, b: 50, a: 255))
      RL.draw_rectangle_lines(dialog_x, dialog_y, dialog_width, dialog_height, RL::WHITE)

      if @is_exporting
        draw_export_progress(dialog_x, dialog_y, dialog_width, dialog_height)
      else
        draw_export_settings(dialog_x, dialog_y, dialog_width, dialog_height)
      end
    end

    private def draw_export_settings(x : Int32, y : Int32, width : Int32, height : Int32)
      # Title
      RL.draw_text("Export Game", x + 20, y + 20, 20, RL::WHITE)
      
      current_y = y + 60

      # Export name
      RL.draw_text("Export Name:", x + 20, current_y, 14, RL::WHITE)
      current_y += 25
      draw_text_field(@export_name, x + 20, current_y, width - 40, 25)
      current_y += 35

      # Export path
      RL.draw_text("Export Path:", x + 20, current_y, 14, RL::WHITE)
      current_y += 25
      draw_text_field(@export_path, x + 20, current_y, width - 120, 25)
      
      # Browse button
      if draw_small_button("Browse", x + width - 90, current_y, 70, 25)
        # TODO: Open file browser for directory selection
        puts "Browse for export directory"
      end
      current_y += 35

      # Export format
      RL.draw_text("Export Format:", x + 20, current_y, 14, RL::WHITE)
      current_y += 25
      
      formats = [
        {id: "standalone", name: "Standalone Executable", desc: "Self-contained game executable"},
        {id: "web", name: "Web Game", desc: "HTML5 game for browsers"},
        {id: "source", name: "Source Package", desc: "Source code with assets"}
      ]

      formats.each do |format|
        format_y = current_y
        is_selected = @export_format == format[:id]
        
        # Radio button
        radio_color = is_selected ? RL::GREEN : RL::GRAY
        RL.draw_circle(x + 30, format_y + 8, 6, radio_color)
        if is_selected
          RL.draw_circle(x + 30, format_y + 8, 3, RL::WHITE)
        end
        
        # Format info
        RL.draw_text(format[:name], x + 50, format_y, 14, RL::WHITE)
        RL.draw_text(format[:desc], x + 50, format_y + 16, 12, RL::LIGHTGRAY)
        
        # Check for click
        mouse_pos = RL.get_mouse_position
        if mouse_pos.x >= x + 20 && mouse_pos.x <= x + width - 20 &&
           mouse_pos.y >= format_y && mouse_pos.y <= format_y + 32 &&
           RL.mouse_button_pressed?(RL::MouseButton::Left)
          @export_format = format[:id]
        end
        
        current_y += 40
      end

      # Options
      RL.draw_text("Options:", x + 20, current_y, 14, RL::WHITE)
      current_y += 25

      # Include source checkbox
      if draw_checkbox("Include source code", @include_source, x + 30, current_y)
        @include_source = !@include_source
      end
      current_y += 25

      # Compress assets checkbox
      if draw_checkbox("Compress assets", @compress_assets, x + 30, current_y)
        @compress_assets = !@compress_assets
      end
      current_y += 25

      # Validate project checkbox
      if draw_checkbox("Validate project before export", @validate_project, x + 30, current_y)
        @validate_project = !@validate_project
      end
      current_y += 35

      # Validation results
      if @validate_project && !@validation_results.empty?
        draw_validation_results(x + 20, current_y, width - 40)
      end

      # Buttons
      button_y = y + height - 60
      draw_export_buttons(x, button_y, width)
    end

    private def draw_export_progress(x : Int32, y : Int32, width : Int32, height : Int32)
      # Title
      RL.draw_text("Exporting Game...", x + 20, y + 20, 20, RL::WHITE)
      
      # Progress bar
      progress_y = y + height // 2 - 20
      progress_width = width - 80
      progress_height = 20
      
      # Background
      RL.draw_rectangle(x + 40, progress_y, progress_width, progress_height,
        RL::Color.new(r: 40, g: 40, b: 40, a: 255))
      RL.draw_rectangle_lines(x + 40, progress_y, progress_width, progress_height, RL::GRAY)
      
      # Progress fill
      fill_width = (progress_width * @export_progress).to_i
      RL.draw_rectangle(x + 40, progress_y, fill_width, progress_height,
        RL::Color.new(r: 100, g: 150, b: 100, a: 255))
      
      # Progress text
      progress_text = "#{(@export_progress * 100).to_i}%"
      text_width = RL.measure_text(progress_text, 14)
      RL.draw_text(progress_text, x + 40 + (progress_width - text_width) // 2, progress_y + 3, 14, RL::WHITE)
      
      # Status text
      RL.draw_text(@export_status, x + 40, progress_y + 40, 14, RL::LIGHTGRAY)
      
      # Cancel button (only if not completed)
      if @export_progress < 1.0
        if draw_button("Cancel", x + width // 2 - 50, y + height - 60, 100, 30, RL::LIGHTGRAY)
          @is_exporting = false
          @export_progress = 0.0_f32
        end
      else
        # Close button when completed
        if draw_button("Close", x + width // 2 - 50, y + height - 60, 100, 30, RL::GREEN)
          hide
        end
      end
    end

    private def draw_text_field(text : String, x : Int32, y : Int32, width : Int32, height : Int32)
      # Field background
      RL.draw_rectangle(x, y, width, height, RL::Color.new(r: 40, g: 40, b: 40, a: 255))
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)
      
      # Text
      display_text = text.size > 50 ? "..." + text[-47..-1] : text
      RL.draw_text(display_text, x + 5, y + (height - 14) // 2, 14, RL::WHITE)
    end

    private def draw_checkbox(text : String, checked : Bool, x : Int32, y : Int32) : Bool
      # Checkbox
      check_size = 16
      RL.draw_rectangle(x, y, check_size, check_size, RL::Color.new(r: 40, g: 40, b: 40, a: 255))
      RL.draw_rectangle_lines(x, y, check_size, check_size, RL::GRAY)
      
      if checked
        RL.draw_text("✓", x + 2, y, 14, RL::GREEN)
      end
      
      # Text
      RL.draw_text(text, x + check_size + 10, y, 14, RL::WHITE)
      
      # Check for click
      mouse_pos = RL.get_mouse_position
      text_width = RL.measure_text(text, 14)
      if mouse_pos.x >= x && mouse_pos.x <= x + check_size + 10 + text_width &&
         mouse_pos.y >= y && mouse_pos.y <= y + check_size
        if RL.mouse_button_pressed?(RL::MouseButton::Left)
          return true
        end
      end
      
      false
    end

    private def draw_small_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32) : Bool
      # Button background
      bg_color = RL::Color.new(r: 60, g: 60, b: 60, a: 255)
      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, RL::GRAY)
      
      # Button text
      text_width = RL.measure_text(text, 12)
      text_x = x + (width - text_width) // 2
      text_y = y + (height - 12) // 2
      RL.draw_text(text, text_x, text_y, 12, RL::WHITE)
      
      # Check if clicked
      mouse_pos = RL.get_mouse_position
      if mouse_pos.x >= x && mouse_pos.x <= x + width &&
         mouse_pos.y >= y && mouse_pos.y <= y + height
        if RL.mouse_button_pressed?(RL::MouseButton::Left)
          return true
        end
      end
      
      false
    end

    private def draw_button(text : String, x : Int32, y : Int32, width : Int32, height : Int32, color : RL::Color = RL::WHITE) : Bool
      # Button background
      bg_color = RL::Color.new(r: 60, g: 60, b: 60, a: 255)
      RL.draw_rectangle(x, y, width, height, bg_color)
      RL.draw_rectangle_lines(x, y, width, height, color)
      
      # Button text
      text_width = RL.measure_text(text, 14)
      text_x = x + (width - text_width) // 2
      text_y = y + (height - 14) // 2
      RL.draw_text(text, text_x, text_y, 14, color)
      
      # Check if clicked
      mouse_pos = RL.get_mouse_position
      if mouse_pos.x >= x && mouse_pos.x <= x + width &&
         mouse_pos.y >= y && mouse_pos.y <= y + height
        if RL.mouse_button_pressed?(RL::MouseButton::Left)
          return true
        end
      end
      
      false
    end

    private def draw_validation_results(x : Int32, y : Int32, width : Int32)
      RL.draw_text("Validation Results:", x, y, 14, RL::YELLOW)
      current_y = y + 20
      
      @validation_results.each_with_index do |result, index|
        break if index >= 3  # Show max 3 results
        color = result.starts_with?("✓") ? RL::GREEN : RL::RED
        RL.draw_text(result, x + 10, current_y, 12, color)
        current_y += 16
      end
      
      if @validation_results.size > 3
        RL.draw_text("... and #{@validation_results.size - 3} more", x + 10, current_y, 12, RL::LIGHTGRAY)
      end
    end

    private def draw_export_buttons(x : Int32, y : Int32, width : Int32)
      button_width = 100
      button_height = 30
      
      # Cancel button
      if draw_button("Cancel", x + 20, y, button_width, button_height, RL::LIGHTGRAY)
        hide
      end
      
      # Validate button (if validation enabled)
      if @validate_project
        validate_x = x + width // 2 - button_width - 10
        if draw_button("Validate", validate_x, y, button_width, button_height, RL::YELLOW)
          validate_project
        end
      end
      
      # Export button
      export_x = x + width - button_width - 20
      export_enabled = !@export_name.empty? && !@export_path.empty?
      export_color = export_enabled ? RL::GREEN : RL::GRAY
      
      if draw_button("Export", export_x, y, button_width, button_height, export_color) && export_enabled
        start_export
      end
    end

    private def handle_input
      # Handle escape key
      if RL.key_pressed?(RL::KeyboardKey::Escape) && !@is_exporting
        hide
      end
    end

    private def validate_project
      return unless project = @state.current_project
      
      @validation_results.clear
      
      # Check for required components
      scenes_dir = File.join(project.project_path, "scenes")
      if Dir.exists?(scenes_dir) && !Dir.glob(File.join(scenes_dir, "*.yml")).empty?
        @validation_results << "✓ Scenes found"
      else
        @validation_results << "✗ No scenes found"
      end
      
      # Check for assets
      assets_dir = File.join(project.project_path, "assets")
      if Dir.exists?(assets_dir)
        @validation_results << "✓ Assets directory exists"
        
        # Check for backgrounds
        bg_dir = File.join(assets_dir, "backgrounds")
        if Dir.exists?(bg_dir) && !Dir.glob(File.join(bg_dir, "*")).empty?
          @validation_results << "✓ Background assets found"
        else
          @validation_results << "✗ No background assets"
        end
      else
        @validation_results << "✗ No assets directory"
      end
      
      # Check project file
      project_file = File.join(project.project_path, "project.pace")
      if File.exists?(project_file)
        @validation_results << "✓ Project file exists"
      else
        @validation_results << "✗ Project file missing"
      end
      
      puts "Project validation completed: #{@validation_results.size} results"
    end

    private def start_export
      return unless project = @state.current_project
      
      @is_exporting = true
      @export_progress = 0.0_f32
      @export_status = "Starting export..."
      
      # Simulate export process
      # In a real implementation, this would be done in a background thread
      perform_export(project)
    end

    private def perform_export(project : Core::Project)
      begin
        # Step 1: Create export directory
        @export_status = "Creating export directory..."
        @export_progress = 0.1_f32
        
        Dir.mkdir_p(@export_path) unless Dir.exists?(@export_path)
        
        # Step 2: Copy assets
        @export_status = "Copying assets..."
        @export_progress = 0.3_f32
        
        copy_assets(project)
        
        # Step 3: Process scenes
        @export_status = "Processing scenes..."
        @export_progress = 0.5_f32
        
        process_scenes(project)
        
        # Step 4: Generate game executable
        @export_status = "Generating game files..."
        @export_progress = 0.7_f32
        
        generate_game_files(project)
        
        # Step 5: Create distribution package
        @export_status = "Creating distribution package..."
        @export_progress = 0.9_f32
        
        create_distribution(project)
        
        # Step 6: Complete
        @export_status = "Export completed successfully!"
        @export_progress = 1.0_f32
        
        puts "Game exported to: #{@export_path}"
        
      rescue ex : Exception
        @export_status = "Export failed: #{ex.message}"
        @export_progress = 0.0_f32
        @is_exporting = false
        puts "Export error: #{ex.message}"
      end
    end

    private def copy_assets(project : Core::Project)
      assets_src = File.join(project.project_path, "assets")
      assets_dest = File.join(@export_path, "assets")
      
      if Dir.exists?(assets_src)
        Dir.mkdir_p(assets_dest)
        
        # Copy all asset directories
        ["backgrounds", "characters", "sounds", "music", "scripts"].each do |asset_type|
          src_dir = File.join(assets_src, asset_type)
          dest_dir = File.join(assets_dest, asset_type)
          
          if Dir.exists?(src_dir)
            Dir.mkdir_p(dest_dir)
            Dir.glob(File.join(src_dir, "*")).each do |file|
              if File.file?(file)
                dest_file = File.join(dest_dir, File.basename(file))
                File.copy(file, dest_file)
              end
            end
          end
        end
      end
    end

    private def process_scenes(project : Core::Project)
      scenes_src = File.join(project.project_path, "scenes")
      scenes_dest = File.join(@export_path, "scenes")
      
      if Dir.exists?(scenes_src)
        Dir.mkdir_p(scenes_dest)
        
        Dir.glob(File.join(scenes_src, "*.yml")).each do |scene_file|
          dest_file = File.join(scenes_dest, File.basename(scene_file))
          File.copy(scene_file, dest_file)
        end
      end
    end

    private def generate_game_files(project : Core::Project)
      case @export_format
      when "standalone"
        generate_standalone_executable(project)
      when "web"
        generate_web_game(project)
      when "source"
        generate_source_package(project)
      end
    end

    private def generate_standalone_executable(project : Core::Project)
      # Create main game executable file
      main_file = File.join(@export_path, "#{@export_name}.cr")
      
      game_code = <<-CRYSTAL
        # Generated game file for #{project.name}
        require "point_click_engine"
        
        module #{project.name.capitalize}Game
          def self.run
            game = PointClickEngine::Game.new("#{project.title}", #{project.window_width}, #{project.window_height})
            
            # Load scenes
            scenes_dir = File.join(File.dirname(__FILE__), "scenes")
            Dir.glob(File.join(scenes_dir, "*.yml")).each do |scene_file|
              scene_name = File.basename(scene_file, ".yml")
              game.load_scene(scene_name, scene_file)
            end
            
            # Start game
            game.start("#{project.current_scene || "main"}")
          end
        end
        
        #{project.name.capitalize}Game.run
        CRYSTAL
      
      File.write(main_file, game_code)
      
      # Create build script
      build_script = File.join(@export_path, "build.sh")
      build_content = <<-BASH
        #!/bin/bash
        echo "Building #{project.name}..."
        crystal build #{@export_name}.cr -o #{@export_name}
        echo "Build complete! Run ./#{@export_name} to play the game."
        BASH
      
      File.write(build_script, build_content)
      
      # Make build script executable
      {% if flag?(:unix) %}
        File.chmod(build_script, 0o755)
      {% end %}
    end

    private def generate_web_game(project : Core::Project)
      # Create HTML file
      html_file = File.join(@export_path, "index.html")
      
      html_content = <<-HTML
        <!DOCTYPE html>
        <html>
        <head>
            <title>#{project.title}</title>
            <style>
                body { margin: 0; background: #000; display: flex; justify-content: center; align-items: center; height: 100vh; }
                canvas { border: 1px solid #333; }
            </style>
        </head>
        <body>
            <canvas id="game-canvas" width="#{project.window_width}" height="#{project.window_height}"></canvas>
            <script>
                // Web game implementation would go here
                console.log("Loading #{project.name}...");
                // This would integrate with a web-compiled version of the game engine
            </script>
        </body>
        </html>
        HTML
      
      File.write(html_file, html_content)
      
      # Create README for web deployment
      readme_file = File.join(@export_path, "README.md")
      readme_content = <<-MARKDOWN
        # #{project.title}
        
        Web version of #{project.name}.
        
        ## Running the Game
        
        1. Upload all files to a web server
        2. Open index.html in a web browser
        
        ## Files
        
        - index.html: Main game page
        - assets/: Game assets (images, sounds, etc.)
        - scenes/: Game scenes and dialog data
        MARKDOWN
      
      File.write(readme_file, readme_content)
    end

    private def generate_source_package(project : Core::Project)
      # Copy project file
      project_src = File.join(project.project_path, "project.pace")
      project_dest = File.join(@export_path, "project.pace")
      
      if File.exists?(project_src)
        File.copy(project_src, project_dest)
      end
      
      # Create development README
      readme_file = File.join(@export_path, "README.md")
      readme_content = <<-MARKDOWN
        # #{project.title} - Source Package
        
        This is the complete source package for #{project.name}.
        
        ## Requirements
        
        - Crystal language
        - PointClickEngine library
        - PACE Editor (for editing)
        
        ## Project Structure
        
        - assets/: Game assets (backgrounds, characters, sounds, etc.)
        - scenes/: Scene definitions in YAML format
        - project.pace: Main project file
        
        ## Development
        
        Open this project in PACE Editor to continue development.
        
        ## Building
        
        Use PACE Editor's export function to create playable builds.
        MARKDOWN
      
      File.write(readme_file, readme_content)
    end

    private def create_distribution(project : Core::Project)
      # Create final distribution structure
      dist_readme = File.join(@export_path, "DISTRIBUTION.txt")
      
      content = <<-TEXT
        #{project.title}
        
        Export Date: #{Time.local}
        Export Format: #{@export_format}
        Compression: #{@compress_assets ? "Enabled" : "Disabled"}
        
        Contents:
        - assets/: Game assets
        - scenes/: Game scenes
        #{@export_format == "standalone" ? "- #{@export_name}.cr: Main game file" : ""}
        #{@export_format == "standalone" ? "- build.sh: Build script" : ""}
        #{@export_format == "web" ? "- index.html: Web game page" : ""}
        
        Created with PACE Editor
        TEXT
      
      File.write(dist_readme, content)
    end
  end
end