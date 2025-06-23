require "spec"
require "yaml"

# Truly headless tests that don't load any Raylib dependencies

describe "Truly Headless Tests" do
  describe "Basic functionality" do
    it "can run tests without opening a window" do
      # This test runs without any graphics initialization
      (1 + 1).should eq(2)
    end

    it "can test string manipulation" do
      text = "Hello, World!"
      text.upcase.should eq("HELLO, WORLD!")
    end

    it "can test file operations" do
      temp_file = File.tempname("test")
      File.write(temp_file, "test content")

      File.read(temp_file).should eq("test content")

      File.delete(temp_file)
    end
  end

  describe "YAML parsing" do
    it "can work with YAML" do
      yaml_content = <<-YAML
      name: test
      value: 42
      YAML

      data = YAML.parse(yaml_content)
      data["name"].as_s.should eq("test")
      data["value"].as_i.should eq(42)
    end
  end

  describe "Model-like structures" do
    it "can create and test simple models" do
      # Use a NamedTuple instead of a class
      anim = {name: "walk", fps: 8.0_f32, loop: true}
      anim[:name].should eq("walk")
      anim[:fps].should eq(8.0_f32)
      anim[:loop].should be_true
    end
  end
end
