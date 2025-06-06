require "spec"

# Minimal spec that doesn't require the full point_click_engine to test basic Crystal code

enum TestMode
  Scene
  Character
  Dialog
end

class TestClass
  property name : String

  def initialize(@name : String)
  end
end

describe "PaceEditor Basic" do
  it "can run basic Crystal tests" do
    result = 1 + 1
    result.should eq(2)
  end

  it "can create basic enums" do
    mode = TestMode::Scene
    mode.should eq(TestMode::Scene)
  end

  it "can create basic classes" do
    test = TestClass.new("test")
    test.name.should eq("test")
  end
end
