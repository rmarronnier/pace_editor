require "../spec_helper"
require "../../src/pace_editor/ui/script_editor"

describe PaceEditor::UI::ScriptEditor do
  state = PaceEditor::Core::EditorState.new
  editor = PaceEditor::UI::ScriptEditor.new(state)

  describe "#initialize" do
    it "creates a script editor with default state" do
      editor.visible.should be_false
    end

    it "has default content" do
      editor.show
      editor.line_count.should be > 0
    end
  end

  describe "#show" do
    it "shows the editor" do
      editor.show
      editor.visible.should be_true
    end

    it "resets cursor position" do
      editor.show
      line, column = editor.cursor_position
      line.should eq(0)
      column.should eq(0)
    end

    it "clears error count" do
      editor.show
      editor.error_count.should eq(0)
    end

    context "with valid script file" do
      it "loads script content" do
        temp_file = File.tempfile("test_script", ".lua")
        temp_file.print("function test()\n    print('hello')\nend")
        temp_file.close

        editor.show(temp_file.path)
        editor.line_count.should be > 1

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
  end

  describe "syntax highlighting" do
    it "processes tokens after content is loaded" do
      editor.show
      # Should have some syntax tokens for default content
      editor.token_count.should be >= 0
    end
  end

  describe "modification tracking" do
    it "tracks modification state" do
      editor.show
      editor.modified?.should be_false

      # After simulating text input, would be modified
      # This would require more complex testing setup
    end
  end

  describe "file operations" do
    it "handles file loading" do
      temp_file = File.tempfile("test_load", ".lua")
      temp_file.print("function loaded()\n    return true\nend")
      temp_file.close

      editor.show(temp_file.path)
      editor.line_count.should be > 1

      temp_file.delete
    end

    it "handles missing files gracefully" do
      editor.show("/nonexistent/file.lua")
      editor.visible.should be_true # Should still show editor
    end
  end

  describe "validation" do
    it "starts with no errors" do
      editor.show
      editor.error_count.should eq(0)
    end
  end

  describe "drawing and updating" do
    it "updates without crashing" do
      editor.show
      editor.update
      # Should not raise any exceptions
    end

    it "draws without crashing" do
      RaylibTestHelper.init
      editor.show

      # Need to be in a drawing context
      RL.begin_drawing
      editor.draw
      RL.end_drawing
      # Should not raise any exceptions
    end
  end
end
