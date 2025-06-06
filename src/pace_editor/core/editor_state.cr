module PaceEditor::Core
  # Manages the global state of the editor
  class EditorState
    property current_project : Project?
    property current_mode : EditorMode = EditorMode::Scene
    property current_tool : Tool = Tool::Select
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

    def initialize
    end

    def has_project? : Bool
      !@current_project.nil?
    end

    def current_scene : PointClickEngine::Scene?
      return nil unless project = @current_project
      return nil unless scene_name = project.current_scene

      scene_path = project.get_scene_file_path(scene_name)
      return nil unless File.exists?(scene_path)

      PointClickEngine::Scene.from_yaml(File.read(scene_path))
    rescue
      nil
    end

    def save_current_scene(scene : PointClickEngine::Scene)
      return unless project = @current_project
      return unless scene_name = project.current_scene

      scene_path = project.get_scene_file_path(scene_name)
      File.write(scene_path, scene.to_yaml)
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
    def initialize(@object_name : String, @old_pos : RL::Vector2, @new_pos : RL::Vector2)
    end

    def undo
      # Implementation would move object back to old position
    end

    def redo
      # Implementation would move object to new position
    end

    def description : String
      "Move #{@object_name}"
    end
  end

  class CreateObjectAction < EditorAction
    def initialize(@object_name : String, @object_data : String)
    end

    def undo
      # Implementation would delete the object
    end

    def redo
      # Implementation would recreate the object
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
end
