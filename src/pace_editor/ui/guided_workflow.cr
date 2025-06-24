module PaceEditor::UI
  # Guided workflow system for user onboarding and contextual help
  # Provides step-by-step guidance and progress tracking
  class GuidedWorkflow
    include PaceEditor::Constants

    property editor_state : Core::EditorState
    property ui_state : UIState
    property current_tutorial : Tutorial?
    property active_step : WorkflowStep?
    property workflow_progress : Hash(String, Float32) = Hash(String, Float32).new
    property tutorials : Hash(String, Tutorial) = Hash(String, Tutorial).new

    # Getting started panel
    property show_getting_started : Bool = true
    property getting_started_rect : RL::Rectangle = RL::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: 400.0_f32, height: 300.0_f32)

    def initialize(@editor_state : Core::EditorState, @ui_state : UIState)
      initialize_tutorials
      @getting_started_rect.x = (RL.get_screen_width - @getting_started_rect.width) / 2
      @getting_started_rect.y = (RL.get_screen_height - @getting_started_rect.height) / 2
    end

    def update
      # Update getting started visibility
      @show_getting_started = should_show_getting_started?

      # Update active tutorial
      if tutorial = @current_tutorial
        tutorial.update(@editor_state, @ui_state)
      end

      # Auto-advance workflows based on state
      check_workflow_progression
    end

    def draw
      # Draw getting started panel
      if @show_getting_started
        draw_getting_started_panel
      end

      # Draw active tutorial step
      if tutorial = @current_tutorial
        if step = tutorial.current_step
          draw_tutorial_step(step)
        end
      end

      # Draw contextual hints
      draw_contextual_hints

      # Draw progress indicator
      if @ui_state.show_hints && @editor_state.has_project?
        draw_progress_indicator
      end
    end

    def handle_input(mouse_pos : RL::Vector2, mouse_clicked : Bool) : Bool
      # Handle getting started panel
      if @show_getting_started && PaceEditor::Constants.point_in_rect?(mouse_pos, @getting_started_rect)
        return handle_getting_started_input(mouse_pos, mouse_clicked)
      end

      # Handle tutorial step input
      if tutorial = @current_tutorial
        if step = tutorial.current_step
          return handle_tutorial_input(step, mouse_pos, mouse_clicked)
        end
      end

      false
    end

    def start_tutorial(tutorial_name : String)
      if tutorial = get_tutorial(tutorial_name)
        @current_tutorial = tutorial
        tutorial.start
        @ui_state.track_action("tutorial_started_#{tutorial_name}")
      end
    end

    def complete_current_step
      if tutorial = @current_tutorial
        tutorial.advance_step

        if tutorial.completed?
          @ui_state.mark_tutorial_completed(tutorial.name)
          @current_tutorial = nil
        end
      end
    end

    def skip_tutorial
      if tutorial = @current_tutorial
        @ui_state.mark_tutorial_completed(tutorial.name)
        @current_tutorial = nil
      end
    end

    private def should_show_getting_started? : Bool
      !@editor_state.has_project? && @ui_state.should_show_onboarding?
    end

    private def draw_getting_started_panel
      # Update position to center on current screen size
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      @getting_started_rect.x = (screen_width - @getting_started_rect.width) / 2
      @getting_started_rect.y = (screen_height - @getting_started_rect.height) / 2
      
      # Panel background
      RL.draw_rectangle_rec(@getting_started_rect, RL::Color.new(r: 255_u8, g: 255_u8, b: 255_u8, a: 240_u8))
      RL.draw_rectangle_lines_ex(@getting_started_rect, 2.0_f32, RL::Color.new(r: 100_u8, g: 150_u8, b: 255_u8, a: 255_u8))

      # Title
      title = "Welcome to PACE Editor!"
      title_width = RL.measure_text(title, 24)
      title_x = @getting_started_rect.x + (@getting_started_rect.width - title_width) / 2
      RL.draw_text(title, title_x.to_i, (@getting_started_rect.y + 20).to_i, 24,
        RL::Color.new(r: 50_u8, g: 50_u8, b: 50_u8, a: 255_u8))

      # Subtitle
      subtitle = "Create amazing point-and-click adventure games"
      subtitle_width = RL.measure_text(subtitle, 14)
      subtitle_x = @getting_started_rect.x + (@getting_started_rect.width - subtitle_width) / 2
      RL.draw_text(subtitle, subtitle_x.to_i, (@getting_started_rect.y + 60).to_i, 14,
        RL::Color.new(r: 100_u8, g: 100_u8, b: 100_u8, a: 255_u8))

      # Action buttons
      button_width = 150.0_f32
      button_height = 35.0_f32
      button_spacing = 20.0_f32

      new_project_rect = RL::Rectangle.new(
        x: @getting_started_rect.x + (@getting_started_rect.width - button_width) / 2,
        y: @getting_started_rect.y + 120.0_f32,
        width: button_width, height: button_height
      )

      open_project_rect = RL::Rectangle.new(
        x: @getting_started_rect.x + (@getting_started_rect.width - button_width) / 2,
        y: @getting_started_rect.y + 120.0_f32 + button_height + button_spacing,
        width: button_width, height: button_height
      )

      tutorial_rect = RL::Rectangle.new(
        x: @getting_started_rect.x + (@getting_started_rect.width - button_width) / 2,
        y: @getting_started_rect.y + 120.0_f32 + (button_height + button_spacing) * 2,
        width: button_width, height: button_height
      )

      # Draw buttons
      draw_action_button(new_project_rect, "New Project", RL::Color.new(r: 100_u8, g: 150_u8, b: 255_u8, a: 255_u8))
      draw_action_button(open_project_rect, "Open Project", RL::Color.new(r: 150_u8, g: 150_u8, b: 150_u8, a: 255_u8))
      draw_action_button(tutorial_rect, "Start Tutorial", RL::Color.new(r: 100_u8, g: 200_u8, b: 100_u8, a: 255_u8))
    end

    private def draw_action_button(rect : RL::Rectangle, text : String, color : RL::Color)
      mouse_pos = RL.get_mouse_position
      hovered = PaceEditor::Constants.point_in_rect?(mouse_pos, rect)

      # Button background
      button_color = hovered ? lighten_color(color, 20) : color
      RL.draw_rectangle_rec(rect, button_color)
      RL.draw_rectangle_lines_ex(rect, 1.0_f32, darken_color(color, 30))

      # Button text
      text_width = RL.measure_text(text, 14)
      text_x = rect.x + (rect.width - text_width) / 2
      text_y = rect.y + (rect.height - 14) / 2
      RL.draw_text(text, text_x.to_i, text_y.to_i, 14, RL::Color.new(r: 255_u8, g: 255_u8, b: 255_u8, a: 255_u8))
    end

    private def draw_tutorial_step(step : WorkflowStep)
      # Draw tutorial overlay
      overlay_color = RL::Color.new(r: 0_u8, g: 0_u8, b: 0_u8, a: 100_u8)
      RL.draw_rectangle(0, 0, RL.get_screen_width, RL.get_screen_height, overlay_color)

      # Highlight target area if specified
      if target = step.target_area
        highlight_area(target)
      end

      # Draw instruction panel - position it properly on screen
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      panel_width = 300.0_f32
      panel_height = 150.0_f32
      panel_x = (screen_width - panel_width) / 2
      panel_y = screen_height * 0.2_f32  # Position at 20% from top
      
      instruction_rect = RL::Rectangle.new(x: panel_x, y: panel_y, width: panel_width, height: panel_height)
      RL.draw_rectangle_rec(instruction_rect, RL::Color.new(r: 255_u8, g: 255_u8, b: 255_u8, a: 255_u8))
      RL.draw_rectangle_lines_ex(instruction_rect, 2.0_f32, RL::Color.new(r: 100_u8, g: 150_u8, b: 255_u8, a: 255_u8))

      # Step title
      RL.draw_text(step.title, (panel_x + 10).to_i, (panel_y + 20).to_i, 16, RL::Color.new(r: 50_u8, g: 50_u8, b: 50_u8, a: 255_u8))

      # Step description
      draw_wrapped_text(step.description, panel_x + 10, panel_y + 50, 280, 14, RL::Color.new(r: 80_u8, g: 80_u8, b: 80_u8, a: 255_u8))

      # Next/Skip buttons
      next_rect = RL::Rectangle.new(x: panel_x + 150.0_f32, y: panel_y + 110.0_f32, width: 60.0_f32, height: 25.0_f32)
      skip_rect = RL::Rectangle.new(x: panel_x + 220.0_f32, y: panel_y + 110.0_f32, width: 60.0_f32, height: 25.0_f32)

      draw_action_button(next_rect, "Next", RL::Color.new(r: 100_u8, g: 150_u8, b: 255_u8, a: 255_u8))
      draw_action_button(skip_rect, "Skip", RL::Color.new(r: 150_u8, g: 150_u8, b: 150_u8, a: 255_u8))
    end

    private def draw_contextual_hints
      return unless @ui_state.show_hints

      # Get and display next suggested action
      if suggestion = @ui_state.get_next_suggested_action(@editor_state)
        draw_suggestion_hint(suggestion)
      end

      # Draw queued hints
      hint_y = 50.0_f32
      while hint = @ui_state.get_next_hint
        draw_hint(hint, hint_y)
        hint_y += 80.0_f32
      end
    end

    private def draw_suggestion_hint(suggestion : String)
      hint_rect = RL::Rectangle.new(x: RL.get_screen_width - 320.0_f32, y: 10.0_f32, width: 300.0_f32, height: 60.0_f32)

      RL.draw_rectangle_rec(hint_rect, RL::Color.new(r: 255_u8, g: 248_u8, b: 220_u8, a: 240_u8))
      RL.draw_rectangle_lines_ex(hint_rect, 1.0_f32, RL::Color.new(r: 255_u8, g: 193_u8, b: 7_u8, a: 255_u8))

      # Icon
      RL.draw_text("💡", (hint_rect.x + 10).to_i, (hint_rect.y + 15).to_i, 24,
        RL::Color.new(r: 255_u8, g: 193_u8, b: 7_u8, a: 255_u8))

      # Text
      draw_wrapped_text("Next: #{suggestion}", hint_rect.x + 45, hint_rect.y + 15, 240, 12,
        RL::Color.new(r: 60_u8, g: 60_u8, b: 60_u8, a: 255_u8))
    end

    private def draw_hint(hint : UIHint, y : Float32)
      hint_rect = RL::Rectangle.new(x: RL.get_screen_width - 320.0_f32, y: y, width: 300.0_f32, height: 70.0_f32)

      # Color based on hint type
      bg_color, border_color, icon = case hint.type
                                     when .info?
                                       {RL::Color.new(r: 220_u8, g: 235_u8, b: 255_u8, a: 240_u8),
                                        RL::Color.new(r: 100_u8, g: 150_u8, b: 255_u8, a: 255_u8), "ℹ️"}
                                     when .warning?
                                       {RL::Color.new(r: 255_u8, g: 243_u8, b: 205_u8, a: 240_u8),
                                        RL::Color.new(r: 255_u8, g: 193_u8, b: 7_u8, a: 255_u8), "⚠️"}
                                     when .success?
                                       {RL::Color.new(r: 212_u8, g: 237_u8, b: 218_u8, a: 240_u8),
                                        RL::Color.new(r: 40_u8, g: 167_u8, b: 69_u8, a: 255_u8), "✅"}
                                     when .error?
                                       {RL::Color.new(r: 248_u8, g: 215_u8, b: 218_u8, a: 240_u8),
                                        RL::Color.new(r: 220_u8, g: 53_u8, b: 69_u8, a: 255_u8), "❌"}
                                     else
                                       {RL::Color.new(r: 240_u8, g: 240_u8, b: 240_u8, a: 240_u8),
                                        RL::Color.new(r: 150_u8, g: 150_u8, b: 150_u8, a: 255_u8), "💡"}
                                     end

      RL.draw_rectangle_rec(hint_rect, bg_color)
      RL.draw_rectangle_lines_ex(hint_rect, 1.0_f32, border_color)

      # Icon
      RL.draw_text(icon, (hint_rect.x + 10).to_i, (hint_rect.y + 10).to_i, 16, border_color)

      # Text
      draw_wrapped_text(hint.text, hint_rect.x + 35, hint_rect.y + 10, 250, 11,
        RL::Color.new(r: 60_u8, g: 60_u8, b: 60_u8, a: 255_u8))

      # Dismiss button
      dismiss_rect = RL::Rectangle.new(x: hint_rect.x + hint_rect.width - 25, y: hint_rect.y + 5, width: 20.0_f32, height: 20.0_f32)
      mouse_pos = RL.get_mouse_position
      if PaceEditor::Constants.point_in_rect?(mouse_pos, dismiss_rect)
        RL.draw_rectangle_rec(dismiss_rect, RL::Color.new(r: 200_u8, g: 200_u8, b: 200_u8, a: 100_u8))
      end
      RL.draw_text("×", (dismiss_rect.x + 6).to_i, (dismiss_rect.y + 2).to_i, 14,
        RL::Color.new(r: 100_u8, g: 100_u8, b: 100_u8, a: 255_u8))
    end

    private def draw_progress_indicator
      progress = @ui_state.get_completion_percentage

      # Progress bar background
      bar_rect = RL::Rectangle.new(x: 10.0_f32, y: RL.get_screen_height - 30.0_f32, width: 200.0_f32, height: 20.0_f32)
      RL.draw_rectangle_rec(bar_rect, RL::Color.new(r: 240_u8, g: 240_u8, b: 240_u8, a: 255_u8))
      RL.draw_rectangle_lines_ex(bar_rect, 1.0_f32, RL::Color.new(r: 150_u8, g: 150_u8, b: 150_u8, a: 255_u8))

      # Progress fill
      fill_width = (bar_rect.width * progress / 100.0_f32)
      fill_rect = RL::Rectangle.new(x: bar_rect.x, y: bar_rect.y, width: fill_width, height: bar_rect.height)
      RL.draw_rectangle_rec(fill_rect, RL::Color.new(r: 100_u8, g: 200_u8, b: 100_u8, a: 255_u8))

      # Progress text
      progress_text = "Project: #{progress.to_i}%"
      RL.draw_text(progress_text, 220, RL.get_screen_height - 25, 12,
        RL::Color.new(r: 80_u8, g: 80_u8, b: 80_u8, a: 255_u8))
    end

    private def handle_getting_started_input(mouse_pos : RL::Vector2, clicked : Bool) : Bool
      return false unless clicked

      button_width = 150.0_f32
      button_height = 35.0_f32
      button_spacing = 20.0_f32

      new_project_rect = RL::Rectangle.new(
        x: @getting_started_rect.x + (@getting_started_rect.width - button_width) / 2,
        y: @getting_started_rect.y + 120.0_f32,
        width: button_width, height: button_height
      )

      open_project_rect = RL::Rectangle.new(
        x: @getting_started_rect.x + (@getting_started_rect.width - button_width) / 2,
        y: @getting_started_rect.y + 120.0_f32 + button_height + button_spacing,
        width: button_width, height: button_height
      )

      tutorial_rect = RL::Rectangle.new(
        x: @getting_started_rect.x + (@getting_started_rect.width - button_width) / 2,
        y: @getting_started_rect.y + 120.0_f32 + (button_height + button_spacing) * 2,
        width: button_width, height: button_height
      )

      if PaceEditor::Constants.point_in_rect?(mouse_pos, new_project_rect)
        @editor_state.show_new_project_dialog = true
        @ui_state.track_action("new_project_from_welcome")
        return true
      elsif PaceEditor::Constants.point_in_rect?(mouse_pos, open_project_rect)
        # Open project logic
        @ui_state.track_action("open_project_from_welcome")
        return true
      elsif PaceEditor::Constants.point_in_rect?(mouse_pos, tutorial_rect)
        start_tutorial("basic_workflow")
        return true
      end

      false
    end

    private def handle_tutorial_input(step : WorkflowStep, mouse_pos : RL::Vector2, clicked : Bool) : Bool
      return false unless clicked

      # Calculate button positions based on actual panel position
      screen_width = RL.get_screen_width
      screen_height = RL.get_screen_height
      panel_width = 300.0_f32
      panel_height = 150.0_f32
      panel_x = (screen_width - panel_width) / 2
      panel_y = screen_height * 0.2_f32  # Position at 20% from top
      
      next_rect = RL::Rectangle.new(x: panel_x + 150.0_f32, y: panel_y + 110.0_f32, width: 60.0_f32, height: 25.0_f32)
      skip_rect = RL::Rectangle.new(x: panel_x + 220.0_f32, y: panel_y + 110.0_f32, width: 60.0_f32, height: 25.0_f32)

      if PaceEditor::Constants.point_in_rect?(mouse_pos, next_rect)
        complete_current_step
        return true
      elsif PaceEditor::Constants.point_in_rect?(mouse_pos, skip_rect)
        skip_tutorial
        return true
      end

      false
    end

    private def check_workflow_progression
      # Auto-advance certain workflows based on state changes
      if @editor_state.has_project? && @ui_state.has_recent_action?("project_created")
        @ui_state.add_hint(UIHint.new("project_created", "Great! Your project is ready. Now create your first scene!",
          UIHintType::Success, expires_in: 10.seconds))
      end
    end

    private def initialize_tutorials
      # Create basic workflow tutorial
      basic_steps = [
        WorkflowStep.new(
          "Welcome to PACE Editor",
          "PACE Editor helps you create point-and-click adventure games. Let's start with the basics!"
        ),
        WorkflowStep.new(
          "Create Your First Project",
          "Click 'File > New Project' to create your first game project. This will set up the basic structure.",
          completion_condition: ->(state : Core::EditorState, ui : UIState) { state.has_project? }
        ),
        WorkflowStep.new(
          "Create Your First Scene",
          "Every game needs scenes. Click 'Scene > New Scene' to create your first game location.",
          completion_condition: ->(state : Core::EditorState, ui : UIState) { !state.current_scene.nil? }
        ),
        WorkflowStep.new(
          "Add a Character",
          "Characters bring your game to life. Use 'Character > Add NPC' to create your first character.",
          completion_condition: ->(state : Core::EditorState, ui : UIState) {
            scene = state.current_scene
            scene ? scene.characters.any? : false
          }
        ),
        WorkflowStep.new(
          "Add Interactive Elements",
          "Create hotspots to make objects interactive. Use the tool palette to add hotspots to your scene.",
          completion_condition: ->(state : Core::EditorState, ui : UIState) {
            scene = state.current_scene
            scene ? scene.hotspots.any? : false
          }
        ),
        WorkflowStep.new(
          "You're Ready!",
          "Congratulations! You've learned the basics. Explore the menus to discover more features like dialogs, animations, and scripting."
        ),
      ]

      @tutorials = {"basic_workflow" => Tutorial.new("basic_workflow", basic_steps)}
    end

    private def get_tutorial(name : String) : Tutorial?
      @tutorials[name]?
    end

    # Utility methods

    private def lighten_color(color : RL::Color, amount : UInt8) : RL::Color
      RL::Color.new(
        r: Math.min(255_u8, (color.r.to_i32 + amount.to_i32).clamp(0, 255).to_u8),
        g: Math.min(255_u8, (color.g.to_i32 + amount.to_i32).clamp(0, 255).to_u8),
        b: Math.min(255_u8, (color.b.to_i32 + amount.to_i32).clamp(0, 255).to_u8),
        a: color.a
      )
    end

    private def darken_color(color : RL::Color, amount : UInt8) : RL::Color
      RL::Color.new(
        r: Math.max(0_u8, (color.r.to_i32 - amount.to_i32).clamp(0, 255).to_u8),
        g: Math.max(0_u8, (color.g.to_i32 - amount.to_i32).clamp(0, 255).to_u8),
        b: Math.max(0_u8, (color.b.to_i32 - amount.to_i32).clamp(0, 255).to_u8),
        a: color.a
      )
    end

    private def draw_wrapped_text(text : String, x : Float32, y : Float32, max_width : Int32, font_size : Int32, color : RL::Color)
      # Simple text wrapping implementation
      words = text.split(' ')
      current_line = ""
      line_y = y

      words.each do |word|
        test_line = current_line.empty? ? word : "#{current_line} #{word}"
        if RL.measure_text(test_line, font_size) <= max_width
          current_line = test_line
        else
          unless current_line.empty?
            RL.draw_text(current_line, x.to_i, line_y.to_i, font_size, color)
            line_y += font_size + 2
          end
          current_line = word
        end
      end

      unless current_line.empty?
        RL.draw_text(current_line, x.to_i, line_y.to_i, font_size, color)
      end
    end

    private def highlight_area(area : RL::Rectangle)
      # Draw highlight overlay
      RL.draw_rectangle_rec(area, RL::Color.new(r: 255_u8, g: 255_u8, b: 0_u8, a: 50_u8))
      RL.draw_rectangle_lines_ex(area, 3.0_f32, RL::Color.new(r: 255_u8, g: 255_u8, b: 0_u8, a: 255_u8))
    end
  end

  # Supporting classes for tutorials (simplified)

  class Tutorial
    property name : String
    property steps : Array(WorkflowStep)
    property current_step_index : Int32 = 0

    def initialize(@name : String, @steps : Array(WorkflowStep))
    end

    def start
      @current_step_index = 0
    end

    def current_step : WorkflowStep?
      @steps[@current_step_index]? if @current_step_index < @steps.size
    end

    def advance_step
      @current_step_index += 1
    end

    def completed? : Bool
      @current_step_index >= @steps.size
    end

    def update(editor_state : Core::EditorState, ui_state : UIState)
      # Update tutorial based on current state
    end
  end

  class WorkflowStep
    property title : String
    property description : String
    property target_area : RL::Rectangle?
    property completion_condition : Proc(Core::EditorState, UIState, Bool)?

    def initialize(@title : String, @description : String, @target_area = nil, @completion_condition = nil)
    end

    def completed?(editor_state : Core::EditorState, ui_state : UIState) : Bool
      if condition = @completion_condition
        condition.call(editor_state, ui_state)
      else
        false
      end
    end
  end
end
