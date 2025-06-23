require "../spec_helper"
require "../../src/pace_editor/models/effect"

describe PaceEditor::Models::Effect do
  describe "factory methods" do
    it "creates a set_flag effect" do
      effect = PaceEditor::Models::Effect.set_flag("door_opened", true)

      effect.type.should eq "set_flag"
      effect.name.should eq "door_opened"
      effect.value.should eq YAML::Any.new(true)
    end

    it "creates a set_variable effect" do
      effect = PaceEditor::Models::Effect.set_variable("player_gold", YAML::Any.new(100))

      effect.type.should eq "set_variable"
      effect.name.should eq "player_gold"
      effect.value.should eq YAML::Any.new(100)
    end

    it "creates an add_item effect" do
      effect = PaceEditor::Models::Effect.add_item("healing_potion")

      effect.type.should eq "add_item"
      effect.name.should eq "healing_potion"
      effect.value.should be_nil
    end

    it "creates a remove_item effect" do
      effect = PaceEditor::Models::Effect.remove_item("old_key")

      effect.type.should eq "remove_item"
      effect.name.should eq "old_key"
    end

    it "creates a start_quest effect" do
      effect = PaceEditor::Models::Effect.start_quest("main_quest")

      effect.type.should eq "start_quest"
      effect.name.should eq "main_quest"
    end

    it "creates a complete_objective effect" do
      effect = PaceEditor::Models::Effect.complete_objective("quest_1", "obj_1")

      effect.type.should eq "complete_objective"
      effect.name.should eq "quest_1"
      effect.value.should eq YAML::Any.new("obj_1")
    end

    it "creates an unlock_achievement effect" do
      effect = PaceEditor::Models::Effect.unlock_achievement("first_victory")

      effect.type.should eq "unlock_achievement"
      effect.name.should eq "first_victory"
    end
  end

  describe "#validate" do
    it "validates effect type" do
      effect = PaceEditor::Models::Effect.new("invalid_type", "test")
      errors = effect.validate

      errors.should contain "Effect type must be one of: set_flag, set_variable, add_item, remove_item, start_quest, complete_objective, unlock_achievement"
    end

    it "validates effect name" do
      effect = PaceEditor::Models::Effect.new("set_flag", "")
      errors = effect.validate

      errors.should contain "Effect name cannot be empty"
    end

    it "validates set_flag requires value" do
      effect = PaceEditor::Models::Effect.new("set_flag", "test_flag")
      errors = effect.validate

      errors.should contain "set_flag effect must have a boolean value"

      effect.value = YAML::Any.new(true)
      effect.validate.should be_empty
    end

    it "validates set_variable requires value" do
      effect = PaceEditor::Models::Effect.new("set_variable", "test_var")
      errors = effect.validate

      errors.should contain "set_variable effect must have a value"

      effect.value = YAML::Any.new(42)
      effect.validate.should be_empty
    end

    it "validates complete_objective requires value" do
      effect = PaceEditor::Models::Effect.new("complete_objective", "quest_id")
      errors = effect.validate

      errors.should contain "complete_objective effect must have objective_id as value"

      effect.value = YAML::Any.new("objective_1")
      effect.validate.should be_empty
    end
  end

  describe "#to_description" do
    it "describes set_flag effects" do
      effect = PaceEditor::Models::Effect.set_flag("door_unlocked", true)
      effect.to_description.should eq "Set flag 'door_unlocked' to true"
    end

    it "describes set_variable effects" do
      effect = PaceEditor::Models::Effect.set_variable("gold", YAML::Any.new(500))
      effect.to_description.should eq "Set variable 'gold' to 500"
    end

    it "describes add_item effects" do
      effect = PaceEditor::Models::Effect.add_item("magic_sword")
      effect.to_description.should eq "Add item 'magic_sword'"
    end

    it "describes remove_item effects" do
      effect = PaceEditor::Models::Effect.remove_item("broken_sword")
      effect.to_description.should eq "Remove item 'broken_sword'"
    end

    it "describes start_quest effects" do
      effect = PaceEditor::Models::Effect.start_quest("side_quest_1")
      effect.to_description.should eq "Start quest 'side_quest_1'"
    end

    it "describes complete_objective effects" do
      effect = PaceEditor::Models::Effect.complete_objective("main_quest", "find_artifact")
      effect.to_description.should eq "Complete objective 'find_artifact' in quest 'main_quest'"
    end

    it "describes unlock_achievement effects" do
      effect = PaceEditor::Models::Effect.unlock_achievement("speedrun")
      effect.to_description.should eq "Unlock achievement 'speedrun'"
    end

    it "describes unknown effects" do
      effect = PaceEditor::Models::Effect.new("unknown", "test")
      effect.to_description.should eq "Unknown effect: unknown"
    end
  end

  describe "YAML serialization" do
    it "serializes effects" do
      effect = PaceEditor::Models::Effect.set_variable("player_level", YAML::Any.new(5))
      yaml = effect.to_yaml

      yaml.should contain "type: set_variable"
      yaml.should contain "name: player_level"
      yaml.should contain "value: 5"
    end

    it "deserializes from YAML" do
      yaml = <<-YAML
      type: add_item
      name: treasure_map
      YAML

      effect = PaceEditor::Models::Effect.from_yaml(yaml)

      effect.type.should eq "add_item"
      effect.name.should eq "treasure_map"
      effect.value.should be_nil
    end

    it "deserializes effects with values" do
      yaml = <<-YAML
      type: complete_objective
      name: main_quest
      value: defeat_boss
      YAML

      effect = PaceEditor::Models::Effect.from_yaml(yaml)

      effect.type.should eq "complete_objective"
      effect.name.should eq "main_quest"
      effect.value.should eq YAML::Any.new("defeat_boss")
    end
  end
end
