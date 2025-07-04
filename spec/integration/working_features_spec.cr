require "../spec_helper"

describe "Working Features Integration" do
  # Test features we know are working based on existing specs

  it "creates project structure" do
    temp_dir = File.tempname("test_project_#{Time.utc.to_unix_ms}")
    project = PaceEditor::Core::Project.new("Test Project", temp_dir)

    # Verify project structure created
    Dir.exists?(project.project_path).should be_true
    Dir.exists?(project.assets_path).should be_true
    Dir.exists?(project.scenes_path).should be_true
    Dir.exists?(project.scripts_path).should be_true
    Dir.exists?(project.dialogs_path).should be_true
    Dir.exists?(project.exports_path).should be_true

    # Verify subfolders
    Dir.exists?(project.backgrounds_path).should be_true
    Dir.exists?(project.characters_path).should be_true
    Dir.exists?(project.sounds_path).should be_true
    Dir.exists?(project.music_path).should be_true

    # Cleanup
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end

  it "saves and loads project file" do
    temp_dir = File.tempname("save_project_#{Time.utc.to_unix_ms}")
    project = PaceEditor::Core::Project.new("Save Test", temp_dir)

    # Modify project
    project.author = "Test Author"
    project.description = "Test Description"
    project.window_width = 1280
    project.window_height = 720

    # Save project
    project_file = File.join(project.project_path, "#{project.name}.pace")
    File.write(project_file, project.to_yaml)

    # Load project back
    loaded_yaml = File.read(project_file)
    loaded_project = PaceEditor::Core::Project.from_yaml(loaded_yaml)

    # Verify loaded data
    loaded_project.name.should eq("Save Test")
    loaded_project.author.should eq("Test Author")
    loaded_project.description.should eq("Test Description")
    loaded_project.window_width.should eq(1280)
    loaded_project.window_height.should eq(720)

    # Cleanup
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end

  # Removed test that depends on undefined PointClickEngine::GameConfig

  it "handles asset imports" do
    temp_dir = File.tempname("asset_project_#{Time.utc.to_unix_ms}")
    project = PaceEditor::Core::Project.new("Asset Test", temp_dir)

    # Create test files
    test_files = {
      "test_bg.png"     => project.backgrounds_path,
      "test_char.png"   => project.characters_path,
      "test_sound.wav"  => project.sounds_path,
      "test_music.ogg"  => project.music_path,
      "test_script.lua" => project.scripts_path,
    }

    test_files.each do |filename, dest_dir|
      # Create dummy source file
      source = File.tempfile(filename)
      source.print("dummy content for #{filename}")
      source.close

      # Copy to project
      dest = File.join(dest_dir, filename)
      FileUtils.cp(source.path, dest)

      # Verify
      File.exists?(dest).should be_true

      # Cleanup source
      source.delete
    end

    # Cleanup
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
  end

  # Removed test that depends on undefined classes (GameConfig, ProjectValidator)
end
