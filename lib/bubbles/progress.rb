# frozen_string_literal: true
# rbs_inline: enabled

require "harmonica"

module Bubbles
  # Progress renders an animated progress bar.
  #
  # Example:
  #   progress = Bubbles::Progress.new
  #   progress.width = 40
  #
  #   # Static rendering
  #   puts progress.view_as(0.5)  # 50%
  #
  #   # Animated rendering (use in bubbletea)
  #   command = progress.set_percent(0.75)
  #   # Then in update: progress.update(message)
  #   puts progress.view
  #
  class Progress
    class FrameMessage < Bubbletea::Message
      attr_reader :id #: Integer
      attr_reader :tag #: Integer

      #: (id: Integer, tag: Integer) -> void
      def initialize(id:, tag:)
        super()
        @id = id
        @tag = tag
      end
    end

    FPS = 60 #: Integer
    DEFAULT_WIDTH = 40 #: Integer
    SPRING_FREQUENCY = 5.0 #: Float
    SPRING_DAMPING = 1.0 #: Float

    # rubocop:disable Style/ClassVars
    @@last_id = 0 #: Integer
    @@id_mutex = Mutex.new #: Mutex

    #: () -> Integer
    def self.next_id
      @@id_mutex.synchronize do
        @@last_id += 1
      end
    end
    # rubocop:enable Style/ClassVars

    attr_accessor :width #: Integer
    attr_accessor :full #: String
    attr_accessor :full_color #: String
    attr_accessor :empty #: String
    attr_accessor :empty_color #: String
    attr_accessor :show_percentage #: bool
    attr_accessor :percent_format #: String
    attr_accessor :percent_style #: Lipgloss::Style?
    attr_accessor :use_gradient #: bool
    attr_accessor :gradient_a #: String?
    attr_accessor :gradient_b #: String?
    attr_accessor :scale_gradient #: bool

    attr_reader :id #: Integer

    #: (?width: Integer, ?gradient: Array[String]?, ?scaled_gradient: Array[String]?, ?solid_fill: String?) -> void
    def initialize(width: DEFAULT_WIDTH, gradient: nil, scaled_gradient: nil, solid_fill: nil)
      @id = self.class.next_id
      @tag = 0

      @width = width
      @full = "█"
      @full_color = "#7571F9"
      @empty = "░"
      @empty_color = "#606060"

      @show_percentage = true
      @percent_format = " %3.0f%%"
      @percent_style = nil

      @percent_shown = 0.0
      @target_percent = 0.0
      @velocity = 0.0

      @spring = Harmonica::Spring.new(
        delta_time: Harmonica.fps(FPS),
        angular_frequency: SPRING_FREQUENCY,
        damping_ratio: SPRING_DAMPING
      )

      @use_gradient = false
      @gradient_a = nil
      @gradient_b = nil
      @scale_gradient = false

      if gradient
        gradient(gradient[0], gradient[1], scaled: false)
      elsif scaled_gradient
        gradient(scaled_gradient[0], scaled_gradient[1], scaled: true)
      elsif solid_fill
        @full_color = solid_fill
        @use_gradient = false
      end
    end

    #: () -> nil
    def init
      nil
    end

    #: (Bubbletea::Message) -> [Progress, Bubbletea::Command?]
    def update(message)
      command = nil

      case message
      when FrameMessage
        if message.id == @id && message.tag == @tag && animating?
          @percent_shown, @velocity = @spring.update(
            @percent_shown,
            @velocity,
            @target_percent
          )

          if (@percent_shown - @target_percent).abs < 0.001 && @velocity.abs < 0.001
            @percent_shown = @target_percent
            @velocity = 0.0
          else
            command = next_frame
          end
        end
      end

      [self, command]
    end

    #: () -> String
    def view
      view_as(@percent_shown)
    end

    #: (Float) -> String
    def view_as(percent)
      percent = percent.clamp(0.0, 1.0)

      percentage_view = render_percentage(percent)
      bar = render_bar(percent, percentage_view.length)

      "#{bar}#{percentage_view}"
    end

    #: () -> Float
    def percent
      @target_percent
    end

    #: (Float) -> Bubbletea::Command
    def set_percent(percent) # rubocop:disable Naming/AccessorMethodName
      @target_percent = percent.clamp(0.0, 1.0)
      @tag += 1

      next_frame
    end

    #: (?Float) -> Bubbletea::Command
    def increment_percent(amount = 1.0)
      set_percent(percent + amount)
    end

    #: (?Float) -> Bubbletea::Command
    def decrement_percent(amount = 1.0)
      set_percent(percent - amount)
    end

    #: () -> bool
    def animating?
      (@percent_shown - @target_percent).abs >= 0.001
    end

    #: (String, String, ?scaled: bool) -> void
    def gradient(color_a, color_b, scaled: false)
      @use_gradient = true
      @gradient_a = color_a
      @gradient_b = color_b
      @scale_gradient = scaled
    end

    private

    #: () -> Bubbletea::Command
    def next_frame
      id = @id
      tag = @tag
      interval = 1.0 / FPS

      Bubbletea.tick(interval) do
        FrameMessage.new(id: id, tag: tag)
      end
    end

    #: (Float, Integer) -> String
    def render_bar(percent, text_width)
      total_width = [@width - text_width, 0].max
      filled_width = (total_width * percent).round
      filled_width = filled_width.clamp(0, total_width)
      empty_width = [total_width - filled_width, 0].max

      filled = if @use_gradient && @gradient_a && @gradient_b
                 render_gradient_fill(filled_width, total_width)
               else
                 render_solid_fill(filled_width)
               end

      empty = render_empty_fill(empty_width)

      "#{filled}#{empty}"
    end

    #: (Integer) -> String
    def render_solid_fill(width)
      return "" if width <= 0

      char = @full * width
      colorize(char, @full_color)
    end

    #: (Integer) -> String
    def render_empty_fill(width)
      return "" if width <= 0

      char = @empty * width
      colorize(char, @empty_color)
    end

    #: (Integer, Integer) -> String
    def render_gradient_fill(filled_width, total_width)
      return "" if filled_width <= 0

      result = ""

      filled_width.times do |i|
        p = if filled_width == 1
              0.5
            elsif @scale_gradient
              i.to_f / (filled_width - 1)
            else
              i.to_f / [total_width - 1, 1].max
            end

        color = blend_colors(@gradient_a, @gradient_b, p)
        result += colorize(@full, color)
      end

      result
    end

    #: (Float) -> String
    def render_percentage(percent)
      return "" unless @show_percentage

      text = format(@percent_format, percent * 100)
      (style = @percent_style) ? style.render(text) : text
    end

    #: (String, String) -> String
    def colorize(text, color)
      Lipgloss::Style.new.foreground(color).render(text)
    end

    #: (String?, String?, Float) -> String
    def blend_colors(color_a, color_b, ratio)
      a = color_a || @full_color
      b = color_b || @full_color
      Lipgloss::ColorBlend.blend(a, b, ratio)
    end
  end
end
