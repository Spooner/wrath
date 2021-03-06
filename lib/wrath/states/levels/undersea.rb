module Wrath
  class Level
    class Undersea < Level
      trait :timer

      DEFAULT_TILE = Sand
      FILTER_COLOR = Color.rgba(0, 100, 200, 100)
      GOD = Squid

      def medium; :water; end
      def gravity; super * 0.3; end

      def pushed
        every(Seaweed::ANIMATION_DELAY) { Seaweed.all.each(&:animate) }
      end

      def create_objects
        super

        # Top "blockers", not really tangible, so don't update/sync them.
        [10, 16].each do |y|
          x = -14
          while x < $window.width + 20
            Seaweed.create(x: x, y: rand(4) + y)
            x += 6 + rand(6)
          end
        end
      end

      def random_tiles
        num_columns, num_rows, grid = super(DEFAULT_TILE)

      # Add rocky bits.
      (rand(5) + 3).times do
        pos = [rand(num_columns - 4) + 2, rand(num_rows - 7) + 5]
        grid[pos[1]][pos[0]] = Gravel
        Tile::ADJACENT_OFFSETS.sample(rand(5) + 2).each do |offset_x, offset_y|
          grid[pos[1] + offset_x][pos[0] + offset_y] = Gravel
        end
      end

        grid
      end

      def update
        # Slow everything down, due to water resistance.
        objects.each do |object|
          if object.is_a? Fire
            object.destroy
          else
            object.remove_status :burning if object.is_a?(HasStatus) and object.burning?

            if object.is_a? DynamicObject and object.thrown?
              # Todo: Make the dampening based on velocity, so faster things slow quicker.
              multiplier = 1.0 - 0.001 * frame_time
              object.x_velocity *= multiplier
              object.y_velocity *= multiplier
              object.z_velocity *= multiplier
            end
          end
        end

        if milliseconds.div(500).modulo(5) == 0
          Priest.each do |priest|
            if not priest.breathes?(:water) and [:standing, :walking, :mounted].include? priest.state
              offset_x = priest.factor_x > 0 ? 2 : -2
              Bubble.create(x: priest.x + offset_x + random(-1.5, 1.5), y: priest.y - priest.z - random(4, 4.5), zorder: priest.zorder + 0.01)
            end
          end
        end

        super
      end

      def draw
        super

        $window.pixel.draw(0, 0, ZOrder::FOREGROUND, $window.width, $window.height, FILTER_COLOR) if started?
      end
    end
  end
end