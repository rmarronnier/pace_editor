require "yaml"
require "file_utils"
require "../export/game_exporter"

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
              File.join(@assets_path, "scripts"),
              File.join(@assets_path, "ui")]

      dirs.each do |dir|
        Dir.mkdir_p(dir)
      end
    end

    private def create_default_files
      # Note: Default scene creation is handled by EditorState.create_new_project
      # This avoids duplicate scene creation

      # Create project file
      save
    end

    private def create_default_scene
      # For now, just create a simple YAML file with basic scene data
      # rather than trying to serialize complex game objects
      scene_yaml = <<-YAML
        name: main_scene
        background_path: null
        hotspots: []
        objects: []
        characters: []
        scale: 1.0
        YAML
      scene_yaml
    end

    def save : Bool
      begin
        project_file = File.join(@project_path, "#{@name}.pace")
        File.write(project_file, to_yaml)
        true
      rescue ex
        puts "Failed to save project: #{ex.message}"
        false
      end
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

    def refresh_assets
      # Refresh asset lists by scanning the filesystem
      @backgrounds = scan_assets_directory("backgrounds")
      @characters = scan_assets_directory("characters")
      @sounds = scan_assets_directory("sounds")
      @music = scan_assets_directory("music")
      @scripts = scan_assets_directory("scripts")
    end

    private def scan_assets_directory(category : String) : Array(String)
      asset_dir = File.join(@assets_path, category)
      return [] of String unless Dir.exists?(asset_dir)

      assets = [] of String
      Dir.glob(File.join(asset_dir, "*")).each do |file_path|
        next unless File.file?(file_path)
        assets << File.basename(file_path)
      end
      assets.sort
    end

    def get_scene_file_path(scene_name : String) : String
      File.join(@scenes_path, "#{scene_name}.yaml")
    end

    def get_asset_file_path(asset_name : String, category : String) : String
      File.join(@assets_path, category, asset_name)
    end

    # Convenience methods for asset directory paths
    def backgrounds_path : String
      File.join(@assets_path, "backgrounds")
    end

    def characters_path : String
      File.join(@assets_path, "characters")
    end

    def sounds_path : String
      File.join(@assets_path, "sounds")
    end

    def music_path : String
      File.join(@assets_path, "music")
    end

    def ui_path : String
      File.join(@assets_path, "ui")
    end

    def export_game(output_path : String, include_source : Bool = false)
      # Use the new game exporter
      exporter = PaceEditor::Export::GameExporter.new(self)
      validation_result = exporter.export(output_path)

      # Return validation result so UI can show errors
      validation_result
    end

    def save_project
      setup_project_structure
      project_file = File.join(@project_path, "project.pace")
      File.write(project_file, self.to_yaml)
    end

    def self.load_project(project_file : String) : Project
      project = Project.from_yaml(File.read(project_file))
      project.project_path = File.dirname(project_file)

      # Set up paths without creating default files
      project.assets_path = File.join(project.project_path, "assets")
      project.scenes_path = File.join(project.project_path, "scenes")
      project.scripts_path = File.join(project.project_path, "scripts")
      project.dialogs_path = File.join(project.project_path, "dialogs")
      project.exports_path = File.join(project.project_path, "exports")

      project
    end
  end
end
