module PaceEditor::Core
  # Manages the global state of the editor
  class EditorState
    property current_project : Project?
    property current_mode : EditorMode = EditorMode::Scene
    property current_tool : Tool = Tool::Select
    property current_scene : PointClickEngine::Scenes::Scene?
    property selected_object : String?
    property selected_objects : Set(String) = Set(String).new
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
    property should_exit : Bool = false
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

    def save_project : Bool
      project = @current_project
      return false unless project
      project.save
    end

    def save_project_as(name : String, path : String) : Bool
      project = @current_project
      return false unless project

      begin
        # Create new project instance with new name and path
        new_project = Project.create_new(name, path)
        
        # Copy all data from current project to new project
        if current_scene = @current_scene
          # Save current scene first
          save_current_scene(current_scene)
          
          # Copy scenes
          project.scenes.each do |scene_file|
            source_path = File.join(project.scenes_path, scene_file)
            target_path = File.join(new_project.scenes_path, scene_file)
            
            if File.exists?(source_path)
              File.copy(source_path, target_path)
              new_project.add_scene(scene_file)
            end
          end
          
          # Copy assets if they exist
          if Dir.exists?(project.assets_path)
            copy_directory_recursive(project.assets_path, new_project.assets_path)
          end
          
          # Copy scripts if they exist
          if Dir.exists?(project.scripts_path)
            copy_directory_recursive(project.scripts_path, new_project.scripts_path)
          end
          
          # Copy dialogs if they exist
          if Dir.exists?(project.dialogs_path)
            copy_directory_recursive(project.dialogs_path, new_project.dialogs_path)
          end
        end
        
        # Update current project reference
        @current_project = new_project
        
        # Save the new project
        new_project.save
        true
      rescue ex
        puts "Error saving project as #{name}: #{ex.message}"
        false
      end
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
        if project = @current_project
          project.add_scene("main.yml")
        end

        # Save the scene file
        save_current_scene(scene)

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
      @selected_objects.clear
      @selected_hotspots.clear
      @selected_characters.clear
    end

    # Clean up resources from the current scene before switching
    def cleanup_current_scene
      if scene = @current_scene
        # Unload background texture if any
        if bg = scene.background
          RL.unload_texture(bg)
          scene.background = nil
        end

        # TODO: Add cleanup for character textures and other scene resources
        # scene.characters.each do |char|
        #   # Unload character sprites/textures
        # end
      end
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

      # Set primary selection only if no objects are selected yet
      if @selected_object.nil?
        @selected_object = object_name
      end

      @selected_objects.add(object_name)

      # Also add to specific type arrays based on object type
      if scene = @current_scene
        if scene.hotspots.any? { |h| h.name == object_name }
          @selected_hotspots << object_name unless @selected_hotspots.includes?(object_name)
        elsif scene.characters.any? { |c| c.name == object_name }
          @selected_characters << object_name unless @selected_characters.includes?(object_name)
        end
      end
    end

    def toggle_object_selection(object_name : String)
      if is_selected?(object_name)
        deselect_object(object_name)
      else
        select_object(object_name, multi_select: true)
      end
    end

    def deselect_object(object_name : String)
      @selected_objects.delete(object_name)
      @selected_hotspots.delete(object_name)
      @selected_characters.delete(object_name)

      # Update primary selection
      if @selected_object == object_name
        @selected_object = @selected_objects.first?
      end
    end

    def get_selected_objects : Array(String)
      @selected_objects.to_a
    end

    def has_multiple_selection? : Bool
      @selected_objects.size > 1
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

    # Scene management methods
    def duplicate_scene(scene_name : String)
      return unless project = @current_project
      return unless project.scenes.includes?(scene_name)

      # Create duplicate with new name
      new_name = "#{scene_name}_copy"
      counter = 1
      while project.scenes.includes?(new_name)
        new_name = "#{scene_name}_copy#{counter}"
        counter += 1
      end

      # TODO: Implement actual scene duplication
      puts "Duplicating scene '#{scene_name}' as '#{new_name}'"
      mark_dirty
    end

    def delete_scene(scene_name : String)
      return unless project = @current_project

      # TODO: Implement actual scene deletion
      puts "Deleting scene '#{scene_name}'"

      # If this was the current scene, clear it
      if scene = @current_scene
        if scene.name == scene_name
          @current_scene = nil
        end
      end

      mark_dirty
    end

    # Character management methods
    def add_player_character(scene : PointClickEngine::Scenes::Scene)
      # Generate unique character name
      character_count = 1
      character_name = "player_#{character_count}"
      
      while scene.characters.any? { |c| c.name == character_name }
        character_count += 1
        character_name = "player_#{character_count}"
      end
      
      # Default position (center of scene)
      position = RL::Vector2.new(400.0_f32, 300.0_f32)
      size = RL::Vector2.new(32.0_f32, 64.0_f32)
      
      # Create new Player character
      character = PointClickEngine::Characters::Player.new(
        character_name,
        position,
        size
      )
      
      # Set default properties
      character.description = "Player character"
      character.state = PointClickEngine::Characters::CharacterState::Idle
      character.direction = PointClickEngine::Characters::Direction::Down
      
      # Add to scene
      scene.characters << character
      
      # Select the new character
      @selected_object = character.name
      
      # Create undo action for creation
      action = CreateCharacterAction.new(scene, character, self)
      add_undo_action(action)
      
      puts "Added player character '#{character_name}' to scene '#{scene.name}'"
      mark_dirty
    end

    def add_npc_character(scene : PointClickEngine::Scenes::Scene)
      # Generate unique character name
      character_count = 1
      character_name = "npc_#{character_count}"
      
      while scene.characters.any? { |c| c.name == character_name }
        character_count += 1
        character_name = "npc_#{character_count}"
      end
      
      # Default position (slightly offset from center)
      position = RL::Vector2.new(450.0_f32, 300.0_f32)
      size = RL::Vector2.new(32.0_f32, 64.0_f32)
      
      # Create new NPC character
      character = PointClickEngine::Characters::NPC.new(
        character_name,
        position,
        size
      )
      
      # Set default properties
      character.description = "Non-player character"
      character.state = PointClickEngine::Characters::CharacterState::Idle
      character.direction = PointClickEngine::Characters::Direction::Down
      character.mood = PointClickEngine::Characters::CharacterMood::Neutral
      
      # Add to scene
      scene.characters << character
      
      # Select the new character
      @selected_object = character.name
      
      # Create undo action for creation
      action = CreateCharacterAction.new(scene, character, self)
      add_undo_action(action)
      
      puts "Added NPC character '#{character_name}' to scene '#{scene.name}'"
      mark_dirty
    end

    # Dialog management methods
    def test_dialog(character_name : String)
      return unless project = @current_project
      return unless scene = @current_scene
      
      # Find the character
      character = scene.characters.find { |c| c.name == character_name }
      unless character
        puts "Character '#{character_name}' not found in current scene"
        return
      end
      
      # Look for dialog file for this character
      dialog_path = File.join(project.dialogs_path, "#{character_name}.yml")
      
      unless File.exists?(dialog_path)
        puts "No dialog file found for character '#{character_name}'. Creating default dialog."
        create_default_dialog_for_character(character_name, dialog_path)
      end
      
      # Load and test the dialog
      begin
        yaml_content = File.read(dialog_path)
        dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.from_yaml(yaml_content)
        
        puts "Testing dialog for character '#{character_name}'"
        puts "Dialog tree: #{dialog_tree.name}"
        puts "Number of nodes: #{dialog_tree.nodes.size}"
        
        # Find start node
        start_node = dialog_tree.nodes["start"]?
        if start_node
          puts "Start node found: '#{start_node.text}'"
          puts "Available choices: #{start_node.choices.size}"
          
          start_node.choices.each_with_index do |choice, index|
            puts "  #{index + 1}. #{choice.text} -> #{choice.target_node_id}"
          end
        else
          puts "Warning: No start node found in dialog tree"
        end
        
        # Validate dialog tree
        validate_dialog_tree(dialog_tree)
        
      rescue ex : Exception
        puts "Error loading dialog for character '#{character_name}': #{ex.message}"
      end
    end

    private def create_default_dialog_for_character(character_name : String, dialog_path : String)
      # Create a simple default dialog tree
      dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("#{character_name}_dialog")
      
      # Create start node
      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "start", 
        "Hello! I'm #{character_name}. Nice to meet you!"
      )
      
      # Create a simple response node
      response_node = PointClickEngine::Characters::Dialogue::DialogNode.new(
        "response",
        "Thanks for talking to me!"
      )
      
      # Add a choice that leads to the response
      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new(
        "Nice to meet you too!",
        "response"
      )
      start_node.choices << choice
      
      # Add nodes to dialog tree
      dialog_tree.nodes["start"] = start_node
      dialog_tree.nodes["response"] = response_node
      
      # Save to file
      Dir.mkdir_p(File.dirname(dialog_path))
      File.write(dialog_path, dialog_tree.to_yaml)
      
      puts "Created default dialog file for character '#{character_name}' at #{dialog_path}"
    end

    private def validate_dialog_tree(dialog_tree : PointClickEngine::Characters::Dialogue::DialogTree)
      errors = [] of String
      
      # Check if start node exists
      unless dialog_tree.nodes.has_key?("start")
        errors << "Missing required 'start' node"
      end
      
      # Check for orphaned nodes (nodes that can't be reached)
      reachable_nodes = Set(String).new
      reachable_nodes << "start"
      
      # Traverse from start node to find all reachable nodes
      to_visit = ["start"]
      while !to_visit.empty?
        current_id = to_visit.pop
        node = dialog_tree.nodes[current_id]?
        next unless node
        
        node.choices.each do |choice|
          unless reachable_nodes.includes?(choice.target_node_id)
            reachable_nodes << choice.target_node_id
            to_visit << choice.target_node_id
          end
        end
      end
      
      # Find orphaned nodes
      dialog_tree.nodes.each do |node_id, node|
        unless reachable_nodes.includes?(node_id)
          errors << "Orphaned node found: '#{node_id}'"
        end
      end
      
      # Check for broken links (choices pointing to non-existent nodes)
      dialog_tree.nodes.each do |node_id, node|
        node.choices.each do |choice|
          unless dialog_tree.nodes.has_key?(choice.target_node_id)
            errors << "Broken link in node '#{node_id}': choice '#{choice.text}' points to non-existent node '#{choice.target_node_id}'"
          end
        end
      end
      
      if errors.empty?
        puts "Dialog tree validation passed: No issues found"
      else
        puts "Dialog tree validation found #{errors.size} issue(s):"
        errors.each_with_index do |error, index|
          puts "  #{index + 1}. #{error}"
        end
      end
    end

    private def copy_directory_recursive(source : String, target : String)
      Dir.mkdir_p(target) unless Dir.exists?(target)
      
      Dir.each_child(source) do |entry|
        source_path = File.join(source, entry)
        target_path = File.join(target, entry)
        
        if Dir.exists?(source_path)
          copy_directory_recursive(source_path, target_path)
        else
          File.copy(source_path, target_path)
        end
      end
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
      when "item"
        scene.hotspots.reject! { |h| h.name == @object_name }
      when "trigger"
        scene.hotspots.reject! { |h| h.name == @object_name }
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
        character.mood = PointClickEngine::Characters::CharacterMood::Neutral
        scene.characters << character
      when "item"
        item_hotspot = PointClickEngine::Scenes::Hotspot.new(
          name: @object_name,
          position: @position,
          size: RL::Vector2.new(32.0_f32, 32.0_f32)
        )
        item_hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
        item_hotspot.visible = true
        item_hotspot.description = "Collectable item"
        item_hotspot.object_type = PointClickEngine::UI::ObjectType::Item
        item_hotspot.default_verb = PointClickEngine::UI::VerbType::Take
        scene.hotspots << item_hotspot
      when "trigger"
        trigger_hotspot = PointClickEngine::Scenes::Hotspot.new(
          name: @object_name,
          position: @position,
          size: RL::Vector2.new(64.0_f32, 64.0_f32)
        )
        trigger_hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Look
        trigger_hotspot.visible = false
        trigger_hotspot.description = "Trigger zone"
        trigger_hotspot.object_type = PointClickEngine::UI::ObjectType::Exit
        trigger_hotspot.default_verb = PointClickEngine::UI::VerbType::Use
        scene.hotspots << trigger_hotspot
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

  # Character creation/deletion action for undo/redo
  class CreateCharacterAction < EditorAction
    def initialize(@scene : PointClickEngine::Scenes::Scene, @character : PointClickEngine::Characters::Character, @editor_state : EditorState)
    end

    def undo
      # Remove the character from the scene
      @scene.characters.reject! { |c| c.name == @character.name }

      # Clear selection if this character was selected
      if @editor_state.selected_object == @character.name
        @editor_state.selected_object = nil
      end

      # Auto-save scene
      if project = @editor_state.current_project
        scene_filename = "#{@scene.name}.yml"
        scene_path = File.join(project.scenes_path, scene_filename)
        PaceEditor::IO::SceneIO.save_scene(@scene, scene_path)
      end

      @editor_state.mark_dirty
    end

    def redo
      # Re-add the character to the scene
      @scene.characters << @character

      # Select the recreated character
      @editor_state.selected_object = @character.name

      # Auto-save scene
      if project = @editor_state.current_project
        scene_filename = "#{@scene.name}.yml"
        scene_path = File.join(project.scenes_path, scene_filename)
        PaceEditor::IO::SceneIO.save_scene(@scene, scene_path)
      end

      @editor_state.mark_dirty
    end

    def description : String
      character_type = @character.is_a?(PointClickEngine::Characters::Player) ? "Player" : "NPC"
      "Create #{character_type} '#{@character.name}'"
    end
  end
end
