require "../spec_helper"
require "file_utils"

describe "Item and Trigger Placement System" do
  state = PaceEditor::Core::EditorState.new
  temp_dir = "/tmp/pace_item_trigger_test_#{Random.new.next_int}"
  scene_editor = PaceEditor::Editors::SceneEditor.new(state, 0, 0, 800, 600)
  
  before_each do
    Dir.mkdir_p(temp_dir)
    state.create_new_project("Item Trigger Test", temp_dir)
  end
  
  after_each do
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end

  describe "Item Placement" do
    it "can place items in the scene" do
      scene = state.current_scene.not_nil!
      initial_hotspot_count = scene.hotspots.size
      
      # Test direct placement method call
      position = RL::Vector2.new(100.0_f32, 200.0_f32)
      scene_editor.send(:place_item_at, position)
      
      # Should have added one hotspot
      scene.hotspots.size.should eq(initial_hotspot_count + 1)
      
      # Check the created item
      item_hotspot = scene.hotspots.last
      item_hotspot.name.should start_with("item_")
      item_hotspot.position.x.should eq(100.0_f32)
      item_hotspot.position.y.should eq(200.0_f32)
      item_hotspot.size.x.should eq(32.0_f32)
      item_hotspot.size.y.should eq(32.0_f32)
      item_hotspot.cursor_type.should eq(PointClickEngine::Scenes::Hotspot::CursorType::Hand)
      item_hotspot.visible.should eq(true)
      item_hotspot.description.should eq("Collectable item")
      item_hotspot.object_type.should eq(PointClickEngine::UI::ObjectType::Item)
      item_hotspot.default_verb.should eq(PointClickEngine::UI::VerbType::Take)
    end
    
    it "generates unique item names" do
      scene = state.current_scene.not_nil!
      
      # Place multiple items
      3.times do |i|
        position = RL::Vector2.new(100.0_f32 + i * 50, 200.0_f32)
        scene_editor.send(:place_item_at, position)
      end
      
      # Check that all items have unique names
      item_names = scene.hotspots.select { |h| h.name.starts_with?("item_") }.map(&.name)
      item_names.uniq.size.should eq(item_names.size)
      item_names.should contain("item_1")
      item_names.should contain("item_2")
      item_names.should contain("item_3")
    end
    
    it "selects the newly created item" do
      scene = state.current_scene.not_nil!
      position = RL::Vector2.new(150.0_f32, 250.0_f32)
      
      scene_editor.send(:place_item_at, position)
      
      item_hotspot = scene.hotspots.last
      state.selected_object.should eq(item_hotspot.name)
    end
    
    it "creates undo action for item placement" do
      scene = state.current_scene.not_nil!
      initial_undo_count = state.undo_stack.size
      
      position = RL::Vector2.new(200.0_f32, 300.0_f32)
      scene_editor.send(:place_item_at, position)
      
      state.undo_stack.size.should eq(initial_undo_count + 1)
      last_action = state.undo_stack.last
      last_action.should be_a(PaceEditor::Core::CreateObjectAction)
      last_action.description.should contain("item_")
    end
    
    it "marks state as dirty after item placement" do
      scene = state.current_scene.not_nil!
      state.is_dirty = false
      
      position = RL::Vector2.new(250.0_f32, 350.0_f32)
      scene_editor.send(:place_item_at, position)
      
      state.is_dirty.should eq(true)
    end
  end

  describe "Trigger Placement" do
    it "can place triggers in the scene" do
      scene = state.current_scene.not_nil!
      initial_hotspot_count = scene.hotspots.size
      
      # Test direct placement method call
      position = RL::Vector2.new(300.0_f32, 400.0_f32)
      scene_editor.send(:place_trigger_at, position)
      
      # Should have added one hotspot
      scene.hotspots.size.should eq(initial_hotspot_count + 1)
      
      # Check the created trigger
      trigger_hotspot = scene.hotspots.last
      trigger_hotspot.name.should start_with("trigger_")
      trigger_hotspot.position.x.should eq(300.0_f32)
      trigger_hotspot.position.y.should eq(400.0_f32)
      trigger_hotspot.size.x.should eq(64.0_f32)
      trigger_hotspot.size.y.should eq(64.0_f32)
      trigger_hotspot.cursor_type.should eq(PointClickEngine::Scenes::Hotspot::CursorType::Look)
      trigger_hotspot.visible.should eq(false) # Triggers are invisible by default
      trigger_hotspot.description.should eq("Trigger zone")
      trigger_hotspot.object_type.should eq(PointClickEngine::UI::ObjectType::Exit)
      trigger_hotspot.default_verb.should eq(PointClickEngine::UI::VerbType::Use)
    end
    
    it "generates unique trigger names" do
      scene = state.current_scene.not_nil!
      
      # Place multiple triggers
      3.times do |i|
        position = RL::Vector2.new(300.0_f32 + i * 70, 400.0_f32)
        scene_editor.send(:place_trigger_at, position)
      end
      
      # Check that all triggers have unique names
      trigger_names = scene.hotspots.select { |h| h.name.starts_with?("trigger_") }.map(&.name)
      trigger_names.uniq.size.should eq(trigger_names.size)
      trigger_names.should contain("trigger_1")
      trigger_names.should contain("trigger_2")
      trigger_names.should contain("trigger_3")
    end
    
    it "selects the newly created trigger" do
      scene = state.current_scene.not_nil!
      position = RL::Vector2.new(350.0_f32, 450.0_f32)
      
      scene_editor.send(:place_trigger_at, position)
      
      trigger_hotspot = scene.hotspots.last
      state.selected_object.should eq(trigger_hotspot.name)
    end
    
    it "creates undo action for trigger placement" do
      scene = state.current_scene.not_nil!
      initial_undo_count = state.undo_stack.size
      
      position = RL::Vector2.new(400.0_f32, 500.0_f32)
      scene_editor.send(:place_trigger_at, position)
      
      state.undo_stack.size.should eq(initial_undo_count + 1)
      last_action = state.undo_stack.last
      last_action.should be_a(PaceEditor::Core::CreateObjectAction)
      last_action.description.should contain("trigger_")
    end
    
    it "marks state as dirty after trigger placement" do
      scene = state.current_scene.not_nil!
      state.is_dirty = false
      
      position = RL::Vector2.new(450.0_f32, 550.0_f32)
      scene_editor.send(:place_trigger_at, position)
      
      state.is_dirty.should eq(true)
    end
  end

  describe "Mixed Item and Trigger Placement" do
    it "handles placing both items and triggers in the same scene" do
      scene = state.current_scene.not_nil!
      
      # Place items and triggers
      scene_editor.send(:place_item_at, RL::Vector2.new(100.0_f32, 100.0_f32))
      scene_editor.send(:place_trigger_at, RL::Vector2.new(200.0_f32, 200.0_f32))
      scene_editor.send(:place_item_at, RL::Vector2.new(300.0_f32, 300.0_f32))
      scene_editor.send(:place_trigger_at, RL::Vector2.new(400.0_f32, 400.0_f32))
      
      items = scene.hotspots.select { |h| h.name.starts_with?("item_") }
      triggers = scene.hotspots.select { |h| h.name.starts_with?("trigger_") }
      
      items.size.should eq(2)
      triggers.size.should eq(2)
      
      # Verify unique names across both types
      all_names = scene.hotspots.map(&.name)
      all_names.uniq.size.should eq(all_names.size)
    end
    
    it "maintains different properties for items vs triggers" do
      scene = state.current_scene.not_nil!
      
      scene_editor.send(:place_item_at, RL::Vector2.new(100.0_f32, 100.0_f32))
      scene_editor.send(:place_trigger_at, RL::Vector2.new(200.0_f32, 200.0_f32))
      
      item = scene.hotspots.find { |h| h.name.starts_with?("item_") }.not_nil!
      trigger = scene.hotspots.find { |h| h.name.starts_with?("trigger_") }.not_nil!
      
      # Items are visible and use hand cursor
      item.visible.should eq(true)
      item.cursor_type.should eq(PointClickEngine::Scenes::Hotspot::CursorType::Hand)
      item.object_type.should eq(PointClickEngine::UI::ObjectType::Item)
      item.default_verb.should eq(PointClickEngine::UI::VerbType::Take)
      item.size.x.should eq(32.0_f32)
      
      # Triggers are invisible and use look cursor
      trigger.visible.should eq(false)
      trigger.cursor_type.should eq(PointClickEngine::Scenes::Hotspot::CursorType::Look)
      trigger.object_type.should eq(PointClickEngine::UI::ObjectType::Exit)
      trigger.default_verb.should eq(PointClickEngine::UI::VerbType::Use)
      trigger.size.x.should eq(64.0_f32)
    end
  end

  describe "Undo/Redo Functionality" do
    it "can undo item placement" do
      scene = state.current_scene.not_nil!
      initial_count = scene.hotspots.size
      
      scene_editor.send(:place_item_at, RL::Vector2.new(100.0_f32, 100.0_f32))
      scene.hotspots.size.should eq(initial_count + 1)
      
      state.undo
      scene.hotspots.size.should eq(initial_count)
      state.selected_object.should be_nil
    end
    
    it "can redo item placement" do
      scene = state.current_scene.not_nil!
      initial_count = scene.hotspots.size
      
      scene_editor.send(:place_item_at, RL::Vector2.new(100.0_f32, 100.0_f32))
      item_name = scene.hotspots.last.name
      
      state.undo
      scene.hotspots.size.should eq(initial_count)
      
      state.redo
      scene.hotspots.size.should eq(initial_count + 1)
      scene.hotspots.last.name.should eq(item_name)
      state.selected_object.should eq(item_name)
    end
    
    it "can undo trigger placement" do
      scene = state.current_scene.not_nil!
      initial_count = scene.hotspots.size
      
      scene_editor.send(:place_trigger_at, RL::Vector2.new(200.0_f32, 200.0_f32))
      scene.hotspots.size.should eq(initial_count + 1)
      
      state.undo
      scene.hotspots.size.should eq(initial_count)
      state.selected_object.should be_nil
    end
    
    it "can redo trigger placement" do
      scene = state.current_scene.not_nil!
      initial_count = scene.hotspots.size
      
      scene_editor.send(:place_trigger_at, RL::Vector2.new(200.0_f32, 200.0_f32))
      trigger_name = scene.hotspots.last.name
      
      state.undo
      scene.hotspots.size.should eq(initial_count)
      
      state.redo
      scene.hotspots.size.should eq(initial_count + 1)
      scene.hotspots.last.name.should eq(trigger_name)
      state.selected_object.should eq(trigger_name)
    end
  end

  describe "Type Detection" do
    it "correctly identifies item hotspots" do
      scene = state.current_scene.not_nil!
      scene_editor.send(:place_item_at, RL::Vector2.new(100.0_f32, 100.0_f32))
      
      item = scene.hotspots.last
      hotspot_type = scene_editor.send(:get_hotspot_type, item)
      hotspot_type.should eq("item")
    end
    
    it "correctly identifies trigger hotspots" do
      scene = state.current_scene.not_nil!
      scene_editor.send(:place_trigger_at, RL::Vector2.new(200.0_f32, 200.0_f32))
      
      trigger = scene.hotspots.last
      hotspot_type = scene_editor.send(:get_hotspot_type, trigger)
      hotspot_type.should eq("trigger")
    end
    
    it "identifies items by action type" do
      # Create a hotspot with pickup action but not item_ name
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        name: "custom_collectable",
        position: RL::Vector2.new(100.0_f32, 100.0_f32),
        size: RL::Vector2.new(32.0_f32, 32.0_f32)
      )
      hotspot.object_type = PointClickEngine::UI::ObjectType::Item
      hotspot.default_verb = PointClickEngine::UI::VerbType::Take
      
      hotspot_type = scene_editor.send(:get_hotspot_type, hotspot)
      hotspot_type.should eq("item")
    end
    
    it "identifies triggers by action type" do
      # Create a hotspot with trigger action but not trigger_ name
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        name: "custom_event_zone",
        position: RL::Vector2.new(200.0_f32, 200.0_f32),
        size: RL::Vector2.new(64.0_f32, 64.0_f32)
      )
      hotspot.object_type = PointClickEngine::UI::ObjectType::Exit
      hotspot.default_verb = PointClickEngine::UI::VerbType::Use
      
      hotspot_type = scene_editor.send(:get_hotspot_type, hotspot)
      hotspot_type.should eq("trigger")
    end
  end
  
  describe "Scene Persistence" do
    it "saves items to scene file" do
      scene = state.current_scene.not_nil!
      project = state.current_project.not_nil!
      
      scene_editor.send(:place_item_at, RL::Vector2.new(100.0_f32, 100.0_f32))
      
      # Check that scene file was saved
      scene_path = File.join(project.scenes_path, "#{scene.name}.yml")
      File.exists?(scene_path).should eq(true)
      
      # Load and verify the scene contains the item
      saved_content = File.read(scene_path)
      saved_content.should contain("item_")
      saved_content.should contain("Item")
    end
    
    it "saves triggers to scene file" do
      scene = state.current_scene.not_nil!
      project = state.current_project.not_nil!
      
      scene_editor.send(:place_trigger_at, RL::Vector2.new(200.0_f32, 200.0_f32))
      
      # Check that scene file was saved
      scene_path = File.join(project.scenes_path, "#{scene.name}.yml")
      File.exists?(scene_path).should eq(true)
      
      # Load and verify the scene contains the trigger
      saved_content = File.read(scene_path)
      saved_content.should contain("trigger_")
      saved_content.should contain("Exit")
    end
  end
end