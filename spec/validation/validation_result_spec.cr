require "../spec_helper"
require "../../src/pace_editor/validation/validation_result"

describe PaceEditor::Validation::ValidationResult do
  describe "#initialize" do
    it "creates an empty result" do
      result = PaceEditor::Validation::ValidationResult.new

      result.errors.should be_empty
      result.warnings.should be_empty
      result.valid?.should be_true
      result.has_issues?.should be_false
      result.issue_count.should eq 0
    end
  end

  describe "#add_error" do
    it "adds an error with message only" do
      result = PaceEditor::Validation::ValidationResult.new
      result.add_error("Test error")

      result.errors.size.should eq 1
      result.errors[0].message.should eq "Test error"
      result.errors[0].path.should be_nil
      result.errors[0].line.should be_nil
      result.valid?.should be_false
    end

    it "adds an error with path and line" do
      result = PaceEditor::Validation::ValidationResult.new
      result.add_error("Syntax error", "config.yaml", 42)

      result.errors.size.should eq 1
      result.errors[0].message.should eq "Syntax error"
      result.errors[0].path.should eq "config.yaml"
      result.errors[0].line.should eq 42
    end
  end

  describe "#add_warning" do
    it "adds a warning" do
      result = PaceEditor::Validation::ValidationResult.new
      result.add_warning("Deprecated feature", "scene.yaml")

      result.warnings.size.should eq 1
      result.warnings[0].message.should eq "Deprecated feature"
      result.warnings[0].path.should eq "scene.yaml"
      result.valid?.should be_true
      result.has_issues?.should be_true
    end
  end

  describe "#valid?" do
    it "returns true when no errors" do
      result = PaceEditor::Validation::ValidationResult.new
      result.add_warning("Just a warning")

      result.valid?.should be_true
    end

    it "returns false when there are errors" do
      result = PaceEditor::Validation::ValidationResult.new
      result.add_error("An error")

      result.valid?.should be_false
    end
  end

  describe "#issue_count" do
    it "counts total issues" do
      result = PaceEditor::Validation::ValidationResult.new
      result.add_error("Error 1")
      result.add_error("Error 2")
      result.add_warning("Warning 1")

      result.issue_count.should eq 3
    end
  end

  describe "#merge" do
    it "merges another result" do
      result1 = PaceEditor::Validation::ValidationResult.new
      result1.add_error("Error from result1")
      result1.add_warning("Warning from result1")

      result2 = PaceEditor::Validation::ValidationResult.new
      result2.add_error("Error from result2")
      result2.add_warning("Warning from result2")

      result1.merge(result2)

      result1.errors.size.should eq 2
      result1.warnings.size.should eq 2
      result1.issue_count.should eq 4
    end
  end

  describe "#to_s" do
    it "formats output for valid result with no warnings" do
      result = PaceEditor::Validation::ValidationResult.new

      result.to_s.should eq "Validation passed with no issues."
    end

    it "formats output for valid result with warnings" do
      result = PaceEditor::Validation::ValidationResult.new
      result.add_warning("Large file size", "asset.png")
      result.add_warning("Missing optional field", "config.yaml")

      output = result.to_s
      output.should contain "Validation passed with 2 warning(s):"
      output.should contain "1. [asset.png] Large file size"
      output.should contain "2. [config.yaml] Missing optional field"
    end

    it "formats output for invalid result" do
      result = PaceEditor::Validation::ValidationResult.new
      result.add_error("File not found", "missing.png")
      result.add_error("Invalid format", "scene.yaml", 10)
      result.add_warning("Unused asset", "old.png")

      output = result.to_s
      output.should contain "Validation failed with 2 error(s) and 1 warning(s):"
      output.should contain "Errors:"
      output.should contain "1. [missing.png] File not found"
      output.should contain "2. [scene.yaml:10] Invalid format"
      output.should contain "Warnings:"
      output.should contain "1. [old.png] Unused asset"
    end
  end
end

describe PaceEditor::Validation::ValidationError do
  describe "#to_s" do
    it "formats error without path" do
      error = PaceEditor::Validation::ValidationError.new("General error")
      error.to_s.should eq "General error"
    end

    it "formats error with path" do
      error = PaceEditor::Validation::ValidationError.new("File error", "test.yaml")
      error.to_s.should eq "[test.yaml] File error"
    end

    it "formats error with path and line" do
      error = PaceEditor::Validation::ValidationError.new("Syntax error", "config.yaml", 25)
      error.to_s.should eq "[config.yaml:25] Syntax error"
    end
  end
end

describe PaceEditor::Validation::ValidationWarning do
  describe "#to_s" do
    it "formats warning similar to errors" do
      warning = PaceEditor::Validation::ValidationWarning.new("Deprecation", "old.yaml", 5)
      expected = "[old.yaml:5] Deprecation"
      actual = warning.to_s
      actual.should eq expected
    end
  end
end
