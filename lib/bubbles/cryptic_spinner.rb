# frozen_string_literal: true
# rbs_inline: enabled

require "lipgloss"

module Bubbles
  # CrypticSpinner is an animated activity indicator that displays cycling
  # random characters with gradient colors. Inspired by the Charm CLI crush
  # animation.
  #
  # Example:
  #   spinner = Bubbles::CrypticSpinner.new(
  #     size: 15,
  #     rows: 1,
  #     label: "Loading",
  #     color_a: "#ff0000",
  #     color_b: "#0000ff",
  #     cycle_colors: true
  #   )
  #
  # Multi-row example (matrix style):
  #   spinner = Bubbles::CrypticSpinner.new(
  #     size: 30,
  #     rows: 5,
  #     cycle_colors: true
  #   )
  #
  #   # In your model's init:
  #   def init
  #     [self, @spinner.tick]
  #   end
  #
  #   # In your model's update:
  #   def update(message)
  #     case message
  #     when Bubbles::CrypticSpinner::TickMessage
  #       @spinner, command = @spinner.update(message)
  #       [self, command]
  #     end
  #   end
  #
  #   # In your model's view:
  #   def view
  #     @spinner.view
  #   end
  #
  class CrypticSpinner
    AVAILABLE_CHARS = "0123456789abcdefABCDEF~!@#$%^&*()+=_".chars.freeze #: Array[String]
    INITIAL_CHAR = "." #: String
    ELLIPSIS_FRAMES = [".", "..", "...", ""].freeze #: Array[String]

    FPS = 20 #: Integer
    FRAME_DURATION = 1.0 / FPS #: Float
    MAX_BIRTH_OFFSET = 1.0 #: Float
    ELLIPSIS_ANIM_SPEED = 8 #: Integer

    DEFAULT_SIZE = 10 #: Integer
    DEFAULT_ROWS = 1 #: Integer
    DEFAULT_COLOR_A = "#6B50FF" #: String
    DEFAULT_COLOR_B = "#FF60FF" #: String
    DEFAULT_LABEL_COLOR = "#DFDBDD" #: String

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
    attr_reader :size #: Integer
    attr_reader :rows #: Integer
    attr_accessor :label
    attr_reader :label_color #: String
    attr_reader :color_a #: String
    attr_reader :color_b #: String
    attr_reader :cycle_colors #: bool

    #: (
    #:   ?size: Integer,
    #:   ?rows: Integer,
    #:   ?label: String,
    #:   ?label_color: String,
    #:   ?color_a: String,
    #:   ?color_b: String,
    #:   ?cycle_colors: bool
    #: ) -> void
    def initialize(
      size: DEFAULT_SIZE,
      rows: DEFAULT_ROWS,
      label: "",
      label_color: DEFAULT_LABEL_COLOR,
      color_a: DEFAULT_COLOR_A,
      color_b: DEFAULT_COLOR_B,
      cycle_colors: false
    )
      @id = self.class.next_id
      @tag = 0
      @size = size
      @rows = rows
      @label = label
      @label_color = label_color
      @color_a = color_a
      @color_b = color_b
      @cycle_colors = cycle_colors

      @step = 0
      @ellipsis_step = 0
      @start_time = Time.now
      @initialized = false

      @birth_offsets = Array.new(@rows) do |row|
        Array.new(@size) { (rand * MAX_BIRTH_OFFSET) + (row * 0.1) }
      end

      @gradient = generate_gradient

      prerender_frames
    end

    #: () -> [CrypticSpinner, Bubbletea::Command]
    def init
      [self, tick]
    end

    #: (Bubbletea::Message) -> [CrypticSpinner, Bubbletea::Command?]
    def update(message)
      case message
      when TickMessage
        return [self, nil] if message.id.positive? && message.id != @id
        return [self, nil] if message.tag.positive? && message.tag != @tag

        @step = (@step + 1) % @cycling_frames.length
        @tag += 1

        if @initialized && !@label.empty?
          @ellipsis_step = (@ellipsis_step + 1) % (ELLIPSIS_ANIM_SPEED * ELLIPSIS_FRAMES.length)
        elsif !@initialized && (Time.now - @start_time) >= MAX_BIRTH_OFFSET
          @initialized = true
        end

        [self, tick]
      else
        [self, nil]
      end
    end

    #: () -> String
    def view
      elapsed = Time.now - @start_time
      lines = [] #: Array[String]

      @rows.times do |row|
        line = String.new

        @size.times do |i|
          line << if !@initialized && elapsed < @birth_offsets[row][i]
                    @initial_frames[@step][row][i]
                  else
                    @cycling_frames[@step][row][i]
                  end
        end

        if row == @rows - 1 && !@label.empty?
          line << " "
          line << render_label

          if @initialized
            ellipsis_index = @ellipsis_step / ELLIPSIS_ANIM_SPEED
            line << render_ellipsis(ELLIPSIS_FRAMES[ellipsis_index])
          end
        end

        lines << line
      end

      lines.join("\n")
    end

    #: () -> Bubbletea::Command
    def tick
      current_id = @id
      current_tag = @tag

      Bubbletea.tick(FRAME_DURATION) { TickMessage.new(id: current_id, tag: current_tag) }
    end

    #: () -> Integer
    def width
      w = @size

      w += 1 + @label.length + (ELLIPSIS_FRAMES.max_by(&:length) || "").length unless @label.empty?

      w
    end

    #: () -> Integer
    def height
      @rows
    end

    #: (String) -> void

    private

    #: () -> Array[String]
    def generate_gradient
      num_colors = @cycle_colors ? @size * 3 : @size

      Lipgloss::ColorBlend.blends(@color_a, @color_b, num_colors, mode: :hcl)
    end

    #: () -> void
    def prerender_frames
      num_frames = @cycle_colors ? @size * 2 : 10

      @initial_frames = Array.new(num_frames) do |frame_index|
        Array.new(@rows) do |row|
          offset = @cycle_colors ? frame_index + row : row

          Array.new(@size) do |char_index|
            color_index = (char_index + offset) % @gradient.length
            style = Lipgloss::Style.new.foreground(@gradient[color_index])
            style.render(INITIAL_CHAR)
          end
        end
      end

      @cycling_frames = Array.new(num_frames) do |frame_index|
        Array.new(@rows) do |row|
          offset = @cycle_colors ? frame_index + row : row

          Array.new(@size) do |char_index|
            color_index = (char_index + offset) % @gradient.length
            char = AVAILABLE_CHARS.sample
            style = Lipgloss::Style.new.foreground(@gradient[color_index])
            style.render(char)
          end
        end
      end
    end

    #: () -> String
    def render_label
      style = Lipgloss::Style.new.foreground(@label_color)
      style.render(@label)
    end

    #: (String) -> String
    def render_ellipsis(ellipsis)
      style = Lipgloss::Style.new.foreground(@label_color)
      style.render(ellipsis)
    end
  end
end
