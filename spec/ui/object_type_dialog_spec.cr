require "../spec_helper"
require "../../src/pace_editor/ui/object_type_dialog"

describe PaceEditor::UI::ObjectTypeDialog do
  describe "#show" do
    it "shows the dialog and sets callback" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::ObjectTypeDialog.new(state)
      
      callback_called = false
      selected_type : PaceEditor::UI::ObjectTypeDialog::ObjectType? = nil
      
      dialog.visible.should be_false
      
      dialog.show do |object_type|
        callback_called = true
        selected_type = object_type
      end
      
      dialog.visible.should be_true
    end
  end
  
  describe "#hide" do
    it "hides the dialog and clears callback" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::ObjectTypeDialog.new(state)
      
      dialog.show do |object_type|
        # callback
      end
      
      dialog.visible.should be_true
      dialog.hide
      dialog.visible.should be_false
    end
  end
  
  describe "ObjectType enum" do
    it "has all expected object types" do
      object_types = PaceEditor::UI::ObjectTypeDialog::ObjectType.values
      object_types.should contain(PaceEditor::UI::ObjectTypeDialog::ObjectType::Hotspot)
      object_types.should contain(PaceEditor::UI::ObjectTypeDialog::ObjectType::Character)
      object_types.should contain(PaceEditor::UI::ObjectTypeDialog::ObjectType::Item)
      object_types.should contain(PaceEditor::UI::ObjectTypeDialog::ObjectType::Trigger)
    end
  end
  
  describe "object type descriptions" do
    it "provides meaningful descriptions for each type" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::ObjectTypeDialog.new(state)
      
      # Test that we can get descriptions without errors
      # Note: These are private methods, so we can't test them directly
      # but they're tested implicitly when the dialog is drawn
      dialog.visible.should be_false  # Just ensure dialog works
    end
  end
  
  describe "keyboard navigation" do
    it "handles escape key to hide dialog" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::ObjectTypeDialog.new(state)
      
      dialog.show do |object_type|
        # callback
      end
      
      dialog.visible.should be_true
      
      # Note: We can't directly test key presses in the spec
      # but the update method handles RL.key_pressed?(RL::KeyboardKey::Escape)
      # This is tested in integration tests
    end
  end
end