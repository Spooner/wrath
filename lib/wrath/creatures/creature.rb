module Wrath

class Creature < Carriable
  trait :timer

  ACTION_DISTANCE = 12

  EXPLOSION_H_SPEED = 0.04..0.1
  EXPLOSION_Z_VELOCITY = 0.1..0.3

  WOUND_FLASH_PERIOD = 200
  AFTER_WOUND_FLASH_DURATION = 100
  POISON_COLOR = Color.rgba(0, 200, 0, 150)
  HURT_COLOR = Color.rgba(255, 0, 0, 150)

  WALK_ANIMATION_DELAY = 200
  STAND_UP_DELAY = 1000
  FRAME_WALK1 = 0
  FRAME_WALK2 = 1
  FRAME_LIE = 2
  FRAME_THROWN = 2
  FRAME_MOUNTED = 0
  FRAME_CARRIED = 2
  FRAME_SLEEP = 3
  FRAME_DEAD = 3

  attr_reader :state, :speed, :favor, :health, :carrying, :player, :max_health

  attr_writer :player

  def z_offset; super + ((carried? and carrier.mount?) ? -4 : 0); end
  def mount?; false; end
  def alive?; @health > 0; end
  def dead?; @health <= 0; end
  def carrying?; not @carrying.nil?; end
  def empty_handed?; @carrying.nil?; end
  def controlled_by_player?; not @player.nil?; end
  def poisoned?; @poisoned; end

  def initialize(options = {})
    options = {
        health: 10000,
        poisoned: false,
    }.merge! options

    super options

    @max_health = @health = options[:health]
    @speed = options[:speed]
    @poisoned = options[:poisoned]

    @sacrificial_explosion = Emitter.new(BloodDroplet, parent, number: ((favor / 5) + 4), h_speed: EXPLOSION_H_SPEED,
                                            z_velocity: EXPLOSION_Z_VELOCITY)

    @carrying = nil
    @state = :standing
    @player = nil

    @first_wounded_at = @last_wounded_at = nil

    @walking_animation = @frames[FRAME_WALK1..FRAME_WALK2]
    @walking_animation.delay = WALK_ANIMATION_DELAY
  end

  def die!
    # Drop anything you are carrying.
    drop

    # Create a corpse to replace this fellow. This will be created simultaneously on all machines, using the next available id.
    parent.objects << Corpse.create(parent: parent, animation: @frames[FRAME_DEAD..FRAME_DEAD], z_offset: z_offset,
                                    encumbrance: encumbrance, position: position, velocity: velocity,
                                    emitter: @sacrificial_explosion, local: (not parent.client?))

    # Drop off anything you are being carried on (do this after creating the corpse, so we don't get "thrown".
    carrier.drop if carried?
    destroy

    parent.lose!(player) if player and not parent.winner
  end

  def draw_self
    super

    if @overlay_color
      image.silhouette.draw_rot(x, y - z, y, 0, center_x, center_y, factor_x, factor_y, @overlay_color)
    end
  end

  def health=(value)
    original_health = @health
    @health = [[value, 0].max, max_health].min

    if @health < original_health
      @last_wounded_at = milliseconds
      @first_wounded_at = @last_wounded_at unless @first_wounded_at
    end

    # Synchronise health from the server to the client.
    if @health != original_health and parent.host?
      parent.send_message(Message::SetHealth.new(self))
    end

    die! if @health == 0

    @health
  end

  def effective_speed
    @carrying ? (@speed * (1 - @carrying.encumbrance)) : @speed
  end

  def drop
    return unless @carrying and @carrying.can_drop?

    # Drop remotely if this is a local carrier or in the special case of a player carrying another player.
    @parent.send_message Message::PerformAction.new(self) if parent.networked? and (local? or (remote? and @carrying.controlled_by_player?))

    # Dropped objects revert to being owned by the host.
    @carrying.local = (not parent.client?)

    dropping = @carrying
    @carrying = nil

    @parent.objects.push dropping

    # Give a little push if you are stationary, so that it doesn't just land at their feet.
    extra_x_velocity = (x_velocity == 0 and y_velocity == 0) ? factor_x * 0.2 : 0
    dropping.dropped(self, x_velocity * 1.5 + extra_x_velocity, y_velocity * 1.5, z_velocity + 0.5)

    dropping
  end

  def local=(value)
    # Player avatar never change locality.
    super(value) unless controlled_by_player?
  end

  def mount(mount)
    mount.activate(self)
  end

  # The creature's ghost has ascended, after sacrifice.
  def ghost_disappeared

  end

  def pick_up(object)
    return unless object.can_pick_up?

    drop if carrying?

    @parent.send_message(Message::PerformAction.new(self, object)) if @parent.host?

    # Picking up objects, except the other player, changes their locality to that of the carrier.
    object.local = local?

    parent.objects.delete object
    @carrying = object
    @carrying.picked_up(self)

    if (factor_x > 0 and @carrying.factor_x < 0) or
        (factor_x < 0 and @carrying.factor_x > 0)
      @carrying.factor_x *= -1
    end
  end

  # The player performs an action.
  def action
    # Find all objects within range, then check them in order
    # and activate the first on we can (generally, pick it up).
    near_objects = parent.objects - [self]
    near_objects.select! {|g| distance_to(g) <= ACTION_DISTANCE }
    near_objects.sort_by! {|g| distance_to(g) }

    near_objects.each do |object|
      if object.can_be_activated?(self)
        if parent.client?
          # Client needs to ask permission first.
          parent.send_message(Message::RequestAction.new(self, object))
        else
          # Host/local can do it immediately.
          object.activate(self)
        end

        return
      end
    end

    # We couldn't activate anything, so drop what we are carrying, if anything.
    drop if carrying?
  end

  def update
    super

    update_color

    case @state
      when :standing
        @state = :walking if [x_velocity, y_velocity] != [0, 0]
      when :walking
        @state = :standing if velocity == [0, 0, 0]
    end

    # Ensure any carried object faces in the same direction as the player.
    if @carrying
      if (factor_x > 0 and @carrying.factor_x < 0) or
          (factor_x < 0 and @carrying.factor_x > 0)
        @carrying.factor_x *= -1
      end
    end

    self.image = case state
                   when :walking
                     z <= @tile.ground_level ? @walking_animation.next : @frames[FRAME_WALK1]
                   when :standing
                     @frames[FRAME_WALK1]
                   when :carried
                     @frames[FRAME_CARRIED]
                   when :mounted
                     @frames[FRAME_MOUNTED]
                   when :lying
                     @frames[FRAME_LIE]
                   when :thrown
                     @frames[FRAME_THROWN]
                   when :sleeping
                     @frames[FRAME_SLEEP]
                   else
                     raise "unknown state: #{state}"
                 end
  end

  def picked_up(by)
    @state = by.mount? ? :mounted : :carried
    drop
    stop_timer :stand_up
    super(by)
  end

  def dropped(*args)
    @state = :thrown
    super(*args)
  end

  def reset_color
    if poisoned?
      @overlay_color = POISON_COLOR
    else
      @overlay_color = nil
    end
  end

  def poison(duration)
    # TODO: play gulping noise.
    @poisoned = true
    reset_color
    stop_timer(:cure_poison)
    after(duration, name: :cure_poison) { cure_poison }
  end

  def move(angle)
    angle += (Math::sin(milliseconds / 150) * 45) if poisoned?
    set_body_velocity(angle, effective_speed)
  end

  def cure_poison
    @poisoned = false
    reset_color
  end

  def update_color
    # Reset colour if it was a while since we were wounded.
    if @first_wounded_at
      if milliseconds - @last_wounded_at > AFTER_WOUND_FLASH_DURATION
        reset_color
        @first_wounded_at = @last_wounded_at = nil
      else
        if (milliseconds - @first_wounded_at).div(WOUND_FLASH_PERIOD) % 2 == 0
          @overlay_color = HURT_COLOR
        else
          reset_color
        end
      end
    end
  end

  def on_stopped
    case @state
      when :thrown
        # Stand up if we were thrown.
        after(STAND_UP_DELAY, name: :stand_up) { @state = :standing if @state == :thrown }
    end

    super
  end
end
end