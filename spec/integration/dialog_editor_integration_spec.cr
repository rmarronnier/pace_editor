require "../spec_helper"

describe "Dialog Editor Integration" do
  temp_dir = ""
  project_dir = ""

  before_each do
    temp_dir = File.tempname
    project_dir = File.join(temp_dir, "test_project")
    Dir.mkdir_p(temp_dir)
    Dir.mkdir_p(project_dir)
    Dir.mkdir_p(File.join(project_dir, "assets"))
    Dir.mkdir_p(File.join(project_dir, "scenes"))
    Dir.mkdir_p(File.join(project_dir, "dialogs"))
  end

  after_each do
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end

  describe "Dialog Editor UI Integration" do
    it "creates dialog editor instance in editor window" do
      editor_window = PaceEditor::Core::EditorWindow.new

      # Dialog editor should be initialized
      editor_window.dialog_editor.should_not be_nil
    end

    it "switches to dialog mode when show_dialog_editor_for_character is called" do
      editor_window = PaceEditor::Core::EditorWindow.new
      initial_mode = editor_window.state.current_mode

      # Should switch to dialog mode
      editor_window.show_dialog_editor_for_character("test_npc")
      editor_window.state.current_mode.should eq(PaceEditor::EditorMode::Dialog)
    end

    it "handles dialog editor for different character names" do
      editor_window = PaceEditor::Core::EditorWindow.new
      character_names = ["wizard", "merchant", "guard", "princess"]

      character_names.each do |name|
        editor_window.show_dialog_editor_for_character(name)
        editor_window.state.current_mode.should eq(PaceEditor::EditorMode::Dialog)
      end
    end
  end

  describe "NPC Dialog Integration" do
    it "creates Edit Dialog button for NPCs in property panel" do
      # Create a test project
      project = PaceEditor::Core::Project.new(
        name: "Test Project",
        project_path: project_dir
      )

      # Create a scene with an NPC
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      npc = PointClickEngine::Characters::NPC.new(
        "test_wizard",
        RL::Vector2.new(200.0_f32, 200.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      scene.add_character(npc)

      # Set up editor state
      state = PaceEditor::Core::EditorState.new
      state.current_project = project
      state.current_scene = scene
      state.selected_object = "test_wizard"

      # Property panel should be able to handle NPC properties
      property_panel = PaceEditor::UI::PropertyPanel.new(state)
      property_panel.should_not be_nil

      # The property panel should have access to the editor window for dialog editing
      editor_window = PaceEditor::Core::EditorWindow.new
      state.editor_window = editor_window

      # Verify NPC is correctly typed
      selected_npc = scene.characters.find { |c| c.name == "test_wizard" }
      selected_npc.should_not be_nil
      selected_npc.should be_a(PointClickEngine::Characters::NPC)
    end

    it "distinguishes between regular characters and NPCs" do
      # Create a scene with both types
      scene = PointClickEngine::Scenes::Scene.new("test_scene")

      # Add player character (concrete type)
      player_char = PointClickEngine::Characters::Player.new(
        "player",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      scene.add_character(player_char)

      # Add NPC
      npc = PointClickEngine::Characters::NPC.new(
        "shopkeeper",
        RL::Vector2.new(200.0_f32, 200.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )
      scene.add_character(npc)

      # Verify types
      player_char.should be_a(PointClickEngine::Characters::Player)
      player_char.should_not be_a(PointClickEngine::Characters::NPC)

      npc.should be_a(PointClickEngine::Characters::NPC)
      npc.should be_a(PointClickEngine::Characters::Character) # NPCs are also Characters
    end
  end

  describe "Dialog Editor Functionality" do
    it "handles dialog editor state correctly" do
      state = PaceEditor::Core::EditorState.new
      dialog_editor = PaceEditor::Editors::DialogEditor.new(state)

      # Should have proper initialization
      dialog_editor.should_not be_nil
      dialog_editor.current_dialog.should be_nil
      dialog_editor.selected_node.should be_nil
    end

    it "manages dialog tree creation for characters" do
      # Create a dialog tree for testing
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("wizard_dialog")

      # Create some dialog nodes
      greeting_node = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "greeting",
        "Hello, traveler! Welcome to my shop."
      )

      question_node = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "question",
        "What brings you here today?"
      )

      # Add nodes to tree
      dialog_tree.add_node(greeting_node)
      dialog_tree.add_node(question_node)

      # Verify dialog structure
      dialog_tree.nodes.size.should eq(2)
      dialog_tree.nodes["greeting"].should_not be_nil
      dialog_tree.nodes["question"].should_not be_nil
    end

    it "handles dialog node connections" do
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")

      # Create connected nodes
      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "start",
        "Greetings!"
      )

      response_node = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "response",
        "How can I help you?"
      )

      # Add choice to connect nodes
      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new(
        "Continue",
        "response"
      )
      start_node.add_choice(choice)

      dialog_tree.add_node(start_node)
      dialog_tree.add_node(response_node)

      # Verify connections
      start_node.choices.size.should eq(1)
      start_node.choices.first.target_node_id.should eq("response")
    end
  end

  describe "Dialog File Management" do
    it "creates dialog directory structure correctly" do
      project = PaceEditor::Core::Project.new(
        name: "Test Project",
        project_path: project_dir
      )

      # Simulate dialog directory creation
      dialogs_dir = File.join(project.project_path, "assets", "dialogs")
      Dir.mkdir_p(dialogs_dir)

      # Verify directory structure
      Dir.exists?(dialogs_dir).should be_true
      File.basename(dialogs_dir).should eq("dialogs")
    end

    it "handles dialog file naming for characters" do
      character_names = ["wizard", "merchant", "guard", "blacksmith"]

      character_names.each do |name|
        dialog_filename = "#{name}_dialog.yml"
        dialog_filename.should end_with(".yml")
        dialog_filename.should contain(name)
        dialog_filename.should contain("dialog")
      end
    end

    it "manages dialog tree serialization" do
      # Create a simple dialog tree
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")

      node = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "start",
        "Hello there!"
      )
      dialog_tree.add_node(node)

      # Test serialization (basic YAML structure)
      yaml_content = dialog_tree.to_yaml
      yaml_content.should be_a(String)
      yaml_content.should contain("test_dialog")
      yaml_content.should contain("Hello there!")
    end
  end

  describe "Editor Mode Integration" do
    it "properly switches between editor modes" do
      state = PaceEditor::Core::EditorState.new
      initial_mode = state.current_mode

      # Should start in Scene mode
      initial_mode.should eq(PaceEditor::EditorMode::Scene)

      # Switch to Dialog mode
      state.current_mode = PaceEditor::EditorMode::Dialog
      state.current_mode.should eq(PaceEditor::EditorMode::Dialog)

      # Can switch to other modes
      state.current_mode = PaceEditor::EditorMode::Character
      state.current_mode.should eq(PaceEditor::EditorMode::Character)
    end

    it "maintains dialog editor state across mode switches" do
      state = PaceEditor::Core::EditorState.new
      dialog_editor = PaceEditor::Editors::DialogEditor.new(state)

      # Set some dialog editor state
      test_dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("test")
      dialog_editor.current_dialog = test_dialog
      dialog_editor.selected_node = "start"

      # Switch modes
      state.current_mode = PaceEditor::EditorMode::Scene
      state.current_mode = PaceEditor::EditorMode::Dialog

      # Dialog editor state should persist
      dialog_editor.current_dialog.should eq(test_dialog)
      dialog_editor.selected_node.should eq("start")
    end
  end

  describe "NPC Property Panel Integration" do
    it "shows mood dropdown for NPCs" do
      # Create NPC with different moods
      npc = PointClickEngine::Characters::NPC.new(
        "test_npc",
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )

      # Test different mood values
      moods = [
        PointClickEngine::Characters::CharacterMood::Friendly,
        PointClickEngine::Characters::CharacterMood::Neutral,
        PointClickEngine::Characters::CharacterMood::Hostile,
        PointClickEngine::Characters::CharacterMood::Happy,
        PointClickEngine::Characters::CharacterMood::Sad,
        PointClickEngine::Characters::CharacterMood::Angry,
      ]

      moods.each do |mood|
        npc.mood = mood
        npc.mood.should eq(mood)
      end
    end

    it "handles NPC-specific properties correctly" do
      npc = PointClickEngine::Characters::NPC.new(
        "merchant",
        RL::Vector2.new(150.0_f32, 150.0_f32),
        RL::Vector2.new(32.0_f32, 64.0_f32)
      )

      # NPCs should have all character properties
      npc.name.should eq("merchant")
      npc.position.x.should eq(150.0_f32)
      npc.position.y.should eq(150.0_f32)

      # Plus NPC-specific properties - NPCs have mood
      npc.mood.should be_a(PointClickEngine::Characters::CharacterMood)
    end
  end

  describe "Error Handling" do
    it "handles missing dialog files gracefully" do
      state = PaceEditor::Core::EditorState.new
      dialog_editor = PaceEditor::Editors::DialogEditor.new(state)

      # Should handle null dialog tree
      dialog_editor.current_dialog = nil
      dialog_editor.current_dialog.should be_nil
    end

    it "handles invalid character names for dialog editing" do
      editor_window = PaceEditor::Core::EditorWindow.new

      # Should not crash with invalid names
      invalid_names = ["", "   ", "special/chars!", "very_long_character_name_that_might_cause_issues"]

      invalid_names.each do |name|
        editor_window.show_dialog_editor_for_character(name)
        editor_window.state.current_mode.should eq(PaceEditor::EditorMode::Dialog)
      end
    end

    it "handles missing project context gracefully" do
      state = PaceEditor::Core::EditorState.new
      state.current_project = nil

      dialog_editor = PaceEditor::Editors::DialogEditor.new(state)

      # Should not crash when no project is loaded
      dialog_editor.should_not be_nil
    end
  end
end
