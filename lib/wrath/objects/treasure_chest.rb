module Wrath
  class TreasureChest < DynamicObject
    OPEN_IMAGE = 1

    public
    def initialize(options = {})
      options = {
        favor: 15,
        encumbrance: 0.8,
        elasticity: 0.1,
        z_offset: -2,
        animation: "treasure_chest_8x8.png",
      }.merge! options

      super options

      @open = false
    end

    def can_be_activated?(actor)
      actor.empty_handed?
    end

    def activated_by(actor)
      if @open or not parent.started? # Allow a container to pick me up at start of game.
        actor.pick_up(self)
      else
        parent.send_message(Message::PerformAction.new(actor, self)) if parent.host?
        @open = true
        self.image = @frames[OPEN_IMAGE]
      end
    end
  end
end