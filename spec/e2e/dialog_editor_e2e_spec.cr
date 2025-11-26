# E2E Tests for Dialog Editor
# Tests dialog tree creation, editing, node management, and validation

require "./e2e_spec_helper"

describe "Dialog Editor E2E" do
  describe "Dialog Tree Creation" do
    it "can create a new dialog tree" do
      harness = E2ETestHelper.create_harness_with_scene

      # Create a dialog tree programmatically
      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("test_dialog")
      dialog.nodes.size.should eq(0)

      # Add a start node
      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello!")
      dialog.add_node(start_node)
      dialog.nodes.size.should eq(1)

      harness.cleanup
    end

    it "can create dialog with multiple nodes" do
      harness = E2ETestHelper.create_harness_with_scene

      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("multi_node_dialog")

      # Create nodes
      nodes = [
        PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Welcome!"),
        PointClickEngine::Characters::Dialogue::DialogNode.new("middle", "How can I help?"),
        PointClickEngine::Characters::Dialogue::DialogNode.new("end", "Goodbye!"),
      ]

      nodes.each { |node| dialog.add_node(node) }
      dialog.nodes.size.should eq(3)

      harness.cleanup
    end

    it "can save dialog to project" do
      harness = E2ETestHelper.create_harness_with_scene

      if project = harness.editor.state.current_project
        dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("saved_dialog")

        start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Test message")
        dialog.add_node(start_node)

        # Save to file
        dialog_path = File.join(project.dialogs_path, "saved_dialog.yml")
        File.write(dialog_path, dialog.to_yaml)

        # Verify file exists
        File.exists?(dialog_path).should be_true

        # Verify content
        content = File.read(dialog_path)
        content.includes?("saved_dialog").should be_true
        content.includes?("Test message").should be_true
      end

      harness.cleanup
    end
  end

  describe "Dialog Node Management" do
    it "can add choices to nodes" do
      harness = E2ETestHelper.create_harness_with_scene

      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("choice_dialog")

      # Create start node
      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "What would you like to do?")

      # Add choices
      choice1 = PointClickEngine::Characters::Dialogue::DialogChoice.new("Option A", "path_a")
      choice2 = PointClickEngine::Characters::Dialogue::DialogChoice.new("Option B", "path_b")
      choice3 = PointClickEngine::Characters::Dialogue::DialogChoice.new("Leave", "end")

      start_node.choices << choice1
      start_node.choices << choice2
      start_node.choices << choice3

      dialog.add_node(start_node)

      # Verify choices
      if node = dialog.nodes["start"]?
        node.choices.size.should eq(3)
        node.choices[0].text.should eq("Option A")
        node.choices[0].target_node_id.should eq("path_a")
      end

      harness.cleanup
    end

    it "can create branching dialog paths" do
      harness = E2ETestHelper.create_harness_with_scene

      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("branching_dialog")

      # Start node with two branches
      start = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Choose your path:")
      start.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Go left", "left_path")
      start.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Go right", "right_path")

      # Left path
      left = PointClickEngine::Characters::Dialogue::DialogNode.new("left_path", "You chose left.")
      left.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Continue", "merge_point")

      # Right path
      right = PointClickEngine::Characters::Dialogue::DialogNode.new("right_path", "You chose right.")
      right.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Continue", "merge_point")

      # Merge point
      merge = PointClickEngine::Characters::Dialogue::DialogNode.new("merge_point", "Both paths lead here.")
      merge.is_end = true

      [start, left, right, merge].each { |n| dialog.add_node(n) }

      # Verify structure
      dialog.nodes.size.should eq(4)
      dialog.nodes["left_path"]?.should_not be_nil
      dialog.nodes["right_path"]?.should_not be_nil

      harness.cleanup
    end

    it "can mark nodes as end nodes" do
      harness = E2ETestHelper.create_harness_with_scene

      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("end_node_dialog")

      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Begin")
      start_node.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Finish", "end")

      end_node = PointClickEngine::Characters::Dialogue::DialogNode.new("end", "Goodbye!")
      end_node.is_end = true

      dialog.add_node(start_node)
      dialog.add_node(end_node)

      # Verify end node
      if node = dialog.nodes["end"]?
        node.is_end.should be_true
      end

      harness.cleanup
    end
  end

  describe "Dialog Validation" do
    it "detects missing start node" do
      harness = E2ETestHelper.create_harness_with_scene

      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("no_start_dialog")

      # Add a node that's NOT named "start"
      other_node = PointClickEngine::Characters::Dialogue::DialogNode.new("other", "Some text")
      dialog.add_node(other_node)

      # Should not have a start node
      dialog.nodes["start"]?.should be_nil

      harness.cleanup
    end

    it "detects broken links" do
      harness = E2ETestHelper.create_harness_with_scene

      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("broken_link_dialog")

      # Create node with choice pointing to non-existent node
      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Begin")
      start_node.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Go", "non_existent_node")

      dialog.add_node(start_node)

      # The target node doesn't exist
      dialog.nodes["non_existent_node"]?.should be_nil

      # But the choice still references it
      if node = dialog.nodes["start"]?
        node.choices.first.target_node_id.should eq("non_existent_node")
      end

      harness.cleanup
    end

    it "detects orphaned nodes" do
      harness = E2ETestHelper.create_harness_with_scene

      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("orphan_dialog")

      # Create connected path
      start = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Begin")
      start.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Next", "middle")

      middle = PointClickEngine::Characters::Dialogue::DialogNode.new("middle", "Middle")
      middle.is_end = true

      # Create orphaned node (not reachable from start)
      orphan = PointClickEngine::Characters::Dialogue::DialogNode.new("orphan", "I'm unreachable!")

      [start, middle, orphan].each { |n| dialog.add_node(n) }

      # Manually check for orphans
      reachable = Set(String).new
      to_visit = ["start"]

      while !to_visit.empty?
        current = to_visit.pop
        next if reachable.includes?(current)
        reachable << current

        if node = dialog.nodes[current]?
          node.choices.each do |choice|
            to_visit << choice.target_node_id unless reachable.includes?(choice.target_node_id)
          end
        end
      end

      orphans = dialog.nodes.keys.reject { |k| reachable.includes?(k) }
      orphans.includes?("orphan").should be_true

      harness.cleanup
    end
  end

  describe "Dialog with Character Names" do
    it "can assign character to dialog node" do
      harness = E2ETestHelper.create_harness_with_scene

      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("character_dialog")

      # Create nodes with character names
      butler_node = PointClickEngine::Characters::Dialogue::DialogNode.new("butler_greeting", "Good evening, sir.")
      butler_node.character_name = "Butler"

      player_node = PointClickEngine::Characters::Dialogue::DialogNode.new("player_response", "Thank you.")
      player_node.character_name = "Player"

      dialog.add_node(butler_node)
      dialog.add_node(player_node)

      # Verify character assignments
      if node = dialog.nodes["butler_greeting"]?
        node.character_name.should eq("Butler")
      end

      if node = dialog.nodes["player_response"]?
        node.character_name.should eq("Player")
      end

      harness.cleanup
    end
  end

  describe "Dialog Actions" do
    it "can add actions to dialog nodes" do
      harness = E2ETestHelper.create_harness_with_scene

      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("action_dialog")

      # Create node with actions
      action_node = PointClickEngine::Characters::Dialogue::DialogNode.new("with_actions", "Something happens!")
      action_node.actions = ["set game_flag_1", "play_sound chime", "add_item key"]

      dialog.add_node(action_node)

      # Verify actions
      if node = dialog.nodes["with_actions"]?
        node.actions.size.should eq(3)
        node.actions.includes?("set game_flag_1").should be_true
        node.actions.includes?("add_item key").should be_true
      end

      harness.cleanup
    end
  end

  describe "Dialog Serialization" do
    it "can serialize dialog to YAML" do
      harness = E2ETestHelper.create_harness_with_scene

      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("yaml_dialog")

      start = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello!")
      start.character_name = "NPC"
      start.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Hi!", "end")

      end_node = PointClickEngine::Characters::Dialogue::DialogNode.new("end", "Bye!")
      end_node.is_end = true

      dialog.add_node(start)
      dialog.add_node(end_node)

      # Serialize to YAML
      yaml = dialog.to_yaml

      # Verify YAML content
      yaml.includes?("yaml_dialog").should be_true
      yaml.includes?("Hello!").should be_true
      yaml.includes?("NPC").should be_true

      harness.cleanup
    end

    it "can load dialog from YAML" do
      harness = E2ETestHelper.create_harness_with_scene

      yaml_content = <<-YAML
      name: loaded_dialog
      nodes:
        start:
          id: start
          text: "Loaded from YAML!"
          choices:
            - text: "Okay"
              target_node_id: end
        end:
          id: end
          text: "Done!"
          is_end: true
      YAML

      if project = harness.editor.state.current_project
        dialog_path = File.join(project.dialogs_path, "loaded_dialog.yml")
        File.write(dialog_path, yaml_content)

        # Load the dialog
        loaded = PointClickEngine::Characters::Dialogue::DialogTree.from_yaml(File.read(dialog_path))

        loaded.name.should eq("loaded_dialog")
        loaded.nodes.size.should eq(2)
        loaded.nodes["start"]?.should_not be_nil
      end

      harness.cleanup
    end
  end

  describe "Complex Dialog Trees" do
    it "can create detective interview dialog" do
      harness = E2ETestHelper.create_harness_with_scene

      dialog = PointClickEngine::Characters::Dialogue::DialogTree.new("detective_interview")

      # Greeting
      greeting = PointClickEngine::Characters::Dialogue::DialogNode.new("greeting", "Good evening, Detective.")
      greeting.character_name = "Butler"
      greeting.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("I'm here about the missing crystal.", "crystal_inquiry")
      greeting.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("You seem nervous.", "nervous")
      greeting.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Tell me about your duties.", "duties")

      # Crystal inquiry path
      crystal = PointClickEngine::Characters::Dialogue::DialogNode.new("crystal_inquiry", "Most distressing, I'm sure.")
      crystal.character_name = "Butler"
      crystal.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Where were you last night?", "alibi")
      crystal.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Back to questions.", "greeting")

      # Nervous path
      nervous = PointClickEngine::Characters::Dialogue::DialogNode.new("nervous", "Nervous? I... well, it's not every day we have a detective.")
      nervous.character_name = "Butler"
      nervous.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("You're hiding something.", "accusation")
      nervous.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Never mind.", "greeting")

      # Duties path
      duties = PointClickEngine::Characters::Dialogue::DialogNode.new("duties", "I oversee the daily operations.")
      duties.character_name = "Butler"
      duties.actions = ["set butler_has_all_keys"]
      duties.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Including the laboratory?", "lab_access")
      duties.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Thank you.", "end")

      # Additional nodes
      alibi = PointClickEngine::Characters::Dialogue::DialogNode.new("alibi", "I was attending to my evening duties.")
      alibi.character_name = "Butler"
      alibi.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Can anyone verify?", "verify")
      alibi.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("I see.", "greeting")

      accusation = PointClickEngine::Characters::Dialogue::DialogNode.new("accusation", "I assure you, my only concern is the household!")
      accusation.character_name = "Butler"
      accusation.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("We'll see about that.", "end")

      lab_access = PointClickEngine::Characters::Dialogue::DialogNode.new("lab_access", "Yes, I have access to all rooms.")
      lab_access.character_name = "Butler"
      lab_access.actions = ["set butler_confirmed_lab_access"]
      lab_access.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("Interesting...", "end")

      verify = PointClickEngine::Characters::Dialogue::DialogNode.new("verify", "The cook saw me in the kitchen at 10pm.")
      verify.character_name = "Butler"
      verify.actions = ["set butler_alibi_given"]
      verify.choices << PointClickEngine::Characters::Dialogue::DialogChoice.new("I'll check with the cook.", "end")

      end_node = PointClickEngine::Characters::Dialogue::DialogNode.new("end", "Is there anything else, Detective?")
      end_node.character_name = "Butler"
      end_node.is_end = true

      # Add all nodes
      [greeting, crystal, nervous, duties, alibi, accusation, lab_access, verify, end_node].each { |n| dialog.add_node(n) }

      # Verify structure
      dialog.nodes.size.should eq(9)

      # Verify some paths exist
      if start = dialog.nodes["greeting"]?
        start.choices.size.should eq(3)
      end

      # Verify actions were set
      if duties_node = dialog.nodes["duties"]?
        duties_node.actions.includes?("set butler_has_all_keys").should be_true
      end

      harness.cleanup
    end
  end

  describe "Dialog Editor Integration" do
    it "can switch to dialog mode and back" do
      harness = E2ETestHelper.create_harness_with_scene

      # Start in Scene mode
      harness.assert_mode(PaceEditor::EditorMode::Scene)

      # Switch to Dialog mode
      harness.editor.state.current_mode = PaceEditor::EditorMode::Dialog
      harness.step_frames(3)
      harness.assert_mode(PaceEditor::EditorMode::Dialog)

      # Switch back
      harness.editor.state.current_mode = PaceEditor::EditorMode::Scene
      harness.step_frames(3)
      harness.assert_mode(PaceEditor::EditorMode::Scene)

      harness.cleanup
    end
  end
end
