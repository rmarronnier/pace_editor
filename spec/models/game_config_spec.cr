require "../spec_helper"
require "../../src/pace_editor/models/game_config"

describe PaceEditor::Models::GameConfig do
  describe ".create_default" do
    it "creates a default game config with valid settings" do
      config = PaceEditor::Models::GameConfig.create_default("TestGame")

      config.game.title.should eq "TestGame"
      config.game.version.should eq "1.0.0"
      config.game.author.should be_nil

      config.window.width.should eq 1024
      config.window.height.should eq 768
      config.window.fullscreen.should be_false
      config.window.target_fps.should eq 60

      config.player.sprite_path.should eq "assets/sprites/player.png"
      config.player.sprite.frame_width.should eq 64
      config.player.sprite.frame_height.should eq 64
    end
  end

  describe "#validate" do
    it "validates window dimensions" do
      config = PaceEditor::Models::GameConfig.create_default("TestGame")

      # Valid dimensions
      config.validate.should be_empty

      # Invalid width
      config.window.width = 100
      errors = config.validate
      errors.should contain "Window width must be between 320 and 7680"

      # Invalid height
      config.window.width = 1024
      config.window.height = 100
      errors = config.validate
      errors.should contain "Window height must be between 240 and 4320"
    end

    it "validates target FPS" do
      config = PaceEditor::Models::GameConfig.create_default("TestGame")

      config.window.target_fps = 25
      errors = config.validate
      errors.should contain "Target FPS must be between 30 and 240"

      config.window.target_fps = 300
      errors = config.validate
      errors.should contain "Target FPS must be between 30 and 240"
    end

    it "validates scaling mode" do
      config = PaceEditor::Models::GameConfig.create_default("TestGame")

      config.display.scaling_mode = "InvalidMode"
      errors = config.validate
      errors.should contain "Invalid scaling mode: InvalidMode"

      config.display.scaling_mode = "FitWithBars"
      config.validate.should be_empty
    end

    it "validates features" do
      config = PaceEditor::Models::GameConfig.create_default("TestGame")

      config.features = ["verbs", "invalid_feature"]
      errors = config.validate
      errors.should contain "Invalid feature: invalid_feature"

      config.features = ["verbs", "portraits", "debug"]
      config.validate.should be_empty
    end

    it "validates volume settings" do
      config = PaceEditor::Models::GameConfig.create_default("TestGame")

      config.settings.master_volume = 1.5_f32
      errors = config.validate
      errors.should contain "Volume values must be between 0 and 1"

      config.settings.master_volume = 0.8_f32
      config.settings.music_volume = -0.1_f32
      errors = config.validate
      errors.should contain "Volume values must be between 0 and 1"
    end
  end

  describe "YAML serialization" do
    it "serializes to valid YAML" do
      config = PaceEditor::Models::GameConfig.create_default("TestGame")
      config.start_scene = "intro"
      config.features = ["verbs", "portraits"]

      yaml = config.to_yaml
      yaml.should contain "game:"
      yaml.should contain "title: TestGame"
      yaml.should contain "window:"
      yaml.should contain "player:"
      yaml.should contain "start_scene: intro"
      yaml.should contain "features:"
      yaml.should contain "- verbs"
      yaml.should contain "- portraits"
    end

    it "deserializes from YAML" do
      yaml = <<-YAML
      game:
        title: "My Adventure"
        version: "2.0.0"
        author: "Test Author"
      window:
        width: 1280
        height: 720
        fullscreen: true
        target_fps: 120
      display:
        scaling_mode: "Stretch"
        target_width: 1280
        target_height: 720
      player:
        name: "Hero"
        sprite_path: "assets/sprites/hero.png"
        sprite:
          frame_width: 32
          frame_height: 32
          columns: 8
          rows: 8
      features:
        - verbs
        - floating_dialogs
      assets:
        scenes:
          - "scenes/*.yaml"
        dialogs:
          - "dialogs/*.yaml"
        quests:
          - "quests/*.yaml"
        audio:
          music:
            theme: "assets/music/theme.ogg"
          sounds:
            click: "assets/sounds/click.wav"
      settings:
        debug_mode: true
        show_fps: true
        master_volume: 0.9
        music_volume: 0.8
        sfx_volume: 1.0
      initial_state:
        flags:
          tutorial_complete: false
        variables:
          player_health: 100
      start_scene: "menu"
      start_music: "theme"
      ui:
        hints:
          - text: "Welcome to the game!"
            duration: 3.0
        opening_message: "Press any key to start"
      YAML

      config = PaceEditor::Models::GameConfig.from_yaml(yaml)

      config.game.title.should eq "My Adventure"
      config.game.version.should eq "2.0.0"
      config.game.author.should eq "Test Author"

      config.window.width.should eq 1280
      config.window.height.should eq 720
      config.window.fullscreen.should be_true
      config.window.target_fps.should eq 120

      config.player.name.should eq "Hero"
      config.player.sprite_path.should eq "assets/sprites/hero.png"

      config.features.should eq ["verbs", "floating_dialogs"]

      config.assets.audio.music["theme"].should eq "assets/music/theme.ogg"
      config.assets.audio.sounds["click"].should eq "assets/sounds/click.wav"

      config.settings.debug_mode.should be_true
      config.settings.master_volume.should eq 0.9_f32

      config.initial_state.flags["tutorial_complete"].should be_false
      config.initial_state.variables["player_health"].as_i.should eq 100

      config.start_scene.should eq "menu"
      config.start_music.should eq "theme"

      config.ui.hints.size.should eq 1
      config.ui.hints[0].text.should eq "Welcome to the game!"
      config.ui.opening_message.should eq "Press any key to start"
    end
  end
end
