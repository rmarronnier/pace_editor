require "yaml"

module PaceEditor::Models
  # Represents a condition that can be evaluated in the game
  class Condition
    include YAML::Serializable

    # Simple conditions
    property flag : String?
    property has_item : String?
    property variable : String?
    property value : YAML::Any?
    property operator : String? # "==" | "!=" | ">" | "<" | ">=" | "<="

    # Complex conditions
    property all_of : Array(Condition)?
    property any_of : Array(Condition)?
    property none_of : Array(Condition)?

    def initialize
    end

    # Create a flag condition
    def self.flag(name : String, value : Bool = true) : Condition
      condition = Condition.new
      condition.flag = name
      condition.value = YAML::Any.new(value)
      condition
    end

    # Create an item condition
    def self.has_item(item_name : String) : Condition
      condition = Condition.new
      condition.has_item = item_name
      condition
    end

    # Create a variable condition
    def self.variable(name : String, operator : String, value : YAML::Any) : Condition
      condition = Condition.new
      condition.variable = name
      condition.operator = operator
      condition.value = value
      condition
    end

    # Create an all_of condition
    def self.all_of(conditions : Array(Condition)) : Condition
      condition = Condition.new
      condition.all_of = conditions
      condition
    end

    # Create an any_of condition
    def self.any_of(conditions : Array(Condition)) : Condition
      condition = Condition.new
      condition.any_of = conditions
      condition
    end

    # Create a none_of condition
    def self.none_of(conditions : Array(Condition)) : Condition
      condition = Condition.new
      condition.none_of = conditions
      condition
    end

    # Validate the condition
    def validate : Array(String)
      errors = [] of String

      # Count how many condition types are set
      condition_count = 0
      condition_count += 1 if flag
      condition_count += 1 if has_item
      condition_count += 1 if variable
      condition_count += 1 if all_of
      condition_count += 1 if any_of
      condition_count += 1 if none_of

      if condition_count == 0
        errors << "Condition must have at least one condition type set"
      elsif condition_count > 1
        errors << "Condition can only have one condition type set"
      end

      # Validate operator if variable condition
      if variable && operator
        valid_operators = ["==", "!=", ">", "<", ">=", "<="]
        unless valid_operators.includes?(operator)
          errors << "Invalid operator: #{operator}. Must be one of: #{valid_operators.join(", ")}"
        end
      elsif variable
        errors << "Variable condition must have an operator"
      end

      # Validate nested conditions
      [all_of, any_of, none_of].each do |condition_list|
        if condition_list
          if condition_list.empty?
            errors << "Condition list cannot be empty"
          else
            condition_list.each do |nested_condition|
              errors.concat(nested_condition.validate.map { |e| "Nested condition: #{e}" })
            end
          end
        end
      end

      errors
    end

    # Check if this is a simple condition
    def simple? : Bool
      !!(flag || has_item || variable)
    end

    # Check if this is a complex condition
    def complex? : Bool
      !!(all_of || any_of || none_of)
    end

    # Get a human-readable description
    def to_description : String
      if flag
        "Flag '#{flag}' is #{value == YAML::Any.new(true) ? "set" : "not set"}"
      elsif has_item
        "Has item '#{has_item}'"
      elsif variable && operator && value
        "Variable '#{variable}' #{operator} #{value}"
      elsif all_of
        "All of: [#{all_of.not_nil!.map(&.to_description).join(", ")}]"
      elsif any_of
        "Any of: [#{any_of.not_nil!.map(&.to_description).join(", ")}]"
      elsif none_of
        "None of: [#{none_of.not_nil!.map(&.to_description).join(", ")}]"
      else
        "Invalid condition"
      end
    end
  end
end
