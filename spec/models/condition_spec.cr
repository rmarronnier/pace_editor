require "../spec_helper"
require "../../src/pace_editor/models/condition"

describe PaceEditor::Models::Condition do
  describe "factory methods" do
    it "creates a flag condition" do
      condition = PaceEditor::Models::Condition.flag("has_key", true)
      
      condition.flag.should eq "has_key"
      condition.value.should eq YAML::Any.new(true)
      condition.simple?.should be_true
      condition.complex?.should be_false
    end

    it "creates a has_item condition" do
      condition = PaceEditor::Models::Condition.has_item("golden_key")
      
      condition.has_item.should eq "golden_key"
      condition.simple?.should be_true
    end

    it "creates a variable condition" do
      condition = PaceEditor::Models::Condition.variable("player_health", ">", YAML::Any.new(50))
      
      condition.variable.should eq "player_health"
      condition.operator.should eq ">"
      condition.value.should eq YAML::Any.new(50)
      condition.simple?.should be_true
    end

    it "creates an all_of condition" do
      c1 = PaceEditor::Models::Condition.flag("has_key")
      c2 = PaceEditor::Models::Condition.has_item("sword")
      
      condition = PaceEditor::Models::Condition.all_of([c1, c2])
      
      condition.all_of.should_not be_nil
      condition.all_of.not_nil!.size.should eq 2
      condition.complex?.should be_true
      condition.simple?.should be_false
    end

    it "creates an any_of condition" do
      c1 = PaceEditor::Models::Condition.flag("door_unlocked")
      c2 = PaceEditor::Models::Condition.has_item("master_key")
      
      condition = PaceEditor::Models::Condition.any_of([c1, c2])
      
      condition.any_of.should_not be_nil
      condition.any_of.not_nil!.size.should eq 2
      condition.complex?.should be_true
    end

    it "creates a none_of condition" do
      c1 = PaceEditor::Models::Condition.flag("in_combat")
      c2 = PaceEditor::Models::Condition.flag("exhausted")
      
      condition = PaceEditor::Models::Condition.none_of([c1, c2])
      
      condition.none_of.should_not be_nil
      condition.none_of.not_nil!.size.should eq 2
      condition.complex?.should be_true
    end
  end

  describe "#validate" do
    it "validates that at least one condition type is set" do
      condition = PaceEditor::Models::Condition.new
      errors = condition.validate
      
      errors.should contain "Condition must have at least one condition type set"
    end

    it "validates that only one condition type is set" do
      condition = PaceEditor::Models::Condition.new
      condition.flag = "test"
      condition.has_item = "item"
      
      errors = condition.validate
      errors.should contain "Condition can only have one condition type set"
    end

    it "validates operator for variable conditions" do
      condition = PaceEditor::Models::Condition.new
      condition.variable = "test_var"
      condition.value = YAML::Any.new(10)
      
      # Missing operator
      errors = condition.validate
      errors.should contain "Variable condition must have an operator"
      
      # Invalid operator
      condition.operator = "~="
      errors = condition.validate
      errors.should contain "Invalid operator: ~=. Must be one of: ==, !=, >, <, >=, <="
      
      # Valid operator
      condition.operator = ">="
      condition.validate.should be_empty
    end

    it "validates nested conditions" do
      invalid_condition = PaceEditor::Models::Condition.new
      valid_condition = PaceEditor::Models::Condition.flag("test")
      
      condition = PaceEditor::Models::Condition.all_of([valid_condition, invalid_condition])
      
      errors = condition.validate
      errors.any? { |e| e.includes?("Nested condition:") }.should be_true
    end

    it "validates empty condition lists" do
      condition = PaceEditor::Models::Condition.new
      condition.all_of = [] of PaceEditor::Models::Condition
      
      errors = condition.validate
      errors.should contain "Condition list cannot be empty"
    end
  end

  describe "#to_description" do
    it "describes flag conditions" do
      condition = PaceEditor::Models::Condition.flag("door_open", true)
      condition.to_description.should eq "Flag 'door_open' is set"
      
      condition = PaceEditor::Models::Condition.flag("door_open", false)
      condition.to_description.should eq "Flag 'door_open' is not set"
    end

    it "describes has_item conditions" do
      condition = PaceEditor::Models::Condition.has_item("magic_sword")
      condition.to_description.should eq "Has item 'magic_sword'"
    end

    it "describes variable conditions" do
      condition = PaceEditor::Models::Condition.variable("player_level", ">=", YAML::Any.new(10))
      condition.to_description.should eq "Variable 'player_level' >= 10"
    end

    it "describes complex conditions" do
      c1 = PaceEditor::Models::Condition.flag("has_map")
      c2 = PaceEditor::Models::Condition.has_item("compass")
      
      condition = PaceEditor::Models::Condition.all_of([c1, c2])
      description = condition.to_description
      
      description.should contain "All of:"
      description.should contain "Flag 'has_map' is set"
      description.should contain "Has item 'compass'"
    end
  end

  describe "YAML serialization" do
    it "serializes simple conditions" do
      condition = PaceEditor::Models::Condition.flag("test_flag")
      yaml = condition.to_yaml
      
      yaml.should contain "flag: test_flag"
      yaml.should contain "value: true"
    end

    it "serializes complex conditions" do
      c1 = PaceEditor::Models::Condition.flag("flag1")
      c2 = PaceEditor::Models::Condition.has_item("item1")
      condition = PaceEditor::Models::Condition.any_of([c1, c2])
      
      yaml = condition.to_yaml
      yaml.should contain "any_of:"
      yaml.should contain "flag: flag1"
      yaml.should contain "has_item: item1"
    end

    it "deserializes from YAML" do
      yaml = <<-YAML
      all_of:
        - flag: has_key
          value: true
        - variable: player_health
          operator: ">"
          value: 0
        - any_of:
          - has_item: sword
          - has_item: staff
      YAML
      
      condition = PaceEditor::Models::Condition.from_yaml(yaml)
      
      condition.all_of.should_not be_nil
      condition.all_of.not_nil!.size.should eq 3
      
      first = condition.all_of.not_nil![0]
      first.flag.should eq "has_key"
      
      second = condition.all_of.not_nil![1]
      second.variable.should eq "player_health"
      second.operator.should eq ">"
      
      third = condition.all_of.not_nil![2]
      third.any_of.should_not be_nil
      third.any_of.not_nil!.size.should eq 2
    end
  end
end