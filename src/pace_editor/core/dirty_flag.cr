module PaceEditor::Core
  # Mixin module for implementing dirty flag pattern for rendering optimization
  module DirtyFlag
    # Core dirty state
    @dirty : Bool = true
    @children_dirty : Bool = false
    @force_redraw : Bool = false
    
    # Dirty tracking for specific components
    @transform_dirty : Bool = false
    @content_dirty : Bool = false
    @style_dirty : Bool = false
    
    # Performance tracking
    @last_draw_time : Time? = nil
    @frame_skip_count : UInt32 = 0_u32
    
    # Parent-child relationships for dirty propagation
    property dirty_parent : DirtyFlag? = nil
    @dirty_children = Set(DirtyFlag).new
    
    # Mark this object as dirty
    def mark_dirty(propagate_up : Bool = true, propagate_down : Bool = false)
      return if @dirty && !@force_redraw
      
      @dirty = true
      @last_draw_time = nil
      
      # Propagate up to parent
      if propagate_up && (parent = @dirty_parent)
        parent.mark_children_dirty
      end
      
      # Propagate down to children
      if propagate_down
        @dirty_children.each(&.mark_dirty(propagate_up: false, propagate_down: true))
      end
    end
    
    # Mark children as dirty without marking self
    def mark_children_dirty
      @children_dirty = true
      
      # Propagate to parent if we weren't already dirty
      unless @dirty
        if parent = @dirty_parent
          parent.mark_children_dirty
        end
      end
    end
    
    # Mark specific component types as dirty
    def mark_transform_dirty
      @transform_dirty = true
      mark_dirty
    end
    
    def mark_content_dirty
      @content_dirty = true
      mark_dirty
    end
    
    def mark_style_dirty
      @style_dirty = true
      mark_dirty
    end
    
    # Force redraw on next frame regardless of dirty state
    def force_redraw
      @force_redraw = true
      @dirty = true
      @last_draw_time = nil
    end
    
    # Clean the dirty state after drawing
    def clean
      @dirty = false
      @children_dirty = false
      @force_redraw = false
      @transform_dirty = false
      @content_dirty = false
      @style_dirty = false
      @last_draw_time = Time.utc
    end
    
    # Check if object needs redrawing
    def needs_redraw? : Bool
      @dirty || @children_dirty || @force_redraw
    end
    
    # Check specific dirty states
    def dirty? : Bool
      @dirty
    end
    
    def children_dirty? : Bool
      @children_dirty
    end
    
    def transform_dirty? : Bool
      @transform_dirty
    end
    
    def content_dirty? : Bool
      @content_dirty
    end
    
    def style_dirty? : Bool
      @style_dirty
    end
    
    def force_redraw? : Bool
      @force_redraw
    end
    
    # Hierarchy management
    def add_dirty_child(child : DirtyFlag)
      @dirty_children.add(child)
      child.dirty_parent = self
    end
    
    def remove_dirty_child(child : DirtyFlag)
      @dirty_children.delete(child)
      child.dirty_parent = nil
    end
    
    def clear_dirty_children
      @dirty_children.each { |child| child.dirty_parent = nil }
      @dirty_children.clear
    end
    
    # Performance metrics
    def time_since_last_draw : Time::Span?
      if last_time = @last_draw_time
        Time.utc - last_time
      else
        nil
      end
    end
    
    def increment_frame_skip
      @frame_skip_count += 1
    end
    
    def reset_frame_skip
      @frame_skip_count = 0_u32
    end
    
    def frame_skip_count : UInt32
      @frame_skip_count
    end
    
    # Conditional drawing based on dirty state and performance
    def draw_if_dirty(skip_threshold : UInt32 = 0_u32, &block)
      if needs_redraw? || @frame_skip_count >= skip_threshold
        yield
        clean
        reset_frame_skip
      else
        increment_frame_skip
      end
    end
    
    # Batch dirty operations
    def with_dirty_batching(&block)
      old_dirty = @dirty
      @dirty = false  # Suppress dirty notifications during batch
      
      yield
      
      # Restore and mark dirty if any changes occurred
      if @dirty || !old_dirty
        @dirty = true
        mark_dirty(propagate_up: true, propagate_down: false)
      else
        @dirty = old_dirty
      end
    end
    
    # Debug information
    def dirty_state_info : Hash(String, Bool | UInt32 | String?)
      {
        "dirty" => @dirty,
        "children_dirty" => @children_dirty,
        "transform_dirty" => @transform_dirty,
        "content_dirty" => @content_dirty,
        "style_dirty" => @style_dirty,
        "force_redraw" => @force_redraw,
        "frame_skip_count" => @frame_skip_count,
        "children_count" => @dirty_children.size.to_u32,
        "last_draw" => @last_draw_time ? @last_draw_time.to_s : nil
      }
    end
    
    # Utility methods for common dirty scenarios
    def mark_geometry_dirty
      mark_transform_dirty
    end
    
    def mark_visual_dirty
      mark_content_dirty
      mark_style_dirty
    end
    
    def mark_completely_dirty
      mark_dirty
      mark_transform_dirty
      mark_content_dirty
      mark_style_dirty
    end
  end
  
  # Concrete implementation for objects that need dirty tracking
  class DirtyTracker
    include DirtyFlag
    
    property name : String
    
    def initialize(@name : String = "unnamed")
    end
    
    def to_s(io : IO) : Nil
      io << "DirtyTracker(#{@name}, dirty=#{@dirty})"
    end
  end
  
  # Manager for coordinating dirty flags across multiple objects
  class DirtyFlagManager
    @tracked_objects = Set(DirtyFlag).new
    @frame_count : UInt64 = 0_u64
    @total_redraws : UInt64 = 0_u64
    @skipped_frames : UInt64 = 0_u64
    
    # Register object for tracking
    def track(object : DirtyFlag)
      @tracked_objects.add(object)
    end
    
    # Unregister object
    def untrack(object : DirtyFlag)
      @tracked_objects.delete(object)
    end
    
    # Update all tracked objects
    def update_frame
      @frame_count += 1
      
      dirty_count = 0
      @tracked_objects.each do |object|
        if object.needs_redraw?
          dirty_count += 1
        end
      end
      
      @total_redraws += dirty_count
      @skipped_frames += (@tracked_objects.size - dirty_count)
    end
    
    # Force clean all objects
    def clean_all
      @tracked_objects.each(&.clean)
    end
    
    # Force dirty all objects
    def mark_all_dirty
      @tracked_objects.each(&.mark_dirty(propagate_up: false))
    end
    
    # Get performance statistics
    def get_stats : Hash(String, UInt64 | Float64)
      redraw_rate = if @frame_count > 0
        (@total_redraws.to_f64 / @frame_count) * 100
      else
        0.0
      end
      
      skip_rate = if @frame_count > 0
        (@skipped_frames.to_f64 / (@frame_count * @tracked_objects.size)) * 100
      else
        0.0
      end
      
      {
        "tracked_objects" => @tracked_objects.size.to_u64,
        "frame_count" => @frame_count,
        "total_redraws" => @total_redraws,
        "skipped_frames" => @skipped_frames,
        "redraw_rate_percent" => redraw_rate,
        "skip_rate_percent" => skip_rate
      }
    end
    
    # Debug information
    def get_dirty_objects : Array(DirtyFlag)
      @tracked_objects.select(&.needs_redraw?).to_a
    end
    
    def get_clean_objects : Array(DirtyFlag)
      @tracked_objects.reject(&.needs_redraw?).to_a
    end
    
    # Reset statistics
    def reset_stats
      @frame_count = 0_u64
      @total_redraws = 0_u64
      @skipped_frames = 0_u64
    end
  end
  
  # Global dirty flag manager instance
  @@global_dirty_manager : DirtyFlagManager? = nil
  
  # Access global dirty manager
  def self.dirty_manager : DirtyFlagManager
    @@global_dirty_manager ||= DirtyFlagManager.new
  end
  
  # Convenience method to track an object globally
  def self.track_dirty(object : DirtyFlag)
    dirty_manager.track(object)
  end
  
  # Convenience method to untrack an object globally
  def self.untrack_dirty(object : DirtyFlag)
    dirty_manager.untrack(object)
  end
end