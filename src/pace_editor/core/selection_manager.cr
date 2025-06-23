module PaceEditor::Core
  # Generic selection manager that can handle different types of objects
  class SelectionManager(T)
    include PaceEditor::Constants

    # Selection storage
    @selected_items : Set(T) = Set(T).new
    @primary_selection : T? = nil
    @selection_history : Array(T) = [] of T

    # Selection callbacks
    @on_selection_changed : Proc(Array(T), Nil)?
    @on_primary_changed : Proc(T?, Nil)?

    # Multi-selection settings
    property multi_select_enabled : Bool = true
    property max_selection_count : Int32 = MAX_SCENE_OBJECTS

    def initialize
    end

    # Set selection change callback
    def on_selection_changed(&block : Array(T) -> Nil)
      @on_selection_changed = block
    end

    # Set primary selection change callback
    def on_primary_changed(&block : T? -> Nil)
      @on_primary_changed = block
    end

    # Select a single item (replaces current selection)
    def select(item : T)
      select_single_item(item)
    end

    # Add an item to the current selection
    def add_to_selection(item : T)
      return if @selected_items.size >= @max_selection_count

      if @selected_items.add?(item)
        @selection_history << item

        # Set as primary if no primary selection
        if @primary_selection.nil?
          @primary_selection = item
          notify_primary_changed
        end

        notify_selection_changed
      end
    end

    # Remove an item from selection
    def remove_from_selection(item : T)
      if @selected_items.delete(item)
        @selection_history.delete(item)

        # Update primary selection if removed item was primary
        if @primary_selection == item
          @primary_selection = @selected_items.first?
          notify_primary_changed
        end

        notify_selection_changed
      end
    end

    # Toggle selection of an item
    def toggle_selection(item : T)
      if selected?(item)
        if @multi_select_enabled
          remove_from_selection(item)
        end
      else
        if @multi_select_enabled
          add_to_selection(item)
        else
          select_single_item(item)
        end
      end
    end

    # Helper method to avoid naming conflict
    private def select_single_item(item : T)
      clear_selection
      add_to_selection(item)
      set_primary(item)
      notify_selection_changed
    end

    # Clear all selections
    def clear_selection
      return if @selected_items.empty?

      @selected_items.clear
      @selection_history.clear
      @primary_selection = nil

      notify_selection_changed
      notify_primary_changed
    end

    # Set primary selection from current selection
    def set_primary(item : T)
      return unless selected?(item)

      if @primary_selection != item
        @primary_selection = item
        notify_primary_changed
      end
    end

    # Select multiple items at once
    def select_multiple(items : Array(T))
      clear_selection

      items.each do |item|
        break if @selected_items.size >= @max_selection_count
        @selected_items.add(item)
        @selection_history << item
      end

      @primary_selection = items.first? if items.any?

      notify_selection_changed
      notify_primary_changed
    end

    # Select all items from a given collection
    def select_all(items : Array(T))
      select_multiple(items.first(@max_selection_count))
    end

    # Invert selection from a given collection
    def invert_selection(all_items : Array(T))
      new_selection = all_items.reject { |item| selected?(item) }
      select_multiple(new_selection)
    end

    # Query methods
    def selected?(item : T) : Bool
      @selected_items.includes?(item)
    end

    def has_selection? : Bool
      !@selected_items.empty?
    end

    def selection_count : Int32
      @selected_items.size
    end

    def is_multi_selection? : Bool
      @selected_items.size > 1
    end

    def primary_selection : T?
      @primary_selection
    end

    def selected_items : Array(T)
      @selected_items.to_a
    end

    def last_selected : T?
      @selection_history.last?
    end

    def first_selected : T?
      @selection_history.first?
    end

    # Selection utilities
    def copy_selection : Array(T)
      @selected_items.to_a.dup
    end

    def restore_selection(items : Array(T))
      select_multiple(items)
    end

    # Selection bounds (for geometric objects with bounds)
    def get_selection_bounds(bounds_proc : Proc(T, RL::Rectangle)) : RL::Rectangle?
      return nil unless has_selection?

      bounds = @selected_items.map { |item| bounds_proc.call(item) }

      # Calculate bounding rectangle
      min_x = bounds.min_of(&.x)
      min_y = bounds.min_of(&.y)
      max_x = bounds.max_of { |b| b.x + b.width }
      max_y = bounds.max_of { |b| b.y + b.height }

      RL::Rectangle.new(x: min_x, y: min_y, width: max_x - min_x, height: max_y - min_y)
    end

    # Filter selection
    def filter_selection(predicate : Proc(T, Bool)) : Array(T)
      @selected_items.select { |item| predicate.call(item) }.to_a
    end

    # Find items in selection
    def find_in_selection(predicate : Proc(T, Bool)) : T?
      @selected_items.find { |item| predicate.call(item) }
    end

    # Selection statistics
    def get_selection_info : Hash(String, Int32 | String)
      {
        "count"        => @selected_items.size,
        "max_count"    => @max_selection_count,
        "multi_select" => @multi_select_enabled ? "enabled" : "disabled",
        "primary"      => @primary_selection ? "set" : "none",
      }
    end

    private def notify_selection_changed
      if callback = @on_selection_changed
        callback.call(@selected_items.to_a)
      end
    end

    private def notify_primary_changed
      if callback = @on_primary_changed
        callback.call(@primary_selection)
      end
    end

    # Serialization support
    def to_hash(serializer : Proc(T, String)) : Hash(String, Array(String) | String?)
      {
        "selected_items"    => @selected_items.map { |item| serializer.call(item) }.to_a,
        "primary_selection" => @primary_selection ? serializer.call(@primary_selection.not_nil!) : nil,
      }
    end

    def from_hash(hash : Hash(String, Array(String) | String?), deserializer : Proc(String, T?))
      clear_selection

      if selected_array = hash["selected_items"].as?(Array(String))
        items = selected_array.compact_map { |id| deserializer.call(id) }
        select_multiple(items)
      end

      if primary_id = hash["primary_selection"].as?(String)
        if primary_item = deserializer.call(primary_id)
          set_primary(primary_item)
        end
      end
    end
  end

  # Specialized selection managers for common types

  # String-based selection manager (for object IDs)
  class StringSelectionManager < SelectionManager(String)
    def initialize
      super
    end
  end

  # Hotspot selection manager
  class HotspotSelectionManager < SelectionManager(String)
    def initialize
      super
      @max_selection_count = MAX_SCENE_OBJECTS
    end

    def get_hotspot_bounds(hotspots : Hash(String, PointClickEngine::Scenes::Hotspot)) : RL::Rectangle?
      get_selection_bounds do |id|
        hotspot = hotspots[id]?
        if hotspot
          RL::Rectangle.new(hotspot.x.to_f32, hotspot.y.to_f32,
            hotspot.width.to_f32, hotspot.height.to_f32)
        else
          RL::Rectangle.new(0.0_f32, 0.0_f32, 0.0_f32, 0.0_f32)
        end
      end
    end
  end

  # Character selection manager
  class CharacterSelectionManager < SelectionManager(String)
    def initialize
      super
      @max_selection_count = MAX_SCENE_OBJECTS
    end

    def get_character_bounds(characters : Hash(String, PointClickEngine::Characters::Character)) : RL::Rectangle?
      get_selection_bounds do |id|
        character = characters[id]?
        if character
          # Assume character has a default size if not specified
          RL::Rectangle.new(character.x.to_f32, character.y.to_f32, 32.0_f32, 64.0_f32)
        else
          RL::Rectangle.new(0.0_f32, 0.0_f32, 0.0_f32, 0.0_f32)
        end
      end
    end
  end

  # Dialog node selection manager
  class DialogNodeSelectionManager < SelectionManager(String)
    def initialize
      super
      @max_selection_count = 50 # Reasonable limit for dialog nodes
    end
  end
end
