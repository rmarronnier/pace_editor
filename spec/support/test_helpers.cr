# Test helper functions for PACE Editor specs

# Mock classes for testing
class MockProject
  property name : String
  property project_path : String
  property scenes : Array(String) = [] of String
  property backgrounds : Array(String) = [] of String
  property characters : Array(String) = [] of String
  property sounds : Array(String) = [] of String
  property music : Array(String) = [] of String
  property scripts : Array(String) = [] of String

  def initialize(@name : String, @project_path : String)
  end

  def scenes_path
    File.join(@project_path, "scenes")
  end
end

class MockScene
  property name : String
  property characters : Array(MockCharacter) = [] of MockCharacter
  property hotspots : Array(MockHotspot) = [] of MockHotspot
  property background_path : String? = nil
  property scale : Float32 = 1.0_f32

  def initialize(@name : String)
  end

  def add_hotspot(hotspot : MockHotspot)
    @hotspots << hotspot
  end
end

class MockCharacter
  property name : String
  property position : RL::Vector2
  property size : RL::Vector2
  property description : String = ""
  property walking_speed : Float32 = 100.0_f32
  property state : MockCharacterState = MockCharacterState::Idle
  property direction : MockDirection = MockDirection::Down

  def initialize(@name : String)
    @position = RL::Vector2.new(x: 0.0_f32, y: 0.0_f32)
    @size = RL::Vector2.new(x: 64.0_f32, y: 128.0_f32)
  end

  def mock_is_npc?
    false
  end
end

class MockNPC < MockCharacter
  property mood : MockCharacterMood = MockCharacterMood::Neutral

  def mock_is_npc?
    true
  end
end

class MockHotspot
  property name : String
  property position : RL::Vector2
  property size : RL::Vector2
  property description : String = ""
  property visible : Bool = true
  property cursor_type : Symbol = :default

  def initialize(@name : String)
    @position = RL::Vector2.new(x: 0.0_f32, y: 0.0_f32)
    @size = RL::Vector2.new(x: 100.0_f32, y: 100.0_f32)
  end
end

enum MockCharacterState
  Idle
  Walking
  Talking
  Interacting
  Thinking
end

enum MockDirection
  Left
  Right
  Up
  Down
end

enum MockCharacterMood
  Friendly
  Neutral
  Hostile
  Sad
  Happy
  Angry
end

class MockEditorState
  property current_project : MockProject? = nil
  property current_scene : MockScene? = nil
  property selected_object : String? = nil
  property current_mode : PaceEditor::EditorMode = PaceEditor::EditorMode::Project
  property is_dirty : Bool = false
  property show_new_project_dialog : Bool = false
  property editor_window : PaceEditor::Core::EditorWindow? = nil

  def has_project?
    !@current_project.nil?
  end

  def can_undo?
    false
  end

  def can_redo?
    false
  end

  def undo
    # Mock implementation
  end

  def redo
    # Mock implementation
  end

  def save_project
    # Mock implementation
  end

  def add_undo_action(action)
    # Mock implementation
  end

  def mark_dirty
    @is_dirty = true
  end

  def save_current_scene(scene)
    # Mock implementation
  end

  def duplicate_scene(scene_name : String)
    # Mock implementation
  end

  def delete_scene(scene_name : String)
    # Mock implementation
  end

  def add_player_character(scene : MockScene)
    character = MockCharacter.new("Player_#{Time.utc.to_unix}")
    scene.characters << character
  end

  def add_npc_character(scene : MockScene)
    npc = MockNPC.new("NPC_#{Time.utc.to_unix}")
    scene.characters << npc
  end

  def test_dialog(character_name : String)
    # Mock implementation
  end
end

# Test helper functions
def test_editor_state(has_project : Bool = false, current_scene : MockScene? = nil, is_dirty : Bool = false)
  state = MockEditorState.new

  if has_project
    state.current_project = MockProject.new("Test Project", "/tmp/test_project")
  end

  state.current_scene = current_scene
  state.is_dirty = is_dirty

  state
end

def test_scene(name : String = "Test Scene")
  MockScene.new(name)
end

def test_project(name : String = "Test Project", path : String = "/tmp/test_project")
  MockProject.new(name, path)
end

def test_character(name : String = "Test Character")
  MockCharacter.new(name)
end

def test_npc(name : String = "Test NPC")
  MockNPC.new(name)
end

def test_hotspot(name : String = "Test Hotspot")
  MockHotspot.new(name)
end

# Mock PaceEditor modules for tests
module PaceEditor
  module Validation
    class ValidationResult
      property errors : Array(ValidationError) = [] of ValidationError

      def has_errors?
        !errors.empty?
      end
    end

    class ValidationError
      property message : String
      property path : String?
      property line : Int32?

      def initialize(@message : String, @path : String? = nil, @line : Int32? = nil)
      end
    end

    class ProjectValidator
      def initialize(@project : Core::Project)
      end

      def validate_for_export(config) : ValidationResult
        ValidationResult.new
      end
    end
  end

  module Export
    class GameExporter
      def initialize(@project : Core::Project)
      end

      def export(config, export_path : String, include_source : Bool = false)
        # Create export directories
        Dir.mkdir_p(export_path)
        Dir.mkdir_p(File.join(export_path, "scenes"))
        Dir.mkdir_p(File.join(export_path, "scripts"))
        Dir.mkdir_p(File.join(export_path, "dialogs"))

        # Create dummy files for test
        File.write(File.join(export_path, "main.cr"), "require \"point_click_engine\"\n\ngame = PointClickEngine::Game.new")
        File.write(File.join(export_path, "shard.yml"), "name: exported_game\nversion: 0.1.0")
        File.write(File.join(export_path, "game_config.yaml"), config.to_yaml)

        # Copy scenes
        Dir.glob(File.join(@project.scenes_path, "*.yaml")).each do |scene_file|
          FileUtils.cp(scene_file, File.join(export_path, "scenes", File.basename(scene_file)))
        end

        # Copy scripts
        Dir.glob(File.join(@project.scripts_path, "*.lua")).each do |script_file|
          FileUtils.cp(script_file, File.join(export_path, "scripts", File.basename(script_file)))
        end

        # Copy dialogs
        Dir.glob(File.join(@project.dialogs_path, "*.yaml")).each do |dialog_file|
          FileUtils.cp(dialog_file, File.join(export_path, "dialogs", File.basename(dialog_file)))
        end
      end
    end
  end
end
