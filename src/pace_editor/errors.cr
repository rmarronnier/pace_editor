module PaceEditor::Errors
  # Base exception class for all PACE Editor errors
  class PaceEditorError < Exception
    getter context : Hash(String, String)?
    
    def initialize(message : String, @context = nil)
      super(message)
    end
    
    def to_user_message : String
      message.to_s
    end
  end
  
  # Project-related errors
  class ProjectError < PaceEditorError
    getter project_path : String
    getter user_message : String
    
    def initialize(@project_path : String, @user_message : String, context = nil)
      super("Project error in #{@project_path}: #{@user_message}", context)
    end
    
    def to_user_message : String
      "Project Error: #{@user_message}"
    end
  end
  
  class ProjectNotFoundError < ProjectError
    def initialize(project_path : String)
      super(project_path, "Project file not found")
    end
    
    def to_user_message : String
      "Project not found at #{project_path}. Please check the path and try again."
    end
  end
  
  class ProjectCorruptedError < ProjectError
    def initialize(project_path : String, details : String)
      super(project_path, "Project file is corrupted: #{details}")
    end
    
    def to_user_message : String
      "The project file appears to be corrupted. Please restore from a backup."
    end
  end
  
  # Validation errors
  class ValidationError < PaceEditorError
    getter field : String
    getter value : String?
    getter user_message : String
    
    def initialize(@field : String, @value : String?, @user_message : String, context = nil)
      super("Validation failed for #{@field}: #{@user_message}", context)
    end
    
    def to_user_message : String
      "Invalid #{field}: #{@user_message}"
    end
  end
  
  class RequiredFieldError < ValidationError
    def initialize(field : String)
      super(field, nil, "is required")
    end
    
    def to_user_message : String
      "#{field.capitalize} is required"
    end
  end
  
  class InvalidValueError < ValidationError
    def initialize(field : String, value : String, expected : String)
      super(field, value, "expected #{expected}, got #{value}")
    end
    
    def to_user_message : String
      "#{field.capitalize} must be #{message.split("expected ")[1]}"
    end
  end
  
  # Asset-related errors
  class AssetError < PaceEditorError
    getter asset_path : String
    
    def initialize(@asset_path : String, message : String, context = nil)
      super("Asset error for #{@asset_path}: #{message}", context)
    end
    
    def to_user_message : String
      "Asset Error: #{message}"
    end
  end
  
  class AssetNotFoundError < AssetError
    def initialize(asset_path : String)
      super(asset_path, "Asset file not found")
    end
    
    def to_user_message : String
      "Asset not found: #{File.basename(asset_path)}"
    end
  end
  
  class UnsupportedAssetError < AssetError
    getter file_extension : String
    
    def initialize(asset_path : String, @file_extension : String)
      super(asset_path, "Unsupported file format: #{@file_extension}")
    end
    
    def to_user_message : String
      "Unsupported file format: #{file_extension}. Please use a supported format."
    end
  end
  
  # Scene-related errors
  class SceneError < PaceEditorError
    getter scene_name : String
    
    def initialize(@scene_name : String, message : String, context = nil)
      super("Scene error in #{@scene_name}: #{message}", context)
    end
    
    def to_user_message : String
      "Scene Error: #{message}"
    end
  end
  
  class CircularReferenceError < SceneError
    def initialize(scene_name : String, reference_chain : Array(String))
      super(scene_name, "Circular reference detected: #{reference_chain.join(" -> ")}")
    end
    
    def to_user_message : String
      "Circular reference detected in scene connections. Please check your scene navigation."
    end
  end
  
  # Dialog-related errors
  class DialogError < PaceEditorError
    getter dialog_id : String
    
    def initialize(@dialog_id : String, message : String, context = nil)
      super("Dialog error in #{@dialog_id}: #{message}", context)
    end
    
    def to_user_message : String
      "Dialog Error: #{message}"
    end
  end
  
  class InvalidDialogConnectionError < DialogError
    def initialize(dialog_id : String, from_node : String, to_node : String)
      super(dialog_id, "Invalid connection from #{from_node} to #{to_node}")
    end
    
    def to_user_message : String
      "Invalid dialog connection. Please check your dialog tree structure."
    end
  end
  
  # Export-related errors
  class ExportError < PaceEditorError
    getter export_path : String
    
    def initialize(@export_path : String, message : String, context = nil)
      super("Export error to #{@export_path}: #{message}", context)
    end
    
    def to_user_message : String
      "Export Error: #{message}"
    end
  end
  
  class ExportValidationError < ExportError
    getter validation_errors : Array(String)
    
    def initialize(export_path : String, @validation_errors : Array(String))
      super(export_path, "Validation failed with #{@validation_errors.size} errors")
    end
    
    def to_user_message : String
      "Cannot export: Please fix the following errors:\n#{validation_errors.join("\n")}"
    end
  end
  
  # Script-related errors
  class ScriptError < PaceEditorError
    getter script_path : String
    getter line_number : Int32?
    
    def initialize(@script_path : String, message : String, @line_number : Int32? = nil, context = nil)
      location = line_number ? " at line #{line_number}" : ""
      super("Script error in #{File.basename(@script_path)}#{location}: #{message}", context)
    end
    
    def to_user_message : String
      location = line_number ? " (line #{line_number})" : ""
      "Script Error#{location}: #{message}"
    end
  end
  
  class LuaSyntaxError < ScriptError
    def initialize(script_path : String, syntax_error : String, line_number : Int32? = nil)
      super(script_path, "Lua syntax error: #{syntax_error}", line_number)
    end
    
    def to_user_message : String
      location = line_number ? " at line #{line_number}" : ""
      "Lua syntax error#{location}: Please check your script syntax."
    end
  end
  
  # Performance-related errors
  class PerformanceError < PaceEditorError
    getter operation : String
    getter duration : Time::Span
    
    def initialize(@operation : String, @duration : Time::Span, threshold : Time::Span)
      super("Performance warning: #{@operation} took #{@duration.total_milliseconds}ms (threshold: #{threshold.total_milliseconds}ms)")
    end
    
    def to_user_message : String
      "Performance Warning: #{operation} is taking longer than expected."
    end
  end
  
  # Memory-related errors
  class MemoryError < PaceEditorError
    getter memory_usage : UInt64
    
    def initialize(@memory_usage : UInt64, threshold : UInt64)
      super("Memory usage warning: #{@memory_usage} bytes (threshold: #{threshold} bytes)")
    end
    
    def to_user_message : String
      "Memory Warning: High memory usage detected. Consider closing unused projects."
    end
  end
  
  # Utility methods for error handling
  module ErrorUtils
    extend self
    
    def handle_error(error : Exception, context : String? = nil) : String
      case error
      when PaceEditorError
        error.to_user_message
      else
        "An unexpected error occurred: #{error.message}"
      end
    end
    
    def wrap_validation_errors(errors : Array(String), field : String) : ValidationError
      if errors.size == 1
        ValidationError.new(field, nil, errors.first)
      else
        ValidationError.new(field, nil, "Multiple issues: #{errors.join(", ")}")
      end
    end
    
    def create_context(file : String, line : Int32, method : String) : Hash(String, String)
      {
        "file" => file,
        "line" => line.to_s,
        "method" => method
      }
    end
  end
end