require "./base_validator"
require "../models/game_config"

module PaceEditor::Validation
  # Validates game configuration
  class GameConfigValidator < BaseValidator
    def initialize(@config : PaceEditor::Models::GameConfig, @project_root : String)
    end

    def validate : ValidationResult
      result = ValidationResult.new

      # Validate using the model's built-in validation
      errors = @config.validate
      errors.each do |error|
        result.add_error(error, "game_config.yaml")
      end

      # Additional validation for file paths
      validate_player_sprite(result)
      validate_asset_paths(result)
      validate_start_scene(result)
      validate_start_music(result)

      result
    end

    private def validate_player_sprite(result : ValidationResult)
      sprite_path = @config.player.sprite_path
      if !file_exists?(sprite_path, @project_root)
        result.add_error("Player sprite not found: #{sprite_path}", "game_config.yaml")
      elsif !valid_extension?(sprite_path, [".png", ".jpg"])
        result.add_error("Player sprite must be PNG or JPG format", "game_config.yaml")
      end
    end

    private def validate_asset_paths(result : ValidationResult)
      # Validate music paths
      @config.assets.audio.music.each do |name, path|
        if !file_exists?(path, @project_root)
          result.add_warning("Music file not found: #{name} => #{path}", "game_config.yaml")
        elsif !valid_extension?(path, [".ogg", ".wav", ".mp3"])
          result.add_error("Music file must be OGG, WAV, or MP3: #{path}", "game_config.yaml")
        end
      end

      # Validate sound paths
      @config.assets.audio.sounds.each do |name, path|
        if !file_exists?(path, @project_root)
          result.add_warning("Sound file not found: #{name} => #{path}", "game_config.yaml")
        elsif !valid_extension?(path, [".ogg", ".wav", ".mp3"])
          result.add_error("Sound file must be OGG, WAV, or MP3: #{path}", "game_config.yaml")
        end
      end
    end

    private def validate_start_scene(result : ValidationResult)
      if start_scene = @config.start_scene
        # Check if scene file exists
        scene_found = false
        @config.assets.scenes.each do |pattern|
          # Simple glob pattern matching
          if pattern.includes?("*")
            dir = File.dirname(pattern)
            if Dir.exists?(File.join(@project_root, dir))
              Dir.glob(File.join(@project_root, pattern)).each do |file|
                scene_name = File.basename(file, ".yaml")
                if scene_name == start_scene
                  scene_found = true
                  break
                end
              end
            end
          else
            if file_exists?(pattern, @project_root)
              scene_name = File.basename(pattern, ".yaml")
              if scene_name == start_scene
                scene_found = true
              end
            end
          end
        end

        unless scene_found
          result.add_error("Start scene '#{start_scene}' not found in scene files", "game_config.yaml")
        end
      else
        result.add_warning("No start scene specified", "game_config.yaml")
      end
    end

    private def validate_start_music(result : ValidationResult)
      if start_music = @config.start_music
        unless @config.assets.audio.music.has_key?(start_music)
          result.add_warning("Start music '#{start_music}' not defined in music assets", "game_config.yaml")
        end
      end
    end
  end
end
