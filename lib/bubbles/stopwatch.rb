# frozen_string_literal: true
# rbs_inline: enabled

module Bubbles
  # Stopwatch is an elapsed time counter component.
  #
  # Example:
  #   stopwatch = Bubbles::Stopwatch.new
  #
  #   # In your model's init:
  #   def init
  #     [self, @stopwatch.init]
  #   end
  #
  #   # In your model's update:
  #   def update(message)
  #     case message
  #     when Bubbles::Stopwatch::TickMessage, Bubbles::Stopwatch::StartStopMessage, Bubbles::Stopwatch::ResetMessage
  #       @stopwatch, command = @stopwatch.update(message)
  #
  #       [self, command]
  #     end
  #   end
  #
  class Stopwatch
    class TickMessage < Bubbletea::Message
      attr_reader :id #: Integer
      attr_reader :tag #: Integer

      #: (id: Integer, tag: Integer) -> void
      def initialize(id:, tag:)
        super()

        @id = id
        @tag = tag
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

    class ResetMessage < Bubbletea::Message
      attr_reader :id #: Integer

      #: (id: Integer) -> void
      def initialize(id:)
        super()

        @id = id
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

    attr_reader :elapsed #: Float
    attr_reader :interval #: Float
    attr_reader :id #: Integer

    #: (?interval: Float) -> void
    def initialize(interval: 1.0)
      @elapsed = 0.0
      @interval = interval.to_f
      @id = self.class.next_id
      @tag = 0
      @running = false
    end

    #: () -> Bubbletea::Command
    def init
      start
    end

    #: () -> bool
    def running?
      @running
    end

    #: (Bubbletea::Message) -> [Stopwatch, Bubbletea::Command?]
    def update(message)
      case message
      when StartStopMessage
        return [self, nil] if message.id.positive? && message.id != @id

        @running = message.running

        [self, @running ? tick : nil]
      when ResetMessage
        return [self, nil] if message.id.positive? && message.id != @id

        @elapsed = 0.0

        [self, nil]
      when TickMessage
        return [self, nil] unless @running
        return [self, nil] if message.id.positive? && message.id != @id
        return [self, nil] if message.tag.positive? && message.tag != @tag

        @elapsed += @interval
        @tag += 1

        [self, tick]
      else
        [self, nil]
      end
    end

    #: () -> String
    def view
      format_duration(@elapsed)
    end

    #: () -> Bubbletea::Command
    def start
      current_id = @id
      current_tag = @tag

      Bubbletea.sequence(
        Bubbletea.send_message(StartStopMessage.new(id: current_id, running: true)),
        Bubbletea.tick(@interval) { TickMessage.new(id: current_id, tag: current_tag) }
      )
    end

    #: () -> Bubbletea::Command
    def stop
      current_id = @id
      Bubbletea.send_message(StartStopMessage.new(id: current_id, running: false))
    end

    #: () -> Bubbletea::Command
    def toggle
      running? ? stop : start
    end

    #: () -> Bubbletea::Command
    def reset
      current_id = @id
      Bubbletea.send_message(ResetMessage.new(id: current_id))
    end

    private

    #: () -> Bubbletea::Command?
    def tick
      return nil unless running?

      current_id = @id
      current_tag = @tag

      Bubbletea.tick(@interval) { TickMessage.new(id: current_id, tag: current_tag) }
    end

    #: (Float) -> String
    def format_duration(seconds)
      total_seconds = seconds.to_i
      hours = total_seconds / 3600
      minutes = (total_seconds % 3600) / 60
      secs = total_seconds % 60
      ms = ((seconds - total_seconds) * 100).to_i

      if hours.positive?
        format("%<hours>d:%<minutes>02d:%<secs>02d.%<ms>02d", hours: hours, minutes: minutes, secs: secs, ms: ms)
      else
        format("%<minutes>d:%<secs>02d.%<ms>02d", minutes: minutes, secs: secs, ms: ms)
      end
    end
  end
end
