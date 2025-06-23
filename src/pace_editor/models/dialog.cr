require "yaml"
require "./condition"
require "./effect"

module PaceEditor::Models
  # Represents a dialog tree
  class DialogTree
    include YAML::Serializable

    property id : String
    property nodes : Array(DialogNode) = [] of DialogNode
    property start_node : String
    property on_end : Array(Effect) = [] of Effect

    def initialize(@id : String, @start_node : String)
    end

    # Add a dialog node
    def add_node(node : DialogNode)
      nodes << node
    end

    # Find a node by ID
    def find_node(node_id : String) : DialogNode?
      nodes.find { |n| n.id == node_id }
    end

    # Validate the dialog tree
    def validate : Array(String)
      errors = [] of String

      # Validate ID format
      unless id.match(/^[a-zA-Z0-9_]+$/)
        errors << "Dialog ID '#{id}' must contain only letters, numbers, and underscores"
      end

      # Check start node exists
      unless find_node(start_node)
        errors << "Start node '#{start_node}' not found"
      end

      # Validate nodes
      node_ids = [] of String
      nodes.each do |node|
        if node_ids.includes?(node.id)
          errors << "Duplicate node ID: #{node.id}"
        else
          node_ids << node.id
        end

        errors.concat(node.validate(self).map { |e| "Node #{node.id}: #{e}" })
      end

      # Check for circular references
      errors.concat(check_circular_references)

      # Validate effects
      on_end.each do |effect|
        errors.concat(effect.validate.map { |e| "On end effect: #{e}" })
      end

      errors
    end

    # Check for circular references in dialog flow
    private def check_circular_references : Array(String)
      errors = [] of String

      nodes.each do |node|
        visited = Set(String).new
        if has_circular_reference(node.id, visited)
          errors << "Circular reference detected starting from node '#{node.id}'"
        end
      end

      errors
    end

    private def has_circular_reference(node_id : String, visited : Set(String)) : Bool
      return true if visited.includes?(node_id)
      visited.add(node_id)

      node = find_node(node_id)
      return false unless node

      # Check next node
      next_node = node.@next
      if next_node && has_circular_reference(next_node, visited.dup)
        return true
      end

      # Check choices
      node.choices.each do |choice|
        choice_next = choice.@next
        if choice_next && has_circular_reference(choice_next, visited.dup)
          return true
        end
      end

      false
    end
  end

  # Represents a dialog node
  class DialogNode
    include YAML::Serializable

    property id : String
    property speaker : String
    property text : String
    property portrait : String?
    property choices : Array(DialogChoice) = [] of DialogChoice
    property next : String?
    property conditions : Condition?
    property effects : Array(Effect) = [] of Effect

    def initialize(@id : String, @speaker : String, @text : String)
    end

    # Add a choice
    def add_choice(choice : DialogChoice)
      choices << choice
    end

    # Validate the node
    def validate(tree : DialogTree) : Array(String)
      errors = [] of String

      if speaker.empty?
        errors << "Speaker cannot be empty"
      end

      if text.empty?
        errors << "Text cannot be empty"
      end

      # Can't have both choices and next
      if !choices.empty? && @next
        errors << "Node cannot have both choices and next"
      end

      # Must have either choices or next (unless it's an end node)
      if choices.empty? && @next.nil? && tree.on_end.empty?
        errors << "Node must have either choices or next (or be handled by on_end)"
      end

      # Validate next reference
      if @next && !tree.find_node(@next.not_nil!)
        errors << "Next node '#{@next}' not found"
      end

      # Validate choices
      choices.each_with_index do |choice, index|
        errors.concat(choice.validate(tree).map { |e| "Choice #{index + 1}: #{e}" })
      end

      # Validate conditions
      if conditions
        errors.concat(conditions.not_nil!.validate.map { |e| "Condition: #{e}" })
      end

      # Validate effects
      effects.each do |effect|
        errors.concat(effect.validate.map { |e| "Effect: #{e}" })
      end

      errors
    end
  end

  # Represents a dialog choice
  class DialogChoice
    include YAML::Serializable

    property text : String
    property next : String?
    property conditions : Condition?
    property effects : Array(Effect) = [] of Effect

    def initialize(@text : String)
    end

    # Validate the choice
    def validate(tree : DialogTree) : Array(String)
      errors = [] of String

      if text.empty?
        errors << "Choice text cannot be empty"
      end

      # Validate next reference
      if @next && !tree.find_node(@next.not_nil!)
        errors << "Next node '#{@next}' not found"
      end

      # Validate conditions
      if conditions
        errors.concat(conditions.not_nil!.validate.map { |e| "Condition: #{e}" })
      end

      # Validate effects
      effects.each do |effect|
        errors.concat(effect.validate.map { |e| "Effect: #{e}" })
      end

      errors
    end
  end
end
