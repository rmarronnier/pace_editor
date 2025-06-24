# Test character implementation for specs
module PointClickEngine::Characters
  class TestCharacter < Character
    def initialize(@name : String)
      super(@name, RL::Vector2.new(x: 0, y: 0), RL::Vector2.new(x: 64, y: 128))
      @dialogue_system_data = nil # Simplified for tests
    end

    def on_interact(interactor : Character)
      # No-op for tests
    end

    def on_look
      # No-op for tests
    end

    def on_talk
      # No-op for tests
    end

    def on_use(item : String)
      # No-op for tests
    end
  end
end
