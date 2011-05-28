module Wrath
class Server < GameStates::NetworkServer
  trait :timer

  attr_reader :remote_socket

  public
  def accept_message?(message); [Message::ClientReady].find {|m| message.is_a? m }; end

  public
  def initialize(options = {})
    options = {
        max_connections: 1,
    }.merge! options

    @font = Font["pixelated.ttf", 48]

    super options

    on_input(:escape) { pop_game_state }

    start(options[:address], options[:port])

    settings[:network, :port] = port
  end

  #
  # Called for each new client connecting to our server
  #
  def on_connect(socket)
    log.info { "Player connected: #{socket.inspect}" }
    send_msg(socket, Message::ServerReady.new(settings[:player, :name]))
  end

  def on_disconnect(socket)
    log.info { "Player disconnected: #{socket.inspect}" }
    pop_until_game_state Menu unless current_game_state.is_a? Menu
  end

  def draw
    $window.scale(1.0 / $window.sprite_scale) do
      @font.draw("Waiting for player...", 10, 10, ZOrder::GUI)
    end
  end

  def on_msg(socket, message)
    message.process if message.is_a? Message
  end
  
  def popped
    close
  end
end
end