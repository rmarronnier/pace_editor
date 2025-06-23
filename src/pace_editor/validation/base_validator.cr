require "./validation_result"

module PaceEditor::Validation
  # Base class for all validators
  abstract class BaseValidator
    # Perform validation and return results
    abstract def validate : ValidationResult

    # Helper method to check if a file exists relative to project root
    protected def file_exists?(path : String, project_root : String) : Bool
      full_path = File.join(project_root, path)
      File.exists?(full_path)
    end

    # Helper method to validate identifier format (letters, numbers, underscores)
    protected def valid_identifier?(identifier : String) : Bool
      !identifier.empty? && !!identifier.match(/^[a-zA-Z0-9_]+$/)
    end

    # Helper method to validate file extension
    protected def valid_extension?(path : String, extensions : Array(String)) : Bool
      ext = File.extname(path).downcase
      extensions.includes?(ext)
    end

    # Helper method to validate numeric range
    protected def in_range?(value : Number, min : Number, max : Number) : Bool
      value >= min && value <= max
    end
  end
end
