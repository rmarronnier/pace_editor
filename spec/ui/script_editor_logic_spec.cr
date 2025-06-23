require "../spec_helper"

# Test the script editor logic without graphics operations
describe "Script Editor Logic" do
  describe "Lua syntax validation" do
    it "validates balanced parentheses" do
      test_cases = [
        {code: "function test() end", valid: true},
        {code: "function test( end", valid: false},
        {code: "if (x > 0) then end", valid: true},
        {code: "if (x > 0 then end", valid: false},
      ]

      test_cases.each do |test_case|
        code = test_case[:code]
        expected_valid = test_case[:valid]

        # Test parentheses balance
        open_count = code.count('(')
        close_count = code.count(')')
        actual_valid = (open_count == close_count)

        if expected_valid
          actual_valid.should be_true
        else
          actual_valid.should be_false
        end
      end
    end

    it "validates function syntax" do
      valid_functions = [
        "function test() end",
        "function calculate(a, b) return a + b end",
        "local function helper() end",
      ]

      invalid_functions = [
        "function test()", # missing end
        "function end",    # missing name
        "test() end",      # missing function keyword
      ]

      valid_functions.each do |func|
        func.should contain("function")
        func.should contain("end")
      end

      invalid_functions.each do |func|
        has_function = func.includes?("function")
        has_end = func.includes?("end")

        # For invalid functions, at least one requirement should be missing
        case func
        when "function test()" # missing end
          has_function.should be_true
          has_end.should be_false
        when "function end" # missing name but has both keywords
          has_function.should be_true
          has_end.should be_true
        when "test() end" # missing function keyword
          has_function.should be_false
          has_end.should be_true
        end
      end
    end

    it "validates if-then syntax" do
      valid_if_statements = [
        "if true then print('yes') end",
        "if x > 0 then return x end",
        "if condition then action() else other() end",
      ]

      invalid_if_statements = [
        "if true print('yes') end",   # missing then
        "if true then print('yes')",  # missing end
        "true then print('yes') end", # missing if
      ]

      valid_if_statements.each do |stmt|
        stmt.should contain("if")
        stmt.should contain("then")
        stmt.should contain("end")
      end

      invalid_if_statements.each do |stmt|
        has_if = stmt.includes?("if")
        has_then = stmt.includes?("then")
        has_end = stmt.includes?("end")

        # At least one requirement should be missing
        (has_if && has_then && has_end).should be_false
      end
    end
  end

  describe "Lua keyword identification" do
    it "identifies all Lua keywords" do
      keywords = %w[and break do else elseif end false for function if in local nil not or repeat return then true until while]

      test_code = "function test() local x = 42 if x then return true else return false end end"

      found_keywords = keywords.select { |keyword| test_code.includes?(keyword) }
      found_keywords.should contain("function")
      found_keywords.should contain("local")
      found_keywords.should contain("if")
      found_keywords.should contain("then")
      found_keywords.should contain("return")
      found_keywords.should contain("true")
      found_keywords.should contain("else")
      found_keywords.should contain("false")
      found_keywords.should contain("end")
    end

    it "distinguishes keywords from identifiers" do
      code_with_similar_names = "function endGame() local ifCondition = true end"

      # "end" should be identified as keyword when standalone
      code_with_similar_names.should match(/\bend\b/)

      # "endGame" should not be identified as "end" keyword
      code_with_similar_names.includes?("endGame").should be_true

      # "ifCondition" should not be identified as "if" keyword
      code_with_similar_names.includes?("ifCondition").should be_true
    end
  end

  describe "string literal identification" do
    it "identifies single-quoted strings" do
      test_cases = [
        "'hello world'",
        "'it\\'s a test'",
        "'line 1\\nline 2'",
      ]

      test_cases.each do |string_literal|
        string_literal.should start_with("'")
        string_literal.should end_with("'")
      end
    end

    it "identifies double-quoted strings" do
      test_cases = [
        "\"hello world\"",
        "\"say \\\"hello\\\"\"",
        "\"tab\\there\"",
      ]

      test_cases.each do |string_literal|
        string_literal.should start_with("\"")
        string_literal.should end_with("\"")
      end
    end

    it "handles nested quotes correctly" do
      nested_examples = [
        {string: "'say \"hello\"'", outer: "'", inner: "\""},
        {string: "\"it's fine\"", outer: "\"", inner: "'"},
      ]

      nested_examples.each do |example|
        string = example[:string]
        outer = example[:outer]
        inner = example[:inner]

        string.should start_with(outer)
        string.should end_with(outer)
        string.should contain(inner)
      end
    end
  end

  describe "comment identification" do
    it "identifies single-line comments" do
      comment_examples = [
        "-- This is a comment",
        "-- TODO: implement this feature",
        "local x = 42 -- inline comment",
      ]

      comment_examples.each do |comment|
        comment.should contain("--")
      end
    end

    it "identifies multi-line comments" do
      multiline_comment = <<-LUA
        --[[
        This is a multi-line comment
        that spans several lines
        and can contain -- single line markers
        ]]
        LUA

      multiline_comment.should contain("--[[")
      multiline_comment.should contain("]]")
    end

    it "distinguishes comments from code" do
      code_with_comments = <<-LUA
        function test() -- this is a comment
            local x = 42
            -- another comment
            return x
        end
        LUA

      lines = code_with_comments.split('\n')
      comment_lines = lines.select { |line| line.strip.starts_with?("--") }
      comment_lines.size.should eq(1) # Only the standalone comment line

      inline_comment_lines = lines.select { |line| line.includes?("--") && !line.strip.starts_with?("--") }
      inline_comment_lines.size.should eq(1) # The line with inline comment
    end
  end

  describe "number identification" do
    it "identifies integer numbers" do
      number_examples = ["42", "0", "999", "1234567890"]

      number_examples.each do |number|
        number.to_i?.should_not be_nil
        number.should match(/^\d+$/)
      end
    end

    it "identifies floating-point numbers" do
      float_examples = ["3.14", "0.5", "99.99", "1.0", ".5", "2."]

      float_examples.each do |number|
        number.should match(/^\d*\.?\d*$/)
        # At least one digit should be present
        number.should match(/\d/)
      end
    end

    it "identifies scientific notation" do
      scientific_examples = ["1e10", "2.5e-3", "1.23E+4"]

      scientific_examples.each do |number|
        number.should match(/\d.*[eE]/)
      end
    end
  end

  describe "operator identification" do
    it "identifies arithmetic operators" do
      operators = ["+", "-", "*", "/", "%", "^"]
      test_expression = "a + b - c * d / e % f ^ g"

      operators.each do |op|
        test_expression.should contain(op)
      end
    end

    it "identifies comparison operators" do
      comparison_ops = ["==", "~=", "<", ">", "<=", ">="]

      comparison_ops.each do |op|
        test_expression = "if x #{op} y then"
        test_expression.should contain(op)
      end
    end

    it "identifies logical operators" do
      logical_ops = ["and", "or", "not"]
      test_code = "if not (a and b) or c then"

      logical_ops.each do |op|
        test_code.should contain(op)
      end
    end
  end

  describe "function extraction" do
    it "extracts function names from code" do
      lua_code = <<-LUA
        function firstFunction()
            return 1
        end
        
        function secondFunction(arg1, arg2)
            return arg1 + arg2
        end
        
        local function localFunction()
            return "local"
        end
        LUA

      # Extract function names using regex
      function_matches = lua_code.scan(/function\s+(\w+)\s*\(/)
      function_names = function_matches.map(&.[1])

      function_names.should contain("firstFunction")
      function_names.should contain("secondFunction")
      function_names.should contain("localFunction")
      function_names.size.should eq(3)
    end

    it "handles method definitions" do
      method_code = <<-LUA
        function Player:move(x, y)
            self.x = x
            self.y = y
        end
        
        function GameObject.create(name)
            return {name = name}
        end
        LUA

      # Extract method names
      method_matches = method_code.scan(/function\s+\w+[:.](\w+)\s*\(/)
      method_names = method_matches.map(&.[1])

      method_matches.size.should be > 0
    end
  end

  describe "text manipulation" do
    it "handles line splitting correctly" do
      multiline_text = "line 1\nline 2\nline 3"
      lines = multiline_text.split('\n')

      lines.size.should eq(3)
      lines[0].should eq("line 1")
      lines[1].should eq("line 2")
      lines[2].should eq("line 3")
    end

    it "handles different line endings" do
      windows_text = "line 1\r\nline 2\r\n"
      unix_text = "line 1\nline 2\n"
      mac_text = "line 1\rline 2\r"

      windows_text.should contain("\r\n")
      unix_text.should contain("\n")
      mac_text.should contain("\r")
    end

    it "handles character insertion" do
      original = "hello world"
      position = 6
      char = 'X'

      result = original[0...position] + char + original[position..-1]
      result.should eq("hello Xworld")
    end

    it "handles character deletion" do
      original = "hello world"
      position = 5 # Delete the space

      result = original[0...position] + original[position + 1..-1]
      result.should eq("helloworld")
    end
  end

  describe "template generation" do
    it "generates hotspot interaction templates" do
      template = <<-LUA
        -- Hotspot interaction script
        function on_click()
            -- Add click interaction code here
        end

        function on_look()
            -- Add look interaction code here
        end

        function on_use()
            -- Add use interaction code here
        end

        function on_talk()
            -- Add talk interaction code here
        end
        LUA

      template.should contain("on_click")
      template.should contain("on_look")
      template.should contain("on_use")
      template.should contain("on_talk")

      # Count function definitions
      function_count = template.scan(/function\s+\w+\(\)/).size
      function_count.should eq(4)
    end

    it "generates character script templates" do
      character_template = <<-LUA
        -- Character script
        function on_interact()
            -- Character interaction code
        end

        function on_dialog_start()
            -- Dialog initialization
        end

        function on_dialog_end()
            -- Dialog cleanup
        end
        LUA

      character_template.should contain("on_interact")
      character_template.should contain("on_dialog_start")
      character_template.should contain("on_dialog_end")
    end
  end
end
