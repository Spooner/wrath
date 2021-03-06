module Wrath
  # X marks the spot where something is buried!
  class X < Sack
    def zorder; ZOrder::TILES; end

    public
    def initialize(options = {})
      options = {
          animation: "x_8x8.png",
          drop_velocity: [0, 0, 1.5],
          casts_shadow: false,
          scale: 0.7,
          rotation_center: :center_center,
      }.merge! options

      super options
    end
  end
end