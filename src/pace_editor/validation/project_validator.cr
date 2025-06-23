require "./base_validator"
require "./game_config_validator"
require "./asset_validator"
require "../core/project"
require "../models/game_config"

module PaceEditor::Validation
  # Main validator that orchestrates all project validations
  class ProjectValidator < BaseValidator
    def initialize(@project : PaceEditor::Core::Project)
    end

    def validate : ValidationResult
      result = ValidationResult.new

      # Check if project has basic structure
      unless Dir.exists?(@project.project_path)
        result.add_error("Project directory does not exist: #{@project.project_path}")
        return result
      end

      # Validate project properties
      validate_project_properties(result)

      # Validate assets
      asset_validator = AssetValidator.new(@project.project_path)
      result.merge(asset_validator.validate)

      # Note: Game config validation will happen during export
      # when we generate the game_config.yaml

      result
    end

    # Validate for export - includes game config generation
    def validate_for_export(game_config : PaceEditor::Models::GameConfig) : ValidationResult
      result = validate

      # Validate the game configuration
      config_validator = GameConfigValidator.new(game_config, @project.project_path)
      result.merge(config_validator.validate)

      # Validate scenes exist
      validate_scenes(result)

      # Check for at least one scene
      if @project.scenes.empty?
        result.add_error("Project must have at least one scene")
      end

      result
    end

    private def validate_project_properties(result : ValidationResult)
      # Validate project name
      unless valid_identifier?(@project.name)
        result.add_error("Project name must contain only letters, numbers, and underscores")
      end

      # Validate window dimensions
      unless in_range?(@project.window_width, 320, 7680)
        result.add_error("Window width must be between 320 and 7680 pixels")
      end

      unless in_range?(@project.window_height, 240, 4320)
        result.add_error("Window height must be between 240 and 4320 pixels")
      end

      # Validate FPS
      unless in_range?(@project.target_fps, 30, 240)
        result.add_error("Target FPS must be between 30 and 240")
      end
    end

    private def validate_scenes(result : ValidationResult)
      @project.scenes.each do |scene_name|
        scene_file = @project.get_scene_file_path(scene_name)
        unless File.exists?(scene_file)
          result.add_error("Scene file not found: #{scene_file}")
        end
      end

      # Validate current scene
      if current = @project.current_scene
        unless @project.scenes.includes?(current)
          result.add_warning("Current scene '#{current}' is not in the scenes list")
        end
      end
    end
  end
end
