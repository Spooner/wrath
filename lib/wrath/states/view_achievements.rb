module Wrath
  class ProgressBar < Fidgit::Label
    BACKGROUND_COLOR = Color.rgb(150, 150, 150)
    BAR_COLOR = Color.rgb(255, 255, 255)
    TEXT_COLOR = Color.rgb(0, 0, 0)

    def initialize(total, required, options = {})
      options = {
          background_color: BACKGROUND_COLOR,
          color: TEXT_COLOR,
          padding_left: 12,
      }.merge! options

      super("#{total} / #{required}", options)

      @progress = [total.to_f / required, 1].min
    end

    def draw_background
      super
      draw_rect(x, y, width * @progress , height, z, BAR_COLOR) if @progress > 0
    end
  end

  class ViewAchievements  < Gui
    ACHIEVEMENT_BACKGROUND_COLOR = Color.rgb(0, 0, 50)
    WINDOW_BACKGROUND_COLOR = Color.rgb(0, 0, 100)

    INCOMPLETE_TITLE_COLOR = Color.rgb(150, 150, 150)
    COMPLETE_TITLE_COLOR = Color.rgb(0, 255, 0)
    UNLOCK_BACKGROUND_COLOR = Color.rgb(50, 50, 50)

    def initialize
      super

      add_inputs(
          c: :pop_game_state,
          escape: :pop_game_state
      )

      pack :vertical do
        pack :horizontal, padding: 0 do |packer|
          packer.label "Achievements", font_size: 32
          completed = achievement_manager.achievements.count {|a| a.complete? }
          ProgressBar.new(completed, achievement_manager.achievements.size,
                                    parent: packer, width: 400, font_size: 32)
        end

        scroll_window width: $window.width - 50, height: $window.height - 150, background_color: WINDOW_BACKGROUND_COLOR do
          pack :vertical, spacing: 5 do
            achievement_manager.achievements.each do |achieve|
              pack :vertical, spacing: 0, background_color: ACHIEVEMENT_BACKGROUND_COLOR do
                pack :horizontal, padding: 0, spacing: 0 do |packer|
                  # title
                  color = achieve.complete? ? COMPLETE_TITLE_COLOR : INCOMPLETE_TITLE_COLOR
                  packer.label achieve.title, width: 390, font_size: 20, color: color

                  # Progress bar, if needed.
                  if achieve.complete?
                    completed_at = achievement_manager.completion_time(achieve.name)
                    packer.label completed_at, font_size: 15, padding_left: 0
                  else
                    ProgressBar.new(achieve.total, achieve.required,
                                    parent: packer, width: 225, height: 20, font_size: 15)
                  end
                end

                # Description of what has been done.
                text_area text: achieve.description, font_size: 15, width: $window.width - 150,
                          background_color: ACHIEVEMENT_BACKGROUND_COLOR, enabled: false

                if achieve.complete? and not achieve.unlocks.empty?
                  pack :horizontal, padding: 0, spacing: 4 do
                    achieve.unlocks.each do |unlock|
                      icon = ScaledImage.new(unlock.icon, sprite_scale * 0.75)
                      label "", icon: icon, tip: "Unlocked: #{unlock.title}", background_color: UNLOCK_BACKGROUND_COLOR
                    end
                  end
                end
              end
            end
          end
        end

        pack :horizontal, padding: 0 do
          button("(C)ancel") { pop_game_state }
        end
      end
    end
  end
end