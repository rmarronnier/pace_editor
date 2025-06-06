require "yaml"
require "file_utils"

module PaceEditor::Core
  # Represents a game project with all its assets and configuration
  class Project
    include YAML::Serializable

    property name : String
    property version : String = "1.0.0"
    property description : String = ""
    property author : String = ""

    # Project paths
    property project_path : String
    property assets_path : String
    property scenes_path : String
    property scripts_path : String
    property dialogs_path : String
    property exports_path : String

    # Game settings
    property window_width : Int32 = 1024
    property window_height : Int32 = 768
    property title : String = "My Adventure Game"
    property target_fps : Int32 = 60

    # Asset tracking
    property scenes : Array(String) = [] of String
    property characters : Array(String) = [] of String
    property backgrounds : Array(String) = [] of String
    property sounds : Array(String) = [] of String
    property music : Array(String) = [] of String
    property scripts : Array(String) = [] of String

    # Current scene being edited
    property current_scene : String?

    def initialize(@name : String, @project_path : String)
      @assets_path = ""
      @scenes_path = ""
      @scripts_path = ""
      @dialogs_path = ""
      @exports_path = ""
      setup_project_structure
    end

    def initialize
      @name = ""
      @project_path = ""
      @assets_path = ""
      @scenes_path = ""
      @scripts_path = ""
      @dialogs_path = ""
      @exports_path = ""
    end

    def setup_project_structure
      @assets_path = File.join(@project_path, "assets")
      @scenes_path = File.join(@project_path, "scenes")
      @scripts_path = File.join(@project_path, "scripts")
      @dialogs_path = File.join(@project_path, "dialogs")
      @exports_path = File.join(@project_path, "exports")

      # Create directory structure
      create_directories
      create_default_files
    end

    private def create_directories
      dirs = [@project_path, @assets_path, @scenes_path, @scripts_path, @dialogs_path, @exports_path,
              File.join(@assets_path, "backgrounds"),
              File.join(@assets_path, "characters"),
              File.join(@assets_path, "sounds"),
              File.join(@assets_path, "music"),
              File.join(@assets_path, "ui")]

      dirs.each do |dir|
        Dir.mkdir_p(dir) unless Dir.exists?(dir)
      end
    end

    private def create_default_files
      # Create a default scene
      default_scene_path = File.join(@scenes_path, "main_scene.yml")
      unless File.exists?(default_scene_path)
        default_scene = create_default_scene
        File.write(default_scene_path, default_scene.to_yaml)
        @scenes << "main_scene.yml"
        @current_scene = "main_scene.yml"
      end

      # Create project file
      save
    end

    private def create_default_scene
      scene = PointClickEngine::Scenes::Scene.new("main_scene")
      # Leave arrays as default empty arrays
      scene
    end

    def save
      project_file = File.join(@project_path, "#{@name}.pace")
      File.write(project_file, to_yaml)
    end

    def self.load(project_file : String) : Project
      content = File.read(project_file)
      project = Project.from_yaml(content)
      project.project_path = File.dirname(project_file)
      project.setup_project_structure if !Dir.exists?(project.assets_path)
      project
    end

    def self.create_new(name : String, path : String) : Project
      project = Project.new(name, path)
      project.title = name
      project
    end

    def add_scene(scene_name : String)
      @scenes << scene_name unless @scenes.includes?(scene_name)
    end

    def remove_scene(scene_name : String)
      @scenes.delete(scene_name)
      if @current_scene == scene_name
        @current_scene = @scenes.first?
      end
    end

    def add_asset(asset_path : String, category : String)
      case category
      when "backgrounds"
        @backgrounds << asset_path unless @backgrounds.includes?(asset_path)
      when "characters"
        @characters << asset_path unless @characters.includes?(asset_path)
      when "sounds"
        @sounds << asset_path unless @sounds.includes?(asset_path)
      when "music"
        @music << asset_path unless @music.includes?(asset_path)
      when "scripts"
        @scripts << asset_path unless @scripts.includes?(asset_path)
      end
    end

    def get_scene_file_path(scene_name : String) : String
      File.join(@scenes_path, scene_name)
    end

    def get_asset_file_path(asset_name : String, category : String) : String
      File.join(@assets_path, category, asset_name)
    end

    def export_game(output_path : String, include_source : Bool = false)
      export_dir = File.join(@exports_path, "game_export")
      Dir.mkdir_p(export_dir)

      # Copy all assets
      FileUtils.cp_r(@assets_path, export_dir)
      FileUtils.cp_r(@scenes_path, export_dir)
      FileUtils.cp_r(@scripts_path, export_dir)
      FileUtils.cp_r(@dialogs_path, export_dir)

      # Create main game file
      create_game_launcher(export_dir)

      # Optionally create archive
      if output_path.ends_with?(".zip")
        create_game_archive(export_dir, output_path)
      end
    end

    private def create_game_launcher(export_dir : String)
      launcher_code = generate_launcher_code
      File.write(File.join(export_dir, "main.cr"), launcher_code)
      File.write(File.join(export_dir, "shard.yml"), generate_shard_yml)
    end

    private def generate_launcher_code : String
      <<-CODE
      require "point_click_engine"

      # Auto-generated game launcher
      engine = PointClickEngine::Game.new(
        window_width: #{@window_width},
        window_height: #{@window_height},
        title: "#{@title}"
      )

      # Load scenes
      #{@scenes.map { |scene| "engine.add_scene(PointClickEngine::Scene.from_yaml(File.read(\"scenes/#{scene}\")))" }.join("\n")}

      # Set initial scene
      #{"engine.change_scene(\"#{@current_scene.not_nil!.split('.').first}\") if !#{@current_scene.nil?}" unless @current_scene.nil?}

      engine.run
      CODE
    end

    private def generate_shard_yml : String
      <<-YAML
      name: #{@name.downcase.gsub(/[^a-z0-9_]/, "_")}
      version: #{@version}
      
      dependencies:
        point_click_engine:
          github: point-click-engine/point-click-engine
      
      targets:
        main:
          main: main.cr
      
      crystal: ">= 1.16.3"
      YAML
    end

    private def create_game_archive(source_dir : String, output_path : String)
      # This would create a ZIP archive of the game
      # For now, just copy to output directory
      if File.dirname(output_path) != source_dir
        FileUtils.cp_r(source_dir, File.dirname(output_path))
      end
    end
  end
end
