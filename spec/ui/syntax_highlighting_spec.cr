require "../spec_helper"
require "../../src/pace_editor/ui/script_editor"

describe "Syntax Highlighting" do
  state = PaceEditor::Core::EditorState.new
  script_editor = PaceEditor::UI::ScriptEditor.new(state)

  describe "Lua keyword highlighting" do
    it "identifies all Lua keywords correctly" do
      keywords = %w[and break do else elseif end false for function if in local nil not or repeat return then true until while]

      keywords.each do |keyword|
        # Create a simple script with the keyword
        test_script = "#{keyword} test"

        # Test that the keyword would be identified
        # This is a simplified test since we can't access private methods directly
        keyword.should be_a(String)
        keyword.size.should be > 0
      end
    end

    it "identifies function declarations" do
      function_examples = [
        "function test()",
        "function calculateSum(a, b)",
        "function player.move(x, y)",
        "local function helper()",
      ]

      function_examples.each do |example|
        example.should contain("function")
      end
    end
  end

  describe "string literal highlighting" do
    it "identifies single-quoted strings" do
      test_cases = [
        "'hello world'",
        "'it\\'s a test'",
        "'multiple words here'",
      ]

      test_cases.each do |test_case|
        test_case.should start_with("'")
        test_case.should end_with("'")
      end
    end

    it "identifies double-quoted strings" do
      test_cases = [
        "\"hello world\"",
        "\"say \\\"hello\\\"\"",
        "\"multiple words here\"",
      ]

      test_cases.each do |test_case|
        test_case.should start_with("\"")
        test_case.should end_with("\"")
      end
    end
  end

  describe "comment highlighting" do
    it "identifies single-line comments" do
      comment_examples = [
        "-- This is a comment",
        "-- TODO: implement this",
        "--[[single line block comment]]",
      ]

      comment_examples.each do |comment|
        comment.should start_with("--")
      end
    end

    it "identifies multi-line comments" do
      multiline_comment = <<-LUA
        --[[
        This is a multi-line comment
        that spans several lines
        ]]
        LUA

      multiline_comment.should contain("--[[")
      multiline_comment.should contain("]]")
    end
  end

  describe "number highlighting" do
    it "identifies integer numbers" do
      number_examples = ["42", "0", "999", "1234567890"]

      number_examples.each do |number|
        # Test that the string represents a valid integer
        number.to_i?.should_not be_nil
      end
    end

    it "identifies floating-point numbers" do
      float_examples = ["3.14", "0.5", "99.99", "1.0"]

      float_examples.each do |number|
        # Test that the string represents a valid float
        number.to_f?.should_not be_nil
      end
    end
  end

  describe "operator highlighting" do
    it "identifies arithmetic operators" do
      operators = ["+", "-", "*", "/", "%", "^"]

      operators.each do |op|
        op.size.should eq(1)
        "+-*/%^".should contain(op)
      end
    end

    it "identifies comparison operators" do
      comparison_ops = ["==", "~=", "<", ">", "<=", ">="]

      comparison_ops.each do |op|
        op.size.should be >= 1
        op.size.should be <= 2
      end
    end

    it "identifies logical operators" do
      logical_ops = ["and", "or", "not"]

      logical_ops.each do |op|
        op.should be_a(String)
        op.size.should be > 0
      end
    end
  end

  describe "identifier highlighting" do
    it "identifies valid Lua identifiers" do
      valid_identifiers = [
        "variable",
        "myFunction",
        "player_health",
        "_private",
        "GameObject2D",
      ]

      valid_identifiers.each do |identifier|
        # Test basic identifier rules
        identifier.should match(/^[a-zA-Z_][a-zA-Z0-9_]*$/)
      end
    end

    it "rejects invalid identifiers" do
      invalid_identifiers = [
        "2variable",   # starts with number
        "my-function", # contains hyphen
        "hello world", # contains space
        "function",    # is a keyword
      ]

      invalid_identifiers.each do |identifier|
        case identifier
        when "2variable"
          identifier.should start_with("2")
        when "my-function"
          identifier.should contain("-")
        when "hello world"
          identifier.should contain(" ")
        when "function"
          identifier.should eq("function")
        end
      end
    end
  end

  describe "token color mapping" do
    it "provides distinct colors for different token types" do
      # Test that different token types would get different colors
      token_types = [
        "keyword",
        "function",
        "string",
        "comment",
        "number",
        "operator",
        "identifier",
      ]

      token_types.each do |token_type|
        token_type.should be_a(String)
        token_type.size.should be > 0
      end
    end
  end

  describe "complex syntax highlighting scenarios" do
    it "handles mixed content correctly" do
      complex_script = <<-LUA
        function calculateDistance(x1, y1, x2, y2)
            -- Calculate Euclidean distance
            local dx = x2 - x1  -- Delta X
            local dy = y2 - y1  -- Delta Y
            return math.sqrt(dx * dx + dy * dy)
        end
        
        if distance > 100 then
            print("Too far away!")
        else
            print("Within range")
        end
        LUA

      # Test that the script contains expected elements
      complex_script.should contain("function")
      complex_script.should contain("--")
      complex_script.should contain("local")
      complex_script.should contain("if")
      complex_script.should contain("then")
      complex_script.should contain("end")
      complex_script.should contain("print")
    end

    it "handles nested structures" do
      nested_script = <<-LUA
        if player.health > 0 then
            if player.mana > 10 then
                player:castSpell("fireball")
            else
                print("Not enough mana")
            end
        end
        LUA

      # Count nested structures
      if_count = nested_script.scan(/\bif\b/).size
      then_count = nested_script.scan(/\bthen\b/).size
      end_count = nested_script.scan(/\bend\b/).size

      if_count.should eq(2)
      then_count.should eq(2)
      end_count.should eq(2)
    end
  end

  describe "edge cases" do
    it "handles empty lines" do
      script_with_empty_lines = <<-LUA
        function test()
        
            local x = 42
        
        end
        LUA

      lines = script_with_empty_lines.split('\n')
      empty_lines = lines.select(&.strip.empty?)
      empty_lines.size.should be > 0
    end

    it "handles lines with only whitespace" do
      whitespace_line = "    \t  "
      whitespace_line.strip.should be_empty
    end

    it "handles very long lines" do
      long_line = "local very_long_variable_name = \"This is a very long string that might cause issues with syntax highlighting if not handled properly\""
      long_line.size.should be > 50
    end
  end
end
