require "yaml"
require "./condition"
require "./effect"

module PaceEditor::Models
  # Represents a cutscene definition
  class Cutscene
    include YAML::Serializable

    property id : String
    property name : String
    property skippable : Bool = true
    property actions : Array(CutsceneAction) = [] of CutsceneAction
    property on_complete : Array(Effect) = [] of Effect
    property on_skip : Array(Effect) = [] of Effect

    def initialize(@id : String, @name : String)
    end

    # Add an action to the cutscene
    def add_action(action : CutsceneAction)
      actions << action
    end

    # Validate the cutscene
    def validate : Array(String)
      errors = [] of String

      # Validate ID format
      unless id.match(/^[a-zA-Z0-9_]+$/)
        errors << "Cutscene ID '#{id}' must contain only letters, numbers, and underscores"
      end

      if name.empty?
        errors << "Cutscene name cannot be empty"
      end

      if actions.empty?
        errors << "Cutscene must have at least one action"
      end

      # Validate actions
      actions.each_with_index do |action, index|
        errors.concat(action.validate.map { |e| "Action #{index + 1}: #{e}" })
      end

      # Validate effects
      on_complete.each do |effect|
        errors.concat(effect.validate.map { |e| "On complete effect: #{e}" })
      end

      on_skip.each do |effect|
        errors.concat(effect.validate.map { |e| "On skip effect: #{e}" })
      end

      errors
    end
  end

  # Base class for cutscene actions
  abstract class CutsceneAction
    include YAML::Serializable

    use_yaml_discriminator "type", {
      "wait"           => WaitAction,
      "fade_in"        => FadeAction,
      "fade_out"       => FadeAction,
      "show_text"      => ShowTextAction,
      "move_character" => MoveCharacterAction,
      "play_animation" => PlayAnimationAction,
      "play_sound"     => PlaySoundAction,
      "play_music"     => PlayMusicAction,
      "change_scene"   => ChangeSceneAction,
      "show_dialog"    => ShowDialogAction,
      "set_flag"       => SetFlagAction,
      "set_variable"   => SetVariableAction,
      "conditional"    => ConditionalAction,
      "parallel"       => ParallelAction,
    }

    property type : String

    def initialize(@type : String)
    end

    abstract def validate : Array(String)
  end

  # Wait action
  class WaitAction < CutsceneAction
    property duration : Float32

    def initialize(@duration : Float32)
      super("wait")
    end

    def validate : Array(String)
      errors = [] of String
      if duration <= 0
        errors << "Wait duration must be positive"
      end
      errors
    end
  end

  # Fade action (used for both fade_in and fade_out)
  class FadeAction < CutsceneAction
    property duration : Float32
    property color : String = "black"

    def initialize(@type : String, @duration : Float32)
      super(type)
    end

    def validate : Array(String)
      errors = [] of String
      if duration <= 0
        errors << "Fade duration must be positive"
      end
      unless ["fade_in", "fade_out"].includes?(type)
        errors << "Fade type must be 'fade_in' or 'fade_out'"
      end
      errors
    end
  end

  # Show text action
  class ShowTextAction < CutsceneAction
    property text : String
    property position : Position?
    property duration : Float32
    property style : TextStyle?

    def initialize(@text : String, @duration : Float32)
      super("show_text")
    end

    def validate : Array(String)
      errors = [] of String
      if text.empty?
        errors << "Text cannot be empty"
      end
      if duration <= 0
        errors << "Text duration must be positive"
      end
      errors
    end

    class Position
      include YAML::Serializable
      property x : Float32
      property y : Float32
    end

    class TextStyle
      include YAML::Serializable
      property font_size : Int32 = 24
      property color : String = "white"
      property align : String = "center"
    end
  end

  # Move character action
  class MoveCharacterAction < CutsceneAction
    property character : String
    property target : Position
    property duration : Float32

    def initialize(@character : String, @target : Position, @duration : Float32)
      super("move_character")
    end

    def validate : Array(String)
      errors = [] of String
      if character.empty?
        errors << "Character name cannot be empty"
      end
      if duration < 0
        errors << "Move duration cannot be negative"
      end
      errors
    end

    class Position
      include YAML::Serializable
      property x : Float32
      property y : Float32
    end
  end

  # Play animation action
  class PlayAnimationAction < CutsceneAction
    property character : String
    property animation : String

    def initialize(@character : String, @animation : String)
      super("play_animation")
    end

    def validate : Array(String)
      errors = [] of String
      if character.empty?
        errors << "Character name cannot be empty"
      end
      if animation.empty?
        errors << "Animation name cannot be empty"
      end
      errors
    end
  end

  # Play sound action
  class PlaySoundAction < CutsceneAction
    property sound : String
    property volume : Float32 = 1.0_f32

    def initialize(@sound : String)
      super("play_sound")
    end

    def validate : Array(String)
      errors = [] of String
      if sound.empty?
        errors << "Sound name cannot be empty"
      end
      if volume < 0 || volume > 1
        errors << "Volume must be between 0 and 1"
      end
      errors
    end
  end

  # Play music action
  class PlayMusicAction < CutsceneAction
    property music : String
    property loop : Bool = true

    def initialize(@music : String)
      super("play_music")
    end

    def validate : Array(String)
      errors = [] of String
      if music.empty?
        errors << "Music name cannot be empty"
      end
      errors
    end
  end

  # Change scene action
  class ChangeSceneAction < CutsceneAction
    property scene : String
    property transition : String?

    def initialize(@scene : String)
      super("change_scene")
    end

    def validate : Array(String)
      errors = [] of String
      if scene.empty?
        errors << "Scene name cannot be empty"
      end
      if transition
        valid_transitions = ["fade", "iris", "slide_left", "slide_right", "slide_up", "slide_down"]
        unless valid_transitions.includes?(transition)
          errors << "Invalid transition type: #{transition}"
        end
      end
      errors
    end
  end

  # Show dialog action
  class ShowDialogAction < CutsceneAction
    property speaker : String
    property text : String

    def initialize(@speaker : String, @text : String)
      super("show_dialog")
    end

    def validate : Array(String)
      errors = [] of String
      if speaker.empty?
        errors << "Speaker cannot be empty"
      end
      if text.empty?
        errors << "Dialog text cannot be empty"
      end
      errors
    end
  end

  # Set flag action
  class SetFlagAction < CutsceneAction
    property name : String
    property value : Bool = true

    def initialize(@name : String)
      super("set_flag")
    end

    def validate : Array(String)
      errors = [] of String
      if name.empty?
        errors << "Flag name cannot be empty"
      end
      errors
    end
  end

  # Set variable action
  class SetVariableAction < CutsceneAction
    property name : String
    property value : YAML::Any

    def initialize(@name : String, @value : YAML::Any)
      super("set_variable")
    end

    def validate : Array(String)
      errors = [] of String
      if name.empty?
        errors << "Variable name cannot be empty"
      end
      errors
    end
  end

  # Conditional action
  class ConditionalAction < CutsceneAction
    property conditions : Condition
    property if_true : Array(CutsceneAction) = [] of CutsceneAction
    property if_false : Array(CutsceneAction) = [] of CutsceneAction

    def initialize(@conditions : Condition)
      super("conditional")
    end

    def validate : Array(String)
      errors = [] of String

      errors.concat(conditions.validate.map { |e| "Condition: #{e}" })

      if if_true.empty? && if_false.empty?
        errors << "Conditional must have at least one action in if_true or if_false"
      end

      if_true.each_with_index do |action, index|
        errors.concat(action.validate.map { |e| "If true action #{index + 1}: #{e}" })
      end

      if_false.each_with_index do |action, index|
        errors.concat(action.validate.map { |e| "If false action #{index + 1}: #{e}" })
      end

      errors
    end
  end

  # Parallel action
  class ParallelAction < CutsceneAction
    property actions : Array(CutsceneAction) = [] of CutsceneAction

    def initialize
      super("parallel")
    end

    def validate : Array(String)
      errors = [] of String

      if actions.empty?
        errors << "Parallel action must have at least one sub-action"
      end

      actions.each_with_index do |action, index|
        errors.concat(action.validate.map { |e| "Parallel action #{index + 1}: #{e}" })
      end

      errors
    end
  end
end
