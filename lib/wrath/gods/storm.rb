module Wrath
  # Storm
  class Storm < God
    SAFE_DARKNESS_COLOR = Color.rgba(0, 0, 0, 100)
    DISASTER_DARKNESS_COLOR = Color.rgba(0, 0, 0, 140)
    LIGHTNING_COLOR = Color.rgba(255, 255, 255, 50)

    def on_disaster_start(sender)
      unless parent.client?
        after(500) { Lightning.create(position: spawn_position(0), parent: parent) }

        schedule_lightning
      end
    end

    def schedule_lightning
      after(1000 + rand(2000)) do
        if in_disaster?
          Lightning.create(position: spawn_position(0), parent: parent)
          schedule_lightning
        end
      end
    end

    def draw
      super

      # Draw overlay to make it look dark.
      if in_disaster?
        if Lightning.all.empty?
          color = DISASTER_DARKNESS_COLOR
          mode = :default
        else
          color = LIGHTNING_COLOR
          mode = :additive
        end
      else
        color = SAFE_DARKNESS_COLOR
        mode = :default
      end

      $window.pixel.draw(0, 0, ZOrder::FOREGROUND, $window.width, $window.height, color, mode )
    end
  end
end