module Wrath
class Message
  # Sent by the server to leave the lobby and start a new game.
  class NewGame < Message

    public
    def initialize(level)
      @level = level
    end

    protected
    def action(state)
      raise "Bad level passed, #{@level}" unless @level != Level and @level.ancestors.include? Level

      state.new_game(@level)
    end
  end
end
end