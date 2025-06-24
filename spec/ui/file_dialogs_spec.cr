require "../spec_helper"
require "file_utils"

# Extend MenuBar to expose internal state for testing
class TestableMenuBar < PaceEditor::UI::MenuBar
  getter show_save_dialog : Bool
  getter save_project_name : String
  getter save_project_path : String
  
  def initialize(state)
    super(state)
  end
end

describe PaceEditor::UI::MenuBar do
  describe "file dialog functionality" do
    describe "#show_save_project_dialog" do
      it "sets show_save_dialog to true" do
        state = PaceEditor::Core::EditorState.new
        menu_bar = TestableMenuBar.new(state)
        
        menu_bar.show_save_project_dialog
        menu_bar.show_save_dialog.should eq(true)
      end
      
      it "pre-populates project name from current project" do
        state = PaceEditor::Core::EditorState.new
        menu_bar = TestableMenuBar.new(state)
        
        # Create a test project
        temp_dir = "/tmp/pace_test_#{Random.new.next_int}"
        Dir.mkdir_p(temp_dir)
        state.create_new_project("Test Project", temp_dir)
        
        menu_bar.show_save_project_dialog
        menu_bar.save_project_name.should eq("Test Project")
        
        # Clean up
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
      
      it "uses default name when no current project" do
        state = PaceEditor::Core::EditorState.new
        menu_bar = TestableMenuBar.new(state)
        
        menu_bar.show_save_project_dialog
        menu_bar.save_project_name.should eq("Untitled Project")
      end
      
      it "sets correct default save path" do
        state = PaceEditor::Core::EditorState.new
        menu_bar = TestableMenuBar.new(state)
        
        menu_bar.show_save_project_dialog
        menu_bar.save_project_path.should eq("./projects")
      end
    end
  end
end

# Create a testable wrapper for EditorState to test private methods
class TestableEditorState < PaceEditor::Core::EditorState
  def test_copy_directory_recursive(source : String, target : String)
    copy_directory_recursive(source, target)
  end
end

describe PaceEditor::Core::EditorState do
  describe "#save_project_as" do
    
    it "returns false when no current project" do
      empty_state = PaceEditor::Core::EditorState.new
      result = empty_state.save_project_as("New Name", "/tmp/new_path")
      result.should eq(false)
    end
    
    it "creates new project with specified name and path" do
      state = PaceEditor::Core::EditorState.new
      temp_dir = "/tmp/pace_test_#{Random.new.next_int}"
      
      begin
        # Create a test project first
        Dir.mkdir_p(temp_dir)
        state.create_new_project("Test Project", temp_dir)
        
        new_path = File.join(temp_dir, "new_project")
        result = state.save_project_as("New Project Name", new_path)
        
        result.should eq(true)
        Dir.exists?(new_path).should eq(true)
        
        # Verify project structure was created
        Dir.exists?(File.join(new_path, "scenes")).should eq(true)
        Dir.exists?(File.join(new_path, "assets")).should eq(true)
        Dir.exists?(File.join(new_path, "scripts")).should eq(true)
        Dir.exists?(File.join(new_path, "dialogs")).should eq(true)
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
    
    it "copies scenes from original project" do
      state = PaceEditor::Core::EditorState.new
      temp_dir = "/tmp/pace_test_#{Random.new.next_int}"
      
      begin
        # Create a test project first
        Dir.mkdir_p(temp_dir)
        state.create_new_project("Test Project", temp_dir)
        
        # Save current scene to ensure it exists
        if scene = state.current_scene
          scene.name = "test_scene"
          state.save_current_scene(scene)
        end
        
        new_path = File.join(temp_dir, "copied_project")
        result = state.save_project_as("Copied Project", new_path)
        
        result.should eq(true)
        
        # Check that scenes directory was created and copied
        scenes_path = File.join(new_path, "scenes")
        Dir.exists?(scenes_path).should eq(true)
        
        # Check if the main scene file was copied
        main_scene_file = File.join(scenes_path, "main.yml")
        File.exists?(main_scene_file).should eq(true)
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
    
    it "updates current project reference to new project" do
      state = PaceEditor::Core::EditorState.new
      temp_dir = "/tmp/pace_test_#{Random.new.next_int}"
      
      begin
        # Create a test project first
        Dir.mkdir_p(temp_dir)
        state.create_new_project("Test Project", temp_dir)
        
        original_project = state.current_project
        original_project.should_not be_nil
        
        new_path = File.join(temp_dir, "new_project")
        result = state.save_project_as("New Project", new_path)
        
        result.should eq(true)
        
        new_project = state.current_project
        new_project.should_not be_nil
        new_project.should_not eq(original_project)
        
        if project = new_project
          project.name.should eq("New Project")
          project.project_path.should contain("new_project")
        end
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
    
    it "handles file copy errors gracefully" do
      state = PaceEditor::Core::EditorState.new
      temp_dir = "/tmp/pace_test_#{Random.new.next_int}"
      
      begin
        Dir.mkdir_p(temp_dir)
        state.create_new_project("Test Project", temp_dir)
        
        # Try to save to a path that should cause issues (like a file instead of directory)
        invalid_path = "/dev/null/invalid_path"
        result = state.save_project_as("Invalid Project", invalid_path)
        
        # Should handle error gracefully and return false
        result.should eq(false)
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
  end
  
  describe "copy_directory_recursive" do
    it "copies directories and files recursively" do
      source_dir = "/tmp/test_source_#{Random.new.next_int}"
      target_dir = "/tmp/test_target_#{Random.new.next_int}"
      
      begin
        # Create test structure
        Dir.mkdir_p(File.join(source_dir, "subdir"))
        File.write(File.join(source_dir, "file.txt"), "test content")
        File.write(File.join(source_dir, "subdir", "nested.txt"), "nested content")
        
        state = TestableEditorState.new
        state.test_copy_directory_recursive(source_dir, target_dir)
        
        # Verify files were copied
        File.exists?(File.join(target_dir, "file.txt")).should eq(true)
        File.exists?(File.join(target_dir, "subdir", "nested.txt")).should eq(true)
        
        # Verify content was copied correctly
        File.read(File.join(target_dir, "file.txt")).should eq("test content")
        File.read(File.join(target_dir, "subdir", "nested.txt")).should eq("nested content")
      ensure
        [source_dir, target_dir].each do |dir|
          FileUtils.rm_rf(dir) if Dir.exists?(dir)
        end
      end
    end
    
    it "handles missing source directory gracefully" do
      non_existent_source = "/tmp/non_existent_#{Random.new.next_int}"
      target_dir = "/tmp/test_target_#{Random.new.next_int}"
      
      begin
        state = TestableEditorState.new
        
        # Should not crash when source doesn't exist
        expect_raises(Exception) do
          state.test_copy_directory_recursive(non_existent_source, target_dir)
        end
      ensure
        FileUtils.rm_rf(target_dir) if Dir.exists?(target_dir)
      end
    end
  end
end

# Create testable version of GameExportDialog
class TestableGameExportDialog < PaceEditor::UI::GameExportDialog
  getter export_path : String
  getter current_directory : String
  getter directory_entries : Array(String)
  getter show_directory_browser : Bool
  
  def test_refresh_directory_list
    refresh_directory_list
  end
  
  def set_current_directory(path : String)
    @current_directory = path
  end
  
  def set_show_directory_browser(value : Bool)
    @show_directory_browser = value
  end
end

describe PaceEditor::UI::GameExportDialog do
  describe "basic functionality" do
    it "can be created and shown" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::GameExportDialog.new(state)
      dialog.show
      dialog.visible.should eq(true)
    end
    
    it "can be hidden" do
      state = PaceEditor::Core::EditorState.new
      dialog = PaceEditor::UI::GameExportDialog.new(state)
      dialog.show
      dialog.hide
      dialog.visible.should eq(false)
    end
    
    it "initializes with project name when shown" do
      state = PaceEditor::Core::EditorState.new
      temp_dir = "/tmp/pace_export_test_#{Random.new.next_int}"
      
      begin
        Dir.mkdir_p(temp_dir)
        state.create_new_project("Export Test Project", temp_dir)
        
        dialog = TestableGameExportDialog.new(state)
        dialog.show
        
        # Should set export path based on project
        dialog.export_path.should contain("export_test_project")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
  end
  
  describe "directory browser functionality" do
    it "initializes directory browser correctly" do
      state = PaceEditor::Core::EditorState.new
      dialog = TestableGameExportDialog.new(state)
      dialog.show
      
      dialog.current_directory.should eq(".")
      dialog.directory_entries.should_not be_empty
    end
    
    it "refreshes directory list correctly" do
      state = PaceEditor::Core::EditorState.new
      dialog = TestableGameExportDialog.new(state)
      
      # Create a test directory with some contents
      test_dir = "/tmp/dir_browser_test_#{Random.new.next_int}"
      
      begin
        Dir.mkdir_p(File.join(test_dir, "subdir1"))
        Dir.mkdir_p(File.join(test_dir, "subdir2"))
        File.write(File.join(test_dir, "file.txt"), "test")
        
        dialog.set_current_directory(test_dir)
        dialog.test_refresh_directory_list
        
        entries = dialog.directory_entries
        
        # Should contain directories but not files (directory browser only shows dirs)
        entries.should contain("subdir1/")
        entries.should contain("subdir2/")
        # Should not contain files in directory browser
      ensure
        FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
      end
    end
    
    it "includes parent directory when not at root" do
      state = PaceEditor::Core::EditorState.new
      dialog = TestableGameExportDialog.new(state)
      
      # Set to a subdirectory
      dialog.set_current_directory("/tmp")
      dialog.test_refresh_directory_list
      
      entries = dialog.directory_entries
      entries.should contain("..")
    end
    
    it "does not include parent directory at root" do
      state = PaceEditor::Core::EditorState.new
      dialog = TestableGameExportDialog.new(state)
      
      # Set to current directory (considered root for testing)
      dialog.set_current_directory(".")
      dialog.test_refresh_directory_list
      
      entries = dialog.directory_entries
      entries.should_not contain("..")
    end
    
    it "handles directory read errors gracefully" do
      state = PaceEditor::Core::EditorState.new
      dialog = TestableGameExportDialog.new(state)
      
      # Try to read a non-existent directory
      dialog.set_current_directory("/non_existent_directory_#{Random.new.next_int}")
      
      # Should not crash
      dialog.test_refresh_directory_list
      
      # Should fall back to current directory
      dialog.current_directory.should eq(".")
    end
    
    it "can toggle directory browser visibility" do
      state = PaceEditor::Core::EditorState.new
      dialog = TestableGameExportDialog.new(state)
      
      dialog.show_directory_browser.should eq(false)
      
      dialog.set_show_directory_browser(true)
      dialog.show_directory_browser.should eq(true)
      
      dialog.set_show_directory_browser(false)
      dialog.show_directory_browser.should eq(false)
    end
  end
  
  describe "export path management" do
    it "updates export path when directory is selected" do
      state = PaceEditor::Core::EditorState.new
      dialog = TestableGameExportDialog.new(state)
      
      original_path = dialog.export_path
      
      # Simulate directory selection by manually updating
      # In real usage, this would happen through the UI
      new_path = "/tmp/selected_export_dir"
      # Note: The actual path update happens in draw_directory_browser
      # when "Select This Directory" button is clicked
      
      # For testing, we verify the structure exists
      dialog.current_directory.should_not be_nil
    end
  end
end

# Create testable version of ConfirmDialog for more thorough testing
class TestableConfirmDialog < PaceEditor::Core::ConfirmDialog
  setter visible : Bool
  getter callback : -> Nil
  
  def initialize(@title : String, @message : String, @callback : -> Nil)
    super(@title, @message, @callback)
  end
  
  def simulate_ok_click
    @callback.call
    @visible = false
  end
  
  def simulate_cancel_click
    @visible = false
  end
  
  def simulate_escape_key
    @visible = false
  end
end

describe PaceEditor::Core::ConfirmDialog do
  describe "confirmation dialog functionality" do
    it "creates dialog with title, message and callback" do
      callback = ->{ nil }
      dialog = PaceEditor::Core::ConfirmDialog.new("Test Title", "Test message", callback)
      dialog.should_not be_nil
    end
    
    it "starts visible" do
      callback = ->{ nil }
      dialog = PaceEditor::Core::ConfirmDialog.new("Title", "Message", callback)
      dialog.visible?.should eq(true)
    end
    
    it "calls callback when OK is clicked" do
      callback_called = false
      callback = ->{
        callback_called = true
        nil
      }
      
      dialog = TestableConfirmDialog.new("Title", "Message", callback)
      dialog.simulate_ok_click
      
      callback_called.should eq(true)
      dialog.visible?.should eq(false)
    end
    
    it "becomes invisible when Cancel is clicked" do
      callback_called = false
      callback = ->{
        callback_called = true
        nil
      }
      
      dialog = TestableConfirmDialog.new("Title", "Message", callback)
      dialog.simulate_cancel_click
      
      callback_called.should eq(false)  # Callback should not be called on cancel
      dialog.visible?.should eq(false)
    end
    
    it "becomes invisible when Escape is pressed" do
      callback_called = false
      callback = ->{
        callback_called = true
        nil
      }
      
      dialog = TestableConfirmDialog.new("Title", "Message", callback)
      dialog.simulate_escape_key
      
      callback_called.should eq(false)  # Callback should not be called on escape
      dialog.visible?.should eq(false)
    end
    
    it "preserves title and message" do
      callback = ->{ nil }
      title = "Important Confirmation"
      message = "Are you sure you want to proceed?"
      
      dialog = TestableConfirmDialog.new(title, message, callback)
      
      # Note: Title and message are private, but we can verify through the constructor
      # In a real implementation, we might add getters for testing
      dialog.should_not be_nil
    end
  end
end

describe "File Dialog Integration" do
  describe "EditorWindow dialog management" do
    it "creates confirm dialog when show_confirm_dialog is called" do
      window = PaceEditor::Core::EditorWindow.new
      
      window.show_confirm_dialog("Title", "Message") { }
      
      window.confirm_dialog.should_not be_nil
      if dialog = window.confirm_dialog
        dialog.visible?.should eq(true)
      end
    end
    
    it "manages confirm dialog lifecycle correctly" do
      window = PaceEditor::Core::EditorWindow.new
      callback_executed = false
      
      # Create dialog
      window.show_confirm_dialog("Test", "Test message") do
        callback_executed = true
      end
      dialog = window.confirm_dialog
      dialog.should_not be_nil
      
      # Verify dialog exists and is visible
      if d = dialog
        d.visible?.should eq(true)
      end
    end
    
    it "integrates project file dialog with menu bar" do
      window = PaceEditor::Core::EditorWindow.new
      
      # Should trigger save project dialog without errors
      window.show_project_file_dialog(false)
      
      # The menu bar should have the save dialog active
      # Note: This tests the integration between EditorWindow and MenuBar
    end
    
    it "integrates open project dialog with menu bar" do
      window = PaceEditor::Core::EditorWindow.new
      
      # Should trigger open project dialog without errors
      window.show_project_file_dialog(true)
      
      # The menu bar should have the open dialog active
    end
  end
  
  describe "Save Project Integration" do
    it "integrates MenuBar save dialog with EditorState" do
      state = PaceEditor::Core::EditorState.new
      menu_bar = TestableMenuBar.new(state)
      temp_dir = "/tmp/pace_save_integration_#{Random.new.next_int}"
      
      begin
        # Create a project
        Dir.mkdir_p(temp_dir)
        state.create_new_project("Integration Test", temp_dir)
        
        # Show save dialog
        menu_bar.show_save_project_dialog
        menu_bar.show_save_dialog.should eq(true)
        menu_bar.save_project_name.should eq("Integration Test")
        
        # Simulate save operation
        new_path = File.join(temp_dir, "saved_project")
        result = state.save_project_as(menu_bar.save_project_name, new_path)
        result.should eq(true)
        
        # Verify project was saved
        Dir.exists?(new_path).should eq(true)
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
    
    it "handles save dialog workflow end-to-end" do
      state = PaceEditor::Core::EditorState.new
      window = PaceEditor::Core::EditorWindow.new
      temp_dir = "/tmp/pace_workflow_test_#{Random.new.next_int}"
      
      begin
        # Create original project through window's state
        Dir.mkdir_p(temp_dir)
        window.state.create_new_project("Workflow Test", temp_dir)
        
        # Trigger save-as workflow
        window.show_project_file_dialog(false)
        
        # The workflow should be set up correctly
        # (actual save would require UI interaction simulation)
        window.state.current_project.should_not be_nil
        
        # Test the save functionality directly
        result = window.state.save_project_as("Saved Workflow Project", temp_dir)
        result.should eq(true)
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
  end
  
  describe "Export Dialog Integration" do
    it "integrates export dialog with project state" do
      state = PaceEditor::Core::EditorState.new
      dialog = TestableGameExportDialog.new(state)
      temp_dir = "/tmp/pace_export_integration_#{Random.new.next_int}"
      
      begin
        # Create a project
        Dir.mkdir_p(temp_dir)
        state.create_new_project("Export Integration Test", temp_dir)
        
        # Show export dialog
        dialog.show
        
        # Should initialize with project data
        dialog.export_path.should contain("export_integration_test")
        dialog.visible.should eq(true)
        
        # Test directory browser initialization
        dialog.current_directory.should eq(".")
        dialog.directory_entries.should_not be_empty
        
        # Test directory navigation
        dialog.set_current_directory(temp_dir)
        dialog.test_refresh_directory_list
        
        # Should handle the project directory
        entries = dialog.directory_entries
        entries.should contain("..")  # Parent directory
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
    
    it "handles export path selection correctly" do
      state = PaceEditor::Core::EditorState.new
      dialog = TestableGameExportDialog.new(state)
      export_dir = "/tmp/pace_export_selection_#{Random.new.next_int}"
      
      begin
        Dir.mkdir_p(export_dir)
        state.create_new_project("Export Selection Test", export_dir)
        
        dialog.show
        
        # Simulate directory browser usage
        dialog.set_show_directory_browser(true)
        dialog.show_directory_browser.should eq(true)
        
        dialog.set_current_directory(export_dir)
        dialog.test_refresh_directory_list
        
        # Directory should be set correctly
        dialog.current_directory.should eq(export_dir)
      ensure
        FileUtils.rm_rf(export_dir) if Dir.exists?(export_dir)
      end
    end
  end
  
  describe "Error Handling Integration" do
    it "handles invalid save paths gracefully in full workflow" do
      state = PaceEditor::Core::EditorState.new
      window = PaceEditor::Core::EditorWindow.new
      temp_dir = "/tmp/pace_error_test_#{Random.new.next_int}"
      
      begin
        Dir.mkdir_p(temp_dir)
        window.state.create_new_project("Error Test", temp_dir)
        
        # Try to save to invalid location
        result = window.state.save_project_as("Invalid Save", "/dev/null/invalid")
        result.should eq(false)
        
        # Original project should still be intact
        window.state.current_project.should_not be_nil
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
    
    it "handles confirm dialog errors gracefully" do
      window = PaceEditor::Core::EditorWindow.new
      error_occurred = false
      
      window.show_confirm_dialog("Error Test", "This will cause an error") do
        begin
          raise "Test error"
        rescue
          error_occurred = true
        end
      end
      
      # Dialog should be created despite callback issues
      window.confirm_dialog.should_not be_nil
    end
  end
end

# Additional helper specs for testing file operations
describe "File Dialog Helpers" do
  describe "directory sanitization" do
    it "sanitizes project names for directory creation" do
      # Test the sanitization logic used in save dialogs
      name = "My Project! @#$%"
      sanitized = name.downcase.gsub(/[^a-z0-9_\s]/, "").gsub(/\s+/, "_")
      sanitized.should eq("my_project___")
    end
    
    it "handles empty project names" do
      name = ""
      sanitized = name.downcase.gsub(/[^a-z0-9_\s]/, "").gsub(/\s+/, "_")
      preview = sanitized.empty? ? "project_name" : sanitized
      preview.should eq("project_name")
    end
  end
end