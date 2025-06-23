require "./base_validator"

module PaceEditor::Validation
  # Validates project assets
  class AssetValidator < BaseValidator
    def initialize(@project_root : String)
    end

    def validate : ValidationResult
      result = ValidationResult.new

      # Check required directories
      validate_directory_structure(result)

      # Validate asset files
      validate_backgrounds(result)
      validate_sprites(result)
      validate_items(result)
      validate_portraits(result)
      validate_audio(result)

      result
    end

    private def validate_directory_structure(result : ValidationResult)
      required_dirs = [
        "assets",
        "assets/backgrounds",
        "assets/sprites",
        "assets/items",
        "assets/portraits",
        "assets/music",
        "assets/sounds",
      ]

      required_dirs.each do |dir|
        full_path = File.join(@project_root, dir)
        unless Dir.exists?(full_path)
          result.add_warning("Missing directory: #{dir}")
        end
      end
    end

    private def validate_backgrounds(result : ValidationResult)
      backgrounds_dir = File.join(@project_root, "assets/backgrounds")
      return unless Dir.exists?(backgrounds_dir)

      Dir.glob(File.join(backgrounds_dir, "**/*")).each do |file|
        next unless File.file?(file)
        relative_path = file.sub(@project_root + "/", "")

        unless valid_extension?(file, [".png", ".jpg"])
          result.add_warning("Background file should be PNG or JPG: #{relative_path}")
        end

        validate_image_file(file, relative_path, result)
      end
    end

    private def validate_sprites(result : ValidationResult)
      sprites_dir = File.join(@project_root, "assets/sprites")
      return unless Dir.exists?(sprites_dir)

      Dir.glob(File.join(sprites_dir, "**/*")).each do |file|
        next unless File.file?(file)
        relative_path = file.sub(@project_root + "/", "")

        unless valid_extension?(file, [".png"])
          result.add_warning("Sprite file should be PNG: #{relative_path}")
        end

        validate_image_file(file, relative_path, result)
      end
    end

    private def validate_items(result : ValidationResult)
      items_dir = File.join(@project_root, "assets/items")
      return unless Dir.exists?(items_dir)

      Dir.glob(File.join(items_dir, "**/*")).each do |file|
        next unless File.file?(file)
        relative_path = file.sub(@project_root + "/", "")

        unless valid_extension?(file, [".png"])
          result.add_warning("Item icon should be PNG: #{relative_path}")
        end

        validate_image_file(file, relative_path, result)
      end
    end

    private def validate_portraits(result : ValidationResult)
      portraits_dir = File.join(@project_root, "assets/portraits")
      return unless Dir.exists?(portraits_dir)

      Dir.glob(File.join(portraits_dir, "**/*")).each do |file|
        next unless File.file?(file)
        relative_path = file.sub(@project_root + "/", "")

        unless valid_extension?(file, [".png"])
          result.add_warning("Portrait should be PNG: #{relative_path}")
        end

        validate_image_file(file, relative_path, result)
      end
    end

    private def validate_audio(result : ValidationResult)
      # Validate music files
      music_dir = File.join(@project_root, "assets/music")
      if Dir.exists?(music_dir)
        Dir.glob(File.join(music_dir, "**/*")).each do |file|
          next unless File.file?(file)
          relative_path = file.sub(@project_root + "/", "")

          unless valid_extension?(file, [".ogg", ".wav", ".mp3"])
            result.add_error("Music file must be OGG, WAV, or MP3: #{relative_path}")
          end

          validate_audio_file(file, relative_path, result)
        end
      end

      # Validate sound files
      sounds_dir = File.join(@project_root, "assets/sounds")
      if Dir.exists?(sounds_dir)
        Dir.glob(File.join(sounds_dir, "**/*")).each do |file|
          next unless File.file?(file)
          relative_path = file.sub(@project_root + "/", "")

          unless valid_extension?(file, [".ogg", ".wav", ".mp3"])
            result.add_error("Sound file must be OGG, WAV, or MP3: #{relative_path}")
          end

          validate_audio_file(file, relative_path, result)
        end
      end
    end

    private def validate_image_file(file : String, relative_path : String, result : ValidationResult)
      # Check file size
      size_mb = File.size(file) / (1024.0 * 1024.0)
      if size_mb > 10
        result.add_warning("Large image file (#{size_mb.round(1)} MB): #{relative_path}")
      end

      # Check filename
      basename = File.basename(file, File.extname(file))
      unless valid_identifier?(basename)
        result.add_warning("Image filename should contain only letters, numbers, and underscores: #{relative_path}")
      end
    end

    private def validate_audio_file(file : String, relative_path : String, result : ValidationResult)
      # Check file size
      size_mb = File.size(file) / (1024.0 * 1024.0)
      if size_mb > 20
        result.add_warning("Large audio file (#{size_mb.round(1)} MB): #{relative_path}")
      end

      # Check filename
      basename = File.basename(file, File.extname(file))
      unless valid_identifier?(basename)
        result.add_warning("Audio filename should contain only letters, numbers, and underscores: #{relative_path}")
      end
    end
  end
end
