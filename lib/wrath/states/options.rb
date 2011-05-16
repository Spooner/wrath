module Wrath
  class Options < Gui
    PAGES = {
        OptionsAudio => "Audio",
        #OptionsVideo => "Video",
        OptionsControls => "Controls",
    }

    def initialize
      super

      on_input(:escape, :pop_game_state)

      pack :vertical do
        label "Options", font_size: 32

        pack :horizontal, padding: 0 do
          PAGES.each_pair do |state, label|
            button(label) { push_game_state state }
          end
        end

        pack :horizontal, padding: 0 do
          button("Back") { pop_game_state }
        end
      end
    end
  end
end