require "yaml"

module PaceEditor::Models
  # Represents an effect that can be triggered in the game
  class Effect
    include YAML::Serializable

    property type : String # "set_flag" | "set_variable" | "add_item" | "remove_item" | "start_quest" | "complete_objective" | "unlock_achievement"
    property name : String
    property value : YAML::Any?

    def initialize(@type : String, @name : String)
    end

    # Factory methods for common effects
    def self.set_flag(name : String, value : Bool = true) : Effect
      effect = Effect.new("set_flag", name)
      effect.value = YAML::Any.new(value)
      effect
    end

    def self.set_variable(name : String, value : YAML::Any) : Effect
      effect = Effect.new("set_variable", name)
      effect.value = value
      effect
    end

    def self.add_item(item_name : String) : Effect
      Effect.new("add_item", item_name)
    end

    def self.remove_item(item_name : String) : Effect
      Effect.new("remove_item", item_name)
    end

    def self.start_quest(quest_id : String) : Effect
      Effect.new("start_quest", quest_id)
    end

    def self.complete_objective(quest_id : String, objective_id : String) : Effect
      effect = Effect.new("complete_objective", quest_id)
      effect.value = YAML::Any.new(objective_id)
      effect
    end

    def self.unlock_achievement(achievement_id : String) : Effect
      Effect.new("unlock_achievement", achievement_id)
    end

    # Validate the effect
    def validate : Array(String)
      errors = [] of String

      valid_types = ["set_flag", "set_variable", "add_item", "remove_item",
                     "start_quest", "complete_objective", "unlock_achievement"]
      unless valid_types.includes?(type)
        errors << "Effect type must be one of: #{valid_types.join(", ")}"
      end

      if name.empty?
        errors << "Effect name cannot be empty"
      end

      # Type-specific validation
      case type
      when "set_flag"
        unless value
          errors << "set_flag effect must have a boolean value"
        end
      when "set_variable"
        unless value
          errors << "set_variable effect must have a value"
        end
      when "complete_objective"
        unless value
          errors << "complete_objective effect must have objective_id as value"
        end
      end

      errors
    end

    # Get a human-readable description
    def to_description : String
      case type
      when "set_flag"
        "Set flag '#{name}' to #{value}"
      when "set_variable"
        "Set variable '#{name}' to #{value}"
      when "add_item"
        "Add item '#{name}'"
      when "remove_item"
        "Remove item '#{name}'"
      when "start_quest"
        "Start quest '#{name}'"
      when "complete_objective"
        "Complete objective '#{value}' in quest '#{name}'"
      when "unlock_achievement"
        "Unlock achievement '#{name}'"
      else
        "Unknown effect: #{type}"
      end
    end
  end
end
