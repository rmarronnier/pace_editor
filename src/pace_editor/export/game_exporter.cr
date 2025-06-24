require "yaml"
require "file_utils"
require "../core/project"
require "../models/game_config"
require "../validation/project_validator"

module PaceEditor::Export
  # Handles exporting projects to the new game format
  class GameExporter
    def initialize(@project : PaceEditor::Core::Project)
    end

    # Export the game with validation
    def export(output_path : String) : PaceEditor::Validation::ValidationResult
      # Create game configuration
      game_config = create_game_config

      # Validate before export
      validator = PaceEditor::Validation::ProjectValidator.new(@project)
      validation_result = validator.validate_for_export(game_config)

      # Only proceed if validation passes
      if validation_result.valid?
        begin
          perform_export(output_path, game_config)
        rescue ex : Exception
          validation_result.add_error("Export failed: #{ex.message}")
        end
      end

      validation_result
    end

    private def create_game_config : PaceEditor::Models::GameConfig
      # Create game metadata
      game_metadata = PaceEditor::Models::GameConfig::GameMetadata.new(@project.title)
      game_metadata.version = @project.version
      game_metadata.author = @project.author unless @project.author.empty?

      # Create player config with defaults
      sprite_info = PaceEditor::Models::GameConfig::PlayerConfig::SpriteInfo.new(
        frame_width: 64,
        frame_height: 64,
        columns: 4,
        rows: 4
      )

      player_config = PaceEditor::Models::GameConfig::PlayerConfig.new(
        sprite_path: "assets/sprites/player.png",
        sprite: sprite_info
      )

      # Create game config
      config = PaceEditor::Models::GameConfig.new(game_metadata, player_config)

      # Set window settings
      config.window.width = @project.window_width
      config.window.height = @project.window_height
      config.window.target_fps = @project.target_fps

      # Set display settings to match window
      config.display.target_width = @project.window_width
      config.display.target_height = @project.window_height

      # Set start scene if available
      config.start_scene = @project.current_scene

      # Add basic features
      config.features = ["verbs", "portraits", "auto_save"]

      # Set up asset paths
      config.assets.scenes = ["scenes/*.yaml"]
      config.assets.dialogs = ["dialogs/*.yaml"]
      config.assets.quests = ["quests/*.yaml"]

      # Add music and sounds from project
      @project.music.each do |music_file|
        name = File.basename(music_file, File.extname(music_file))
        config.assets.audio.music[name] = File.join("assets", "music", music_file)
      end

      @project.sounds.each do |sound_file|
        name = File.basename(sound_file, File.extname(sound_file))
        config.assets.audio.sounds[name] = File.join("assets", "sounds", sound_file)
      end

      config
    end

    private def perform_export(output_path : String, game_config : PaceEditor::Models::GameConfig)
      # Create export directory
      export_dir = output_path.ends_with?(".zip") ? File.join(@project.exports_path, "game_export") : output_path
      Dir.mkdir_p(export_dir)

      # Create directory structure
      create_export_directories(export_dir)

      # Write game_config.yaml
      File.write(File.join(export_dir, "game_config.yaml"), game_config.to_yaml)

      # Copy and organize assets
      copy_assets(export_dir)

      # Export scenes in new format
      export_scenes(export_dir)

      # Export dialogs
      export_dialogs(export_dir)

      # Create placeholder files for missing components
      create_placeholder_files(export_dir)

      # Create main.cr entry point
      create_main_file(export_dir)

      # Create shard.yml
      create_shard_file(export_dir)

      # Create ZIP if requested
      if output_path.ends_with?(".zip")
        create_zip_archive(export_dir, output_path)
      end
    end

    private def create_export_directories(export_dir : String)
      dirs = [
        "scenes",
        "scripts",
        "dialogs",
        "quests",
        "items",
        "cutscenes",
        "assets",
        "assets/backgrounds",
        "assets/sprites",
        "assets/items",
        "assets/portraits",
        "assets/music",
        "assets/sounds",
        "assets/sounds/effects",
        "assets/sounds/ambience",
      ]

      dirs.each do |dir|
        Dir.mkdir_p(File.join(export_dir, dir))
      end
    end

    private def copy_assets(export_dir : String)
      # Copy backgrounds
      @project.backgrounds.each do |bg|
        src = File.join(@project.assets_path, "backgrounds", bg)
        dst = File.join(export_dir, "assets/backgrounds", bg)
        FileUtils.cp(src, dst) if File.exists?(src)
      end

      # Copy character sprites
      @project.characters.each do |char|
        src = File.join(@project.assets_path, "characters", char)
        dst = File.join(export_dir, "assets/sprites", char)
        FileUtils.cp(src, dst) if File.exists?(src)
      end

      # Copy sounds
      @project.sounds.each do |sound|
        src = File.join(@project.assets_path, "sounds", sound)
        dst = File.join(export_dir, "assets/sounds/effects", sound)
        FileUtils.cp(src, dst) if File.exists?(src)
      end

      # Copy music
      @project.music.each do |music|
        src = File.join(@project.assets_path, "music", music)
        dst = File.join(export_dir, "assets/music", music)
        FileUtils.cp(src, dst) if File.exists?(src)
      end

      # Copy any other assets
      copy_additional_assets(export_dir)
    end

    private def copy_additional_assets(export_dir : String)
      # Copy UI assets if they exist
      ui_dir = File.join(@project.assets_path, "ui")
      if Dir.exists?(ui_dir)
        FileUtils.cp_r(ui_dir, File.join(export_dir, "assets"))
      end

      # Copy items directory if it exists
      items_dir = File.join(@project.assets_path, "items")
      if Dir.exists?(items_dir)
        Dir.glob(File.join(items_dir, "*")).each do |file|
          next unless File.file?(file)
          FileUtils.cp(file, File.join(export_dir, "assets/items", File.basename(file)))
        end
      end

      # Copy portraits directory if it exists
      portraits_dir = File.join(@project.assets_path, "portraits")
      if Dir.exists?(portraits_dir)
        Dir.glob(File.join(portraits_dir, "*")).each do |file|
          next unless File.file?(file)
          FileUtils.cp(file, File.join(export_dir, "assets/portraits", File.basename(file)))
        end
      end
    end

    private def export_scenes(export_dir : String)
      @project.scenes.each do |scene_name|
        scene_file = @project.get_scene_file_path(scene_name)
        if File.exists?(scene_file)
          # Copy scene file to new location
          # TODO: Convert scene format if needed
          dst = File.join(export_dir, "scenes", "#{scene_name}.yaml")
          FileUtils.cp(scene_file, dst)
        end
      end
    end

    private def export_dialogs(export_dir : String)
      # Copy dialog files if they exist
      if Dir.exists?(@project.dialogs_path)
        Dir.glob(File.join(@project.dialogs_path, "*.yaml")).each do |dialog_file|
          FileUtils.cp(dialog_file, File.join(export_dir, "dialogs", File.basename(dialog_file)))
        end
      end
    end

    private def create_placeholder_files(export_dir : String)
      # Create empty items.yaml if it doesn't exist
      items_file = File.join(export_dir, "items/items.yaml")
      unless File.exists?(items_file)
        File.write(items_file, "items: {}\n")
      end

      # Create sample quest file if none exist
      quests_dir = File.join(export_dir, "quests")
      if Dir.glob(File.join(quests_dir, "*.yaml")).empty?
        File.write(File.join(quests_dir, "main_quests.yaml"), "quests: []\n")
      end
    end

    private def create_main_file(export_dir : String)
      main_content = <<-CRYSTAL
      require "point_click_engine"

      # Auto-generated game launcher
      # Created by PACE Editor v#{PaceEditor::VERSION}

      # Load game configuration
      config_path = Path["game_config.yaml"]
      unless File.exists?(config_path)
        puts "Error: game_config.yaml not found!"
        exit 1
      end

      # Create and run the game
      begin
        engine = PointClickEngine::Game.from_config(config_path.to_s)
        engine.run
      rescue ex
        puts "Error starting game: \#{ex.message}"
        exit 1
      end
      CRYSTAL

      File.write(File.join(export_dir, "main.cr"), main_content)
    end

    private def create_shard_file(export_dir : String)
      shard_content = <<-YAML
      name: #{@project.name.downcase.gsub(/[^a-z0-9_]/, "_")}
      version: #{@project.version}
      description: #{@project.description.empty? ? "A point & click adventure game" : @project.description}
      
      authors:
        - #{@project.author.empty? ? "Unknown" : @project.author}
      
      dependencies:
        point_click_engine:
          github: point-click-engine/point-click-engine
          version: "~> 1.0"
      
      targets:
        #{@project.name.downcase.gsub(/[^a-z0-9_]/, "_")}:
          main: main.cr
      
      crystal: ">= 1.6.0"
      
      license: MIT
      YAML

      File.write(File.join(export_dir, "shard.yml"), shard_content)
    end

    private def create_zip_archive(source_dir : String, output_path : String)
      # Create parent directory if needed
      Dir.mkdir_p(File.dirname(output_path))

      # Use system zip command
      system("cd #{source_dir} && zip -r #{output_path} .")

      # Clean up temporary directory
      FileUtils.rm_rf(source_dir)
    end
  end
end
