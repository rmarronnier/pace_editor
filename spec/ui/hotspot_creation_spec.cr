require "../spec_helper"

describe "Hotspot Creation" do
  describe "ToolPalette hotspot creation methods" do

    describe "add_hotspot" do
      it "creates hotspot with correct constructor parameters" do
        initial_count = editor_state.current_scene.not_nil!.hotspots.size
        
        # Call the private method via send if available, or test indirectly
        tool_palette.send(:add_hotspot) if tool_palette.responds_to?(:add_hotspot)
        
        # Verify hotspot was added
        editor_state.current_scene.not_nil!.hotspots.size.should eq(initial_count + 1)
      end

      it "sets hotspot properties correctly" do
        tool_palette.send(:add_hotspot) if tool_palette.responds_to?(:add_hotspot)
        
        hotspot = editor_state.current_scene.not_nil!.hotspots.last
        hotspot.description.should eq("New hotspot")
        hotspot.cursor_type.should eq(:hand)
      end

      it "selects newly created hotspot" do
        tool_palette.send(:add_hotspot) if tool_palette.responds_to?(:add_hotspot)
        
        hotspot = editor_state.current_scene.not_nil!.hotspots.last
        editor_state.selected_object.should eq(hotspot.name)
      end
    end

    describe "create_rectangular_hotspot" do
      it "creates rectangular hotspot with correct parameters" do
        initial_count = editor_state.current_scene.not_nil!.hotspots.size
        
        tool_palette.send(:create_rectangular_hotspot) if tool_palette.responds_to?(:create_rectangular_hotspot)
        
        editor_state.current_scene.not_nil!.hotspots.size.should eq(initial_count + 1)
        
        hotspot = editor_state.current_scene.not_nil!.hotspots.last
        hotspot.description.should eq("Rectangle hotspot")
        hotspot.position.x.should eq(300.0_f32)
        hotspot.position.y.should eq(200.0_f32)
        hotspot.size.x.should eq(100.0_f32)
        hotspot.size.y.should eq(100.0_f32)
      end

      it "marks editor as dirty after creation" do
        tool_palette.send(:create_rectangular_hotspot) if tool_palette.responds_to?(:create_rectangular_hotspot)
        
        # Verify state is marked as dirty (implementation dependent)
        # This would need to be mocked or tested through the actual dirty flag
      end
    end

    describe "create_circular_hotspot" do
      it "creates circular hotspot with correct parameters" do
        initial_count = editor_state.current_scene.not_nil!.hotspots.size
        
        tool_palette.send(:create_circular_hotspot) if tool_palette.responds_to?(:create_circular_hotspot)
        
        editor_state.current_scene.not_nil!.hotspots.size.should eq(initial_count + 1)
        
        hotspot = editor_state.current_scene.not_nil!.hotspots.last
        hotspot.description.should eq("Circle hotspot")
        hotspot.position.x.should eq(300.0_f32)
        hotspot.position.y.should eq(200.0_f32)
        hotspot.size.x.should eq(80.0_f32)
        hotspot.size.y.should eq(80.0_f32)
      end
    end

    describe "hotspot name generation" do
      it "generates unique names for hotspots" do
        # Create multiple hotspots and verify names are unique
        tool_palette.send(:add_hotspot) if tool_palette.responds_to?(:add_hotspot)
        tool_palette.send(:create_rectangular_hotspot) if tool_palette.responds_to?(:create_rectangular_hotspot)
        tool_palette.send(:create_circular_hotspot) if tool_palette.responds_to?(:create_circular_hotspot)
        
        scene = editor_state.current_scene.not_nil!
        names = scene.hotspots.map(&.name)
        
        # All names should be unique
        names.uniq.size.should eq(names.size)
      end

      it "includes timestamp in hotspot names" do
        tool_palette.send(:create_rectangular_hotspot) if tool_palette.responds_to?(:create_rectangular_hotspot)
        
        hotspot = editor_state.current_scene.not_nil!.hotspots.last
        hotspot.name.should contain("rect_hotspot_")
        
        # Name should include a timestamp-like number
        name_parts = hotspot.name.split("_")
        name_parts.last.to_i64?.should_not be_nil
      end
    end

    describe "error handling" do
      it "handles case when no scene is present" do
        editor_state.current_scene = nil
        
        initial_hotspot_count = 0
        
        # These methods should not crash when no scene is present
        tool_palette.send(:add_hotspot) if tool_palette.responds_to?(:add_hotspot)
        tool_palette.send(:create_rectangular_hotspot) if tool_palette.responds_to?(:create_rectangular_hotspot)
        tool_palette.send(:create_circular_hotspot) if tool_palette.responds_to?(:create_circular_hotspot)
        
        # No hotspots should be created and no errors should occur
      end
    end
  end
end