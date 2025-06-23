module PaceEditor::Core
  # Manages the global state of the editor
  class EditorState
    property current_project : Project?
    property current_mode : EditorMode = EditorMode::Scene
    property current_tool : Tool = Tool::Select
    property current_scene : PointClickEngine::Scenes::Scene?
    property selected_object : String?
    property camera_x : Float32 = 0.0f32
    property camera_y : Float32 = 0.0f32
    property zoom : Float32 = 1.0f32
    property grid_size : Int32 = 16
    property snap_to_grid : Bool = true
    property show_grid : Bool = true
    property show_hotspots : Bool = true
    property show_character_bounds : Bool = true

    # Undo/Redo system
    @undo_stack : Array(EditorAction) = [] of EditorAction
    @redo_stack : Array(EditorAction) = [] of EditorAction
    @max_undo_levels : Int32 = 50

    # Selection state
    property selected_hotspots : Array(String) = [] of String
    property selected_characters : Array(String) = [] of String
    property clipboard : String?

    # Additional workflow properties
    # Note: undo_stack and redo_stack are already defined above as Array(EditorAction)
    property selected_character : String?
    property is_dirty : Bool = false
    property dragging : Bool = false
    property drag_data : String?
    property drag_type : String?
    property show_new_project_dialog : Bool = false
    property new_project_name : String = ""
    property new_project_path : String = ""
    property focused_panel : String = "scene_editor"
    property text_input_active : Bool = false
    property active_text_field : String?
    property frame_time : Float32 = 16.67f32
    property fps : Int32 = 60
    property loaded_textures : Int32 = 0
    property loaded_sounds : Int32 = 0
    property memory_usage : Int64 = 0_i64
    property auto_save : Bool = true
    property auto_save_interval : Int32 = 300
    property editor_mode : EditorMode = EditorMode::Scene
    
    # Reference to the main editor window (set after initialization)
    property editor_window : EditorWindow?
    
    # Editor references
    property dialog_editor : Editors::DialogEditor?

    def initialize
    end

    def has_project? : Bool
      !@current_project.nil?
    end


    def save_current_scene(scene : PointClickEngine::Scenes::Scene)
      return unless project = @current_project
      
      scene_path = IO::SceneIO.get_scene_file_path(project, scene.name)
      IO::SceneIO.save_scene(scene, scene_path)
    end

    def create_new_project(name : String, path : String) : Bool
      begin
        @current_project = Project.create_new(name, path)
        @current_mode = EditorMode::Scene
        clear_selection
        true
      rescue ex
        puts "Failed to create project: #{ex.message}"
        false
      end
    end

    def load_project(project_file : String) : Bool
      begin
        @current_project = Project.load(project_file)
        @current_mode = EditorMode::Scene
        clear_selection
        true
      rescue ex
        puts "Failed to load project: #{ex.message}"
        false
      end
    end

    def save_project
      @current_project.try(&.save)
    end

    def create_new_project(name : String, path : String) : Bool
      begin
        @current_project = Project.create_new(name, path)
        @current_mode = EditorMode::Scene
        clear_selection
        
        # Create a default scene
        scene = PointClickEngine::Scenes::Scene.new("main")
        scene.hotspots = [] of PointClickEngine::Scenes::Hotspot
        scene.characters = [] of PointClickEngine::Characters::Character
        @current_scene = scene
        
        # Add scene to project
        @current_project.not_nil!.add_scene("main.yml")
        
        # Save the project
        save_project
        true
      rescue ex
        puts "Failed to create project: #{ex.message}"
        false
      end
    end

    def add_undo_action(action : EditorAction)
      @undo_stack << action
      @undo_stack.shift if @undo_stack.size > @max_undo_levels
      @redo_stack.clear
    end

    def undo : Bool
      return false if @undo_stack.empty?

      action = @undo_stack.pop
      action.undo
      @redo_stack << action
      true
    end

    def redo : Bool
      return false if @redo_stack.empty?

      action = @redo_stack.pop
      action.redo
      @undo_stack << action
      true
    end

    def can_undo? : Bool
      !@undo_stack.empty?
    end

    def can_redo? : Bool
      !@redo_stack.empty?
    end

    def clear_selection
      @selected_object = nil
      @selected_hotspots.clear
      @selected_characters.clear
    end

    # Undo/Redo support
    def push_undo_state(description : String)
      # For workflow tests, we'll create a simple action
      action = SimpleAction.new(description)
      add_undo_action(action)
    end

    # Dirty state management
    def mark_dirty
      @is_dirty = true
    end

    def clear_dirty
      @is_dirty = false
    end

    # Modal state checks
    def has_modal_open? : Bool
      @show_new_project_dialog
    end

    def modal_blocks_input? : Bool
      has_modal_open?
    end

    def is_selected?(object_name : String) : Bool
      @selected_object == object_name ||
        @selected_hotspots.includes?(object_name) ||
        @selected_characters.includes?(object_name)
    end

    def select_object(object_name : String, multi_select : Bool = false)
      unless multi_select
        clear_selection
      end

      @selected_object = object_name
    end

    def world_to_screen(world_pos : RL::Vector2) : RL::Vector2
      RL::Vector2.new(
        x: (world_pos.x - @camera_x) * @zoom,
        y: (world_pos.y - @camera_y) * @zoom
      )
    end

    def screen_to_world(screen_pos : RL::Vector2) : RL::Vector2
      RL::Vector2.new(
        x: screen_pos.x / @zoom + @camera_x,
        y: screen_pos.y / @zoom + @camera_y
      )
    end

    def snap_to_grid(pos : RL::Vector2) : RL::Vector2
      return pos unless @snap_to_grid

      RL::Vector2.new(
        x: (pos.x / @grid_size).round * @grid_size,
        y: (pos.y / @grid_size).round * @grid_size
      )
    end

    def set_zoom(new_zoom : Float32)
      @zoom = [0.1f32, [5.0f32, new_zoom].min].max
    end

    def zoom_in
      set_zoom(@zoom * 1.2f32)
    end

    def zoom_out
      set_zoom(@zoom / 1.2f32)
    end

    def reset_camera
      @camera_x = 0.0f32
      @camera_y = 0.0f32
      @zoom = 1.0f32
    end
  end

  # Base class for undo/redo actions
  abstract class EditorAction
    abstract def undo
    abstract def redo
    abstract def description : String
  end

  # Specific action implementations
  class MoveObjectAction < EditorAction
    def initialize(@object_name : String, @old_pos : RL::Vector2, @new_pos : RL::Vector2, @editor_state : EditorState)
    end

    def undo
      return unless scene = @editor_state.current_scene
      
      # Find and move the object back to old position
      if hotspot = scene.hotspots.find { |h| h.name == @object_name }
        hotspot.position = @old_pos
      elsif character = scene.characters.find { |c| c.name == @object_name }
        character.position = @old_pos
      end
      
      # Auto-save scene after undo
      if project = @editor_state.current_project
        scene_filename = "#{scene.name}.yml"
        scene_path = File.join(project.scenes_path, scene_filename)
        PaceEditor::IO::SceneIO.save_scene(scene, scene_path)
      end
      
      # Mark as dirty
      @editor_state.mark_dirty
    end

    def redo
      return unless scene = @editor_state.current_scene
      
      # Find and move the object to new position
      if hotspot = scene.hotspots.find { |h| h.name == @object_name }
        hotspot.position = @new_pos
      elsif character = scene.characters.find { |c| c.name == @object_name }
        character.position = @new_pos
      end
      
      # Auto-save scene after redo
      if project = @editor_state.current_project
        scene_filename = "#{scene.name}.yml"
        scene_path = File.join(project.scenes_path, scene_filename)
        PaceEditor::IO::SceneIO.save_scene(scene, scene_path)
      end
    end

    def description : String
      "Move #{@object_name}"
    end
  end

  class CreateObjectAction < EditorAction
    def initialize(@object_name : String, @object_type : String, @position : RL::Vector2, @editor_state : EditorState)
      @object_type = object_type
      @position = position
    end

    def undo
      return unless scene = @editor_state.current_scene
      
      # Remove the created object
      case @object_type
      when "hotspot"
        scene.hotspots.reject! { |h| h.name == @object_name }
      when "character"
        scene.characters.reject! { |c| c.name == @object_name }
      end
      
      # Clear selection if this object was selected
      if @editor_state.selected_object == @object_name
        @editor_state.selected_object = nil
      end
      
      # Auto-save scene
      if project = @editor_state.current_project
        scene_filename = "#{scene.name}.yml"
        scene_path = File.join(project.scenes_path, scene_filename)
        PaceEditor::IO::SceneIO.save_scene(scene, scene_path)
      end
    end

    def redo
      return unless scene = @editor_state.current_scene
      
      # Recreate the object
      case @object_type
      when "hotspot"
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          name: @object_name,
          position: @position,
          size: RL::Vector2.new(64.0_f32, 64.0_f32)
        )
        hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
        hotspot.visible = true
        hotspot.description = "New hotspot"
        scene.hotspots << hotspot
      when "character"
        character = PointClickEngine::Characters::NPC.new(
          @object_name,
          @position,
          RL::Vector2.new(32.0_f32, 64.0_f32)
        )
        character.description = "New character"
        character.walking_speed = 100.0_f32
        character.state = PointClickEngine::Characters::CharacterState::Idle
        character.direction = PointClickEngine::Characters::Direction::Right
        character.mood = PointClickEngine::Characters::NPCMood::Neutral
        scene.characters << character
      end
      
      # Select the recreated object
      @editor_state.selected_object = @object_name
      
      # Auto-save scene
      if project = @editor_state.current_project
        scene_filename = "#{scene.name}.yml"
        scene_path = File.join(project.scenes_path, scene_filename)
        PaceEditor::IO::SceneIO.save_scene(scene, scene_path)
      end
    end

    def description : String
      "Create #{@object_name}"
    end
  end

  class DeleteObjectAction < EditorAction
    def initialize(@object_name : String, @object_data : String)
    end

    def undo
      # Implementation would recreate the object
    end

    def redo
      # Implementation would delete the object
    end

    def description : String
      "Delete #{@object_name}"
    end
  end

  # Simple action for testing
  class SimpleAction < EditorAction
    def initialize(@description : String)
    end

    def undo
      # No-op for tests
    end

    def redo
      # No-op for tests
    end

    def description : String
      @description
    end
  end
end
