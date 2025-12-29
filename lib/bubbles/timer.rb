# frozen_string_literal: true
# rbs_inline: enabled

module Bubbles
  # Timer is a countdown timer component.
  #
  # Example:
  #   timer = Bubbles::Timer.new(60.0)  # 60 second countdown
  #
  #   # In your model's init:
  #   def init
  #     [self, @timer.init]
  #   end
  #
  #   # In your model's update:
  #   def update(message)
  #     case message
  #     when Bubbles::Timer::TickMessage, Bubbles::Timer::StartStopMessage
  #       @timer, command = @timer.update(message)
  #       [self, command]
  #     when Bubbles::Timer::TimeoutMessage
  #       # Timer finished!
  #       [self, nil]
  #     end
  #   end
  #
  class Timer
    class TickMessage < Bubbletea::Message
      attr_reader :id #: Integer
      attr_reader :tag #: Integer
      attr_reader :timeout #: bool

      #: (id: Integer, tag: Integer, ?timeout: bool) -> void
      def initialize(id:, tag:, timeout: false)
        super()

        @id = id
        @tag = tag
        @timeout = timeout
      end
    end

    class TimeoutMessage < Bubbletea::Message
      attr_reader :id #: Integer

      #: (id: Integer) -> void
      def initialize(id:)
        super()

        @id = id
      end
    end

    class StartStopMessage < Bubbletea::Message
      attr_reader :id #: Integer
      attr_reader :running #: bool

      #: (id: Integer, running: bool) -> void
      def initialize(id:, running:)
        super()

        @id = id
        @running = running
      end
    end

    # @rbs self.@next_id: Integer
    # @rbs self.@id_mutex: Mutex
    @next_id = 0
    @id_mutex = Mutex.new

    class << self
      #: () -> Integer
      def next_id
        @id_mutex.synchronize do
          @next_id += 1
        end
      end
    end

    attr_reader :timeout #: Float
    attr_reader :interval #: Float
    attr_reader :id #: Integer

    #: (Float, ?interval: Float) -> void
    def initialize(timeout, interval: 1.0)
      @timeout = timeout.to_f
      @interval = interval.to_f
      @id = self.class.next_id
      @tag = 0
      @running = false
    end

    #: () -> Bubbletea::Command?
    def init
      @running = true
      tick
    end

    #: () -> bool
    def running?
      @running && @timeout.positive?
    end

    #: () -> bool
    def timed_out?
      @timeout <= 0
    end

    #: (Bubbletea::Message) -> [Timer, Bubbletea::Command?]
    def update(message)
      case message
      when StartStopMessage
        return [self, nil] if message.id.positive? && message.id != @id

        @running = message.running
        [self, @running ? tick : nil]

      when TickMessage
        return [self, nil] unless @running
        return [self, nil] if message.id.positive? && message.id != @id
        return [self, nil] if message.tag.positive? && message.tag != @tag

        @timeout -= @interval
        @tag += 1

        [self, Bubbletea.batch(tick, timeout_command)]
      else
        [self, nil]
      end
    end

    #: () -> String
    def view
      format_duration(@timeout)
    end

    #: () -> Bubbletea::Command
    def start
      start_stop(true)
    end

    #: () -> Bubbletea::Command
    def stop
      start_stop(false)
    end

    #: () -> Bubbletea::Command
    def toggle
      start_stop(!@running)
    end

    private

    #: (bool) -> Bubbletea::Command
    def start_stop(running)
      current_id = @id
      Bubbletea.send_message(StartStopMessage.new(id: current_id, running: running))
    end

    #: () -> Bubbletea::Command?
    def tick
      return nil unless running?

      current_id = @id
      current_tag = @tag

      Bubbletea.tick(@interval) { TickMessage.new(id: current_id, tag: current_tag) }
    end

    #: () -> Bubbletea::Command?
    def timeout_command
      return nil unless timed_out?

      current_id = @id
      Bubbletea.send_message(TimeoutMessage.new(id: current_id))
    end

    #: (Float) -> String
    def format_duration(seconds)
      return "0s" if seconds <= 0

      total_seconds = seconds.to_i
      hours = total_seconds / 3600
      minutes = (total_seconds % 3600) / 60
      secs = total_seconds % 60

      parts = [] #: Array[String]
      parts << "#{hours}h" if hours.positive?
      parts << "#{minutes}m" if minutes.positive? || hours.positive?
      parts << "#{secs}s"

      parts.join
    end
  end
end
