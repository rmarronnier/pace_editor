require "yaml"

module PaceEditor::Models
  # Represents an action that can be performed when interacting with a hotspot
  class HotspotAction
    include YAML::Serializable

    # Type of action to perform
    enum ActionType
      ShowMessage # Display a text message
      ChangeScene # Navigate to another scene
      PlaySound   # Play a sound effect
      GiveItem    # Add item to inventory
      RunScript   # Execute Lua script
      SetVariable # Set a game variable
      StartDialog # Start a dialog tree
    end

    property action_type : ActionType
    property parameters : Hash(String, String)

    def initialize(@action_type : ActionType)
      @parameters = {} of String => String
    end

    # Get a human-readable description of the action
    def description : String
      case @action_type
      when ActionType::ShowMessage
        text = @parameters["message"]? || "No message"
        "Show: \"#{text.size > 32 ? text[0...29] + "..." : text}\""
      when ActionType::ChangeScene
        scene = @parameters["scene"]? || "None"
        "Go to: #{scene}"
      when ActionType::PlaySound
        sound = @parameters["sound"]? || "None"
        "Play: #{File.basename(sound)}"
      when ActionType::GiveItem
        item = @parameters["item"]? || "None"
        "Give: #{item}"
      when ActionType::RunScript
        script = @parameters["script"]? || "None"
        "Run: #{File.basename(script)}"
      when ActionType::SetVariable
        var = @parameters["variable"]? || "None"
        val = @parameters["value"]? || ""
        "Set #{var} = #{val}"
      when ActionType::StartDialog
        dialog = @parameters["dialog"]? || "None"
        "Dialog: #{dialog}"
      else
        @action_type.to_s
      end
    end

    # Get parameter names for this action type
    def self.parameters_for(action_type : ActionType) : Array(String)
      case action_type
      when ActionType::ShowMessage
        ["message"]
      when ActionType::ChangeScene
        ["scene", "entry_point"]
      when ActionType::PlaySound
        ["sound", "volume"]
      when ActionType::GiveItem
        ["item", "quantity"]
      when ActionType::RunScript
        ["script", "function"]
      when ActionType::SetVariable
        ["variable", "value", "operation"]
      when ActionType::StartDialog
        ["dialog", "node"]
      else
        [] of String
      end
    end
  end

  # Extension to store actions in hotspots
  class HotspotData
    include YAML::Serializable

    property actions : Hash(String, Array(HotspotAction))

    def initialize
      @actions = {
        "on_click" => [] of HotspotAction,
        "on_look"  => [] of HotspotAction,
        "on_use"   => [] of HotspotAction,
        "on_talk"  => [] of HotspotAction,
      }
    end

    # Add an action to a specific event
    def add_action(event : String, action : HotspotAction)
      @actions[event] ||= [] of HotspotAction
      @actions[event] << action
    end

    # Remove an action from an event
    def remove_action(event : String, index : Int32)
      if actions = @actions[event]?
        actions.delete_at(index) if index >= 0 && index < actions.size
      end
    end

    # Get actions for a specific event
    def get_actions(event : String) : Array(HotspotAction)
      @actions[event]? || [] of HotspotAction
    end
  end
end
