require "../spec_helper"
require "../../src/pace_editor/models/hotspot_action"

describe PaceEditor::Models::HotspotAction do
  describe "initialization" do
    it "creates an action with specified type" do
      action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::ShowMessage
      )
      
      action.action_type.should eq(PaceEditor::Models::HotspotAction::ActionType::ShowMessage)
      action.parameters.should eq({} of String => String)
    end
  end
  
  describe "#description" do
    it "returns formatted description for ShowMessage" do
      action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::ShowMessage
      )
      action.parameters["message"] = "Hello, world!"
      
      action.description.should eq("Show: \"Hello, world!\"")
    end
    
    it "truncates long messages" do
      action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::ShowMessage
      )
      action.parameters["message"] = "This is a very long message that should be truncated"
      
      action.description.should eq("Show: \"This is a very long message t...\"")
    end
    
    it "returns formatted description for ChangeScene" do
      action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::ChangeScene
      )
      action.parameters["scene"] = "kitchen"
      
      action.description.should eq("Go to: kitchen")
    end
    
    it "returns formatted description for PlaySound" do
      action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::PlaySound
      )
      action.parameters["sound"] = "sounds/door_open.wav"
      
      action.description.should eq("Play: door_open.wav")
    end
    
    it "returns formatted description for GiveItem" do
      action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::GiveItem
      )
      action.parameters["item"] = "golden_key"
      
      action.description.should eq("Give: golden_key")
    end
    
    it "returns formatted description for RunScript" do
      action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::RunScript
      )
      action.parameters["script"] = "scripts/puzzle_complete.lua"
      
      action.description.should eq("Run: puzzle_complete.lua")
    end
    
    it "returns formatted description for SetVariable" do
      action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::SetVariable
      )
      action.parameters["variable"] = "door_opened"
      action.parameters["value"] = "true"
      
      action.description.should eq("Set door_opened = true")
    end
    
    it "returns formatted description for StartDialog" do
      action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::StartDialog
      )
      action.parameters["dialog"] = "guard_conversation"
      
      action.description.should eq("Dialog: guard_conversation")
    end
  end
  
  describe ".parameters_for" do
    it "returns correct parameters for ShowMessage" do
      params = PaceEditor::Models::HotspotAction.parameters_for(
        PaceEditor::Models::HotspotAction::ActionType::ShowMessage
      )
      params.should eq(["message"])
    end
    
    it "returns correct parameters for ChangeScene" do
      params = PaceEditor::Models::HotspotAction.parameters_for(
        PaceEditor::Models::HotspotAction::ActionType::ChangeScene
      )
      params.should eq(["scene", "entry_point"])
    end
    
    it "returns correct parameters for PlaySound" do
      params = PaceEditor::Models::HotspotAction.parameters_for(
        PaceEditor::Models::HotspotAction::ActionType::PlaySound
      )
      params.should eq(["sound", "volume"])
    end
    
    it "returns correct parameters for GiveItem" do
      params = PaceEditor::Models::HotspotAction.parameters_for(
        PaceEditor::Models::HotspotAction::ActionType::GiveItem
      )
      params.should eq(["item", "quantity"])
    end
    
    it "returns correct parameters for RunScript" do
      params = PaceEditor::Models::HotspotAction.parameters_for(
        PaceEditor::Models::HotspotAction::ActionType::RunScript
      )
      params.should eq(["script", "function"])
    end
    
    it "returns correct parameters for SetVariable" do
      params = PaceEditor::Models::HotspotAction.parameters_for(
        PaceEditor::Models::HotspotAction::ActionType::SetVariable
      )
      params.should eq(["variable", "value", "operation"])
    end
    
    it "returns correct parameters for StartDialog" do
      params = PaceEditor::Models::HotspotAction.parameters_for(
        PaceEditor::Models::HotspotAction::ActionType::StartDialog
      )
      params.should eq(["dialog", "node"])
    end
  end
  
  describe "YAML serialization" do
    it "serializes to YAML" do
      action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::ShowMessage
      )
      action.parameters["message"] = "Test message"
      
      yaml = action.to_yaml
      yaml.should contain("action_type: show_message")
      yaml.should contain("message: Test message")
    end
    
    it "deserializes from YAML" do
      yaml_content = <<-YAML
      action_type: show_message
      parameters:
        message: Test message
      YAML
      
      action = PaceEditor::Models::HotspotAction.from_yaml(yaml_content)
      action.action_type.should eq(PaceEditor::Models::HotspotAction::ActionType::ShowMessage)
      action.parameters["message"].should eq("Test message")
    end
  end
end

describe PaceEditor::Models::HotspotData do
  describe "initialization" do
    it "creates hotspot data with default action lists" do
      data = PaceEditor::Models::HotspotData.new
      
      data.actions.should_not be_nil
      data.actions["on_click"].should eq([] of PaceEditor::Models::HotspotAction)
      data.actions["on_look"].should eq([] of PaceEditor::Models::HotspotAction)
      data.actions["on_use"].should eq([] of PaceEditor::Models::HotspotAction)
      data.actions["on_talk"].should eq([] of PaceEditor::Models::HotspotAction)
    end
  end
  
  describe "#add_action" do
    it "adds action to specified event" do
      data = PaceEditor::Models::HotspotData.new
      action = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::ShowMessage
      )
      
      data.add_action("on_click", action)
      
      data.get_actions("on_click").size.should eq(1)
      data.get_actions("on_click")[0].should eq(action)
    end
    
    it "adds multiple actions to same event" do
      data = PaceEditor::Models::HotspotData.new
      action1 = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::ShowMessage
      )
      action2 = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::PlaySound
      )
      
      data.add_action("on_click", action1)
      data.add_action("on_click", action2)
      
      data.get_actions("on_click").size.should eq(2)
    end
  end
  
  describe "#remove_action" do
    it "removes action at specified index" do
      data = PaceEditor::Models::HotspotData.new
      action1 = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::ShowMessage
      )
      action2 = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::PlaySound
      )
      
      data.add_action("on_click", action1)
      data.add_action("on_click", action2)
      
      data.remove_action("on_click", 0)
      
      data.get_actions("on_click").size.should eq(1)
      data.get_actions("on_click")[0].action_type.should eq(
        PaceEditor::Models::HotspotAction::ActionType::PlaySound
      )
    end
    
    it "handles invalid index gracefully" do
      data = PaceEditor::Models::HotspotData.new
      
      # Should not raise error
      data.remove_action("on_click", 5)
      data.remove_action("on_click", -1)
    end
  end
  
  describe "#get_actions" do
    it "returns empty array for non-existent event" do
      data = PaceEditor::Models::HotspotData.new
      
      data.get_actions("invalid_event").should eq([] of PaceEditor::Models::HotspotAction)
    end
  end
  
  describe "YAML serialization" do
    it "serializes to YAML with actions" do
      data = PaceEditor::Models::HotspotData.new
      
      action1 = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::ShowMessage
      )
      action1.parameters["message"] = "Hello"
      
      action2 = PaceEditor::Models::HotspotAction.new(
        PaceEditor::Models::HotspotAction::ActionType::ChangeScene
      )
      action2.parameters["scene"] = "next_room"
      
      data.add_action("on_click", action1)
      data.add_action("on_look", action2)
      
      yaml = data.to_yaml
      yaml.should contain("on_click:")
      yaml.should contain("on_look:")
      yaml.should contain("show_message")
      yaml.should contain("change_scene")
    end
    
    it "deserializes from YAML" do
      yaml_content = <<-YAML
      actions:
        on_click:
          - action_type: show_message
            parameters:
              message: Test
        on_look:
          - action_type: play_sound
            parameters:
              sound: test.wav
              volume: "0.8"
        on_use: []
        on_talk: []
      YAML
      
      data = PaceEditor::Models::HotspotData.from_yaml(yaml_content)
      
      click_actions = data.get_actions("on_click")
      click_actions.size.should eq(1)
      click_actions[0].action_type.should eq(PaceEditor::Models::HotspotAction::ActionType::ShowMessage)
      click_actions[0].parameters["message"].should eq("Test")
      
      look_actions = data.get_actions("on_look")
      look_actions.size.should eq(1)
      look_actions[0].action_type.should eq(PaceEditor::Models::HotspotAction::ActionType::PlaySound)
      look_actions[0].parameters["sound"].should eq("test.wav")
      look_actions[0].parameters["volume"].should eq("0.8")
    end
  end
end