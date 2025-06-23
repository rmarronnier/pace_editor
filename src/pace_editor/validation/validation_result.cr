module PaceEditor::Validation
  # Represents the result of a validation operation
  class ValidationResult
    getter errors : Array(ValidationError)
    getter warnings : Array(ValidationWarning)

    def initialize
      @errors = [] of ValidationError
      @warnings = [] of ValidationWarning
    end

    # Add an error
    def add_error(message : String, path : String? = nil, line : Int32? = nil)
      @errors << ValidationError.new(message, path, line)
    end

    # Add a warning
    def add_warning(message : String, path : String? = nil, line : Int32? = nil)
      @warnings << ValidationWarning.new(message, path, line)
    end

    # Check if validation passed (no errors)
    def valid? : Bool
      @errors.empty?
    end

    # Check if there are any issues (errors or warnings)
    def has_issues? : Bool
      !@errors.empty? || !@warnings.empty?
    end

    # Get total number of issues
    def issue_count : Int32
      @errors.size + @warnings.size
    end

    # Merge another validation result into this one
    def merge(other : ValidationResult)
      @errors.concat(other.errors)
      @warnings.concat(other.warnings)
    end

    # Get a formatted summary of all issues
    def to_s(io : IO)
      if valid?
        if @warnings.empty?
          io << "Validation passed with no issues."
        else
          io << "Validation passed with #{@warnings.size} warning(s):\n"
          @warnings.each_with_index do |warning, index|
            io << "#{index + 1}. #{warning}\n"
          end
        end
      else
        io << "Validation failed with #{@errors.size} error(s)"
        io << " and #{@warnings.size} warning(s)" unless @warnings.empty?
        io << ":\n"

        unless @errors.empty?
          io << "Errors:\n"
          @errors.each_with_index do |error, index|
            io << "#{index + 1}. #{error}\n"
          end
        end

        unless @warnings.empty?
          io << "Warnings:\n"
          @warnings.each_with_index do |warning, index|
            io << "#{index + 1}. #{warning}\n"
          end
        end
      end
    end

    def to_s : String
      result = ""
      if valid?
        if @warnings.empty?
          result = "Validation passed with no issues."
        else
          result = "Validation passed with #{@warnings.size} warning(s):\n"
          @warnings.each_with_index do |warning, index|
            result += "#{index + 1}. #{warning.to_s}\n"
          end
        end
      else
        result = "Validation failed with #{@errors.size} error(s)"
        result += " and #{@warnings.size} warning(s)" unless @warnings.empty?
        result += ":\n"

        unless @errors.empty?
          result += "Errors:\n"
          @errors.each_with_index do |error, index|
            result += "#{index + 1}. #{error.to_s}\n"
          end
        end

        unless @warnings.empty?
          result += "Warnings:\n"
          @warnings.each_with_index do |warning, index|
            result += "#{index + 1}. #{warning.to_s}\n"
          end
        end
      end
      result
    end
  end

  # Represents a validation error
  class ValidationError
    getter message : String
    getter path : String?
    getter line : Int32?

    def initialize(@message : String, @path : String? = nil, @line : Int32? = nil)
    end

    def to_s : String
      result = ""
      if @path
        result += "[#{@path}"
        result += ":#{@line}" if @line
        result += "] "
      end
      result + @message
    end
  end

  # Represents a validation warning
  class ValidationWarning
    getter message : String
    getter path : String?
    getter line : Int32?

    def initialize(@message : String, @path : String? = nil, @line : Int32? = nil)
    end

    def to_s : String
      result = ""
      if @path
        result += "[#{@path}"
        result += ":#{@line}" if @line
        result += "] "
      end
      result + @message
    end
  end
end
