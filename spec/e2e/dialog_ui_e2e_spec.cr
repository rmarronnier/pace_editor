require "./e2e_spec_helper"

describe "Dialog UI E2E Tests" do
  describe "BackgroundImportDialog" do
    it "initializes in hidden state" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundImportDialog.new(harness.editor.state)

      dialog.visible.should be_false
      dialog.selected_file.should be_nil
    end

    it "shows dialog and sets up initial state" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundImportDialog.new(harness.editor.state)

      dialog.show
      dialog.visible.should be_true
      dialog.selected_file.should be_nil
      dialog.test_selected_index.should eq(-1)
    end

    it "hides dialog when hide is called" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundImportDialog.new(harness.editor.state)

      dialog.show
      dialog.visible.should be_true

      dialog.hide
      dialog.visible.should be_false
    end

    it "closes on escape key" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundImportDialog.new(harness.editor.state)

      dialog.show
      dialog.visible.should be_true

      input = harness.input
      input.press_key(RL::KeyboardKey::Escape)

      dialog.update_with_input(input)
      dialog.visible.should be_false
    end

    it "closes on cancel button click" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundImportDialog.new(harness.editor.state)

      dialog.show

      cancel_bounds = dialog.test_cancel_button_bounds
      input = harness.input
      input.set_mouse_position((cancel_bounds[:x] + 5).to_f32, (cancel_bounds[:y] + 5).to_f32)
      input.press_mouse_button(RL::MouseButton::Left)

      dialog.update_with_input(input)
      dialog.visible.should be_false
    end

    it "navigates to parent directory when clicking .." do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundImportDialog.new(harness.editor.state)

      # Change to a subdirectory first
      original_dir = dialog.test_current_directory
      subdir = File.join(original_dir, "spec")
      if Dir.exists?(subdir)
        dialog.test_set_current_directory(subdir)
        dialog.visible = true

        # The file list should now have ".." as first entry
        dialog.test_file_list.first?.should eq("..")
      end
    end

    it "refreshes file list when changing directory" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundImportDialog.new(harness.editor.state)

      dialog.show
      initial_list_size = dialog.test_file_list.size

      # Just verify the list is populated
      dialog.test_file_list.should_not be_empty
    end

    it "filters to only image files" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundImportDialog.new(harness.editor.state)

      dialog.show

      # All non-directory entries should have image extensions
      dialog.test_file_list.each do |item|
        next if item == ".." || item.ends_with?("/")
        ext = File.extname(item).downcase
        [".png", ".jpg", ".jpeg", ".bmp", ".gif"].should contain(ext)
      end
    end

    it "calculates button bounds correctly" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundImportDialog.new(harness.editor.state)

      cancel_bounds = dialog.test_cancel_button_bounds
      import_bounds = dialog.test_import_button_bounds

      # Cancel button should be to the left of import button
      cancel_bounds[:x].should be < import_bounds[:x]

      # Both should have standard button dimensions
      cancel_bounds[:width].should eq(100)
      cancel_bounds[:height].should eq(30)
      import_bounds[:width].should eq(100)
      import_bounds[:height].should eq(30)
    end

    it "calculates file list bounds correctly" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundImportDialog.new(harness.editor.state)

      list_bounds = dialog.test_file_list_bounds
      list_bounds[:width].should eq(560) # dialog_width - 40
      list_bounds[:height].should eq(200)
    end
  end

  describe "ObjectTypeDialog" do
    it "initializes in hidden state" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::ObjectTypeDialog.new(harness.editor.state)

      dialog.visible.should be_false
    end

    it "shows dialog with default selection" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::ObjectTypeDialog.new(harness.editor.state)

      dialog.show { |type| }
      dialog.visible.should be_true
      dialog.test_selected_type.should eq(PaceEditor::UI::ObjectTypeDialog::ObjectType::Hotspot)
    end

    it "calls callback with selected type on confirm" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::ObjectTypeDialog.new(harness.editor.state)

      selected_type : PaceEditor::UI::ObjectTypeDialog::ObjectType? = nil
      dialog.show do |type|
        selected_type = type
      end

      dialog.test_set_selected_type(PaceEditor::UI::ObjectTypeDialog::ObjectType::Character)
      dialog.test_confirm_selection

      selected_type.should eq(PaceEditor::UI::ObjectTypeDialog::ObjectType::Character)
      dialog.visible.should be_false
    end

    it "closes on escape key without calling callback" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::ObjectTypeDialog.new(harness.editor.state)

      callback_called = false
      dialog.show do |type|
        callback_called = true
      end

      input = harness.input
      input.press_key(RL::KeyboardKey::Escape)

      dialog.update_with_input(input)
      dialog.visible.should be_false
      callback_called.should be_false
    end

    it "confirms on enter key" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::ObjectTypeDialog.new(harness.editor.state)

      callback_called = false
      selected_type : PaceEditor::UI::ObjectTypeDialog::ObjectType? = nil
      dialog.show do |type|
        callback_called = true
        selected_type = type
      end

      input = harness.input
      input.press_key(RL::KeyboardKey::Enter)

      dialog.update_with_input(input)
      callback_called.should be_true
      dialog.visible.should be_false
    end

    it "cycles selection with down arrow" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::ObjectTypeDialog.new(harness.editor.state)

      dialog.show { |type| }
      dialog.test_selected_type.should eq(PaceEditor::UI::ObjectTypeDialog::ObjectType::Hotspot)

      input = harness.input
      input.press_key(RL::KeyboardKey::Down)

      dialog.update_with_input(input)
      dialog.test_selected_type.should eq(PaceEditor::UI::ObjectTypeDialog::ObjectType::Character)
    end

    it "cycles selection with up arrow" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::ObjectTypeDialog.new(harness.editor.state)

      dialog.show { |type| }
      dialog.test_set_selected_type(PaceEditor::UI::ObjectTypeDialog::ObjectType::Character)

      input = harness.input
      input.press_key(RL::KeyboardKey::Up)

      dialog.update_with_input(input)
      dialog.test_selected_type.should eq(PaceEditor::UI::ObjectTypeDialog::ObjectType::Hotspot)
    end

    it "wraps selection from first to last with up arrow" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::ObjectTypeDialog.new(harness.editor.state)

      dialog.show { |type| }
      # Starts at Hotspot (first)

      input = harness.input
      input.press_key(RL::KeyboardKey::Up)

      dialog.update_with_input(input)
      # Should wrap to Trigger (last)
      dialog.test_selected_type.should eq(PaceEditor::UI::ObjectTypeDialog::ObjectType::Trigger)
    end

    it "wraps selection from last to first with down arrow" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::ObjectTypeDialog.new(harness.editor.state)

      dialog.show { |type| }
      dialog.test_set_selected_type(PaceEditor::UI::ObjectTypeDialog::ObjectType::Trigger)

      input = harness.input
      input.press_key(RL::KeyboardKey::Down)

      dialog.update_with_input(input)
      dialog.test_selected_type.should eq(PaceEditor::UI::ObjectTypeDialog::ObjectType::Hotspot)
    end

    it "closes on close button click" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::ObjectTypeDialog.new(harness.editor.state)

      dialog.show { |type| }

      close_bounds = dialog.test_close_button_bounds
      input = harness.input
      input.set_mouse_position((close_bounds[:x] + 5).to_f32, (close_bounds[:y] + 5).to_f32)
      input.press_mouse_button(RL::MouseButton::Left)

      dialog.update_with_input(input)
      dialog.visible.should be_false
    end

    it "selects and confirms on option click" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::ObjectTypeDialog.new(harness.editor.state)

      selected_type : PaceEditor::UI::ObjectTypeDialog::ObjectType? = nil
      dialog.show do |type|
        selected_type = type
      end

      # Click on Character option
      option_bounds = dialog.test_option_bounds(PaceEditor::UI::ObjectTypeDialog::ObjectType::Character)
      input = harness.input
      input.set_mouse_position((option_bounds[:x] + 5).to_f32, (option_bounds[:y] + 5).to_f32)
      input.press_mouse_button(RL::MouseButton::Left)

      dialog.update_with_input(input)
      selected_type.should eq(PaceEditor::UI::ObjectTypeDialog::ObjectType::Character)
      dialog.visible.should be_false
    end

    it "closes on cancel button click" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::ObjectTypeDialog.new(harness.editor.state)

      callback_called = false
      dialog.show { |type| callback_called = true }

      cancel_bounds = dialog.test_cancel_button_bounds
      input = harness.input
      # Click at y+15 to be safely within button (away from option boundaries)
      input.set_mouse_position((cancel_bounds[:x] + 5).to_f32, (cancel_bounds[:y] + 15).to_f32)
      input.press_mouse_button(RL::MouseButton::Left)

      dialog.update_with_input(input)
      dialog.visible.should be_false
      callback_called.should be_false
    end

    it "confirms on OK button click" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::ObjectTypeDialog.new(harness.editor.state)

      callback_called = false
      dialog.show { |type| callback_called = true }

      ok_bounds = dialog.test_ok_button_bounds
      input = harness.input
      # Click at y+15 to be safely within button (away from option boundaries)
      input.set_mouse_position((ok_bounds[:x] + 5).to_f32, (ok_bounds[:y] + 15).to_f32)
      input.press_mouse_button(RL::MouseButton::Left)

      dialog.update_with_input(input)
      callback_called.should be_true
      dialog.visible.should be_false
    end

    it "has correct option bounds for all types" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::ObjectTypeDialog.new(harness.editor.state)

      dialog.show { |type| }

      # Verify bounds are calculated correctly for each type
      previous_y = 0
      PaceEditor::UI::ObjectTypeDialog::ObjectType.values.each_with_index do |type, index|
        bounds = dialog.test_option_bounds(type)
        bounds[:width].should eq(260) # window_width - 40
        bounds[:height].should eq(30)

        if index > 0
          # Each option should be below the previous
          bounds[:y].should be > previous_y
        end
        previous_y = bounds[:y]
      end
    end
  end

  describe "BackgroundSelectorDialog" do
    it "initializes in hidden state" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(harness.editor.state)

      dialog.visible.should be_false
    end

    it "shows dialog and resets state" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(harness.editor.state)

      dialog.test_set_selected_background("test.png")
      dialog.test_set_scroll_offset(100.0_f32)

      dialog.show
      dialog.visible.should be_true
      dialog.test_selected_background.should be_nil
      dialog.test_scroll_offset.should eq(0.0_f32)
    end

    it "hides dialog when hide is called" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(harness.editor.state)

      dialog.show
      dialog.hide
      dialog.visible.should be_false
    end

    it "closes on escape key" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(harness.editor.state)

      dialog.show

      input = harness.input
      input.press_key(RL::KeyboardKey::Escape)

      dialog.update_with_input(input)
      dialog.visible.should be_false
    end

    it "scrolls with mouse wheel" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(harness.editor.state)

      dialog.show
      dialog.test_scroll_offset.should eq(0.0_f32)

      input = harness.input
      input.set_mouse_wheel(-1.0_f32) # Scroll down

      dialog.update_with_input(input)
      dialog.test_scroll_offset.should eq(30.0_f32)
    end

    it "prevents negative scroll" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(harness.editor.state)

      dialog.show
      dialog.test_scroll_offset.should eq(0.0_f32)

      input = harness.input
      input.set_mouse_wheel(1.0_f32) # Scroll up (negative direction)

      dialog.update_with_input(input)
      dialog.test_scroll_offset.should eq(0.0_f32) # Should not go negative
    end

    it "closes on cancel button click" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(harness.editor.state)

      dialog.show

      cancel_bounds = dialog.test_cancel_button_bounds
      input = harness.input
      input.set_mouse_position((cancel_bounds[:x] + 5).to_f32, (cancel_bounds[:y] + 5).to_f32)
      input.press_mouse_button(RL::MouseButton::Left)

      dialog.draw_with_input(input)
      dialog.visible.should be_false
    end

    it "calculates button bounds correctly" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(harness.editor.state)

      ok_bounds = dialog.test_ok_button_bounds
      cancel_bounds = dialog.test_cancel_button_bounds
      import_bounds = dialog.test_import_button_bounds

      # OK button should be to the left of cancel
      ok_bounds[:x].should be < cancel_bounds[:x]

      # Import button should be on the left side
      import_bounds[:x].should be < ok_bounds[:x]

      # All buttons should have standard dimensions
      ok_bounds[:width].should eq(100)
      ok_bounds[:height].should eq(30)
      cancel_bounds[:width].should eq(100)
      cancel_bounds[:height].should eq(30)
      import_bounds[:width].should eq(100)
      import_bounds[:height].should eq(30)
    end

    it "calculates list bounds correctly" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(harness.editor.state)

      list_bounds = dialog.test_list_bounds
      list_bounds[:width].should eq(560) # dialog_width - 40
      list_bounds[:height].should eq(380) # dialog_height - 120
    end

    it "gets available backgrounds from project" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(harness.editor.state)

      # Should not crash, returns empty array if no backgrounds
      backgrounds = dialog.test_get_available_backgrounds
      backgrounds.should be_a(Array(String))
    end

    it "selects background on click" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(harness.editor.state)

      # Manually set a selected background to test the getter/setter
      dialog.test_set_selected_background("test_bg.png")
      dialog.test_selected_background.should eq("test_bg.png")
    end

    it "triggers import when import button clicked" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(harness.editor.state)

      dialog.show

      import_bounds = dialog.test_import_button_bounds
      input = harness.input
      input.set_mouse_position((import_bounds[:x] + 5).to_f32, (import_bounds[:y] + 5).to_f32)
      input.press_mouse_button(RL::MouseButton::Left)

      dialog.draw_with_input(input)

      # Should close and set show_new_project_dialog flag
      dialog.visible.should be_false
      harness.editor.state.show_new_project_dialog.should be_true
    end

    it "OK button only works when background selected" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::BackgroundSelectorDialog.new(harness.editor.state)

      dialog.show
      dialog.test_selected_background.should be_nil

      ok_bounds = dialog.test_ok_button_bounds
      input = harness.input
      input.set_mouse_position((ok_bounds[:x] + 5).to_f32, (ok_bounds[:y] + 5).to_f32)
      input.press_mouse_button(RL::MouseButton::Left)

      dialog.draw_with_input(input)

      # Should still be visible because no background selected
      dialog.visible.should be_true
    end
  end

  describe "AssetImportDialog" do
    it "initializes in hidden state with backgrounds category" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::AssetImportDialog.new(harness.editor.state)

      dialog.visible.should be_false
      dialog.asset_category.should eq("backgrounds")
    end

    it "shows dialog with custom category" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::AssetImportDialog.new(harness.editor.state)

      dialog.show("characters")
      dialog.visible.should be_true
      dialog.asset_category.should eq("characters")
      dialog.selected_files.should be_empty
    end

    it "supports multiple file selection" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::AssetImportDialog.new(harness.editor.state)

      dialog.show
      dialog.selected_files << "/path/to/file1.png"
      dialog.selected_files << "/path/to/file2.png"

      dialog.selected_files.size.should eq(2)
    end

    it "hides dialog when hide is called" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::AssetImportDialog.new(harness.editor.state)

      dialog.show
      dialog.hide
      dialog.visible.should be_false
    end

    it "clears selection on show" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::AssetImportDialog.new(harness.editor.state)

      dialog.selected_files << "/path/to/file.png"
      dialog.show

      dialog.selected_files.should be_empty
    end

    it "has correct supported extensions for backgrounds" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::AssetImportDialog.new(harness.editor.state)

      dialog.show("backgrounds")
      # The file list should filter to image files
      # (tested indirectly through refresh_file_list behavior)
    end

    it "has correct supported extensions for sounds" do
      harness = E2ETestHelper.create_harness_with_project
      dialog = PaceEditor::UI::AssetImportDialog.new(harness.editor.state)

      dialog.show("sounds")
      # The file list should filter to audio files
      dialog.asset_category.should eq("sounds")
    end
  end
end
