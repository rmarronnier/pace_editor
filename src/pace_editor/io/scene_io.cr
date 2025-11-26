require "yaml"

module PaceEditor::IO
  # Handles saving and loading scenes to/from YAML files
  class SceneIO
    # Get the file path for a scene
    def self.get_scene_file_path(project : Core::Project, scene_name : String) : String
      File.join(project.scenes_path, "#{scene_name}.yml")
    end

    # Save a scene to a YAML file
    def self.save_scene(scene : PointClickEngine::Scenes::Scene, file_path : String) : Bool
      begin
        # Create a serializable representation of the scene
        scene_data = {
          "name"                 => scene.name,
          "background_path"      => scene.background_path,
          "scale"                => scene.scale,
          "enable_pathfinding"   => scene.enable_pathfinding,
          "navigation_cell_size" => scene.navigation_cell_size,
          "script_path"          => scene.script_path,
          "hotspots"             => serialize_hotspots(scene.hotspots),
          "characters"           => serialize_characters(scene.characters),
          "walkable_areas"       => serialize_walkable_areas(scene.walkable_area),
        }

        # Ensure directory exists
        dir = File.dirname(file_path)
        Dir.mkdir_p(dir) unless Dir.exists?(dir)

        # Write YAML to file
        File.write(file_path, scene_data.to_yaml)

        puts "Saved scene '#{scene.name}' to #{file_path}"
        true
      rescue ex
        puts "Error saving scene: #{ex.message}"
        false
      end
    end

    # Load a scene from a YAML file
    def self.load_scene(file_path : String) : PointClickEngine::Scenes::Scene?
      begin
        return nil unless File.exists?(file_path)

        # Parse YAML
        yaml_content = File.read(file_path)
        scene_data = YAML.parse(yaml_content)

        # Create scene
        scene = PointClickEngine::Scenes::Scene.new(scene_data["name"].as_s)

        # Set basic properties
        scene.background_path = scene_data["background_path"]?.try(&.as_s?)
        scene.scale = scene_data["scale"]?.try(&.as_f.to_f32) || 1.0_f32
        scene.enable_pathfinding = scene_data["enable_pathfinding"]?.try(&.as_bool?) != false
        scene.navigation_cell_size = scene_data["navigation_cell_size"]?.try(&.as_i) || 16
        scene.script_path = scene_data["script_path"]?.try(&.as_s?)

        # Load hotspots
        if hotspots_data = scene_data["hotspots"]?
          scene.hotspots = deserialize_hotspots(hotspots_data)
        end

        # Load characters
        if characters_data = scene_data["characters"]?
          scene.characters = deserialize_characters(characters_data)
        end

        # Load walkable areas
        if walkable_data = scene_data["walkable_areas"]?
          unless walkable_data.raw.nil?
            scene.walkable_area = deserialize_walkable_areas(walkable_data)
          end
        end

        puts "Loaded scene '#{scene.name}' from #{file_path}"
        scene
      rescue ex
        puts "Error loading scene: #{ex.message}"
        nil
      end
    end

    # Serialize hotspots to YAML-friendly format
    private def self.serialize_hotspots(hotspots : Array(PointClickEngine::Scenes::Hotspot))
      hotspots.map do |hotspot|
        {
          "name"     => hotspot.name,
          "position" => {
            "x" => hotspot.position.x,
            "y" => hotspot.position.y,
          },
          "size" => {
            "x" => hotspot.size.x,
            "y" => hotspot.size.y,
          },
          "cursor_type" => hotspot.cursor_type.to_s,
          "visible"     => hotspot.visible,
          "description" => hotspot.description,
          "script_path" => hotspot.script_path,
        }
      end
    end

    # Deserialize hotspots from YAML data
    private def self.deserialize_hotspots(data : YAML::Any) : Array(PointClickEngine::Scenes::Hotspot)
      hotspots = [] of PointClickEngine::Scenes::Hotspot

      data.as_a.each do |hotspot_data|
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          name: hotspot_data["name"].as_s,
          position: RL::Vector2.new(
            hotspot_data["position"]["x"].as_f.to_f32,
            hotspot_data["position"]["y"].as_f.to_f32
          ),
          size: RL::Vector2.new(
            hotspot_data["size"]["x"].as_f.to_f32,
            hotspot_data["size"]["y"].as_f.to_f32
          )
        )

        # Set optional properties
        if cursor_type = hotspot_data["cursor_type"]?
          # Parse cursor type enum
          case cursor_type.as_s
          when "hand"
            hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
          when "look"
            hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Look
          when "talk"
            hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Talk
          when "use"
            hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Use
          else
            hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Default
          end
        end

        hotspot.visible = hotspot_data["visible"]?.try(&.as_bool) || true
        hotspot.description = hotspot_data["description"]?.try(&.as_s) || ""
        hotspot.script_path = hotspot_data["script_path"]?.try(&.as_s?)

        hotspots << hotspot
      end

      hotspots
    end

    # Serialize characters
    private def self.serialize_characters(characters : Array(PointClickEngine::Characters::Character))
      characters.map do |char|
        char_data = {
          "name"        => char.name,
          "description" => char.description,
          "position"    => {
            "x" => char.position.x,
            "y" => char.position.y,
          },
          "size" => {
            "x" => char.size.x,
            "y" => char.size.y,
          },
          "state"           => char.state.to_s,
          "direction"       => char.direction.to_s,
          "walking_speed"   => char.walking_speed,
          "use_pathfinding" => char.use_pathfinding,
          "sprite_path"     => char.sprite_path,
        }

        # Add NPC-specific data if it's an NPC
        if npc = char.as?(PointClickEngine::Characters::NPC)
          char_data = char_data.merge({
            "type"                 => "npc",
            "mood"                 => npc.mood.to_s,
            "dialogues"            => npc.dialogues,
            "can_repeat_dialogues" => npc.can_repeat_dialogues,
            "interaction_distance" => npc.interaction_distance,
          })
        else
          char_data = char_data.merge({
            "type" => "character",
          })
        end

        char_data
      end
    end

    # Deserialize hotspots
    private def self.deserialize_hotspots(data : YAML::Any) : Array(PointClickEngine::Scenes::Hotspot)
      hotspots = [] of PointClickEngine::Scenes::Hotspot

      data.as_a.each do |hotspot_data|
        name = hotspot_data["name"].as_s
        position = RL::Vector2.new(
          hotspot_data["position"]["x"].as_f.to_f32,
          hotspot_data["position"]["y"].as_f.to_f32
        )
        size = RL::Vector2.new(
          hotspot_data["size"]["x"].as_f.to_f32,
          hotspot_data["size"]["y"].as_f.to_f32
        )

        hotspot = PointClickEngine::Scenes::Hotspot.new(name, position, size)

        # Set cursor type
        if cursor_str = hotspot_data["cursor_type"]?.try(&.as_s)
          case cursor_str
          when "Look"
            hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Look
          when "Hand"
            hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
          when "Talk"
            hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Talk
          when "Use"
            hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Use
          else
            hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Default
          end
        end

        # Set other properties
        hotspot.visible = hotspot_data["visible"]?.try(&.as_bool) || true
        hotspot.description = hotspot_data["description"]?.try(&.as_s) || ""

        hotspots << hotspot
      end

      hotspots
    end

    # Deserialize characters
    private def self.deserialize_characters(data : YAML::Any) : Array(PointClickEngine::Characters::Character)
      characters = [] of PointClickEngine::Characters::Character

      data.as_a.each do |char_data|
        name = char_data["name"].as_s
        position = RL::Vector2.new(
          char_data["position"]["x"].as_f.to_f32,
          char_data["position"]["y"].as_f.to_f32
        )
        size = RL::Vector2.new(
          char_data["size"]["x"].as_f.to_f32,
          char_data["size"]["y"].as_f.to_f32
        )

        # Create character based on type
        character = if char_data["type"]?.try(&.as_s) == "npc"
                      PointClickEngine::Characters::NPC.new(name, position, size)
                    else
                      # For now, default to NPC since Character is abstract
                      PointClickEngine::Characters::NPC.new(name, position, size)
                    end

        # Set common properties
        character.description = char_data["description"]?.try(&.as_s) || "Character"
        character.walking_speed = char_data["walking_speed"]?.try(&.as_f.to_f32) || 100.0_f32
        character.use_pathfinding = char_data["use_pathfinding"]?.try(&.as_bool) || true
        if sprite_path = char_data["sprite_path"]?.try(&.as_s)
          character.sprite_controller.sprite_path = sprite_path
        end

        # Set state enum
        if state_str = char_data["state"]?.try(&.as_s)
          case state_str.downcase
          when "idle"
            character.state = PointClickEngine::Characters::CharacterState::Idle
          when "walking"
            character.state = PointClickEngine::Characters::CharacterState::Walking
          when "talking"
            character.state = PointClickEngine::Characters::CharacterState::Talking
          when "interacting"
            character.state = PointClickEngine::Characters::CharacterState::Interacting
          when "thinking"
            character.state = PointClickEngine::Characters::CharacterState::Thinking
          else
            character.state = PointClickEngine::Characters::CharacterState::Idle
          end
        end

        # Set direction enum
        if direction_str = char_data["direction"]?.try(&.as_s)
          case direction_str.downcase
          when "left"
            character.direction = PointClickEngine::Characters::Direction::Left
          when "right"
            character.direction = PointClickEngine::Characters::Direction::Right
          when "up"
            character.direction = PointClickEngine::Characters::Direction::Up
          when "down"
            character.direction = PointClickEngine::Characters::Direction::Down
          else
            character.direction = PointClickEngine::Characters::Direction::Right
          end
        end

        # Set NPC-specific properties
        if npc = character.as?(PointClickEngine::Characters::NPC)
          if mood_str = char_data["mood"]?.try(&.as_s)
            case mood_str.downcase
            when "friendly"
              npc.mood = PointClickEngine::Characters::CharacterMood::Friendly
            when "neutral"
              npc.mood = PointClickEngine::Characters::CharacterMood::Neutral
            when "hostile"
              npc.mood = PointClickEngine::Characters::CharacterMood::Hostile
            when "sad"
              npc.mood = PointClickEngine::Characters::CharacterMood::Sad
            when "happy"
              npc.mood = PointClickEngine::Characters::CharacterMood::Happy
            when "angry"
              npc.mood = PointClickEngine::Characters::CharacterMood::Angry
            else
              npc.mood = PointClickEngine::Characters::CharacterMood::Neutral
            end
          end

          npc.can_repeat_dialogues = char_data["can_repeat_dialogues"]?.try(&.as_bool) || true
          npc.interaction_distance = char_data["interaction_distance"]?.try(&.as_f.to_f32) || 50.0_f32

          # Load dialogues
          if dialogues_data = char_data["dialogues"]?
            dialogues_data.as_a.each do |dialogue|
              npc.add_dialogue(dialogue.as_s)
            end
          end
        end

        characters << character
      end

      characters
    end

    # Serialize walkable areas
    private def self.serialize_walkable_areas(walkable_area : PointClickEngine::Scenes::WalkableArea?)
      return nil unless walkable_area

      {
        "regions" => walkable_area.regions.map do |region|
          {
            "name"     => region.name,
            "walkable" => region.walkable,
            "vertices" => region.vertices.map do |vertex|
              {"x" => vertex.x, "y" => vertex.y}
            end,
          }
        end,
        "scale_zones" => walkable_area.scale_zones.map do |zone|
          {
            "min_y"     => zone.min_y,
            "max_y"     => zone.max_y,
            "min_scale" => zone.min_scale,
            "max_scale" => zone.max_scale,
          }
        end,
      }
    end

    # Deserialize walkable areas
    private def self.deserialize_walkable_areas(data : YAML::Any) : PointClickEngine::Scenes::WalkableArea?
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Deserialize regions
      if regions_data = data["regions"]?
        regions_data.as_a.each do |region_data|
          region = PointClickEngine::Scenes::PolygonRegion.new(
            region_data["name"].as_s,
            region_data["walkable"].as_bool
          )

          # Add vertices
          if vertices_data = region_data["vertices"]?
            vertices_data.as_a.each do |vertex_data|
              vertex = RL::Vector2.new(
                vertex_data["x"].as_f.to_f32,
                vertex_data["y"].as_f.to_f32
              )
              region.vertices << vertex
            end
          end

          walkable_area.regions << region
        end
      end

      # Deserialize scale zones
      if scale_zones_data = data["scale_zones"]?
        scale_zones_data.as_a.each do |zone_data|
          scale_zone = PointClickEngine::Scenes::ScaleZone.new(
            zone_data["min_y"].as_f.to_f32,
            zone_data["max_y"].as_f.to_f32,
            zone_data["min_scale"].as_f.to_f32,
            zone_data["max_scale"].as_f.to_f32
          )
          walkable_area.scale_zones << scale_zone
        end
      end

      # Update bounds after loading
      walkable_area.update_bounds

      walkable_area
    end
  end
end
