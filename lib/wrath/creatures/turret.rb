module Wrath
  # Turret doesn't move and counts as a
  class Turret < Creature
    DAMAGE = 10

    def hurts?(other); not other.is_a?(Turret); end
    def dazed_offset_x; 0; end

    public
    def initialize(options = {})
      options = {
          damage_per_hit: DAMAGE,
          favor: 6,
          health: 10,
          encumbrance: 0.2,
          move_type: :none,
          animation: "turret_6x6.png",
          sacrifice_particle: Spark,
      }.merge! options

      super(options)
    end

    def schedule_move
      # Do nothing.
    end

    def start_jump

    end
  end
end