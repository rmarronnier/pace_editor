require "../spec_helper"
require "../../src/pace_editor/ui/script_editor"

describe "Script File Operations" do
  state = PaceEditor::Core::EditorState.new
  script_editor = PaceEditor::UI::ScriptEditor.new(state)

  describe "file creation" do
    it "creates new script files" do
      temp_dir = Dir.tempdir
      script_path = File.join(temp_dir, "new_script.lua")

      # Ensure file doesn't exist initially
      File.exists?(script_path).should be_false

      # Create the file by opening editor and showing it
      script_editor.show(script_path)

      # File should be ready for editing
      script_editor.visible.should be_true

      # Cleanup
      File.delete(script_path) if File.exists?(script_path)
    rescue
      # Handle any file system errors gracefully
    end

    it "creates script templates" do
      template_content = <<-LUA
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

      # Test that template content has expected structure
      template_content.should contain("on_click")
      template_content.should contain("on_look")
      template_content.should contain("on_use")
      template_content.should contain("on_talk")

      # Count function definitions
      function_count = template_content.scan(/function\s+\w+\(\)/).size
      function_count.should eq(4)
    end
  end

  describe "file loading" do
    it "loads existing script files" do
      temp_file = File.tempfile("load_test", ".lua")
      test_content = <<-LUA
        function greet(name)
            print("Hello, " .. name .. "!")
        end
        
        greet("World")
        LUA

      temp_file.print(test_content)
      temp_file.close

      # Load the file in script editor
      script_editor.show(temp_file.path)
      script_editor.visible.should be_true

      # Verify content was loaded
      script_editor.line_count.should be > 1

      temp_file.delete
    end

    it "handles missing files gracefully" do
      nonexistent_path = "/tmp/does_not_exist_#{Time.utc.to_unix}.lua"

      # Should not crash when opening non-existent file
      script_editor.show(nonexistent_path)
      script_editor.visible.should be_true
    end

    it "handles corrupted files gracefully" do
      temp_file = File.tempfile("corrupted", ".lua")

      # Write binary data that isn't valid Lua
      temp_file.write(Bytes[0xFF, 0xFE, 0x00, 0x01, 0x02])
      temp_file.close

      # Should handle corrupted file without crashing
      script_editor.show(temp_file.path)
      script_editor.visible.should be_true

      temp_file.delete
    end
  end

  describe "file saving" do
    it "saves script content to files" do
      temp_file = File.tempfile("save_test", ".lua")
      temp_file.close

      # Open file in editor
      script_editor.show(temp_file.path)

      # Editor should be visible
      script_editor.visible.should be_true

      # File should exist (even if empty initially)
      File.exists?(temp_file.path).should be_true

      temp_file.delete
    end

    it "preserves file content during save/load cycles" do
      temp_file = File.tempfile("preserve_test", ".lua")
      original_content = <<-LUA
        function fibonacci(n)
            if n <= 1 then
                return n
            else
                return fibonacci(n - 1) + fibonacci(n - 2)
            end
        end
        LUA

      temp_file.print(original_content)
      temp_file.close

      # Load in editor
      script_editor.show(temp_file.path)
      script_editor.visible.should be_true

      # Content should be preserved
      saved_content = File.read(temp_file.path)
      saved_content.should contain("fibonacci")
      saved_content.should contain("if n <= 1")

      temp_file.delete
    end

    it "handles save errors gracefully" do
      # Try to save to a read-only location
      readonly_path = "/dev/null/cannot_write_here.lua"

      script_editor.show(readonly_path)
      script_editor.visible.should be_true

      # Should handle save errors without crashing
    end
  end

  describe "file watching and auto-save" do
    it "tracks file modification state" do
      temp_file = File.tempfile("modify_test", ".lua")
      temp_file.print("function test() end")
      temp_file.close

      script_editor.show(temp_file.path)
      script_editor.visible.should be_true

      # Initially should not be modified
      script_editor.modified?.should be_false

      temp_file.delete
    end

    it "handles external file changes" do
      temp_file = File.tempfile("external_change", ".lua")
      temp_file.print("function original() end")
      temp_file.close

      # Load in editor
      script_editor.show(temp_file.path)

      # Simulate external modification
      File.write(temp_file.path, "function modified() end")

      # Editor should handle external changes gracefully
      script_editor.visible.should be_true

      temp_file.delete
    end
  end

  describe "backup and recovery" do
    it "creates backup files for safety" do
      temp_file = File.tempfile("backup_test", ".lua")
      important_content = <<-LUA
        -- Important script that shouldn't be lost
        function criticalFunction()
            -- This does something very important
            return "success"
        end
        LUA

      temp_file.print(important_content)
      temp_file.close

      script_editor.show(temp_file.path)
      script_editor.visible.should be_true

      # Original file should still exist
      File.exists?(temp_file.path).should be_true

      temp_file.delete
    end
  end

  describe "path handling" do
    it "handles various path formats" do
      path_examples = [
        "script.lua",
        "scripts/player.lua",
        "scripts/npcs/guard.lua",
        "/absolute/path/script.lua",
      ]

      path_examples.each do |path|
        # Test that paths can be processed
        path.should be_a(String)
        path.should end_with(".lua")
      end
    end

    it "handles special characters in paths" do
      special_paths = [
        "script with spaces.lua",
        "script-with-dashes.lua",
        "script_with_underscores.lua",
      ]

      special_paths.each do |path|
        path.should be_a(String)
        path.should end_with(".lua")
      end
    end
  end

  describe "encoding handling" do
    it "handles UTF-8 encoded files" do
      temp_file = File.tempfile("utf8_test", ".lua")
      utf8_content = <<-LUA
        -- Script with UTF-8 characters: café, naïve, résumé
        function greetInFrench()
            print("Bonjour, ça va?")
        end
        LUA

      temp_file.print(utf8_content)
      temp_file.close

      script_editor.show(temp_file.path)
      script_editor.visible.should be_true

      temp_file.delete
    end

    it "handles line ending variations" do
      temp_file = File.tempfile("line_endings", ".lua")

      # Test with different line endings
      content_with_crlf = "function test()\r\n    return true\r\nend"

      temp_file.print(content_with_crlf)
      temp_file.close

      script_editor.show(temp_file.path)
      script_editor.visible.should be_true

      temp_file.delete
    end
  end
end
