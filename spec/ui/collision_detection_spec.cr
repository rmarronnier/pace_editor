require "../spec_helper"

describe "Collision Detection Helper" do
  describe "PaceEditor::Constants.point_in_rect?" do
    it "returns true when point is inside rectangle" do
      point = RL::Vector2.new(x: 50.0_f32, y: 50.0_f32)
      rect = RL::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: 100.0_f32, height: 100.0_f32)
      
      PaceEditor::Constants.point_in_rect?(point, rect).should be_true
    end

    it "returns false when point is outside rectangle" do
      point = RL::Vector2.new(x: 150.0_f32, y: 50.0_f32)
      rect = RL::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: 100.0_f32, height: 100.0_f32)
      
      PaceEditor::Constants.point_in_rect?(point, rect).should be_false
    end

    it "returns true when point is on rectangle edge" do
      point = RL::Vector2.new(x: 100.0_f32, y: 50.0_f32)
      rect = RL::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: 100.0_f32, height: 100.0_f32)
      
      PaceEditor::Constants.point_in_rect?(point, rect).should be_true
    end

    it "returns false when point is below rectangle" do
      point = RL::Vector2.new(x: 50.0_f32, y: 150.0_f32)
      rect = RL::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: 100.0_f32, height: 100.0_f32)
      
      PaceEditor::Constants.point_in_rect?(point, rect).should be_false
    end

    it "returns false when point is above rectangle" do
      point = RL::Vector2.new(x: 50.0_f32, y: -10.0_f32)
      rect = RL::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: 100.0_f32, height: 100.0_f32)
      
      PaceEditor::Constants.point_in_rect?(point, rect).should be_false
    end

    it "returns false when point is left of rectangle" do
      point = RL::Vector2.new(x: -10.0_f32, y: 50.0_f32)
      rect = RL::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: 100.0_f32, height: 100.0_f32)
      
      PaceEditor::Constants.point_in_rect?(point, rect).should be_false
    end

    it "handles zero-sized rectangles" do
      point = RL::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      rect = RL::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: 0.0_f32, height: 0.0_f32)
      
      PaceEditor::Constants.point_in_rect?(point, rect).should be_true
    end

    it "handles negative coordinates" do
      point = RL::Vector2.new(x: -50.0_f32, y: -25.0_f32)
      rect = RL::Rectangle.new(x: -100.0_f32, y: -50.0_f32, width: 100.0_f32, height: 50.0_f32)
      
      PaceEditor::Constants.point_in_rect?(point, rect).should be_true
    end
  end
end