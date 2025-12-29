# frozen_string_literal: true
# rbs_inline: enabled

require_relative "spinner/spinners"

module Bubbles
  # Spinner is an animated activity indicator component.
  #
  # Example:
  #   spinner = Bubbles::Spinner.new(spinner: Bubbles::Spinners::DOT)
  #   spinner.style = Lipgloss::Style.new.foreground("205")
  #
  #   # In your model's init:
  #   def init
  #     [self, @spinner.tick]
  #   end
  #
  #   # In your model's update:
  #   def update(message)
  #     case message
  #     when Bubbles::Spinner::TickMessage
  #       @spinner, command = @spinner.update(message)
  #       [self, command]
  #     end
  #   end
  #
  #   # In your model's view:
  #   def view
  #     "#{@spinner.view} Loading..."
  #   end
  #
  class Spinner
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

    attr_reader :id #: Integer
    attr_accessor :spinner #: Hash[Symbol, untyped]
    attr_accessor :style #: Lipgloss::Style?

    #: (?spinner: Hash[Symbol, untyped], ?style: Lipgloss::Style?) -> void
    def initialize(spinner: Spinners::DEFAULT, style: nil)
      @spinner = spinner
      @style = style
      @frame = 0
      @id = self.class.next_id
      @tag = 0
    end

    #: () -> [Spinner, Bubbletea::Command]
    def init
      [self, tick]
    end

    #: (Bubbletea::Message) -> [Spinner, Bubbletea::Command?]
    def update(message)
      case message
      when TickMessage
        return [self, nil] if message.id.positive? && message.id != @id
        return [self, nil] if message.tag.positive? && message.tag != @tag

        @frame = (@frame + 1) % frames.length
        @tag += 1

        [self, tick]
      else
        [self, nil]
      end
    end

    #: () -> String
    def view
      return "(error)" if @frame >= frames.length

      frame_str = frames[@frame]
      (style = @style) ? style.render(frame_str) : frame_str
    end

    #: () -> Bubbletea::Command
    def tick
      current_id = @id
      current_tag = @tag

      Bubbletea.tick(fps) { TickMessage.new(id: current_id, tag: current_tag) }
    end

    private

    #: () -> Array[String]
    def frames
      @spinner[:frames] || Spinners::DEFAULT[:frames]
    end

    #: () -> Float
    def fps
      @spinner[:fps] || Spinners::DEFAULT[:fps]
    end
  end
end
