require "yaml"
require "./condition"
require "./effect"

module PaceEditor::Models
  # Represents a quest definition
  class Quest
    include YAML::Serializable

    property id : String
    property name : String
    property description : String
    property category : String # "main" | "side" | "hidden"
    property icon : String?
    property auto_start : Bool = false
    property start_conditions : Condition?
    property prerequisites : Array(String) = [] of String
    property requirements : Condition?
    property objectives : Array(QuestObjective) = [] of QuestObjective
    property rewards : Array(Reward) = [] of Reward
    property can_fail : Bool = false
    property fail_conditions : Condition?
    property journal_entries : Array(JournalEntry) = [] of JournalEntry

    def initialize(@id : String, @name : String, @description : String, @category : String)
    end

    # Validate the quest
    def validate : Array(String)
      errors = [] of String

      # Validate ID format
      unless id.match(/^[a-zA-Z0-9_]+$/)
        errors << "Quest ID '#{id}' must contain only letters, numbers, and underscores"
      end

      # Validate category
      valid_categories = ["main", "side", "hidden"]
      unless valid_categories.includes?(category)
        errors << "Quest category must be one of: #{valid_categories.join(", ")}"
      end

      # Validate objectives
      if objectives.empty?
        errors << "Quest must have at least one objective"
      end

      objective_ids = [] of String
      objectives.each do |objective|
        if objective_ids.includes?(objective.id)
          errors << "Duplicate objective ID: #{objective.id}"
        else
          objective_ids << objective.id
        end
        errors.concat(objective.validate.map { |e| "Objective #{objective.id}: #{e}" })
      end

      # Validate rewards
      rewards.each do |reward|
        errors.concat(reward.validate.map { |e| "Reward: #{e}" })
      end

      errors
    end
  end

  # Quest objective
  class QuestObjective
    include YAML::Serializable

    property id : String
    property description : String
    property optional : Bool = false
    property hidden : Bool = false
    property completion_conditions : Condition?
    property rewards : Array(Reward) = [] of Reward

    def initialize(@id : String, @description : String)
    end

    def validate : Array(String)
      errors = [] of String

      unless id.match(/^[a-zA-Z0-9_]+$/)
        errors << "Objective ID must contain only letters, numbers, and underscores"
      end

      if description.empty?
        errors << "Objective description cannot be empty"
      end

      rewards.each do |reward|
        errors.concat(reward.validate)
      end

      errors
    end
  end

  # Quest reward
  class Reward
    include YAML::Serializable

    property type : String # "item" | "flag" | "variable" | "achievement"
    property name : String
    property value : YAML::Any?
    property quantity : Int32?

    def initialize(@type : String, @name : String)
    end

    def validate : Array(String)
      errors = [] of String

      valid_types = ["item", "flag", "variable", "achievement"]
      unless valid_types.includes?(type)
        errors << "Reward type must be one of: #{valid_types.join(", ")}"
      end

      if name.empty?
        errors << "Reward name cannot be empty"
      end

      if type == "item" && quantity && quantity.not_nil! < 1
        errors << "Item quantity must be at least 1"
      end

      errors
    end
  end

  # Journal entry for quest
  class JournalEntry
    include YAML::Serializable

    property id : String
    property text : String
    property conditions : Condition?

    def initialize(@id : String, @text : String)
    end
  end

  # Container for multiple quests (quests.yaml)
  class QuestFile
    include YAML::Serializable

    property quests : Array(Quest) = [] of Quest

    def initialize
    end

    def validate : Array(String)
      errors = [] of String
      quest_ids = [] of String

      quests.each do |quest|
        if quest_ids.includes?(quest.id)
          errors << "Duplicate quest ID: #{quest.id}"
        else
          quest_ids << quest.id
        end

        errors.concat(quest.validate.map { |e| "Quest #{quest.id}: #{e}" })
      end

      errors
    end
  end
end
