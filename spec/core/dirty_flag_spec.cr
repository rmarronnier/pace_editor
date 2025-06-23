require "../spec_helper"

# Test class that includes DirtyFlag
class TestDirtyObject
  include PaceEditor::Core::DirtyFlag

  property name : String

  def initialize(@name : String = "test")
  end
end

describe PaceEditor::Core::DirtyFlag do
  describe "initialization" do
    it "starts in dirty state" do
      obj = TestDirtyObject.new("test_object")
      obj.dirty?.should be_true
      obj.needs_redraw?.should be_true
    end

    it "initializes other flags as false" do
      obj = TestDirtyObject.new("test_object")
      obj.children_dirty?.should be_false
      obj.transform_dirty?.should be_false
      obj.content_dirty?.should be_false
      obj.style_dirty?.should be_false
      obj.force_redraw?.should be_false
    end
  end

  describe "#mark_dirty" do
    it "marks object as dirty" do
      obj = TestDirtyObject.new("test_object")
      obj.clean # Start with clean state

      obj.mark_dirty

      obj.dirty?.should be_true
      obj.needs_redraw?.should be_true
    end

    it "propagates up to parent" do
      obj = TestDirtyObject.new("test_object")
      parent = TestDirtyObject.new("parent")
      obj.dirty_parent = parent
      parent.clean
      obj.clean

      obj.mark_dirty(propagate_up: true)

      parent.children_dirty?.should be_true
    end

    it "propagates down to children" do
      obj = TestDirtyObject.new("test_object")
      child = TestDirtyObject.new("child")
      obj.add_dirty_child(child)
      child.clean
      obj.clean

      obj.mark_dirty(propagate_up: false, propagate_down: true)

      child.dirty?.should be_true
    end
  end

  describe "#mark_children_dirty" do
    it "marks children as dirty without marking self" do
      obj = TestDirtyObject.new("test_object")
      obj.clean
      obj.mark_children_dirty

      obj.dirty?.should be_false
      obj.children_dirty?.should be_true
      obj.needs_redraw?.should be_true
    end
  end

  describe "specific dirty markers" do
    describe "#mark_transform_dirty" do
      it "marks transform as dirty and object as dirty" do
        obj = TestDirtyObject.new("test_object")
        obj.clean
        obj.mark_transform_dirty

        obj.transform_dirty?.should be_true
        obj.dirty?.should be_true
      end
    end

    describe "#mark_content_dirty" do
      it "marks content as dirty and object as dirty" do
        obj = TestDirtyObject.new("test_object")
        obj.clean
        obj.mark_content_dirty

        obj.content_dirty?.should be_true
        obj.dirty?.should be_true
      end
    end

    describe "#mark_style_dirty" do
      it "marks style as dirty and object as dirty" do
        obj = TestDirtyObject.new("test_object")
        obj.clean
        obj.mark_style_dirty

        obj.style_dirty?.should be_true
        obj.dirty?.should be_true
      end
    end
  end

  describe "#force_redraw" do
    it "forces redraw even if clean" do
      obj = TestDirtyObject.new("test_object")
      obj.clean
      obj.force_redraw

      obj.force_redraw?.should be_true
      obj.needs_redraw?.should be_true
    end
  end

  describe "#clean" do
    it "clears all dirty flags" do
      obj = TestDirtyObject.new("test_object")
      obj.mark_dirty
      obj.mark_transform_dirty
      obj.mark_content_dirty
      obj.mark_style_dirty
      obj.mark_children_dirty
      obj.force_redraw

      obj.clean

      obj.dirty?.should be_false
      obj.children_dirty?.should be_false
      obj.transform_dirty?.should be_false
      obj.content_dirty?.should be_false
      obj.style_dirty?.should be_false
      obj.force_redraw?.should be_false
    end

    it "sets last draw time" do
      obj = TestDirtyObject.new("test_object")
      obj.clean
      obj.time_since_last_draw.should_not be_nil
    end
  end

  describe "hierarchy management" do
    describe "#add_dirty_child" do
      it "adds child and sets parent reference" do
        obj = TestDirtyObject.new("test_object")
        child = TestDirtyObject.new("child")
        obj.add_dirty_child(child)

        child.dirty_parent.should eq(obj)
      end
    end

    describe "#remove_dirty_child" do
      it "removes child and clears parent reference" do
        obj = TestDirtyObject.new("test_object")
        child = TestDirtyObject.new("child")
        obj.add_dirty_child(child)
        obj.remove_dirty_child(child)

        child.dirty_parent.should be_nil
      end
    end

    describe "#clear_dirty_children" do
      it "removes all children and clears their parent references" do
        obj = TestDirtyObject.new("test_object")
        child1 = TestDirtyObject.new("child1")
        child2 = TestDirtyObject.new("child2")

        obj.add_dirty_child(child1)
        obj.add_dirty_child(child2)

        obj.clear_dirty_children

        child1.dirty_parent.should be_nil
        child2.dirty_parent.should be_nil
      end
    end
  end

  describe "performance tracking" do
    describe "#time_since_last_draw" do
      it "returns nil before first draw" do
        obj = TestDirtyObject.new("test_object")
        obj.time_since_last_draw.should be_nil
      end

      it "returns time span after cleaning" do
        obj = TestDirtyObject.new("test_object")
        obj.clean
        sleep 0.001 # Small delay

        time_span = obj.time_since_last_draw
        time_span.should_not be_nil
        time_span.not_nil!.total_milliseconds.should be > 0
      end
    end

    describe "frame skip tracking" do
      it "increments frame skip count" do
        obj = TestDirtyObject.new("test_object")
        initial_count = obj.frame_skip_count
        obj.increment_frame_skip

        obj.frame_skip_count.should eq(initial_count + 1)
      end

      it "resets frame skip count" do
        obj = TestDirtyObject.new("test_object")
        obj.increment_frame_skip
        obj.increment_frame_skip
        obj.reset_frame_skip

        obj.frame_skip_count.should eq(0_u32)
      end
    end
  end

  describe "#draw_if_dirty" do
    it "executes block when dirty" do
      obj = TestDirtyObject.new("test_object")
      obj.mark_dirty
      block_executed = false

      obj.draw_if_dirty do
        block_executed = true
      end

      block_executed.should be_true
      obj.dirty?.should be_false # Should be cleaned after drawing
    end

    it "skips block when clean" do
      obj = TestDirtyObject.new("test_object")
      obj.clean
      block_executed = false

      obj.draw_if_dirty do
        block_executed = true
      end

      block_executed.should be_false
    end

    it "executes block when frame skip threshold is reached" do
      obj = TestDirtyObject.new("test_object")
      obj.clean
      skip_threshold = 2_u32
      block_executed = false

      # Skip twice to reach threshold
      obj.draw_if_dirty(skip_threshold) { }
      obj.draw_if_dirty(skip_threshold) { }

      # Third time should execute
      obj.draw_if_dirty(skip_threshold) do
        block_executed = true
      end

      block_executed.should be_true
      obj.frame_skip_count.should eq(0_u32) # Should be reset
    end
  end

  describe "#with_dirty_batching" do
    it "batches dirty operations" do
      obj = TestDirtyObject.new("test_object")
      obj.clean

      obj.with_dirty_batching do
        obj.mark_content_dirty
        obj.mark_style_dirty
        # These shouldn't trigger immediate dirty propagation
      end

      obj.dirty?.should be_true
    end
  end

  describe "#dirty_state_info" do
    it "returns comprehensive state information" do
      obj = TestDirtyObject.new("test_object")
      child = TestDirtyObject.new("child")
      obj.mark_dirty
      obj.mark_transform_dirty
      obj.add_dirty_child(child)
      obj.increment_frame_skip

      info = obj.dirty_state_info

      info["dirty"].should be_true
      info["transform_dirty"].should be_true
      info["frame_skip_count"].should eq(1_u32)
      info["children_count"].should eq(1_u32)
    end
  end

  describe "utility methods" do
    describe "#mark_geometry_dirty" do
      it "marks transform as dirty" do
        obj = TestDirtyObject.new("test_object")
        obj.clean
        obj.mark_geometry_dirty
        obj.transform_dirty?.should be_true
      end
    end

    describe "#mark_visual_dirty" do
      it "marks content and style as dirty" do
        obj = TestDirtyObject.new("test_object")
        obj.clean
        obj.mark_visual_dirty

        obj.content_dirty?.should be_true
        obj.style_dirty?.should be_true
      end
    end

    describe "#mark_completely_dirty" do
      it "marks all aspects as dirty" do
        obj = TestDirtyObject.new("test_object")
        obj.clean
        obj.mark_completely_dirty

        obj.dirty?.should be_true
        obj.transform_dirty?.should be_true
        obj.content_dirty?.should be_true
        obj.style_dirty?.should be_true
      end
    end
  end
end

describe PaceEditor::Core::DirtyTracker do
  describe "#initialize" do
    it "creates tracker with name" do
      tracker = PaceEditor::Core::DirtyTracker.new("test_tracker")
      tracker.name.should eq("test_tracker")
      tracker.dirty?.should be_true
    end

    it "creates unnamed tracker" do
      unnamed = PaceEditor::Core::DirtyTracker.new
      unnamed.name.should eq("unnamed")
    end
  end

  describe "#to_s" do
    it "provides readable string representation" do
      tracker = PaceEditor::Core::DirtyTracker.new("test_tracker")
      string_repr = tracker.to_s
      string_repr.should contain("DirtyTracker")
      string_repr.should contain("test_tracker")
      string_repr.should contain("dirty=true")
    end
  end
end

describe PaceEditor::Core::DirtyFlagManager do
  describe "#track and #untrack" do
    it "tracks dirty objects" do
      manager = PaceEditor::Core::DirtyFlagManager.new
      object1 = PaceEditor::Core::DirtyTracker.new("object1")
      object2 = PaceEditor::Core::DirtyTracker.new("object2")

      manager.track(object1)
      manager.track(object2)

      stats = manager.get_stats
      stats["tracked_objects"].should eq(2_u64)
    end

    it "untracks dirty objects" do
      manager = PaceEditor::Core::DirtyFlagManager.new
      object1 = PaceEditor::Core::DirtyTracker.new("object1")
      object2 = PaceEditor::Core::DirtyTracker.new("object2")

      manager.track(object1)
      manager.track(object2)
      manager.untrack(object1)

      stats = manager.get_stats
      stats["tracked_objects"].should eq(1_u64)
    end
  end

  describe "#update_frame" do
    it "updates frame statistics" do
      manager = PaceEditor::Core::DirtyFlagManager.new
      object1 = PaceEditor::Core::DirtyTracker.new("object1")
      object2 = PaceEditor::Core::DirtyTracker.new("object2")

      manager.track(object1)
      object1.clean          # Make it clean
      manager.track(object2) # Keep dirty

      manager.update_frame

      stats = manager.get_stats
      stats["frame_count"].should eq(1_u64)
      stats["total_redraws"].should eq(1_u64)  # Only object2 is dirty
      stats["skipped_frames"].should eq(1_u64) # object1 was clean
    end
  end

  describe "#clean_all" do
    it "cleans all tracked objects" do
      manager = PaceEditor::Core::DirtyFlagManager.new
      object1 = PaceEditor::Core::DirtyTracker.new("object1")
      object2 = PaceEditor::Core::DirtyTracker.new("object2")

      manager.track(object1)
      manager.track(object2)

      manager.clean_all

      object1.dirty?.should be_false
      object2.dirty?.should be_false
    end
  end

  describe "#mark_all_dirty" do
    it "marks all tracked objects as dirty" do
      manager = PaceEditor::Core::DirtyFlagManager.new
      object1 = PaceEditor::Core::DirtyTracker.new("object1")
      object2 = PaceEditor::Core::DirtyTracker.new("object2")

      manager.track(object1)
      manager.track(object2)

      object1.clean
      object2.clean

      manager.mark_all_dirty

      object1.dirty?.should be_true
      object2.dirty?.should be_true
    end
  end

  describe "#get_stats" do
    it "calculates performance statistics" do
      manager = PaceEditor::Core::DirtyFlagManager.new
      object1 = PaceEditor::Core::DirtyTracker.new("object1")
      object2 = PaceEditor::Core::DirtyTracker.new("object2")

      manager.track(object1)
      manager.track(object2)

      # Simulate some frame updates
      object1.clean
      manager.update_frame # 1 dirty, 1 clean
      manager.update_frame # 1 dirty, 1 clean

      stats = manager.get_stats
      stats["frame_count"].should eq(2_u64)
      stats["total_redraws"].should eq(2_u64)
      stats["skipped_frames"].should eq(2_u64)
      stats["redraw_rate_percent"].should eq(50.0) # 2 redraws / 2 frames
      stats["skip_rate_percent"].should eq(50.0)   # 2 skips / (2 frames * 2 objects)
    end
  end

  describe "#get_dirty_objects and #get_clean_objects" do
    it "separates dirty and clean objects" do
      manager = PaceEditor::Core::DirtyFlagManager.new
      object1 = PaceEditor::Core::DirtyTracker.new("object1")
      object2 = PaceEditor::Core::DirtyTracker.new("object2")

      manager.track(object1)
      manager.track(object2)

      object1.clean
      # object2 remains dirty

      dirty_objects = manager.get_dirty_objects
      clean_objects = manager.get_clean_objects

      dirty_objects.should contain(object2)
      dirty_objects.should_not contain(object1)

      clean_objects.should contain(object1)
      clean_objects.should_not contain(object2)
    end
  end

  describe "#reset_stats" do
    it "resets all statistics" do
      manager = PaceEditor::Core::DirtyFlagManager.new
      object1 = PaceEditor::Core::DirtyTracker.new("object1")

      manager.track(object1)
      manager.update_frame

      stats_before = manager.get_stats
      stats_before["frame_count"].should eq(1_u64)

      manager.reset_stats

      stats_after = manager.get_stats
      stats_after["frame_count"].should eq(0_u64)
      stats_after["total_redraws"].should eq(0_u64)
      stats_after["skipped_frames"].should eq(0_u64)
    end
  end
end

describe "Global dirty manager" do
  describe ".dirty_manager" do
    it "returns global manager instance" do
      manager1 = PaceEditor::Core.dirty_manager
      manager2 = PaceEditor::Core.dirty_manager

      manager1.should eq(manager2)
    end
  end

  describe ".track_dirty and .untrack_dirty" do
    it "tracks objects globally" do
      object = PaceEditor::Core::DirtyTracker.new("global_test")

      PaceEditor::Core.track_dirty(object)

      stats = PaceEditor::Core.dirty_manager.get_stats
      stats["tracked_objects"].should be >= 1_u64

      # Clean up global state
      PaceEditor::Core.untrack_dirty(object)
    end

    it "untracks objects globally" do
      object = PaceEditor::Core::DirtyTracker.new("global_test")

      PaceEditor::Core.track_dirty(object)
      initial_count = PaceEditor::Core.dirty_manager.get_stats["tracked_objects"]

      PaceEditor::Core.untrack_dirty(object)

      final_count = PaceEditor::Core.dirty_manager.get_stats["tracked_objects"]
      final_count.should eq(initial_count - 1)
    end
  end
end
