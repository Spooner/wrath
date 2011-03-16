module Wrath
class Message
  class Map < Message
    def initialize(tiles)
      @tiles = tiles
    end

    def process
      state = $window.current_game_state
      if state.is_a? Play
        state.create_map(@tiles)
      else
        log.warn { "Failed to recreate map; wrong game mode" }
      end
    end
  end
end
end