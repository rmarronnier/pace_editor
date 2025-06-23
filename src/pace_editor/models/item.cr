require "yaml"
require "./effect"

module PaceEditor::Models
  # Represents an inventory item definition
  class Item
    include YAML::Serializable

    property name : String
    property display_name : String
    property description : String
    property icon_path : String
    property usable_on : Array(String) = [] of String
    property combinable_with : Array(String) = [] of String
    property consumable : Bool = false
    property stackable : Bool = false
    property max_stack : Int32?
    property quest_item : Bool = false
    property readable : Bool = false
    property equippable : Bool = false
    property states : Array(ItemState) = [] of ItemState
    property use_effects : Array(Effect) = [] of Effect
    property combine_effects : Hash(String, Array(Effect)) = {} of String => Array(Effect)

    def initialize(@name : String, @display_name : String, @description : String, @icon_path : String)
    end

    # Validate the item
    def validate : Array(String)
      errors = [] of String

      # Validate name format
      unless name.match(/^[a-zA-Z0-9_]+$/)
        errors << "Item name '#{name}' must contain only letters, numbers, and underscores"
      end

      if display_name.empty?
        errors << "Display name cannot be empty"
      end

      if description.empty?
        errors << "Description cannot be empty"
      end

      if icon_path.empty?
        errors << "Icon path cannot be empty"
      end

      # Validate stackable properties
      if stackable && max_stack && max_stack.not_nil! < 2
        errors << "Max stack must be at least 2 for stackable items"
      elsif !stackable && max_stack
        errors << "Max stack should not be set for non-stackable items"
      end

      # Validate states
      state_names = [] of String
      states.each do |state|
        if state_names.includes?(state.name)
          errors << "Duplicate state name: #{state.name}"
        else
          state_names << state.name
        end
      end

      # Validate effects
      use_effects.each do |effect|
        errors.concat(effect.validate.map { |e| "Use effect: #{e}" })
      end

      combine_effects.each do |target_item, effects|
        effects.each do |effect|
          errors.concat(effect.validate.map { |e| "Combine effect for #{target_item}: #{e}" })
        end
      end

      errors
    end
  end

  # Item state definition
  class ItemState
    include YAML::Serializable

    property name : String
    property description : String
    property icon_path : String?

    def initialize(@name : String, @description : String)
    end
  end

  # Container for items (items.yaml)
  class ItemFile
    include YAML::Serializable

    property items : Hash(String, Item) = {} of String => Item

    def initialize
    end

    def add_item(item : Item)
      items[item.name] = item
    end

    def validate : Array(String)
      errors = [] of String

      items.each do |item_id, item|
        if item_id != item.name
          errors << "Item ID '#{item_id}' doesn't match item name '#{item.name}'"
        end

        errors.concat(item.validate.map { |e| "Item #{item_id}: #{e}" })

        # Validate references to other items
        item.combinable_with.each do |other_item|
          unless items.has_key?(other_item)
            errors << "Item #{item_id}: References unknown item '#{other_item}' in combinable_with"
          end
        end
      end

      errors
    end
  end
end
