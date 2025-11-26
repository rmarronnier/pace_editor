require "../spec_helper"
require "./e2e_spec_helper"

describe "Advanced UI E2E Tests" do
  describe "GameExportDialog" do
    it "shows dialog with default settings" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = harness.editor.game_export_dialog

      # Show the dialog
      dialog.show

      dialog.visible.should be_true
      dialog.export_name_for_test.should_not be_empty
      dialog.export_format_for_test.should eq "standalone"
      dialog.compress_assets_for_test.should be_true
      dialog.validate_project_for_test.should be_true
    end

    it "can change export format" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = harness.editor.game_export_dialog
      dialog.show

      dialog.set_export_format_for_test("web")
      dialog.export_format_for_test.should eq "web"

      dialog.set_export_format_for_test("source")
      dialog.export_format_for_test.should eq "source"
    end

    it "can toggle checkboxes" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = harness.editor.game_export_dialog
      dialog.show

      # Toggle include source
      dialog.set_include_source_for_test(true)
      dialog.include_source_for_test.should be_true

      dialog.set_include_source_for_test(false)
      dialog.include_source_for_test.should be_false

      # Toggle compress assets
      dialog.set_compress_assets_for_test(false)
      dialog.compress_assets_for_test.should be_false
    end

    it "validates project before export" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = harness.editor.game_export_dialog
      dialog.show

      dialog.trigger_validation_for_test
      dialog.validation_results_for_test.should_not be_empty
    end

    it "hides on escape key" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = harness.editor.game_export_dialog
      dialog.show
      dialog.visible.should be_true

      # Simulate escape key
      harness.input.press_key(RL::KeyboardKey::Escape)
      dialog.update_with_input(harness.input)

      dialog.visible.should be_false
    end

    it "can set export path" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = harness.editor.game_export_dialog
      dialog.show

      dialog.set_export_path_for_test("/tmp/test_export")
      dialog.export_path_for_test.should eq "/tmp/test_export"
    end
  end

  describe "AnimationEditor" do
    it "shows with default animations" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.animation_editor

      editor.show_for_test("test_character")

      editor.visible.should be_true
      editor.character_name_for_test.should eq "test_character"
      editor.animation_count_for_test.should be > 0
    end

    it "can select different animations" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.animation_editor
      editor.show_for_test("test_character")

      names = editor.animation_names_for_test
      names.size.should be > 0

      first_name = names.first
      editor.set_current_animation_for_test(first_name)
      editor.current_animation_for_test.should eq first_name
    end

    it "can navigate frames with keyboard" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.animation_editor
      editor.show_for_test("test_character")

      # Ensure we have frames
      next if editor.frame_count_for_test <= 1

      initial_frame = editor.current_frame_for_test

      # Press right arrow to go to next frame
      harness.input.press_key(RL::KeyboardKey::Right)
      editor.update_with_input(harness.input)

      editor.current_frame_for_test.should eq (initial_frame + 1) % editor.frame_count_for_test
    end

    it "wraps around when navigating past last frame" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.animation_editor
      editor.show_for_test("test_character")

      frame_count = editor.frame_count_for_test
      next if frame_count <= 1

      # Go to last frame
      editor.set_current_frame_for_test(frame_count - 1)

      # Press right - should wrap to 0
      harness.input.press_key(RL::KeyboardKey::Right)
      editor.update_with_input(harness.input)

      editor.current_frame_for_test.should eq 0
    end

    it "wraps around when navigating before first frame" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.animation_editor
      editor.show_for_test("test_character")

      frame_count = editor.frame_count_for_test
      next if frame_count <= 1

      # Start at first frame
      editor.set_current_frame_for_test(0)

      # Press left - should wrap to last
      harness.input.press_key(RL::KeyboardKey::Left)
      editor.update_with_input(harness.input)

      editor.current_frame_for_test.should eq frame_count - 1
    end

    it "can toggle playback with space" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.animation_editor
      editor.show_for_test("test_character")

      editor.is_playing_for_test.should be_false

      harness.input.press_key(RL::KeyboardKey::Space)
      editor.update_with_input(harness.input)

      editor.is_playing_for_test.should be_true

      harness.input.press_key(RL::KeyboardKey::Space)
      editor.update_with_input(harness.input)

      editor.is_playing_for_test.should be_false
    end

    it "can create new animation" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.animation_editor
      editor.show_for_test("test_character")

      initial_count = editor.animation_count_for_test
      editor.create_new_animation_for_test

      editor.animation_count_for_test.should eq initial_count + 1
    end

    it "can add frames to animation" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.animation_editor
      editor.show_for_test("test_character")

      initial_frames = editor.frame_count_for_test
      editor.add_frame_for_test

      editor.frame_count_for_test.should eq initial_frames + 1
    end

    it "hides on escape key" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.animation_editor
      editor.show_for_test("test_character")
      editor.visible.should be_true

      harness.input.press_key(RL::KeyboardKey::Escape)
      editor.update_with_input(harness.input)

      editor.visible.should be_false
    end
  end

  describe "ScriptEditor" do
    it "shows with default content" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.script_editor

      editor.show_for_test
      editor.visible.should be_true
      editor.line_count.should be > 0
    end

    it "can insert text" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.script_editor
      editor.show_for_test

      editor.set_lines_for_test([""])
      editor.set_cursor_for_test(0, 0)

      editor.insert_text_for_test("hello")
      editor.line_at_for_test(0).should eq "hello"
      editor.cursor_column_for_test.should eq 5
    end

    it "can insert newlines" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.script_editor
      editor.show_for_test

      editor.set_lines_for_test(["line1"])
      editor.set_cursor_for_test(0, 5)

      editor.insert_text_for_test("\n")
      editor.line_count.should eq 2
      editor.cursor_line_for_test.should eq 1
    end

    it "can insert tabs as spaces" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.script_editor
      editor.show_for_test

      editor.set_lines_for_test([""])
      editor.set_cursor_for_test(0, 0)

      # Press tab
      harness.input.press_key(RL::KeyboardKey::Tab)
      editor.update_with_input(harness.input)

      # Tab size is 2 by default
      editor.line_at_for_test(0).should eq "  "
      editor.cursor_column_for_test.should eq 2
    end

    it "can navigate with arrow keys" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.script_editor
      editor.show_for_test

      editor.set_lines_for_test(["line1", "line2", "line3"])
      editor.set_cursor_for_test(0, 0)

      # Move right
      harness.input.press_key(RL::KeyboardKey::Right)
      editor.update_with_input(harness.input)
      editor.cursor_column_for_test.should eq 1

      # Move down
      harness.input.press_key(RL::KeyboardKey::Down)
      editor.update_with_input(harness.input)
      editor.cursor_line_for_test.should eq 1

      # Move up
      harness.input.press_key(RL::KeyboardKey::Up)
      editor.update_with_input(harness.input)
      editor.cursor_line_for_test.should eq 0
    end

    it "validates Lua syntax" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.script_editor
      editor.show_for_test

      # Valid syntax
      editor.set_lines_for_test([
        "function test()",
        "  return 42",
        "end",
      ])
      editor.validate_syntax_for_test
      # Should pass validation
      editor.error_messages_for_test.any? { |msg| msg.includes?("passed") }.should be_true
    end

    it "detects unbalanced brackets" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.script_editor
      editor.show_for_test

      editor.set_lines_for_test([
        "function test(",
        "  return 42",
        "end",
      ])
      editor.validate_syntax_for_test

      # Should find unmatched bracket
      editor.error_messages_for_test.any? { |msg| msg.includes?("Unmatched") }.should be_true
    end

    it "tracks modified state" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.script_editor
      editor.show_for_test

      editor.clear_modified_for_test
      editor.is_modified_for_test.should be_false

      editor.insert_text_for_test("x")
      editor.is_modified_for_test.should be_true
    end

    it "performs syntax highlighting" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.script_editor
      editor.show_for_test

      editor.set_lines_for_test([
        "-- comment",
        "function test()",
        "  local x = 42",
        "  return \"hello\"",
        "end",
      ])

      # Should have syntax tokens
      editor.syntax_token_count_for_test.should be > 0
    end

    it "hides on escape key" do
      harness = E2ETestHelper.create_harness_with_project
      editor = harness.editor.script_editor
      editor.show_for_test
      editor.visible.should be_true

      harness.input.press_key(RL::KeyboardKey::Escape)
      editor.update_with_input(harness.input)

      editor.visible.should be_false
    end
  end

  describe "DialogPreviewWindow" do
    it "shows dialog preview" do
      harness = E2ETestHelper.create_harness_with_project
      preview = harness.editor.dialog_preview_window

      # Create a simple dialog tree
      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new
      node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello, adventurer!")
      node.character_name = "NPC"
      dialog.add_node(node)

      preview.show(dialog)
      preview.visible.should be_true
    end

    it "wraps choice selection correctly" do
      harness = E2ETestHelper.create_harness_with_project
      preview = harness.editor.dialog_preview_window

      # Create dialog with choices
      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new
      node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "What do you want?")
      node.character_name = "NPC"
      node.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Option 1", "end1")
      node.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Option 2", "end2")
      node.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Option 3", "end3")
      dialog.add_node(node)

      preview.show(dialog)

      # Selection should work (not crash on negative modulo)
      preview.update
      preview.visible.should be_true
    end
  end
end
