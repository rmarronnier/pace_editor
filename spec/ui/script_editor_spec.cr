require "../spec_helper"
require "../../src/pace_editor/ui/script_editor"

describe PaceEditor::UI::ScriptEditor do
  let(:state) { PaceEditor::Core::EditorState.new }
  let(:editor) { PaceEditor::UI::ScriptEditor.new(state) }

  before_each do
    editor.visible = false
  end

  describe "#initialize" do
    it "creates a script editor with default state" do
      editor.visible.should be_false
    end

    it "has default content" do
      # Should have default content when shown
      editor.show
      # Script editor should be initialized with default content
      # We can't access private variables directly in specs
    end
  end

  describe "#show" do
    context "with no script path" do
      it "shows the editor with default content" do
        editor.show
        editor.visible.should be_true
      end

      it "sets cursor to initial position" do
        editor.show
        editor.@cursor_line.should eq(0)
        editor.@cursor_column.should eq(0)
      end

      it "clears error messages" do
        editor.@error_messages << "Test error"
        editor.show
        editor.@error_messages.should be_empty
      end
    end

    context "with valid script path" do
      it "loads the script content" do
        temp_file = File.tempfile("test_script", ".lua")
        temp_file.print("function test()\n    print('hello')\nend")
        temp_file.close

        editor.show(temp_file.path)
        editor.@script_content.should contain("function test()")
        editor.@lines.should contain("function test()")

        temp_file.delete
      end
    end
  end

  describe "#hide" do
    it "hides the editor" do
      editor.show
      editor.hide
      editor.visible.should be_false
    end

    it "clears script path" do
      editor.show("test.lua")
      editor.hide
      editor.@script_path.should be_nil
    end
  end

  describe "text editing operations" do
    before_each do
      editor.show
      # Start with a simple script
      editor.@lines = ["function test()", "    print('hello')", "end"]
      editor.@cursor_line = 1
      editor.@cursor_column = 4
    end

    describe "#insert_character" do
      it "inserts character at cursor position" do
        editor.send(:insert_character, 'x')
        editor.@lines[1].should eq("    xprint('hello')")
        editor.@cursor_column.should eq(5)
      end

      it "marks content as modified" do
        editor.@is_modified = false
        editor.send(:insert_character, 'x')
        editor.@is_modified.should be_true
      end
    end

    describe "#insert_newline" do
      it "splits line at cursor position" do
        editor.send(:insert_newline)
        editor.@lines[1].should eq("    ")
        editor.@lines[2].should eq("print('hello')")
        editor.@cursor_line.should eq(2)
        editor.@cursor_column.should eq(0)
      end
    end

    describe "#delete_character" do
      it "deletes character before cursor" do
        editor.send(:delete_character)
        editor.@lines[1].should eq("   print('hello')")
        editor.@cursor_column.should eq(3)
      end

      it "joins lines when at start of line" do
        editor.@cursor_column = 0
        editor.send(:delete_character)
        editor.@lines[0].should eq("function test()    print('hello')")
        editor.@cursor_line.should eq(0)
        editor.@cursor_column.should eq(15)
      end
    end
  end

  describe "cursor movement" do
    before_each do
      editor.show
      editor.@lines = ["line 1", "line 2", "line 3"]
      editor.@cursor_line = 1
      editor.@cursor_column = 3
    end

    describe "#move_cursor_up" do
      it "moves cursor to previous line" do
        editor.send(:move_cursor_up)
        editor.@cursor_line.should eq(0)
        editor.@cursor_column.should eq(3)
      end

      it "adjusts column if line is shorter" do
        editor.@lines[0] = "hi"
        editor.send(:move_cursor_up)
        editor.@cursor_column.should eq(2)
      end
    end

    describe "#move_cursor_down" do
      it "moves cursor to next line" do
        editor.send(:move_cursor_down)
        editor.@cursor_line.should eq(2)
        editor.@cursor_column.should eq(3)
      end
    end

    describe "#move_cursor_left" do
      it "moves cursor left within line" do
        editor.send(:move_cursor_left)
        editor.@cursor_column.should eq(2)
      end

      it "moves to end of previous line when at start" do
        editor.@cursor_column = 0
        editor.send(:move_cursor_left)
        editor.@cursor_line.should eq(0)
        editor.@cursor_column.should eq(6)
      end
    end

    describe "#move_cursor_right" do
      it "moves cursor right within line" do
        editor.send(:move_cursor_right)
        editor.@cursor_column.should eq(4)
      end

      it "moves to start of next line when at end" do
        editor.@cursor_column = 6
        editor.send(:move_cursor_right)
        editor.@cursor_line.should eq(2)
        editor.@cursor_column.should eq(0)
      end
    end
  end

  describe "syntax highlighting" do
    before_each do
      editor.show
      editor.@lines = ["function test()", "    local x = 42", "    -- comment", "    return x", "end"]
      editor.send(:update_syntax_highlighting)
    end

    it "identifies keywords" do
      tokens = editor.@syntax_tokens
      keyword_tokens = tokens.select { |t| t.type.keyword? }
      keyword_tokens.should_not be_empty
      
      # Should find 'function', 'local', 'return', 'end'
      keyword_tokens.map(&.text).should contain("function")
      keyword_tokens.map(&.text).should contain("local")
      keyword_tokens.map(&.text).should contain("return")
      keyword_tokens.map(&.text).should contain("end")
    end

    it "identifies comments" do
      comment_tokens = editor.@syntax_tokens.select { |t| t.type.comment? }
      comment_tokens.should_not be_empty
      comment_tokens.first.text.should eq("-- comment")
    end

    it "identifies numbers" do
      number_tokens = editor.@syntax_tokens.select { |t| t.type.number? }
      number_tokens.should_not be_empty
      number_tokens.first.text.should eq("42")
    end

    it "identifies identifiers" do
      identifier_tokens = editor.@syntax_tokens.select { |t| t.type.identifier? }
      identifier_tokens.should_not be_empty
      identifier_tokens.map(&.text).should contain("test")
      identifier_tokens.map(&.text).should contain("x")
    end
  end

  describe "syntax validation" do
    before_each do
      editor.show
    end

    it "validates balanced parentheses" do
      editor.@lines = ["function test(", "    print('hello')", "end"]
      editor.send(:validate_syntax)
      editor.@error_messages.should_not be_empty
      editor.@error_messages.join.should contain("Unmatched opening '('")
    end

    it "validates function syntax" do
      editor.@lines = ["function test", "    print('hello')"]  # Missing 'end'
      editor.send(:validate_syntax)
      editor.@error_messages.should_not be_empty
      editor.@error_messages.join.should contain("missing 'end'")
    end

    it "validates if-then syntax" do
      editor.@lines = ["if condition", "    print('hello')", "end"]  # Missing 'then'
      editor.send(:validate_syntax)
      editor.@error_messages.should_not be_empty
      editor.@error_messages.join.should contain("missing 'then'")
    end

    it "passes validation for correct syntax" do
      editor.@lines = ["function test()", "    if true then", "        print('hello')", "    end", "end"]
      editor.send(:validate_syntax)
      # Should have at least one success message
      editor.@error_messages.join.should contain("passed")
    end
  end

  describe "file operations" do
    context "saving scripts" do
      it "saves content to file" do
        temp_file = File.tempfile("test_save", ".lua")
        temp_file.close

        editor.show(temp_file.path)
        editor.@lines = ["function hello()", "    print('world')", "end"]
        editor.@is_modified = true
        
        editor.send(:save_script)
        
        saved_content = File.read(temp_file.path)
        saved_content.should contain("function hello()")
        saved_content.should contain("print('world')")
        
        editor.@is_modified.should be_false
        
        temp_file.delete
      end
    end

    context "loading scripts" do
      it "loads content from file" do
        temp_file = File.tempfile("test_load", ".lua")
        temp_file.print("function loaded()\n    return true\nend")
        temp_file.close

        editor.send(:load_script, temp_file.path)
        
        editor.@script_content.should contain("function loaded()")
        editor.@lines.should contain("function loaded()")
        editor.@is_modified.should be_false

        temp_file.delete
      end

      it "handles file read errors gracefully" do
        editor.send(:load_script, "/nonexistent/path.lua")
        editor.@error_messages.should_not be_empty
      end
    end
  end

  describe "function extraction" do
    it "extracts function names from code" do
      editor.@lines = [
        "function first_function()",
        "    print('one')",
        "end",
        "",
        "function second_function(arg1, arg2)",
        "    return arg1 + arg2",
        "end"
      ]

      functions = editor.send(:extract_functions)
      functions.should contain("first_function")
      functions.should contain("second_function")
      functions.size.should eq(2)
    end
  end

  describe "text wrapping" do
    it "wraps long text correctly" do
      long_text = "This is a very long line that should be wrapped at word boundaries"
      wrapped = editor.send(:wrap_text, long_text, 20, 12)
      
      wrapped.should be_a(Array(String))
      wrapped.size.should be > 1
      wrapped.each { |line| line.size.should be <= 25 }  # Allowing some margin for font measurement
    end

    it "handles single words longer than max width" do
      long_word = "supercalifragilisticexpialidocious"
      wrapped = editor.send(:wrap_text, long_word, 10, 12)
      
      wrapped.should contain(long_word)
    end
  end

  describe "integration with editor state" do
    it "respects modal state" do
      editor.show
      # When script editor is visible, it should block other editor inputs
      # This would be tested in integration tests with the main editor
    end

    it "handles keyboard shortcuts" do
      editor.show
      # Test would require mocking keyboard input
      # Verify Ctrl+S triggers save, F5 triggers validation, etc.
    end
  end

  describe "token color mapping" do
    it "returns appropriate colors for token types" do
      # Test each token type returns a valid color
      PaceEditor::UI::ScriptEditor::TokenType.each do |token_type|
        color = editor.send(:get_token_color, token_type)
        color.should be_a(RL::Color)
        # Colors should have reasonable RGB values
        color.r.should be >= 0
        color.g.should be >= 0  
        color.b.should be >= 0
        color.a.should be > 0
      end
    end
  end

  describe "scrolling behavior" do
    before_each do
      editor.show
      # Create enough lines to require scrolling
      editor.@lines = (0...50).map { |i| "line #{i}" }
    end

    it "ensures cursor visibility when moving beyond viewport" do
      editor.@cursor_line = 40
      editor.send(:ensure_cursor_visible)
      # Scroll offset should be adjusted to show cursor
      editor.@scroll_offset.should be > 0
    end

    it "handles scroll boundaries correctly" do
      editor.@scroll_offset = -5  # Invalid negative scroll
      editor.send(:handle_scrolling)
      # Should be clamped to valid range
      editor.@scroll_offset.should be >= 0
    end
  end
end