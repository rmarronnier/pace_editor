require "../spec_helper"

describe PaceEditor::Errors do
  describe PaceEditor::Errors::PaceEditorError do
    it "creates base error with message" do
      error = PaceEditor::Errors::PaceEditorError.new("test error")
      error.message.should eq("test error")
      error.context.should be_nil
    end

    it "creates error with context" do
      context = {"file" => "test.cr", "line" => "10"}
      error = PaceEditor::Errors::PaceEditorError.new("test error", context)
      error.context.should eq(context)
    end

    it "provides user-friendly message" do
      error = PaceEditor::Errors::PaceEditorError.new("test error")
      error.to_user_message.should eq("test error")
    end
  end

  describe PaceEditor::Errors::ProjectError do
    it "creates project error with path and message" do
      error = PaceEditor::Errors::ProjectError.new("/path/to/project", "failed to load")
      error.project_path.should eq("/path/to/project")
      error.message.not_nil!.should contain("Project error in /path/to/project")
      error.message.not_nil!.should contain("failed to load")
    end

    it "provides user-friendly message" do
      error = PaceEditor::Errors::ProjectError.new("/path/to/project", "failed to load")
      error.to_user_message.should eq("Project Error: failed to load")
    end
  end

  describe PaceEditor::Errors::ProjectNotFoundError do
    it "creates not found error" do
      error = PaceEditor::Errors::ProjectNotFoundError.new("/missing/project")
      error.project_path.should eq("/missing/project")
      error.to_user_message.should contain("Project not found at /missing/project")
    end
  end

  describe PaceEditor::Errors::ValidationError do
    it "creates validation error with field and value" do
      error = PaceEditor::Errors::ValidationError.new("name", "test", "is too short")
      error.field.should eq("name")
      error.value.should eq("test")
      error.message.not_nil!.should contain("Validation failed for name")
    end

    it "provides user-friendly message" do
      error = PaceEditor::Errors::ValidationError.new("name", "test", "is too short")
      error.to_user_message.should eq("Invalid name: is too short")
    end
  end

  describe PaceEditor::Errors::RequiredFieldError do
    it "creates required field error" do
      error = PaceEditor::Errors::RequiredFieldError.new("email")
      error.field.should eq("email")
      error.to_user_message.should eq("Email is required")
    end
  end

  describe PaceEditor::Errors::AssetError do
    it "creates asset error with path" do
      error = PaceEditor::Errors::AssetError.new("/path/to/asset.png", "corrupted file")
      error.asset_path.should eq("/path/to/asset.png")
      error.message.not_nil!.should contain("Asset error for /path/to/asset.png")
    end
  end

  describe PaceEditor::Errors::AssetNotFoundError do
    it "creates asset not found error" do
      error = PaceEditor::Errors::AssetNotFoundError.new("/missing/asset.png")
      error.to_user_message.should eq("Asset not found: asset.png")
    end
  end

  describe PaceEditor::Errors::UnsupportedAssetError do
    it "creates unsupported asset error" do
      error = PaceEditor::Errors::UnsupportedAssetError.new("/path/file.xyz", ".xyz")
      error.file_extension.should eq(".xyz")
      error.to_user_message.should contain("Unsupported file format: .xyz")
    end
  end

  describe PaceEditor::Errors::SceneError do
    it "creates scene error" do
      error = PaceEditor::Errors::SceneError.new("main_scene", "invalid background")
      error.scene_name.should eq("main_scene")
      error.message.not_nil!.should contain("Scene error in main_scene")
    end
  end

  describe PaceEditor::Errors::CircularReferenceError do
    it "creates circular reference error" do
      chain = ["scene1", "scene2", "scene1"]
      error = PaceEditor::Errors::CircularReferenceError.new("scene1", chain)
      error.message.not_nil!.should contain("scene1 -> scene2 -> scene1")
      error.to_user_message.should contain("Circular reference detected")
    end
  end

  describe PaceEditor::Errors::DialogError do
    it "creates dialog error" do
      error = PaceEditor::Errors::DialogError.new("dialog_123", "missing end node")
      error.dialog_id.should eq("dialog_123")
    end
  end

  describe PaceEditor::Errors::ScriptError do
    it "creates script error with line number" do
      error = PaceEditor::Errors::ScriptError.new("/path/script.lua", "syntax error", 42)
      error.script_path.should eq("/path/script.lua")
      error.line_number.should eq(42)
      error.message.not_nil!.should contain("script.lua")
      error.message.not_nil!.should contain("line 42")
    end

    it "creates script error without line number" do
      error = PaceEditor::Errors::ScriptError.new("/path/script.lua", "file not found")
      error.line_number.should be_nil
      error.message.not_nil!.should_not contain("line")
    end
  end

  describe PaceEditor::Errors::LuaSyntaxError do
    it "creates Lua syntax error" do
      error = PaceEditor::Errors::LuaSyntaxError.new("/path/script.lua", "unexpected token", 10)
      error.to_user_message.should contain("Lua syntax error at line 10")
    end
  end

  describe PaceEditor::Errors::ExportError do
    it "creates export error" do
      error = PaceEditor::Errors::ExportError.new("/export/path", "disk full")
      error.export_path.should eq("/export/path")
    end
  end

  describe PaceEditor::Errors::ExportValidationError do
    it "creates export validation error with multiple errors" do
      validation_errors = ["Missing background", "Invalid character"]
      error = PaceEditor::Errors::ExportValidationError.new("/export", validation_errors)
      error.validation_errors.should eq(validation_errors)
      error.to_user_message.should contain("Missing background")
      error.to_user_message.should contain("Invalid character")
    end
  end

  describe PaceEditor::Errors::PerformanceError do
    it "creates performance error" do
      duration = 5.seconds
      threshold = 1.second
      error = PaceEditor::Errors::PerformanceError.new("texture_load", duration, threshold)
      error.operation.should eq("texture_load")
      error.duration.should eq(duration)
    end
  end

  describe PaceEditor::Errors::MemoryError do
    it "creates memory error" do
      usage = 1024_u64 * 1024 * 100    # 100MB
      threshold = 1024_u64 * 1024 * 50 # 50MB
      error = PaceEditor::Errors::MemoryError.new(usage, threshold)
      error.memory_usage.should eq(usage)
    end
  end

  describe PaceEditor::Errors::ErrorUtils do
    describe "#handle_error" do
      it "handles PaceEditorError" do
        error = PaceEditor::Errors::ValidationError.new("field", "value", "message")
        result = PaceEditor::Errors::ErrorUtils.handle_error(error)
        result.should eq("Invalid field: message")
      end

      it "handles generic exception" do
        error = Exception.new("generic error")
        result = PaceEditor::Errors::ErrorUtils.handle_error(error)
        result.should eq("An unexpected error occurred: generic error")
      end

      it "handles error with context" do
        error = PaceEditor::Errors::ValidationError.new("field", "value", "message")
        result = PaceEditor::Errors::ErrorUtils.handle_error(error, "validation context")
        result.should eq("Invalid field: message")
      end
    end

    describe "#wrap_validation_errors" do
      it "wraps single error" do
        errors = ["is required"]
        result = PaceEditor::Errors::ErrorUtils.wrap_validation_errors(errors, "name")
        result.field.should eq("name")
        result.message.not_nil!.should contain("is required")
      end

      it "wraps multiple errors" do
        errors = ["is required", "is too short"]
        result = PaceEditor::Errors::ErrorUtils.wrap_validation_errors(errors, "name")
        result.message.not_nil!.should contain("Multiple issues")
        result.message.not_nil!.should contain("is required")
        result.message.not_nil!.should contain("is too short")
      end
    end

    describe "#create_context" do
      it "creates context hash" do
        context = PaceEditor::Errors::ErrorUtils.create_context("test.cr", 42, "test_method")
        context["file"].should eq("test.cr")
        context["line"].should eq("42")
        context["method"].should eq("test_method")
      end
    end
  end
end
