# Advanced Tutorial: "The Detective's Case"

This advanced tutorial will teach you sophisticated PACE features by creating a complex detective adventure game. You'll learn about multi-character interactions, inventory puzzles, conditional storylines, and advanced scripting.

## What You'll Build

A detective mystery game featuring:
- Multiple interconnected scenes
- Complex character interactions and conversations
- Inventory-based puzzle solving
- Conditional story branches
- Custom Lua scripting
- Save/load system
- Multiple endings

**Estimated Time:** 4-6 hours  
**Difficulty:** Advanced  
**Prerequisites:** Completed [Beginner Tutorial](beginner-tutorial.md)

## Game Overview: "The Detective's Case"

**Story:** Detective Morgan investigates a theft at the museum. The player must:
1. Interview witnesses (Museum Director, Security Guard, Janitor)
2. Examine evidence (Broken window, footprints, security footage)
3. Solve inventory puzzles (Combine clues to form conclusions)
4. Make deductive choices that affect the story outcome
5. Confront the suspect based on gathered evidence

## Part 1: Advanced Project Setup

### Step 1: Create the Project

1. Create new project: "The Detective's Case"
2. Set resolution to 1280x720 (widescreen for better scene composition)
3. Enable advanced features in Project Settings:
   - Inventory System: On
   - Save/Load System: On
   - Dialog Variables: On
   - Custom Scripts: On

### Step 2: Asset Planning

Download or create these assets:
- **Backgrounds:** Museum lobby, security office, storage room, outside museum
- **Characters:** Detective Morgan, Museum Director, Security Guard, Janitor, Suspect
- **Objects:** Evidence items, interactive furniture, clue documents
- **UI Elements:** Inventory icons, notebook interface, dialog portraits

## Part 2: Multi-Scene Environment

### Scene 1: Museum Lobby (Main Hub)

1. **Create Scene:** "museum_lobby"
2. **Add Background:** Ornate museum entrance hall
3. **Add Objects:**
   - Reception desk
   - Display cases (some broken)
   - Security camera
   - Exit doors to other areas

4. **Create Navigation Hotspots:**
   ```yaml
   # Security Office Door
   name: "security_office_door"
   bounds: [320, 200, 80, 120]
   interaction: "Use"
   action: "CHANGE_SCENE security_office"
   description: "Door to Security Office"
   
   # Storage Room Door  
   name: "storage_door"
   bounds: [800, 180, 60, 140]
   interaction: "Use" 
   action: |
     IF has_inventory security_keycard THEN
       CHANGE_SCENE storage_room
     ELSE
       SHOW_MESSAGE "The door is locked. I need a keycard."
     END
   ```

### Scene 2: Security Office

1. **Create Scene:** "security_office"
2. **Add Interactive Elements:**
   - Security monitors (show footage)
   - Filing cabinets (contain records)
   - Coffee cup (character detail)
   - Keycard on desk

### Scene 3: Storage Room

1. **Create Scene:** "storage_room" 
2. **Add Elements:**
   - Boxes and crates
   - Hidden evidence
   - Janitor's supplies
   - Secret exit

### Scene 4: Outside Museum

1. **Create Scene:** "museum_exterior"
2. **Add Elements:**
   - Broken window
   - Footprint evidence  
   - Witness locations
   - Vehicle tracks

## Part 3: Advanced Character System

### Character 1: Detective Morgan (Player)

```crystal
# Character configuration
name: "Detective Morgan"
sprite_sheet: "detective_sprites.png"
frame_size: [48, 64]

animations:
  idle:
    frames: [0]
    duration: 1.0
  walk:
    frames: [1, 2, 3, 2]
    duration: 0.8
  investigate:
    frames: [4, 5]
    duration: 1.5
  notebook:
    frames: [6]
    duration: 2.0
```

### Character 2: Museum Director

**Advanced Dialog Tree with State Tracking:**

```yaml
dialog_tree: "director_conversation"
variables:
  - director_questioned: false
  - knows_about_theft: false
  - director_suspicious: false

root_node:
  text: "Detective Morgan! Thank goodness you're here."
  speaker: "Director"
  conditions: ["!director_questioned"]
  choices:
    - text: "Tell me about the theft."
      action: "SET_VAR knows_about_theft true"
      target: "theft_details"
    - text: "Who had access to this area?"
      target: "access_question"
    - text: "I'll look around first."
      target: "investigate_first"

theft_details:
  text: "The Emerald Crown was taken last night. No alarms went off."
  speaker: "Director" 
  actions: ["ADD_NOTEBOOK_ENTRY 'Theft occurred last night, no alarms'"]
  choices:
    - text: "No alarms? That's suspicious."
      action: "SET_VAR director_suspicious true"
      target: "suspicious_response"
    - text: "Who was working last night?"
      target: "night_staff_question"
```

### Character 3: Security Guard

**Conditional Responses Based on Evidence:**

```yaml
dialog_tree: "guard_conversation"

root_node:
  text: "I was on duty, but I didn't see anything unusual."
  speaker: "Security Guard"
  choices:
    - text: "Show security footage"
      condition: "has_inventory security_tape"
      target: "footage_confrontation"
    - text: "What about the broken window?"
      condition: "examined_window"
      target: "window_discussion"
    - text: "Tell me about your rounds."
      target: "rounds_explanation"

footage_confrontation:
  text: "I... that can't be right. Let me see that again."
  speaker: "Security Guard"
  actions: ["SET_VAR guard_nervous true"]
  target: "guard_confession"
```

## Part 4: Complex Inventory System

### Evidence Collection

```lua
-- Custom script: evidence_system.lua
local evidence = {}

function add_evidence(item_id, description, scene_found)
    evidence[item_id] = {
        description = description,
        scene = scene_found,
        analyzed = false
    }
    add_inventory_item(item_id)
    show_message("Evidence collected: " .. description)
end

function analyze_evidence(item1_id, item2_id)
    if has_inventory(item1_id) and has_inventory(item2_id) then
        return combine_evidence(item1_id, item2_id)
    end
    return false
end

function combine_evidence(item1, item2)
    -- Footprint + Security footage = Timeline
    if (item1 == "footprint_cast" and item2 == "security_tape") or
       (item1 == "security_tape" and item2 == "footprint_cast") then
        add_evidence("timeline_evidence", "Timeline of events", "combined")
        remove_inventory_item(item1)
        remove_inventory_item(item2)
        return true
    end
    
    -- Keycard + Access logs = Insider info
    if (item1 == "security_keycard" and item2 == "access_logs") or
       (item1 == "access_logs" and item2 == "security_keycard") then
        add_evidence("insider_evidence", "Proof of inside job", "combined")
        remove_inventory_item(item1)
        remove_inventory_item(item2)
        return true
    end
    
    return false
end
```

### Inventory Interface Hotspots

```yaml
# Detective's notebook hotspot
notebook_hotspot:
  name: "detective_notebook"
  bounds: [50, 50, 100, 80]
  interaction: "Use"
  action: "OPEN_NOTEBOOK"
  always_visible: true

# Evidence combination area
evidence_combiner:
  name: "evidence_table"
  bounds: [400, 500, 200, 100]
  interaction: "Use"
  action: |
    IF inventory_count >= 2 THEN
      SHOW_EVIDENCE_COMBINER
    ELSE
      SHOW_MESSAGE "I need at least two pieces of evidence to compare."
    END
```

## Part 5: Advanced Dialog and Branching

### Conditional Story Branches

```yaml
# Main story progression dialog
case_resolution:
  variables:
    - evidence_count: 0
    - suspect_identified: false
    - case_solved: false

  root_node:
    text: "I think I'm ready to solve this case."
    speaker: "Detective Morgan"
    conditions: ["evidence_count >= 3"]
    choices:
      - text: "The guard did it."
        condition: "has_evidence guard_motive"
        target: "accuse_guard"
      - text: "The director is involved."
        condition: "has_evidence director_suspicious"
        target: "accuse_director"
      - text: "It was the janitor."
        condition: "has_evidence janitor_access"
        target: "accuse_janitor"
      - text: "I need more evidence."
        target: "continue_investigation"

  accuse_guard:
    text: "The security guard had motive and opportunity."
    speaker: "Detective Morgan"
    actions: ["SET_VAR suspect_identified true", "SET_VAR accused_guard true"]
    target: "guard_reaction"

  guard_reaction:
    text: "How did you know? I needed the money for my sick daughter..."
    speaker: "Security Guard"
    actions: ["PLAY_SOUND confession.wav", "SET_VAR case_solved true"]
    target: "case_ending_guard"
```

### Dynamic Dialog Based on Player Actions

```lua
-- Dynamic dialog generation
function generate_character_response(character_id, topic)
    local response_data = get_character_data(character_id)
    local player_reputation = get_player_reputation()
    local evidence_strength = calculate_evidence_strength()
    
    if topic == "accusation" then
        if evidence_strength >= 0.8 then
            return response_data.guilty_confession
        elseif evidence_strength >= 0.5 then
            return response_data.defensive_response
        else
            return response_data.dismissive_response
        end
    end
    
    return response_data.default_response
end
```

## Part 6: Custom Scripting and Logic

### Investigation System

```lua
-- investigation_system.lua
local investigation_points = 0
local max_investigation_points = 100

function examine_object(object_id, scene_id)
    local object_data = get_object_data(object_id)
    
    if not object_data.examined then
        object_data.examined = true
        investigation_points = investigation_points + object_data.investigation_value
        
        -- Show examination result
        show_examination_ui(object_data.examination_text)
        
        -- Add to notebook if significant
        if object_data.investigation_value >= 10 then
            add_notebook_entry(object_data.notebook_entry)
        end
        
        -- Check for evidence discovery
        if object_data.contains_evidence then
            discover_evidence(object_data.evidence_item)
        end
        
        -- Update investigation progress
        update_investigation_progress()
    else
        show_message("I've already examined this thoroughly.")
    end
end

function update_investigation_progress()
    local progress = investigation_points / max_investigation_points
    set_ui_element_value("investigation_progress_bar", progress)
    
    if progress >= 0.7 and not get_var("can_solve_case") then
        set_var("can_solve_case", true)
        show_message("I think I have enough evidence to solve this case.")
        enable_hotspot("case_resolution_hotspot")
    end
end
```

### Save/Load System

```lua
-- save_system.lua
function save_game(slot_number)
    local save_data = {
        scene = get_current_scene(),
        inventory = get_inventory_contents(),
        variables = get_all_variables(),
        evidence = get_evidence_collection(),
        investigation_progress = investigation_points,
        dialog_states = get_dialog_states(),
        timestamp = os.time()
    }
    
    write_save_file("save_slot_" .. slot_number .. ".json", save_data)
    show_message("Game saved successfully.")
end

function load_game(slot_number)
    local save_data = read_save_file("save_slot_" .. slot_number .. ".json")
    
    if save_data then
        change_scene(save_data.scene)
        set_inventory_contents(save_data.inventory)
        set_all_variables(save_data.variables)
        set_evidence_collection(save_data.evidence)
        investigation_points = save_data.investigation_progress
        set_dialog_states(save_data.dialog_states)
        
        show_message("Game loaded successfully.")
        return true
    else
        show_message("Save file not found.")
        return false
    end
end
```

## Part 7: Advanced UI Features

### Custom Notebook Interface

```yaml
# notebook_ui.yml
notebook_interface:
  background: "notebook_bg.png"
  position: [200, 100]
  size: [800, 500]
  
  sections:
    evidence:
      title: "Evidence"
      position: [20, 50]
      size: [350, 400]
      scrollable: true
      
    suspects:
      title: "Suspects"
      position: [400, 50]
      size: [350, 180]
      
    notes:
      title: "Notes"
      position: [400, 250]
      size: [350, 200]
      editable: true

  buttons:
    close:
      text: "Close"
      position: [700, 460]
      action: "CLOSE_NOTEBOOK"
```

### Evidence Combination Interface

```lua
-- evidence_combiner.lua
local selected_evidence = {}

function show_evidence_combiner()
    open_ui_panel("evidence_combiner")
    populate_evidence_list()
end

function select_evidence_item(item_id)
    if #selected_evidence < 2 then
        table.insert(selected_evidence, item_id)
        highlight_evidence_item(item_id)
        
        if #selected_evidence == 2 then
            enable_combine_button()
        end
    end
end

function attempt_combination()
    if #selected_evidence == 2 then
        local result = combine_evidence(selected_evidence[1], selected_evidence[2])
        
        if result then
            show_combination_success()
            play_sound("evidence_combined.wav")
        else
            show_combination_failure()
            play_sound("combination_failed.wav")
        end
        
        clear_selection()
    end
end
```

## Part 8: Multiple Endings System

### Ending Calculation

```lua
-- endings_system.lua
function calculate_ending()
    local accuracy_score = calculate_case_accuracy()
    local evidence_completeness = calculate_evidence_completeness()
    local character_relationships = calculate_relationship_scores()
    
    if accuracy_score >= 0.9 and evidence_completeness >= 0.8 then
        return "perfect_detective"
    elseif accuracy_score >= 0.7 then
        return "good_detective"
    elseif get_var("accused_innocent") then
        return "false_accusation"
    else
        return "case_unsolved"
    end
end

function play_ending(ending_type)
    local ending_data = get_ending_data(ending_type)
    
    -- Play ending cutscene
    play_cutscene(ending_data.cutscene_file)
    
    -- Show ending text
    show_ending_text(ending_data.ending_text)
    
    -- Update statistics
    update_player_statistics(ending_type)
    
    -- Show credits
    show_credits()
end
```

### Ending Variants

**Perfect Detective Ending:**
- Correctly identified the culprit
- Collected all evidence
- Made no false accusations
- Maintained good relationships

**Good Detective Ending:**
- Solved the case with minor mistakes
- Most evidence collected
- One false accusation allowed

**False Accusation Ending:**
- Accused an innocent person
- Case remains officially unsolved
- Character faces consequences

**Unsolved Case Ending:**
- Unable to gather sufficient evidence
- No clear conclusion reached
- Open-ended finale

## Part 9: Testing and Polish

### Comprehensive Testing Script

```lua
-- test_system.lua
function run_automated_tests()
    test_scene_transitions()
    test_inventory_system()
    test_dialog_branches()
    test_evidence_combinations()
    test_save_load_functionality()
    test_ending_scenarios()
end

function test_scene_transitions()
    local scenes = {"museum_lobby", "security_office", "storage_room", "museum_exterior"}
    
    for _, scene in ipairs(scenes) do
        change_scene(scene)
        assert(get_current_scene() == scene, "Scene transition failed: " .. scene)
    end
end

function test_evidence_combinations()
    local test_combinations = {
        {"footprint_cast", "security_tape", "timeline_evidence"},
        {"security_keycard", "access_logs", "insider_evidence"}
    }
    
    for _, combo in ipairs(test_combinations) do
        clear_inventory()
        add_inventory_item(combo[1])
        add_inventory_item(combo[2])
        
        local result = combine_evidence(combo[1], combo[2])
        assert(result and has_inventory(combo[3]), "Evidence combination failed")
    end
end
```

### Performance Optimization

```lua
-- optimization.lua
function optimize_game_performance()
    -- Preload frequently used assets
    preload_assets({
        "detective_sprites.png",
        "notebook_bg.png", 
        "evidence_icons.png"
    })
    
    -- Cache dialog trees
    cache_dialog_trees({
        "director_conversation",
        "guard_conversation", 
        "case_resolution"
    })
    
    -- Enable object pooling for UI elements
    enable_ui_object_pooling()
    
    -- Set LOD for complex scenes
    set_scene_detail_level("museum_lobby", "high")
    set_scene_detail_level("storage_room", "medium")
end
```

## Part 10: Advanced Features

### Character AI Behavior

```lua
-- character_ai.lua
function update_character_behavior(character_id, delta_time)
    local character = get_character(character_id)
    local player_pos = get_player_position()
    local distance_to_player = calculate_distance(character.position, player_pos)
    
    -- Characters react based on investigation progress
    local investigation_level = investigation_points / max_investigation_points
    
    if character_id == "security_guard" then
        if investigation_level > 0.6 and get_var("guard_nervous") then
            character.animation = "nervous_idle"
            character.dialog_mood = "defensive"
        end
    elseif character_id == "museum_director" then
        if has_evidence("director_suspicious") then
            character.animation = "worried_idle"
            character.dialog_mood = "concerned"
        end
    end
    
    -- Proximity-based interactions
    if distance_to_player < 100 then
        show_character_interaction_prompt(character_id)
    end
end
```

### Dynamic Music System

```lua
-- music_system.lua
local current_music_mood = "neutral"

function update_music_based_on_context()
    local new_mood = calculate_current_mood()
    
    if new_mood ~= current_music_mood then
        transition_music(current_music_mood, new_mood)
        current_music_mood = new_mood
    end
end

function calculate_current_mood()
    if get_var("case_solved") then
        return "victory"
    elseif investigation_points > 70 then
        return "tension"
    elseif get_var("false_accusation") then
        return "failure"
    else
        return "investigation"
    end
end
```

## Completion Checklist

### Core Features
- [ ] 4 interconnected scenes with seamless navigation
- [ ] 5 fully voiced characters with complex dialog trees
- [ ] Evidence collection and combination system
- [ ] Multiple investigation paths and story branches
- [ ] Save/load functionality
- [ ] Multiple endings based on player performance

### Advanced Features
- [ ] Dynamic character AI responses
- [ ] Conditional music and sound effects
- [ ] Comprehensive notebook/journal system
- [ ] Automated testing suite
- [ ] Performance optimization
- [ ] Accessibility options (text size, colorblind support)

### Polish Elements
- [ ] Smooth scene transitions with effects
- [ ] Particle effects for evidence discovery
- [ ] Character portrait animations during dialog
- [ ] UI sound effects and feedback
- [ ] Professional credits sequence

## Next Steps

After completing this tutorial, you'll have mastered:
- Complex project architecture
- Advanced scripting techniques
- Multi-character story management
- Professional game polish

### Continue Learning
- **[Scripting Tutorial](scripting-tutorial.md)** - Deep dive into Lua scripting
- **[Publishing Guide](../guides/publishing.md)** - Release your games professionally
- **[Modding Guide](../guides/modding.md)** - Create extensible game systems

### Share Your Work
- Export your completed detective game
- Share with the PACE community
- Consider creating additional cases using the same framework

This advanced tutorial demonstrates PACE's full capabilities for creating professional-quality adventure games. The techniques learned here can be applied to any complex interactive narrative project.