module PaceEditor::Constants
  # UI Layout Constants
  MENU_HEIGHT          =  30
  TOOL_PALETTE_WIDTH   =  80
  PROPERTY_PANEL_WIDTH = 300
  STATUS_BAR_HEIGHT    =  25
  SEPARATOR_WIDTH      =   2

  # Editor Settings
  DEFAULT_GRID_SIZE =      16
  DEFAULT_ZOOM      = 1.0_f32
  MIN_ZOOM          = 0.1_f32
  MAX_ZOOM          = 5.0_f32
  ZOOM_STEP         = 0.1_f32

  # Camera Settings
  CAMERA_PAN_SPEED     = 2.0_f32
  CAMERA_ZOOM_SPEED    = 0.1_f32
  CAMERA_SMOOTH_FACTOR = 0.1_f32

  # Asset Categories
  ASSET_CATEGORIES = %w[backgrounds characters sounds music scripts]

  # File Extensions
  SUPPORTED_IMAGE_EXTENSIONS  = %w[.png .jpg .jpeg .bmp .tga]
  SUPPORTED_AUDIO_EXTENSIONS  = %w[.wav .ogg .mp3]
  SUPPORTED_SCRIPT_EXTENSIONS = %w[.lua .cr]

  # Dialog System
  DEFAULT_DIALOG_NODE_WIDTH       =      200
  DEFAULT_DIALOG_NODE_HEIGHT      =      100
  DIALOG_CONNECTION_BEZIER_OFFSET = 50.0_f32

  # Hotspot System
  DEFAULT_HOTSPOT_SIZE        = 32
  HOTSPOT_HANDLE_SIZE         =  8
  HOTSPOT_SELECTION_TOLERANCE =  5

  # Animation System
  DEFAULT_ANIMATION_FPS  = 12.0_f32
  MIN_ANIMATION_FPS      =  1.0_f32
  MAX_ANIMATION_FPS      = 60.0_f32
  DEFAULT_FRAME_DURATION =      100 # milliseconds

  # Project Settings
  DEFAULT_WINDOW_WIDTH  = 1024
  DEFAULT_WINDOW_HEIGHT =  768
  MIN_WINDOW_WIDTH      =  640
  MIN_WINDOW_HEIGHT     =  480
  MAX_WINDOW_WIDTH      = 3840
  MAX_WINDOW_HEIGHT     = 2160

  # Validation Settings
  MAX_OBJECT_NAME_LENGTH =   50
  MAX_DIALOG_TEXT_LENGTH = 1000
  MAX_SCENE_OBJECTS      =  100

  # Performance Settings
  TEXTURE_CACHE_MAX_SIZE = 100
  UNDO_HISTORY_MAX_SIZE  =  50
  AUTO_SAVE_INTERVAL     =  30 # seconds

  # Color Constants
  GRID_COLOR       = RL::Color.new(r: 200_u8, g: 200_u8, b: 200_u8, a: 100_u8)
  SELECTION_COLOR  = RL::Color.new(r: 255_u8, g: 255_u8, b: 0_u8, a: 200_u8)
  HOTSPOT_COLOR    = RL::Color.new(r: 255_u8, g: 0_u8, b: 0_u8, a: 150_u8)
  CONNECTION_COLOR = RL::Color.new(r: 100_u8, g: 100_u8, b: 255_u8, a: 255_u8)

  # Input Constants
  DOUBLE_CLICK_TIME = 500 # milliseconds
  DRAG_THRESHOLD    =   5 # pixels

  # Export Settings
  EXPORT_COMPRESSION_LEVEL =  6
  EXPORT_TIMEOUT           = 30 # seconds
end
