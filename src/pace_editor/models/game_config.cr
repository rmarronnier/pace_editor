require "yaml"

module PaceEditor::Models
  # Represents the main game configuration (game_config.yaml)
  class GameConfig
    include YAML::Serializable

    # Game metadata
    @[YAML::Field(key: "game")]
    property game : GameMetadata

    # Window settings
    @[YAML::Field(key: "window")]
    property window : WindowSettings = WindowSettings.new

    # Display settings
    @[YAML::Field(key: "display")]
    property display : DisplaySettings = DisplaySettings.new

    # Player character configuration
    @[YAML::Field(key: "player")]
    property player : PlayerConfig

    # Engine features to enable
    @[YAML::Field(key: "features")]
    property features : Array(String) = [] of String

    # Asset loading paths
    @[YAML::Field(key: "assets")]
    property assets : AssetConfig = AssetConfig.new

    # Game settings
    @[YAML::Field(key: "settings")]
    property settings : GameSettings = GameSettings.new

    # Initial game state
    @[YAML::Field(key: "initial_state")]
    property initial_state : InitialState = InitialState.new

    # Starting configuration
    @[YAML::Field(key: "start_scene")]
    property start_scene : String?

    @[YAML::Field(key: "start_music")]
    property start_music : String?

    # UI configuration
    @[YAML::Field(key: "ui")]
    property ui : UIConfig = UIConfig.new

    def initialize(@game : GameMetadata, @player : PlayerConfig)
    end

    # Game metadata nested class
    class GameMetadata
      include YAML::Serializable

      property title : String
      property version : String = "1.0.0"
      property author : String?

      def initialize(@title : String)
      end
    end

    # Window settings nested class
    class WindowSettings
      include YAML::Serializable

      property width : Int32 = 1024
      property height : Int32 = 768
      property fullscreen : Bool = false
      property target_fps : Int32 = 60

      def initialize
      end
    end

    # Display settings nested class
    class DisplaySettings
      include YAML::Serializable

      property scaling_mode : String = "FitWithBars"
      property target_width : Int32 = 1024
      property target_height : Int32 = 768

      def initialize
      end
    end

    # Player configuration nested class
    class PlayerConfig
      include YAML::Serializable

      property name : String = "Player"
      property sprite_path : String
      property sprite : SpriteInfo
      property start_position : Position?

      def initialize(@sprite_path : String, @sprite : SpriteInfo)
      end

      class SpriteInfo
        include YAML::Serializable

        property frame_width : Int32
        property frame_height : Int32
        property columns : Int32
        property rows : Int32

        def initialize(@frame_width : Int32, @frame_height : Int32, @columns : Int32, @rows : Int32)
        end
      end

      class Position
        include YAML::Serializable

        property x : Float32
        property y : Float32

        def initialize(@x : Float32, @y : Float32)
        end
      end
    end

    # Asset configuration nested class
    class AssetConfig
      include YAML::Serializable

      property scenes : Array(String) = ["scenes/*.yaml"]
      property dialogs : Array(String) = ["dialogs/*.yaml"]
      property quests : Array(String) = ["quests/*.yaml"]
      property audio : AudioAssets = AudioAssets.new

      def initialize
      end

      class AudioAssets
        include YAML::Serializable

        property music : Hash(String, String) = {} of String => String
        property sounds : Hash(String, String) = {} of String => String

        def initialize
        end
      end
    end

    # Game settings nested class
    class GameSettings
      include YAML::Serializable

      property debug_mode : Bool = false
      property show_fps : Bool = false
      property master_volume : Float32 = 0.8_f32
      property music_volume : Float32 = 0.7_f32
      property sfx_volume : Float32 = 0.9_f32

      def initialize
      end
    end

    # Initial state nested class
    class InitialState
      include YAML::Serializable

      property flags : Hash(String, Bool) = {} of String => Bool
      property variables : Hash(String, YAML::Any) = {} of String => YAML::Any

      def initialize
      end
    end

    # UI configuration nested class
    class UIConfig
      include YAML::Serializable

      property hints : Array(UIHint) = [] of UIHint
      property opening_message : String?

      def initialize
      end

      class UIHint
        include YAML::Serializable

        property text : String
        property duration : Float32 = 5.0_f32

        def initialize(@text : String)
        end
      end
    end

    # Create default game config for new projects
    def self.create_default(project_name : String) : GameConfig
      game_metadata = GameMetadata.new(project_name)

      sprite_info = PlayerConfig::SpriteInfo.new(
        frame_width: 64,
        frame_height: 64,
        columns: 4,
        rows: 4
      )

      player_config = PlayerConfig.new(
        sprite_path: "assets/sprites/player.png",
        sprite: sprite_info
      )

      GameConfig.new(game_metadata, player_config)
    end

    # Validate the configuration
    def validate : Array(String)
      errors = [] of String

      # Validate window dimensions
      if window.width < 320 || window.width > 7680
        errors << "Window width must be between 320 and 7680"
      end
      if window.height < 240 || window.height > 4320
        errors << "Window height must be between 240 and 4320"
      end

      # Validate target FPS
      if window.target_fps < 30 || window.target_fps > 240
        errors << "Target FPS must be between 30 and 240"
      end

      # Validate scaling mode
      valid_scaling_modes = ["FitWithBars", "Stretch", "PixelPerfect"]
      unless valid_scaling_modes.includes?(display.scaling_mode)
        errors << "Invalid scaling mode: #{display.scaling_mode}"
      end

      # Validate features
      valid_features = ["verbs", "floating_dialogs", "portraits", "shaders", "auto_save", "debug"]
      features.each do |feature|
        unless valid_features.includes?(feature)
          errors << "Invalid feature: #{feature}"
        end
      end

      # Validate volumes
      [settings.master_volume, settings.music_volume, settings.sfx_volume].each do |volume|
        if volume < 0 || volume > 1
          errors << "Volume values must be between 0 and 1"
        end
      end

      errors
    end
  end
end
