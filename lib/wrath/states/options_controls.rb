module Wrath
  class OptionsControls < Gui
    TABS = [:offline_player_1, :offline_player_2, :online_player, :general]

    def initialize
      super

      @control_waiting_for_key = nil

      init_key_codes
    end

    public
    def body
      vertical spacing: 0, padding: 0 do
        # Choose control group.
        @tabs_group = group do
          @tab_buttons = horizontal padding: 0, spacing: 2 do
            TABS.each do |name|
              radio_button(t.tab[name].text, name, tip: t.tab[name].tip, border_thickness: 0)
            end
          end

          subscribe :changed do |sender, value|
            @control_waiting_for_key = nil
            list_keys

            current = @tab_buttons.find {|elem| elem.value == value }
            @tab_buttons.each {|t| t.enabled = (t != current) }
            current.color, current.background_color = current.background_color, current.color
          end
        end

        scroll_window height: 75, width: $window.width - 10, background_color: BACKGROUND_COLOR do
          @key_grid = grid num_columns: 2, padding: 2.5, spacing: 2.5
        end
      end

      @tabs_group.value = TABS.first
    end

    def extra_buttons
      button(t.button.default.text, tip: t.button.default.tip) do
        controls.reset_to_default
        $window.options_changed
      end
    end


    public
    def update
      if @control_waiting_for_key
        # Check every key to see if it pressed and a valid key.
        @key_codes.each do |code|
          if $window.button_down?(code)
            # If it is defined in Chingu, allow its use. If not, leave the key as it is.
            if symbols = Chingu::Input::CONSTANT_TO_SYMBOL[code]
              symbol = symbols.first
              symbol = :space if symbol == :' '
              controls[@tabs_group.value, @control_waiting_for_key] = symbol
            end

            @control_waiting_for_key = nil
            list_keys
          end
        end
      end

      super
    end

    protected
    # Get all possible key codes supported by Gosu, except escape, which takes us out of the screen.
    def init_key_codes
      @key_codes = (Gosu::KbRangeBegin..Gosu::KbRangeEnd).to_a +
          (Gosu::GpRangeBegin..Gosu::GpRangeEnd).to_a -
          [Gosu::KbEscape]
    end

    protected
    # Make a new list of keys in the main part of the window.
    def list_keys
      @key_grid.with do
        clear

        controls.keys(@tabs_group.value).each do |control|
          key_label = label t.label[control], width: 95
          key = controls[@tabs_group.value, control]
          button_label = key.to_s.tr('_', ' ')
          button(button_label, width: 75) { choose_key control, key_label }
        end
      end
    end

    protected
    # Get ready to pick a key.
    def choose_key(control, key_label)
      key_label.color = Color.rgb(255, 0, 0)
      @control_waiting_for_key = control
      @key_grid.each {|element| element.enabled = false if element.is_a? Fidgit::Button }
    end
  end
end