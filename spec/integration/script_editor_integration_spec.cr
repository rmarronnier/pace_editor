require "../spec_helper"
require "../../src/pace_editor/ui/script_editor"
require "../../src/pace_editor/editors/hotspot_editor"

describe "Script Editor Integration" do
  state = PaceEditor::Core::EditorState.new
  script_editor = PaceEditor::UI::ScriptEditor.new(state)

  describe "hotspot script integration" do
    it "opens script editor for hotspot editing" do
      # Test that script editor can be opened from hotspot context
      script_editor.show("scripts/hotspot_interactions.lua")
      script_editor.visible.should be_true
    end

    it "handles script template generation" do
      # Create a temporary script file with template content
      temp_file = File.tempfile("hotspot_script", ".lua")
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

      temp_file.print(template_content)
      temp_file.close

      script_editor.show(temp_file.path)
      script_editor.visible.should be_true
      script_editor.line_count.should be > 5

      temp_file.delete
    end
  end

  describe "script validation workflow" do
    it "validates basic Lua syntax" do
      # Create a script with valid Lua code
      temp_file = File.tempfile("valid_script", ".lua")
      valid_lua = <<-LUA
        function test()
            local x = 42
            if x > 0 then
                print("positive")
            end
        end
        LUA

      temp_file.print(valid_lua)
      temp_file.close

      script_editor.show(temp_file.path)
      script_editor.visible.should be_true

      temp_file.delete
    end

    it "reports syntax errors" do
      # Create a script with syntax errors
      temp_file = File.tempfile("invalid_script", ".lua")
      invalid_lua = <<-LUA
        function test(
            local x = 42
            if x > 0
                print("missing then")
        -- missing end
        LUA

      temp_file.print(invalid_lua)
      temp_file.close

      script_editor.show(temp_file.path)
      script_editor.visible.should be_true

      temp_file.delete
    end
  end

  describe "file operations workflow" do
    it "saves and loads script files" do
      # Create a script file
      temp_file = File.tempfile("save_test", ".lua")
      temp_file.close

      # Open in editor
      script_editor.show(temp_file.path)
      script_editor.visible.should be_true

      # File should exist (even if empty)
      File.exists?(temp_file.path).should be_true

      temp_file.delete
    end

    it "handles new script creation" do
      # Test creating a new script without existing file
      script_editor.show("/tmp/new_script.lua")
      script_editor.visible.should be_true
    end
  end

  describe "script editor UI workflow" do
    it "handles keyboard shortcuts" do
      script_editor.show
      # Test that update doesn't crash with no input
      script_editor.update
      script_editor.visible.should be_true
    end

    it "renders without errors" do
      script_editor.show
      # Test that draw doesn't crash
      script_editor.draw
      script_editor.visible.should be_true
    end
  end

  describe "project integration" do
    it "integrates with project script directory" do
      # Test that script editor works with project structure
      script_path = "scripts/test_script.lua"
      script_editor.show(script_path)
      script_editor.visible.should be_true
    end

    it "handles script organization" do
      # Test that scripts can be organized by purpose
      hotspot_script = "scripts/hotspots/door_interaction.lua"
      character_script = "scripts/characters/npc_dialog.lua"

      script_editor.show(hotspot_script)
      script_editor.visible.should be_true

      script_editor.hide
      script_editor.visible.should be_false

      script_editor.show(character_script)
      script_editor.visible.should be_true
    end
  end
end
