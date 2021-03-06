module Wrath
  class NetworkOverlay < Overlay
    trait :timer

    MAX_HISTORY = 300
    SCALE = 250.0
    SENT_COLOR = Color.rgba(0, 0, 255, 100)
    RECEIVED_COLOR = Color.rgba(0, 255, 0, 100)
    TEXT_COLOR = Color.rgba(255, 255, 255, 100)

    def initialize(network)
      super()

      @network = network
      @network.reset_counters

      every(1000) { count }

      @font = Font[15]

      @seconds = [] # Recorded values from each second.
    end

    def average_over(time, y)
      time = [time, @seconds.size].min
      bytes_sent, bytes_received = 0, 0
      packets_sent, packets_received = 0, 0
      @seconds[-time..-1].each do |second|
        bytes_sent += second[:bytes_sent]
        bytes_received += second[:bytes_received]
        packets_sent += second[:packets_sent]
        packets_received += second[:packets_received]
      end

      str = "%7ds %15d %5d %20d %5d" % [
          time,
          (bytes_sent / time).round, (packets_sent / time).round,
          (bytes_received / time).round, (packets_received / time).round
      ]

      @font.draw str, 0, y, ZOrder::GUI, 1, 1, TEXT_COLOR
    end

    def draw
      @font.draw "Over(s)  Sent(b/s | pkt/s) Received(b/s | pkt/s)", 0, $window.height - 80, ZOrder::GUI, 1, 1, TEXT_COLOR

      unless @seconds.empty?
        average_over(1, $window.height - 60)
        average_over(10, $window.height - 40)
        average_over(60, $window.height - 20)

        pixel = $window.pixel
        @seconds.each_with_index do |data, i|
          sent_height, received_height = data[:bytes_sent] / SCALE, data[:bytes_received] / SCALE
          pixel.draw i, 400 - sent_height, ZOrder::GUI, 1, sent_height, SENT_COLOR
          pixel.draw i, 400 - received_height, ZOrder::GUI, 1, received_height, RECEIVED_COLOR
        end
      end
    end

    def count
      @seconds.shift if @seconds.size == MAX_HISTORY
      @seconds << {
          bytes_sent: @network.bytes_sent,
          bytes_received: @network.bytes_received,
          packets_sent: @network.packets_sent,
          packets_received: @network.packets_received
      }
      log.debug { "Over the last second, sent #{@network.bytes_sent} bytes in #{@network.packets_sent} packets; and received #{@network.bytes_received} bytes in #{@network.packets_received} packets" }
      @network.reset_counters
    end
  end
end