require "../spec_helper"
require "../../src/pace_editor/models/quest"

describe PaceEditor::Models::Quest do
  describe "#initialize" do
    it "creates a quest with basic properties" do
      quest = PaceEditor::Models::Quest.new("find_artifact", "Find the Ancient Artifact", 
                                           "Locate the legendary artifact hidden in the ruins.", "main")
      
      quest.id.should eq "find_artifact"
      quest.name.should eq "Find the Ancient Artifact"
      quest.description.should eq "Locate the legendary artifact hidden in the ruins."
      quest.category.should eq "main"
      quest.auto_start.should be_false
      quest.can_fail.should be_false
      quest.objectives.should be_empty
      quest.rewards.should be_empty
    end
  end

  describe "#validate" do
    it "validates quest ID format" do
      quest = PaceEditor::Models::Quest.new("invalid-id!", "Test Quest", "Description", "main")
      errors = quest.validate
      
      errors.should contain "Quest ID 'invalid-id!' must contain only letters, numbers, and underscores"
      
      quest.id = "valid_id_123"
      quest.validate.should_not contain "Quest ID"
    end

    it "validates quest category" do
      quest = PaceEditor::Models::Quest.new("quest1", "Test Quest", "Description", "invalid")
      errors = quest.validate
      
      errors.should contain "Quest category must be one of: main, side, hidden"
      
      quest.category = "side"
      # Add an objective to make the quest valid
      objective = PaceEditor::Models::QuestObjective.new("obj1", "Complete the task")
      quest.objectives << objective
      quest.validate.should be_empty
    end

    it "validates quest must have objectives" do
      quest = PaceEditor::Models::Quest.new("quest1", "Test Quest", "Description", "main")
      errors = quest.validate
      
      errors.should contain "Quest must have at least one objective"
      
      objective = PaceEditor::Models::QuestObjective.new("obj1", "Complete the task")
      quest.objectives << objective
      quest.validate.should be_empty
    end

    it "validates duplicate objective IDs" do
      quest = PaceEditor::Models::Quest.new("quest1", "Test Quest", "Description", "main")
      
      obj1 = PaceEditor::Models::QuestObjective.new("obj1", "First task")
      obj2 = PaceEditor::Models::QuestObjective.new("obj1", "Second task")
      
      quest.objectives << obj1
      quest.objectives << obj2
      
      errors = quest.validate
      errors.should contain "Duplicate objective ID: obj1"
    end

    it "validates objectives" do
      quest = PaceEditor::Models::Quest.new("quest1", "Test Quest", "Description", "main")
      
      objective = PaceEditor::Models::QuestObjective.new("", "Complete the task")
      quest.objectives << objective
      
      errors = quest.validate
      errors.any? { |e| e.includes?("Objective :") }.should be_true
    end

    it "validates rewards" do
      quest = PaceEditor::Models::Quest.new("quest1", "Test Quest", "Description", "main")
      objective = PaceEditor::Models::QuestObjective.new("obj1", "Complete the task")
      quest.objectives << objective
      
      reward = PaceEditor::Models::Reward.new("invalid_type", "test")
      quest.rewards << reward
      
      errors = quest.validate
      errors.any? { |e| e.includes?("Reward:") }.should be_true
    end
  end
end

describe PaceEditor::Models::QuestObjective do
  describe "#initialize" do
    it "creates an objective with defaults" do
      objective = PaceEditor::Models::QuestObjective.new("find_key", "Find the golden key")
      
      objective.id.should eq "find_key"
      objective.description.should eq "Find the golden key"
      objective.optional.should be_false
      objective.hidden.should be_false
      objective.rewards.should be_empty
    end
  end

  describe "#validate" do
    it "validates objective ID format" do
      objective = PaceEditor::Models::QuestObjective.new("invalid id!", "Description")
      errors = objective.validate
      
      errors.should contain "Objective ID must contain only letters, numbers, and underscores"
    end

    it "validates description not empty" do
      objective = PaceEditor::Models::QuestObjective.new("obj1", "")
      errors = objective.validate
      
      errors.should contain "Objective description cannot be empty"
    end

    it "validates rewards" do
      objective = PaceEditor::Models::QuestObjective.new("obj1", "Test objective")
      
      reward = PaceEditor::Models::Reward.new("item", "")
      objective.rewards << reward
      
      errors = objective.validate
      errors.should_not be_empty
    end
  end
end

describe PaceEditor::Models::Reward do
  describe "#initialize" do
    it "creates a reward" do
      reward = PaceEditor::Models::Reward.new("item", "gold_coin")
      
      reward.type.should eq "item"
      reward.name.should eq "gold_coin"
      reward.value.should be_nil
      reward.quantity.should be_nil
    end
  end

  describe "#validate" do
    it "validates reward type" do
      reward = PaceEditor::Models::Reward.new("invalid", "test")
      errors = reward.validate
      
      errors.should contain "Reward type must be one of: item, flag, variable, achievement"
    end

    it "validates reward name" do
      reward = PaceEditor::Models::Reward.new("item", "")
      errors = reward.validate
      
      errors.should contain "Reward name cannot be empty"
    end

    it "validates item quantity" do
      reward = PaceEditor::Models::Reward.new("item", "gold")
      reward.quantity = 0
      
      errors = reward.validate
      errors.should contain "Item quantity must be at least 1"
      
      reward.quantity = 5
      reward.validate.should be_empty
    end
  end
end

describe PaceEditor::Models::QuestFile do
  describe "#validate" do
    it "validates duplicate quest IDs" do
      file = PaceEditor::Models::QuestFile.new
      
      quest1 = PaceEditor::Models::Quest.new("quest1", "First Quest", "Description", "main")
      quest2 = PaceEditor::Models::Quest.new("quest1", "Second Quest", "Description", "side")
      
      # Add objectives to make quests valid
      quest1.objectives << PaceEditor::Models::QuestObjective.new("obj1", "Task")
      quest2.objectives << PaceEditor::Models::QuestObjective.new("obj1", "Task")
      
      file.quests << quest1
      file.quests << quest2
      
      errors = file.validate
      errors.should contain "Duplicate quest ID: quest1"
    end

    it "validates all quests" do
      file = PaceEditor::Models::QuestFile.new
      
      # Invalid quest (no objectives)
      quest = PaceEditor::Models::Quest.new("quest1", "Test Quest", "Description", "main")
      file.quests << quest
      
      errors = file.validate
      errors.any? { |e| e.includes?("Quest quest1:") }.should be_true
    end
  end

  describe "YAML serialization" do
    it "serializes to YAML" do
      file = PaceEditor::Models::QuestFile.new
      
      quest = PaceEditor::Models::Quest.new("main_quest", "The Main Quest", "Save the world!", "main")
      quest.auto_start = true
      
      objective = PaceEditor::Models::QuestObjective.new("defeat_boss", "Defeat the evil boss")
      quest.objectives << objective
      
      reward = PaceEditor::Models::Reward.new("item", "legendary_sword")
      quest.rewards << reward
      
      file.quests << quest
      
      yaml = file.to_yaml
      yaml.should contain "quests:"
      yaml.should contain "id: main_quest"
      yaml.should contain "name: The Main Quest"
      yaml.should contain "objectives:"
      yaml.should contain "id: defeat_boss"
      yaml.should contain "rewards:"
      yaml.should contain "type: item"
      yaml.should contain "name: legendary_sword"
    end

    it "deserializes from YAML" do
      yaml = <<-YAML
      quests:
        - id: find_treasure
          name: "Find the Hidden Treasure"
          description: "Locate the pirate's hidden treasure"
          category: side
          icon: "assets/icons/treasure.png"
          auto_start: false
          prerequisites:
            - main_quest
          objectives:
            - id: find_map
              description: "Find the treasure map"
              optional: false
              hidden: false
              completion_conditions:
                has_item: treasure_map
              rewards:
                - type: variable
                  name: experience
                  value: 100
            - id: dig_treasure
              description: "Dig up the treasure"
              optional: false
              hidden: true
              completion_conditions:
                flag: treasure_dug
          rewards:
            - type: item
              name: gold_coins
              quantity: 1000
            - type: achievement
              name: treasure_hunter
          can_fail: true
          fail_conditions:
            flag: map_destroyed
          journal_entries:
            - id: entry1
              text: "I found a mysterious map..."
              conditions:
                has_item: treasure_map
      YAML
      
      file = PaceEditor::Models::QuestFile.from_yaml(yaml)
      
      file.quests.size.should eq 1
      
      quest = file.quests[0]
      quest.id.should eq "find_treasure"
      quest.name.should eq "Find the Hidden Treasure"
      quest.category.should eq "side"
      quest.icon.should eq "assets/icons/treasure.png"
      quest.prerequisites.should eq ["main_quest"]
      
      quest.objectives.size.should eq 2
      
      obj1 = quest.objectives[0]
      obj1.id.should eq "find_map"
      obj1.hidden.should be_false
      obj1.completion_conditions.should_not be_nil
      obj1.completion_conditions.not_nil!.has_item.should eq "treasure_map"
      obj1.rewards.size.should eq 1
      
      obj2 = quest.objectives[1]
      obj2.hidden.should be_true
      
      quest.rewards.size.should eq 2
      quest.rewards[0].type.should eq "item"
      quest.rewards[0].quantity.should eq 1000
      
      quest.can_fail.should be_true
      quest.fail_conditions.should_not be_nil
      
      quest.journal_entries.size.should eq 1
    end
  end
end