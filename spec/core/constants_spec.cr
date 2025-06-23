require "../spec_helper"

describe PaceEditor::Constants do
  describe "UI Layout Constants" do
    it "defines menu height" do
      PaceEditor::Constants::MENU_HEIGHT.should eq(30)
    end

    it "defines tool palette width" do
      PaceEditor::Constants::TOOL_PALETTE_WIDTH.should eq(80)
    end

    it "defines property panel width" do
      PaceEditor::Constants::PROPERTY_PANEL_WIDTH.should eq(300)
    end

    it "defines status bar height" do
      PaceEditor::Constants::STATUS_BAR_HEIGHT.should eq(25)
    end
  end

  describe "Editor Settings" do
    it "defines default grid size" do
      PaceEditor::Constants::DEFAULT_GRID_SIZE.should eq(16)
    end

    it "defines zoom constraints" do
      PaceEditor::Constants::DEFAULT_ZOOM.should eq(1.0_f32)
      PaceEditor::Constants::MIN_ZOOM.should eq(0.1_f32)
      PaceEditor::Constants::MAX_ZOOM.should eq(5.0_f32)
      PaceEditor::Constants::ZOOM_STEP.should eq(0.1_f32)
    end

    it "defines camera settings" do
      PaceEditor::Constants::CAMERA_PAN_SPEED.should eq(2.0_f32)
      PaceEditor::Constants::CAMERA_ZOOM_SPEED.should eq(0.1_f32)
      PaceEditor::Constants::CAMERA_SMOOTH_FACTOR.should eq(0.1_f32)
    end
  end

  describe "Asset Categories" do
    it "defines supported asset categories" do
      categories = PaceEditor::Constants::ASSET_CATEGORIES
      categories.should contain("backgrounds")
      categories.should contain("characters")
      categories.should contain("sounds")
      categories.should contain("music")
      categories.should contain("scripts")
    end

    it "defines supported image extensions" do
      extensions = PaceEditor::Constants::SUPPORTED_IMAGE_EXTENSIONS
      extensions.should contain(".png")
      extensions.should contain(".jpg")
      extensions.should contain(".jpeg")
      extensions.should contain(".bmp")
      extensions.should contain(".tga")
    end

    it "defines supported audio extensions" do
      extensions = PaceEditor::Constants::SUPPORTED_AUDIO_EXTENSIONS
      extensions.should contain(".wav")
      extensions.should contain(".ogg")
      extensions.should contain(".mp3")
    end
  end

  describe "Dialog System Constants" do
    it "defines dialog node dimensions" do
      PaceEditor::Constants::DEFAULT_DIALOG_NODE_WIDTH.should eq(200)
      PaceEditor::Constants::DEFAULT_DIALOG_NODE_HEIGHT.should eq(100)
    end

    it "defines connection settings" do
      PaceEditor::Constants::DIALOG_CONNECTION_BEZIER_OFFSET.should eq(50.0_f32)
    end
  end

  describe "Animation Constants" do
    it "defines animation FPS settings" do
      PaceEditor::Constants::DEFAULT_ANIMATION_FPS.should eq(12.0_f32)
      PaceEditor::Constants::MIN_ANIMATION_FPS.should eq(1.0_f32)
      PaceEditor::Constants::MAX_ANIMATION_FPS.should eq(60.0_f32)
    end

    it "defines frame duration" do
      PaceEditor::Constants::DEFAULT_FRAME_DURATION.should eq(100)
    end
  end

  describe "Validation Settings" do
    it "defines object limits" do
      PaceEditor::Constants::MAX_OBJECT_NAME_LENGTH.should eq(50)
      PaceEditor::Constants::MAX_DIALOG_TEXT_LENGTH.should eq(1000)
      PaceEditor::Constants::MAX_SCENE_OBJECTS.should eq(100)
    end
  end

  describe "Performance Settings" do
    it "defines cache limits" do
      PaceEditor::Constants::TEXTURE_CACHE_MAX_SIZE.should eq(100)
      PaceEditor::Constants::UNDO_HISTORY_MAX_SIZE.should eq(50)
    end

    it "defines timing settings" do
      PaceEditor::Constants::AUTO_SAVE_INTERVAL.should eq(30)
      PaceEditor::Constants::DOUBLE_CLICK_TIME.should eq(500)
    end
  end

  describe "Color Constants" do
    it "defines UI colors" do
      grid_color = PaceEditor::Constants::GRID_COLOR
      grid_color.r.should eq(200)
      grid_color.g.should eq(200)
      grid_color.b.should eq(200)
      grid_color.a.should eq(100)

      selection_color = PaceEditor::Constants::SELECTION_COLOR
      selection_color.r.should eq(255)
      selection_color.g.should eq(255)
      selection_color.b.should eq(0)
      selection_color.a.should eq(200)
    end
  end
end
