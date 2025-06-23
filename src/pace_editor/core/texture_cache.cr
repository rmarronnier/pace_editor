module PaceEditor::Core
  # Manages texture loading and caching for performance optimization
  class TextureCache
    include PaceEditor::Constants
    
    # Cache storage
    @@cache = Hash(String, CachedTexture).new
    @@access_times = Hash(String, Time).new
    @@max_cache_size = TEXTURE_CACHE_MAX_SIZE
    @@total_memory_usage = 0_u64
    
    # Texture metadata
    struct CachedTexture
      property texture : RL::Texture2D
      property file_path : String
      property file_size : UInt64
      property load_time : Time
      property access_count : UInt32
      property memory_usage : UInt64
      
      def initialize(@texture : RL::Texture2D, @file_path : String, @file_size : UInt64)
        @load_time = Time.utc
        @access_count = 0_u32
        @memory_usage = calculate_memory_usage
      end
      
      private def calculate_memory_usage : UInt64
        # Estimate memory usage: width * height * 4 bytes (RGBA)
        (@texture.width * @texture.height * 4).to_u64
      end
      
      def mark_accessed
        @access_count += 1
      end
    end
    
    # Statistics tracking
    @@stats = {
      "cache_hits" => 0_u64,
      "cache_misses" => 0_u64,
      "evictions" => 0_u64,
      "load_errors" => 0_u64
    }
    
    # Load and cache a texture
    def self.get_texture(file_path : String) : RL::Texture2D?
      # Normalize path
      normalized_path = File.expand_path(file_path)
      
      # Check cache first
      if cached_texture = @@cache[normalized_path]?
        cached_texture.mark_accessed
        @@access_times[normalized_path] = Time.utc
        @@stats["cache_hits"] += 1
        return cached_texture.texture
      end
      
      # Load texture if not cached
      @@stats["cache_misses"] += 1
      load_texture(normalized_path)
    end
    
    # Load texture from file
    private def self.load_texture(file_path : String) : RL::Texture2D?
      begin
        # Check if file exists and is supported
        unless File.exists?(file_path)
          raise PaceEditor::Errors::AssetNotFoundError.new(file_path)
        end
        
        extension = File.extname(file_path).downcase
        unless SUPPORTED_IMAGE_EXTENSIONS.includes?(extension)
          raise PaceEditor::Errors::UnsupportedAssetError.new(file_path, extension)
        end
        
        # Get file size
        file_size = File.size(file_path).to_u64
        
        # Check cache size before loading
        ensure_cache_space(file_size)
        
        # Load texture using Raylib
        texture = RL.load_texture(file_path)
        
        # Verify texture loaded successfully
        if texture.width == 0 || texture.height == 0
          RL.unload_texture(texture)
          raise PaceEditor::Errors::AssetError.new(file_path, "Failed to load texture data")
        end
        
        # Cache the texture
        cached_texture = CachedTexture.new(texture, file_path, file_size)
        @@cache[file_path] = cached_texture
        @@access_times[file_path] = Time.utc
        @@total_memory_usage += cached_texture.memory_usage
        
        texture
      rescue ex : PaceEditor::Errors::PaceEditorError
        @@stats["load_errors"] += 1
        raise ex
      rescue ex
        @@stats["load_errors"] += 1
        raise PaceEditor::Errors::AssetError.new(file_path, "Unexpected error: #{ex.message}")
      end
    end
    
    # Ensure there's space in cache for new texture
    private def self.ensure_cache_space(required_memory : UInt64)
      # Remove old entries if cache is full
      while @@cache.size >= @@max_cache_size
        evict_least_recently_used
      end
      
      # Estimate memory limit (rough calculation)
      memory_limit = @@max_cache_size * 1024 * 1024  # Assume 1MB per texture average
      while @@total_memory_usage + required_memory > memory_limit && @@cache.any?
        evict_least_recently_used
      end
    end
    
    # Remove least recently used texture from cache
    private def self.evict_least_recently_used
      return if @@cache.empty?
      
      # Find least recently accessed texture
      oldest_path = @@access_times.min_by { |path, time| time }[0]
      
      if cached_texture = @@cache[oldest_path]?
        # Unload texture from GPU
        RL.unload_texture(cached_texture.texture)
        
        # Remove from cache
        @@cache.delete(oldest_path)
        @@access_times.delete(oldest_path)
        @@total_memory_usage -= cached_texture.memory_usage
        @@stats["evictions"] += 1
      end
    end
    
    # Check if texture is cached
    def self.cached?(file_path : String) : Bool
      normalized_path = File.expand_path(file_path)
      @@cache.has_key?(normalized_path)
    end
    
    # Remove specific texture from cache
    def self.evict_texture(file_path : String) : Bool
      normalized_path = File.expand_path(file_path)
      
      if cached_texture = @@cache[normalized_path]?
        RL.unload_texture(cached_texture.texture)
        @@cache.delete(normalized_path)
        @@access_times.delete(normalized_path)
        @@total_memory_usage -= cached_texture.memory_usage
        true
      else
        false
      end
    end
    
    # Clear entire cache
    def self.clear_cache
      @@cache.each do |path, cached_texture|
        RL.unload_texture(cached_texture.texture)
      end
      
      @@cache.clear
      @@access_times.clear
      @@total_memory_usage = 0_u64
    end
    
    # Get cache statistics
    def self.get_stats : Hash(String, UInt64 | UInt32 | Float64)
      hit_rate = if @@stats["cache_hits"] + @@stats["cache_misses"] > 0
        @@stats["cache_hits"].to_f64 / (@@stats["cache_hits"] + @@stats["cache_misses"]) * 100
      else
        0.0
      end
      
      {
        "cache_size" => @@cache.size.to_u64,
        "max_cache_size" => @@max_cache_size.to_u64,
        "memory_usage_mb" => (@@total_memory_usage / (1024 * 1024)).to_u64,
        "cache_hits" => @@stats["cache_hits"],
        "cache_misses" => @@stats["cache_misses"],
        "evictions" => @@stats["evictions"],
        "load_errors" => @@stats["load_errors"],
        "hit_rate_percent" => hit_rate
      }
    end
    
    # Get detailed cache info
    def self.get_cache_info : Array(Hash(String, String | UInt32 | UInt64))
      @@cache.map do |path, cached_texture|
        {
          "path" => File.basename(path),
          "full_path" => path,
          "width" => cached_texture.texture.width.to_u32,
          "height" => cached_texture.texture.height.to_u32,
          "memory_mb" => (cached_texture.memory_usage / (1024 * 1024)).to_u64,
          "access_count" => cached_texture.access_count,
          "age_seconds" => (Time.utc - cached_texture.load_time).total_seconds.to_u64
        }
      end.sort_by { |info| info["access_count"].as(UInt32) }.reverse
    end
    
    # Configure cache settings
    def self.set_max_cache_size(size : Int32)
      @@max_cache_size = size
      
      # Evict excess entries if new size is smaller
      while @@cache.size > @@max_cache_size
        evict_least_recently_used
      end
    end
    
    # Reset statistics
    def self.reset_stats
      @@stats = {
        "cache_hits" => 0_u64,
        "cache_misses" => 0_u64,
        "evictions" => 0_u64,
        "load_errors" => 0_u64
      }
    end
    
    # Cleanup method to call on shutdown
    def self.cleanup
      clear_cache
      reset_stats
    end
    
    # Validate cache integrity
    def self.validate_cache : Array(String)
      errors = [] of String
      
      @@cache.each do |path, cached_texture|
        # Check if file still exists
        unless File.exists?(path)
          errors << "Cached texture file no longer exists: #{path}"
        end
        
        # Check if texture is valid
        if cached_texture.texture.width == 0 || cached_texture.texture.height == 0
          errors << "Invalid texture dimensions: #{path}"
        end
      end
      
      errors
    end
  end
end