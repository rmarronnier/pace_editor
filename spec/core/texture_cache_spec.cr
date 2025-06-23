require "../spec_helper"

describe PaceEditor::Core::TextureCache do
  # Create a mock texture for testing
  let(mock_texture) { RL::Texture2D.new(id: 1_u32, width: 100, height: 100, mipmaps: 1, format: 1) }
  
  # Create temporary test files
  let(temp_dir) { File.tempname }
  let(test_image_path) { File.join(temp_dir, "test.png") }
  let(test_invalid_path) { File.join(temp_dir, "nonexistent.png") }
  
  before_each do
    # Clear cache before each test
    PaceEditor::Core::TextureCache.clear_cache
    PaceEditor::Core::TextureCache.reset_stats
    
    # Create temp directory and test file
    Dir.mkdir_p(temp_dir)
    
    # Create a minimal PNG file (1x1 transparent pixel)
    png_data = Bytes[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  # PNG signature
      0x00, 0x00, 0x00, 0x0D,                           # IHDR chunk length
      0x49, 0x48, 0x44, 0x52,                           # IHDR
      0x00, 0x00, 0x00, 0x01,                           # Width: 1
      0x00, 0x00, 0x00, 0x01,                           # Height: 1
      0x08, 0x06, 0x00, 0x00, 0x00,                     # Bit depth, color type, compression, filter, interlace
      0x1F, 0x15, 0xC4, 0x89,                           # CRC
      0x00, 0x00, 0x00, 0x0A,                           # IDAT chunk length
      0x49, 0x44, 0x41, 0x54,                           # IDAT
      0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01,  # Compressed data
      0xE2, 0x21, 0xBC, 0x33,                           # CRC
      0x00, 0x00, 0x00, 0x00,                           # IEND chunk length
      0x49, 0x45, 0x4E, 0x44,                           # IEND
      0xAE, 0x42, 0x60, 0x82                            # CRC
    ]
    
    File.write(test_image_path, png_data)
  end
  
  after_each do
    # Clean up
    FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    PaceEditor::Core::TextureCache.clear_cache
  end
  
  describe ".get_texture" do
    context "when file exists and is supported" do
      it "loads and caches texture" do
        # Note: This test may fail in headless environment due to Raylib requirements
        # In a real test environment with proper Raylib setup, this should work
        pending "requires Raylib graphics context" do
          texture = PaceEditor::Core::TextureCache.get_texture(test_image_path)
          texture.should_not be_nil
          
          # Verify it was cached
          PaceEditor::Core::TextureCache.cached?(test_image_path).should be_true
          
          # Second call should hit cache
          texture2 = PaceEditor::Core::TextureCache.get_texture(test_image_path)
          texture2.should eq(texture)
          
          stats = PaceEditor::Core::TextureCache.get_stats
          stats["cache_hits"].should eq(1_u64)
          stats["cache_misses"].should eq(1_u64)
        end
      end
    end
    
    context "when file does not exist" do
      it "raises AssetNotFoundError" do
        expect_raises(PaceEditor::Errors::AssetNotFoundError) do
          PaceEditor::Core::TextureCache.get_texture(test_invalid_path)
        end
        
        stats = PaceEditor::Core::TextureCache.get_stats
        stats["load_errors"].should eq(1_u64)
      end
    end
    
    context "when file has unsupported extension" do
      let(unsupported_file) { File.join(temp_dir, "test.xyz") }
      
      it "raises UnsupportedAssetError" do
        File.write(unsupported_file, "test content")
        
        expect_raises(PaceEditor::Errors::UnsupportedAssetError) do
          PaceEditor::Core::TextureCache.get_texture(unsupported_file)
        end
      end
    end
  end
  
  describe ".cached?" do
    it "returns false for non-cached textures" do
      PaceEditor::Core::TextureCache.cached?(test_image_path).should be_false
    end
    
    it "normalizes file paths" do
      relative_path = File.basename(test_image_path)
      Dir.cd(File.dirname(test_image_path)) do
        PaceEditor::Core::TextureCache.cached?(relative_path).should be_false
      end
    end
  end
  
  describe ".evict_texture" do
    it "removes specific texture from cache" do
      pending "requires Raylib graphics context" do
        # Load texture first
        PaceEditor::Core::TextureCache.get_texture(test_image_path)
        PaceEditor::Core::TextureCache.cached?(test_image_path).should be_true
        
        # Evict it
        result = PaceEditor::Core::TextureCache.evict_texture(test_image_path)
        result.should be_true
        PaceEditor::Core::TextureCache.cached?(test_image_path).should be_false
      end
    end
    
    it "returns false for non-cached texture" do
      result = PaceEditor::Core::TextureCache.evict_texture(test_image_path)
      result.should be_false
    end
  end
  
  describe ".clear_cache" do
    it "removes all cached textures" do
      pending "requires Raylib graphics context" do
        # Load some textures
        PaceEditor::Core::TextureCache.get_texture(test_image_path)
        
        stats_before = PaceEditor::Core::TextureCache.get_stats
        stats_before["cache_size"].should eq(1_u64)
        
        # Clear cache
        PaceEditor::Core::TextureCache.clear_cache
        
        stats_after = PaceEditor::Core::TextureCache.get_stats
        stats_after["cache_size"].should eq(0_u64)
        stats_after["memory_usage_mb"].should eq(0_u64)
      end
    end
  end
  
  describe ".get_stats" do
    it "returns cache statistics" do
      stats = PaceEditor::Core::TextureCache.get_stats
      
      stats["cache_size"].should eq(0_u64)
      stats["max_cache_size"].should eq(PaceEditor::Constants::TEXTURE_CACHE_MAX_SIZE.to_u64)
      stats["memory_usage_mb"].should eq(0_u64)
      stats["cache_hits"].should eq(0_u64)
      stats["cache_misses"].should eq(0_u64)
      stats["evictions"].should eq(0_u64)
      stats["load_errors"].should eq(0_u64)
      stats["hit_rate_percent"].should eq(0.0)
    end
    
    it "calculates hit rate correctly" do
      pending "requires Raylib graphics context" do
        # Simulate cache hits and misses
        PaceEditor::Core::TextureCache.get_texture(test_image_path)  # miss
        PaceEditor::Core::TextureCache.get_texture(test_image_path)  # hit
        PaceEditor::Core::TextureCache.get_texture(test_image_path)  # hit
        
        stats = PaceEditor::Core::TextureCache.get_stats
        stats["cache_hits"].should eq(2_u64)
        stats["cache_misses"].should eq(1_u64)
        stats["hit_rate_percent"].should eq(66.67)  # Approximately
      end
    end
  end
  
  describe ".get_cache_info" do
    it "returns detailed cache information" do
      info = PaceEditor::Core::TextureCache.get_cache_info
      info.should be_a(Array(Hash(String, String | UInt32 | UInt64)))
      info.empty?.should be_true
    end
    
    it "provides detailed texture information" do
      pending "requires Raylib graphics context" do
        PaceEditor::Core::TextureCache.get_texture(test_image_path)
        
        info = PaceEditor::Core::TextureCache.get_cache_info
        info.size.should eq(1)
        
        texture_info = info.first
        texture_info["path"].should eq("test.png")
        texture_info["full_path"].should eq(File.expand_path(test_image_path))
        texture_info["width"].should be_a(UInt32)
        texture_info["height"].should be_a(UInt32)
        texture_info["access_count"].should eq(1_u32)
      end
    end
  end
  
  describe ".set_max_cache_size" do
    it "updates maximum cache size" do
      PaceEditor::Core::TextureCache.set_max_cache_size(50)
      
      stats = PaceEditor::Core::TextureCache.get_stats
      stats["max_cache_size"].should eq(50_u64)
    end
    
    it "evicts excess entries when size is reduced" do
      pending "requires Raylib graphics context and multiple test files" do
        # This would require creating multiple test files and loading them
        # to test the eviction behavior when cache size is reduced
      end
    end
  end
  
  describe ".preload_directory" do
    let(asset_dir) { File.join(temp_dir, "assets") }
    let(subfolder) { File.join(asset_dir, "subfolder") }
    
    before_each do
      Dir.mkdir_p(subfolder)
      
      # Create test image files
      File.write(File.join(asset_dir, "image1.png"), File.read(test_image_path))
      File.write(File.join(asset_dir, "image2.jpg"), "fake jpg")
      File.write(File.join(asset_dir, "script.lua"), "-- lua script")
      File.write(File.join(subfolder, "image3.png"), File.read(test_image_path))
    end
    
    it "preloads images from directory" do
      pending "requires Raylib graphics context" do
        PaceEditor::Core::TextureCache.preload_directory(asset_dir, recursive: false)
        
        # Should load PNG and JPG files from main directory only
        stats = PaceEditor::Core::TextureCache.get_stats
        stats["cache_size"].should eq(2_u64)  # image1.png and image2.jpg
      end
    end
    
    it "preloads images recursively" do
      pending "requires Raylib graphics context" do
        PaceEditor::Core::TextureCache.preload_directory(asset_dir, recursive: true)
        
        # Should load all image files including subdirectories
        stats = PaceEditor::Core::TextureCache.get_stats
        stats["cache_size"].should eq(3_u64)  # All PNG and JPG files
      end
    end
    
    it "ignores non-existent directories" do
      PaceEditor::Core::TextureCache.preload_directory("/nonexistent/path")
      # Should not raise an exception
      
      stats = PaceEditor::Core::TextureCache.get_stats
      stats["cache_size"].should eq(0_u64)
    end
  end
  
  describe ".preload_textures" do
    it "preloads specific texture files" do
      pending "requires Raylib graphics context" do
        file_paths = [test_image_path]
        PaceEditor::Core::TextureCache.preload_textures(file_paths)
        
        PaceEditor::Core::TextureCache.cached?(test_image_path).should be_true
      end
    end
  end
  
  describe ".handle_memory_pressure" do
    it "reduces cache size under memory pressure" do
      pending "requires Raylib graphics context and multiple textures" do
        # Would need to load multiple textures and then trigger memory pressure
        # to test eviction behavior
      end
    end
  end
  
  describe ".validate_cache" do
    it "returns empty array for valid cache" do
      errors = PaceEditor::Core::TextureCache.validate_cache
      errors.empty?.should be_true
    end
    
    it "detects missing files" do
      pending "requires Raylib graphics context" do
        # Load texture
        PaceEditor::Core::TextureCache.get_texture(test_image_path)
        
        # Delete the file
        File.delete(test_image_path)
        
        # Validate cache
        errors = PaceEditor::Core::TextureCache.validate_cache
        errors.size.should eq(1)
        errors.first.should contain("no longer exists")
      end
    end
  end
  
  describe ".reset_stats" do
    it "resets all statistics" do
      # Simulate some activity first
      begin
        PaceEditor::Core::TextureCache.get_texture(test_invalid_path)
      rescue PaceEditor::Errors::AssetNotFoundError
        # Expected
      end
      
      stats_before = PaceEditor::Core::TextureCache.get_stats
      stats_before["load_errors"].should eq(1_u64)
      
      PaceEditor::Core::TextureCache.reset_stats
      
      stats_after = PaceEditor::Core::TextureCache.get_stats
      stats_after["load_errors"].should eq(0_u64)
    end
  end
  
  describe ".cleanup" do
    it "performs full cleanup" do
      PaceEditor::Core::TextureCache.cleanup
      
      stats = PaceEditor::Core::TextureCache.get_stats
      stats["cache_size"].should eq(0_u64)
      stats["cache_hits"].should eq(0_u64)
      stats["cache_misses"].should eq(0_u64)
    end
  end
  
  describe "cache eviction behavior" do
    it "evicts least recently used textures when cache is full" do
      pending "requires Raylib graphics context and cache size management" do
        # This would test the LRU eviction policy when the cache reaches its limit
      end
    end
  end
  
  describe "error handling" do
    it "handles corrupted image files gracefully" do
      corrupted_file = File.join(temp_dir, "corrupted.png")
      File.write(corrupted_file, "not a valid png file")
      
      expect_raises(PaceEditor::Errors::AssetError) do
        PaceEditor::Core::TextureCache.get_texture(corrupted_file)
      end
    end
  end
end