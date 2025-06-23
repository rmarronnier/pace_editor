require "../spec_helper"
require "../../src/pace_editor/models/item"

describe PaceEditor::Models::Item do
  describe "#initialize" do
    it "creates an item with default values" do
      item = PaceEditor::Models::Item.new("golden_key", "Golden Key", 
                                          "A shiny golden key", "assets/items/golden_key.png")
      
      item.name.should eq "golden_key"
      item.display_name.should eq "Golden Key"
      item.description.should eq "A shiny golden key"
      item.icon_path.should eq "assets/items/golden_key.png"
      item.consumable.should be_false
      item.stackable.should be_false
      item.quest_item.should be_false
      item.readable.should be_false
      item.equippable.should be_false
    end
  end

  describe "#validate" do
    it "validates item name format" do
      item = PaceEditor::Models::Item.new("invalid-name!", "Item", "Desc", "icon.png")
      errors = item.validate
      
      errors.should contain "Item name 'invalid-name!' must contain only letters, numbers, and underscores"
    end

    it "validates required fields not empty" do
      item = PaceEditor::Models::Item.new("item", "", "", "")
      errors = item.validate
      
      errors.should contain "Display name cannot be empty"
      errors.should contain "Description cannot be empty"
      errors.should contain "Icon path cannot be empty"
    end

    it "validates stackable properties" do
      item = PaceEditor::Models::Item.new("coins", "Gold Coins", "Currency", "coin.png")
      item.stackable = true
      item.max_stack = 1
      
      errors = item.validate
      errors.should contain "Max stack must be at least 2 for stackable items"
      
      item.max_stack = 99
      item.validate.should be_empty
    end

    it "validates non-stackable items shouldn't have max_stack" do
      item = PaceEditor::Models::Item.new("sword", "Sword", "A sharp blade", "sword.png")
      item.stackable = false
      item.max_stack = 10
      
      errors = item.validate
      errors.should contain "Max stack should not be set for non-stackable items"
    end

    it "validates item states" do
      item = PaceEditor::Models::Item.new("torch", "Torch", "Provides light", "torch.png")
      
      state1 = PaceEditor::Models::ItemState.new("lit", "The torch is burning")
      state2 = PaceEditor::Models::ItemState.new("lit", "Duplicate state")
      
      item.states << state1
      item.states << state2
      
      errors = item.validate
      errors.should contain "Duplicate state name: lit"
    end

    it "validates use effects" do
      item = PaceEditor::Models::Item.new("potion", "Health Potion", "Restores health", "potion.png")
      
      effect = PaceEditor::Models::Effect.new("invalid_effect", "test")
      item.use_effects << effect
      
      errors = item.validate
      errors.any? { |e| e.includes?("Use effect:") }.should be_true
    end

    it "validates combine effects" do
      item = PaceEditor::Models::Item.new("key", "Key", "A key", "key.png")
      
      effect = PaceEditor::Models::Effect.new("unlock", "door")
      item.combine_effects["lock"] = [effect]
      
      errors = item.validate
      errors.any? { |e| e.includes?("Combine effect for lock:") }.should be_true
    end
  end
end

describe PaceEditor::Models::ItemFile do
  describe "#add_item" do
    it "adds items to the collection" do
      file = PaceEditor::Models::ItemFile.new
      
      item1 = PaceEditor::Models::Item.new("sword", "Sword", "A weapon", "sword.png")
      item2 = PaceEditor::Models::Item.new("shield", "Shield", "Protection", "shield.png")
      
      file.add_item(item1)
      file.add_item(item2)
      
      file.items.size.should eq 2
      file.items["sword"].should eq item1
      file.items["shield"].should eq item2
    end
  end

  describe "#validate" do
    it "validates item ID matches name" do
      file = PaceEditor::Models::ItemFile.new
      
      item = PaceEditor::Models::Item.new("sword", "Sword", "A weapon", "sword.png")
      file.items["wrong_id"] = item
      
      errors = file.validate
      errors.should contain "Item ID 'wrong_id' doesn't match item name 'sword'"
    end

    it "validates combinable_with references" do
      file = PaceEditor::Models::ItemFile.new
      
      item1 = PaceEditor::Models::Item.new("key", "Key", "A key", "key.png")
      item1.combinable_with << "lock"
      item1.combinable_with << "nonexistent_item"
      
      file.add_item(item1)
      
      errors = file.validate
      errors.should contain "Item key: References unknown item 'nonexistent_item' in combinable_with"
    end

    it "validates all items" do
      file = PaceEditor::Models::ItemFile.new
      
      item = PaceEditor::Models::Item.new("invalid!", "Item", "Desc", "icon.png")
      file.add_item(item)
      
      errors = file.validate
      errors.any? { |e| e.includes?("Item invalid!:") }.should be_true
    end
  end

  describe "YAML serialization" do
    it "serializes to YAML" do
      file = PaceEditor::Models::ItemFile.new
      
      item = PaceEditor::Models::Item.new("health_potion", "Health Potion", 
                                          "Restores 50 HP", "assets/items/health_potion.png")
      item.consumable = true
      item.stackable = true
      item.max_stack = 10
      item.use_effects << PaceEditor::Models::Effect.set_variable("player_health", YAML::Any.new(50))
      
      file.add_item(item)
      
      yaml = file.to_yaml
      yaml.should contain "items:"
      yaml.should contain "health_potion:"
      yaml.should contain "name: health_potion"
      yaml.should contain "display_name: Health Potion"
      yaml.should contain "consumable: true"
      yaml.should contain "stackable: true"
      yaml.should contain "max_stack: 10"
      yaml.should contain "use_effects:"
    end

    it "deserializes from YAML" do
      yaml = <<-YAML
      items:
        magic_sword:
          name: magic_sword
          display_name: "Magic Sword"
          description: "A sword imbued with magical power"
          icon_path: "assets/items/magic_sword.png"
          usable_on:
            - enemy_weak
            - enemy_strong
          combinable_with:
            - whetstone
          consumable: false
          stackable: false
          quest_item: true
          equippable: true
          states:
            - name: enchanted
              description: "The sword glows with power"
              icon_path: "assets/items/magic_sword_glow.png"
          use_effects:
            - type: set_variable
              name: damage_bonus
              value: 10
          combine_effects:
            whetstone:
              - type: set_flag
                name: sword_sharpened
                value: true
        whetstone:
          name: whetstone
          display_name: "Whetstone"
          description: "Used to sharpen blades"
          icon_path: "assets/items/whetstone.png"
          combinable_with:
            - magic_sword
          consumable: true
      YAML
      
      file = PaceEditor::Models::ItemFile.from_yaml(yaml)
      
      file.items.size.should eq 2
      
      sword = file.items["magic_sword"]
      sword.name.should eq "magic_sword"
      sword.display_name.should eq "Magic Sword"
      sword.usable_on.should eq ["enemy_weak", "enemy_strong"]
      sword.combinable_with.should eq ["whetstone"]
      sword.quest_item.should be_true
      sword.equippable.should be_true
      
      sword.states.size.should eq 1
      sword.states[0].name.should eq "enchanted"
      
      sword.use_effects.size.should eq 1
      sword.use_effects[0].type.should eq "set_variable"
      
      sword.combine_effects["whetstone"].size.should eq 1
      
      whetstone = file.items["whetstone"]
      whetstone.consumable.should be_true
    end
  end
end