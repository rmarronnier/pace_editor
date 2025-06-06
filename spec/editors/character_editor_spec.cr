require "../spec_helper"

describe PaceEditor::Editors::CharacterEditor do
  describe "#initialize" do
    it "initializes with correct default values" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::CharacterEditor.new(state)

      editor.current_character.should be_nil
      editor.animation_preview_time.should eq(0.0f32)
    end
  end

  describe "#get_current_character" do
    it "returns cached character when available" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::CharacterEditor.new(state)

      # Create test character
      character = PointClickEngine::Characters::Character.new("test_hero", RL::Vector2.new(x: 100, y: 200), RL::Vector2.new(x: 32, y: 64))
      editor.current_character = character

      result = editor.get_current_character
      result.should eq(character)
    end

    it "finds character from selection when no cached character" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::CharacterEditor.new(state)

      # Create test scene with character
      scene = PointClickEngine::Scene.new("test_scene")
      character = PointClickEngine::Characters::Character.new("selected_hero", RL::Vector2.new(x: 150, y: 250), RL::Vector2.new(x: 32, y: 64))
      scene.add_character(character)

      # Set up state
      state.current_project = create_test_project
      state.selected_object = "selected_hero"

      # Mock current scene
      allow(state).to receive(:current_scene).and_return(scene)

      result = editor.get_current_character
      result.should eq(character)
      editor.current_character.should eq(character) # Should cache it
    end

    it "returns nil when no character found" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::CharacterEditor.new(state)

      result = editor.get_current_character
      result.should be_nil
    end
  end

  describe "#create_new_character" do
    it "creates character and adds to scene" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::CharacterEditor.new(state)

      # Create test scene
      scene = PointClickEngine::Scene.new("test_scene")
      initial_character_count = scene.characters.size

      # Set up state
      state.current_project = create_test_project
      allow(state).to receive(:current_scene).and_return(scene)
      allow(state).to receive(:save_current_scene)

      editor.create_new_character

      # Should have added one character
      scene.characters.size.should eq(initial_character_count + 1)

      # Should set as current character
      editor.current_character.should_not be_nil
      editor.current_character.not_nil!.name.should start_with("new_character")

      # Should select the new character
      state.selected_object.should eq(editor.current_character.not_nil!.name)
    end

    it "handles case when no scene is available" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::CharacterEditor.new(state)

      # No current scene
      allow(state).to receive(:current_scene).and_return(nil)

      editor.create_new_character

      # Should not crash, character should remain nil
      editor.current_character.should be_nil
    end
  end

  describe "#update" do
    it "advances animation preview time" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::CharacterEditor.new(state)

      initial_time = editor.animation_preview_time

      # Mock frame time
      allow(RL).to receive(:get_frame_time).and_return(0.016f32) # ~60 FPS

      editor.update

      editor.animation_preview_time.should be > initial_time
    end
  end

  describe "character properties" do
    it "handles character with basic properties" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::CharacterEditor.new(state)

      # Create character with specific properties
      character = PointClickEngine::Characters::Character.new(
        "hero",
        RL::Vector2.new(x: 100, y: 200),
        RL::Vector2.new(x: 32, y: 64)
      )

      editor.current_character = character

      character.name.should eq("hero")
      character.position.x.should eq(100)
      character.position.y.should eq(200)
      character.size.x.should eq(32)
      character.size.y.should eq(64)
    end

    it "validates character properties" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::CharacterEditor.new(state)

      character = PointClickEngine::Characters::Character.new(
        "test_character",
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 1, y: 1)
      )

      editor.current_character = character

      # Basic validation
      character.name.should_not be_empty
      character.size.x.should be > 0
      character.size.y.should be > 0
    end
  end

  describe "character state management" do
    it "maintains character reference correctly" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::CharacterEditor.new(state)

      character1 = PointClickEngine::Characters::Character.new("char1", RL::Vector2.new(x: 0, y: 0), RL::Vector2.new(x: 32, y: 64))
      character2 = PointClickEngine::Characters::Character.new("char2", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 32, y: 64))

      # Set first character
      editor.current_character = character1
      editor.current_character.should eq(character1)

      # Switch to second character
      editor.current_character = character2
      editor.current_character.should eq(character2)
      editor.current_character.should_not eq(character1)

      # Clear character
      editor.current_character = nil
      editor.current_character.should be_nil
    end
  end

  describe "animation preview" do
    it "tracks preview time correctly" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::CharacterEditor.new(state)

      editor.animation_preview_time = 1.5f32
      editor.animation_preview_time.should eq(1.5f32)

      # Simulate time advancement
      editor.animation_preview_time += 0.016f32
      editor.animation_preview_time.should be_close(1.516f32, 0.001f32)
    end

    it "resets preview time when needed" do
      state = PaceEditor::Core::EditorState.new
      editor = PaceEditor::Editors::CharacterEditor.new(state)

      editor.animation_preview_time = 5.0f32
      editor.animation_preview_time = 0.0f32
      editor.animation_preview_time.should eq(0.0f32)
    end
  end
end

# Helper methods for testing
private def create_test_project
  test_dir = File.tempname("test_project")
  project = PaceEditor::Core::Project.new("Test Project", test_dir)
  project
end

# Simple mock helpers (since we can't use full mocking framework)
private def allow(object)
  MockHelper.new
end

private class MockHelper
  def receive(method_name)
    self
  end

  def and_return(value)
    # In a real test, this would set up the mock
    # For our simple case, we'll just return the value
    value
  end
end
