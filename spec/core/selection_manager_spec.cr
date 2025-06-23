require "../spec_helper"

describe PaceEditor::Core::SelectionManager do
  describe "#initialize" do
    it "creates empty selection manager" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.has_selection?.should be_false
      manager.selection_count.should eq(0)
      manager.multi_select_enabled.should be_true
    end
  end

  describe "#select" do
    it "selects single item" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select("item1")

      manager.selected?("item1").should be_true
      manager.primary_selection.should eq("item1")
      manager.selection_count.should eq(1)
    end

    it "replaces previous selection" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select("item1")
      manager.select("item2")

      manager.selected?("item1").should be_false
      manager.selected?("item2").should be_true
      manager.selection_count.should eq(1)
    end
  end

  describe "#add_to_selection" do
    it "adds item to selection" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.add_to_selection("item1")
      manager.add_to_selection("item2")

      manager.selected?("item1").should be_true
      manager.selected?("item2").should be_true
      manager.selection_count.should eq(2)
    end

    it "sets first item as primary" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.add_to_selection("item1")
      manager.add_to_selection("item2")

      manager.primary_selection.should eq("item1")
    end

    it "ignores duplicate additions" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.add_to_selection("item1")
      manager.add_to_selection("item1")

      manager.selection_count.should eq(1)
    end

    it "respects max selection count" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.max_selection_count = 2
      manager.add_to_selection("item1")
      manager.add_to_selection("item2")
      manager.add_to_selection("item3") # Should be ignored

      manager.selection_count.should eq(2)
      manager.selected?("item3").should be_false
    end
  end

  describe "#remove_from_selection" do
    it "removes item from selection" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select_multiple(["item1", "item2"])
      manager.remove_from_selection("item1")

      manager.selected?("item1").should be_false
      manager.selected?("item2").should be_true
      manager.selection_count.should eq(1)
    end

    it "updates primary selection when primary is removed" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select_multiple(["item1", "item2"])
      manager.set_primary("item1")
      manager.remove_from_selection("item1")

      manager.primary_selection.should eq("item2")
    end

    it "clears primary when last item is removed" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select("item1")
      manager.remove_from_selection("item1")

      manager.primary_selection.should be_nil
    end
  end

  describe "#toggle_selection" do
    context "with multi-select enabled" do
      it "adds item if not selected" do
        manager = PaceEditor::Core::SelectionManager(String).new
        manager.toggle_selection("item1")

        manager.selected?("item1").should be_true
      end

      it "removes item if selected" do
        manager = PaceEditor::Core::SelectionManager(String).new
        manager.select("item1")
        manager.toggle_selection("item1")

        manager.selected?("item1").should be_false
      end
    end

    context "with multi-select disabled" do
      it "selects item replacing previous selection" do
        manager = PaceEditor::Core::SelectionManager(String).new
        manager.multi_select_enabled = false
        manager.select("item1")
        manager.toggle_selection("item2")

        manager.selected?("item1").should be_false
        manager.selected?("item2").should be_true
      end
    end
  end

  describe "#clear_selection" do
    it "clears all selections" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select_multiple(["item1", "item2"])
      manager.clear_selection

      manager.has_selection?.should be_false
      manager.primary_selection.should be_nil
      manager.selection_count.should eq(0)
    end
  end

  describe "#set_primary" do
    it "sets primary selection from current selection" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select_multiple(["item1", "item2"])
      manager.set_primary("item2")

      manager.primary_selection.should eq("item2")
    end

    it "ignores setting primary for non-selected item" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select("item1")
      original_primary = manager.primary_selection
      manager.set_primary("item2")

      manager.primary_selection.should eq(original_primary)
    end
  end

  describe "#select_multiple" do
    it "selects multiple items" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select_multiple(["item1", "item2", "item3"])

      manager.selected?("item1").should be_true
      manager.selected?("item2").should be_true
      manager.selected?("item3").should be_true
      manager.selection_count.should eq(3)
    end

    it "sets first item as primary" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select_multiple(["item1", "item2", "item3"])

      manager.primary_selection.should eq("item1")
    end

    it "respects max selection count" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.max_selection_count = 2
      manager.select_multiple(["item1", "item2", "item3"])

      manager.selection_count.should eq(2)
    end

    it "clears previous selection" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select("item1")
      manager.select_multiple(["item2", "item3"])

      manager.selected?("item1").should be_false
      manager.selection_count.should eq(2)
    end
  end

  describe "#select_all" do
    it "selects all items up to max count" do
      manager = PaceEditor::Core::SelectionManager(String).new
      items = ["item1", "item2", "item3", "item4"]
      manager.select_all(items)

      items.each { |item| manager.selected?(item).should be_true }
      manager.selection_count.should eq(4)
    end

    it "respects max selection count" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.max_selection_count = 2
      manager.select_all(["item1", "item2", "item3", "item4"])

      manager.selection_count.should eq(2)
    end
  end

  describe "#invert_selection" do
    it "inverts current selection" do
      manager = PaceEditor::Core::SelectionManager(String).new
      items = ["item1", "item2", "item3", "item4"]
      manager.select_multiple(["item1", "item3"])
      manager.invert_selection(items)

      manager.selected?("item1").should be_false
      manager.selected?("item2").should be_true
      manager.selected?("item3").should be_false
      manager.selected?("item4").should be_true
    end
  end

  describe "query methods" do
    describe "#has_selection?" do
      it "returns true when items are selected" do
        manager = PaceEditor::Core::SelectionManager(String).new
        manager.select_multiple(["item1", "item2"])
        manager.has_selection?.should be_true
      end

      it "returns false when no items are selected" do
        manager = PaceEditor::Core::SelectionManager(String).new
        manager.has_selection?.should be_false
      end
    end

    describe "#is_multi_selection?" do
      it "returns true for multiple items" do
        manager = PaceEditor::Core::SelectionManager(String).new
        manager.select_multiple(["item1", "item2"])
        manager.is_multi_selection?.should be_true
      end

      it "returns false for single item" do
        manager = PaceEditor::Core::SelectionManager(String).new
        manager.select("item1")
        manager.is_multi_selection?.should be_false
      end
    end

    describe "#selected_items" do
      it "returns array of selected items" do
        manager = PaceEditor::Core::SelectionManager(String).new
        manager.select_multiple(["item1", "item2"])
        selected = manager.selected_items
        selected.should contain("item1")
        selected.should contain("item2")
        selected.size.should eq(2)
      end
    end

    describe "#last_selected" do
      it "returns most recently selected item" do
        manager = PaceEditor::Core::SelectionManager(String).new
        manager.select_multiple(["item1", "item2"])
        manager.last_selected.should eq("item2")
      end
    end

    describe "#first_selected" do
      it "returns first selected item" do
        manager = PaceEditor::Core::SelectionManager(String).new
        manager.select_multiple(["item1", "item2"])
        manager.first_selected.should eq("item1")
      end
    end
  end

  describe "#copy_selection and #restore_selection" do
    it "copies and restores selection" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select_multiple(["item1", "item3"])
      copied = manager.copy_selection

      manager.clear_selection
      manager.restore_selection(copied)

      manager.selected?("item1").should be_true
      manager.selected?("item3").should be_true
      manager.selection_count.should eq(2)
    end
  end

  describe "#get_selection_bounds" do
    it "calculates bounds for selected items" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select_multiple(["item1", "item2"])

      bounds_proc = ->(item : String) {
        case item
        when "item1"
          RL::Rectangle.new(x: 10.0_f32, y: 10.0_f32, width: 20.0_f32, height: 20.0_f32)
        when "item2"
          RL::Rectangle.new(x: 40.0_f32, y: 40.0_f32, width: 20.0_f32, height: 20.0_f32)
        else
          RL::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: 0.0_f32, height: 0.0_f32)
        end
      }

      bounds = manager.get_selection_bounds(bounds_proc)
      bounds.should_not be_nil

      if bounds
        bounds.x.should eq(10.0_f32)
        bounds.y.should eq(10.0_f32)
        bounds.width.should eq(50.0_f32) # 40 + 20 - 10
        bounds.height.should eq(50.0_f32)
      end
    end

    it "returns nil for empty selection" do
      manager = PaceEditor::Core::SelectionManager(String).new
      bounds_proc = ->(item : String) { RL::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: 0.0_f32, height: 0.0_f32) }
      bounds = manager.get_selection_bounds(bounds_proc)
      bounds.should be_nil
    end
  end

  describe "#filter_selection" do
    it "filters selected items" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select_multiple(["item1", "item22", "item3"])

      filtered = manager.filter_selection(->(item : String) { item.size > 5 })
      filtered.should contain("item22")
      filtered.should_not contain("item1")
      filtered.should_not contain("item3")
    end
  end

  describe "#find_in_selection" do
    it "finds item in selection" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select_multiple(["item1", "item22", "item3"])

      found = manager.find_in_selection(->(item : String) { item.size > 5 })
      found.should eq("item22")
    end

    it "returns nil if not found" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select_multiple(["item1", "item2"])

      found = manager.find_in_selection(->(item : String) { item.size > 10 })
      found.should be_nil
    end
  end

  describe "#get_selection_info" do
    it "returns selection statistics" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select_multiple(["item1", "item2"])
      manager.max_selection_count = 10

      info = manager.get_selection_info
      info["count"].should eq(2)
      info["max_count"].should eq(10)
      info["multi_select"].should eq("enabled")
      info["primary"].should eq("set")
    end
  end

  describe "serialization" do
    it "serializes and deserializes selection" do
      manager = PaceEditor::Core::SelectionManager(String).new
      manager.select_multiple(["item1", "item3"])
      manager.set_primary("item3")

      serializer = ->(item : String) { item }
      deserializer = ->(id : String) { id }

      hash = manager.to_hash(serializer)

      new_manager = PaceEditor::Core::SelectionManager(String).new
      new_manager.from_hash(hash, deserializer)

      new_manager.selected?("item1").should be_true
      new_manager.selected?("item3").should be_true
      new_manager.primary_selection.should eq("item3")
    end
  end

  describe "selection callbacks" do
    it "calls selection changed callback" do
      manager = PaceEditor::Core::SelectionManager(String).new
      callback_called = false
      callback_items = [] of String

      manager.on_selection_changed do |items|
        callback_called = true
        callback_items = items
      end

      manager.select("item1")

      callback_called.should be_true
      callback_items.should contain("item1")
    end

    it "calls primary changed callback" do
      manager = PaceEditor::Core::SelectionManager(String).new
      callback_called = false
      callback_primary : String? = nil

      manager.on_primary_changed do |primary|
        callback_called = true
        callback_primary = primary
      end

      manager.select("item1")

      callback_called.should be_true
      callback_primary.should eq("item1")
    end
  end
end

describe PaceEditor::Core::StringSelectionManager do
  it "creates string-based selection manager" do
    manager = PaceEditor::Core::StringSelectionManager.new
    manager.should be_a(PaceEditor::Core::SelectionManager(String))
  end
end

describe PaceEditor::Core::HotspotSelectionManager do
  it "creates hotspot selection manager" do
    manager = PaceEditor::Core::HotspotSelectionManager.new
    manager.should be_a(PaceEditor::Core::SelectionManager(String))
    manager.max_selection_count.should eq(PaceEditor::Constants::MAX_SCENE_OBJECTS)
  end
end

describe PaceEditor::Core::CharacterSelectionManager do
  it "creates character selection manager" do
    manager = PaceEditor::Core::CharacterSelectionManager.new
    manager.should be_a(PaceEditor::Core::SelectionManager(String))
    manager.max_selection_count.should eq(PaceEditor::Constants::MAX_SCENE_OBJECTS)
  end
end

describe PaceEditor::Core::DialogNodeSelectionManager do
  it "creates dialog node selection manager" do
    manager = PaceEditor::Core::DialogNodeSelectionManager.new
    manager.should be_a(PaceEditor::Core::SelectionManager(String))
    manager.max_selection_count.should eq(50)
  end
end