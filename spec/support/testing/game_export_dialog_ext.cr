# Testing extensions for GameExportDialog
# Reopens the class to add e2e testing support methods

module PaceEditor::UI
  class GameExportDialog
    # Update with a specific input provider (for testing)
    def update_with_input(input : Testing::InputProvider)
      return unless @visible

      # Handle input
      handle_input_with_test(input)
    end

    private def handle_input_with_test(input : Testing::InputProvider)
      # Handle escape key
      if input.key_pressed?(RL::KeyboardKey::Escape) && !@is_exporting
        hide
      end
    end

    # Testing getters
    def export_name_for_test : String
      @export_name
    end

    def export_path_for_test : String
      @export_path
    end

    def export_format_for_test : String
      @export_format
    end

    def is_exporting_for_test : Bool
      @is_exporting
    end

    def export_progress_for_test : Float32
      @export_progress
    end

    def export_status_for_test : String
      @export_status
    end

    def include_source_for_test : Bool
      @include_source
    end

    def compress_assets_for_test : Bool
      @compress_assets
    end

    def validate_project_for_test : Bool
      @validate_project
    end

    def validation_results_for_test : Array(String)
      @validation_results
    end

    def show_directory_browser_for_test : Bool
      @show_directory_browser
    end

    # Testing setters
    def set_export_name_for_test(name : String)
      @export_name = name
    end

    def set_export_path_for_test(path : String)
      @export_path = path
    end

    def set_export_format_for_test(format : String)
      @export_format = format
    end

    def set_include_source_for_test(value : Bool)
      @include_source = value
    end

    def set_compress_assets_for_test(value : Bool)
      @compress_assets = value
    end

    def set_validate_project_for_test(value : Bool)
      @validate_project = value
    end

    # Testing actions
    def trigger_validation_for_test
      validate_project
    end

    def trigger_export_for_test
      start_export
    end

    def toggle_directory_browser_for_test
      @show_directory_browser = !@show_directory_browser
      refresh_directory_list if @show_directory_browser
    end

    # Get button positions for click testing
    def get_export_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      button_y = dialog_y + dialog_height - 60
      {dialog_x + dialog_width - 60, button_y + 15}
    end

    def get_cancel_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      button_y = dialog_y + dialog_height - 60
      {dialog_x + 70, button_y + 15}
    end

    def get_validate_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      button_y = dialog_y + dialog_height - 60
      {dialog_x + dialog_width // 2 - 50, button_y + 15}
    end

    def get_browse_button_position(screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2
      {dialog_x + dialog_width - 55, dialog_y + 120}
    end

    def get_format_option_position(format : String, screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      formats = ["standalone", "web", "source"]
      index = formats.index(format) || 0

      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      format_y = dialog_y + 170 + index * 40
      {dialog_x + 50, format_y + 16}
    end

    def get_checkbox_position(checkbox : String, screen_width : Int32 = 1400, screen_height : Int32 = 900) : {Int32, Int32}
      dialog_width = 600
      dialog_height = 500
      dialog_x = (screen_width - dialog_width) // 2
      dialog_y = (screen_height - dialog_height) // 2

      base_y = dialog_y + 310
      case checkbox
      when "include_source"
        {dialog_x + 38, base_y + 8}
      when "compress_assets"
        {dialog_x + 38, base_y + 33}
      when "validate_project"
        {dialog_x + 38, base_y + 58}
      else
        {dialog_x + 38, base_y + 8}
      end
    end
  end
end
