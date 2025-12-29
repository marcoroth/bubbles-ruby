# frozen_string_literal: true
# rbs_inline: enabled

module Bubbles
  # Viewport is a scrollable content pane.
  #
  # Example:
  #   viewport = Bubbles::Viewport.new(width: 80, height: 24)
  #   viewport.content = "Long text content..."
  #
  #   # In update:
  #   viewport, command = viewport.update(message)
  #
  #   # In view:
  #   viewport.view
  #
  class Viewport
    attr_accessor :width #: Integer
    attr_accessor :height #: Integer
    attr_accessor :style #: Lipgloss::Style?
    attr_accessor :mouse_wheel_enabled #: bool
    attr_accessor :mouse_wheel_delta #: Integer

    attr_reader :y_offset #: Integer
    attr_reader :x_offset #: Integer

    #: (?width: Integer, ?height: Integer) -> void
    def initialize(width: 80, height: 24)
      @width = width
      @height = height
      @style = nil

      @mouse_wheel_enabled = true
      @mouse_wheel_delta = 3
      @horizontal_step = 0

      @y_offset = 0
      @x_offset = 0

      @lines = [] #: Array[String]
      @longest_line_width = 0
    end

    #: () -> nil
    def init
      nil
    end

    #: () -> bool
    def at_top?
      @y_offset <= 0
    end

    #: () -> bool
    def at_bottom?
      @y_offset >= max_y_offset
    end

    #: () -> bool
    def past_bottom?
      @y_offset > max_y_offset
    end

    #: () -> Float -- scroll percentage (0.0 to 1.0)
    def scroll_percent
      return 1.0 if @height >= @lines.length

      y = @y_offset.to_f
      h = @height.to_f
      t = @lines.length.to_f

      v = y / (t - h)

      v.clamp(0.0, 1.0).to_f
    end

    #: (String) -> void
    def content=(content)
      content = content.gsub("\r\n", "\n")
      @lines = content.split("\n", -1)
      @longest_line_width = @lines.map { |l| strip_ansi(l).length }.max || 0

      goto_bottom if @y_offset > @lines.length - 1
    end

    #: () -> String
    def content
      @lines.join("\n")
    end

    #: (Integer) -> Integer
    def y_offset=(offset)
      @y_offset = offset.clamp(0, max_y_offset)
    end

    #: (Integer) -> Integer
    def x_offset=(offset)
      max_x = [@longest_line_width - @width, 0].max
      @x_offset = offset.clamp(0, max_x)
    end

    #: (Integer) -> Integer
    def horizontal_step=(step)
      @horizontal_step = [step, 0].max
    end

    #: (Integer) -> Array[String]
    def scroll_down(line_count)
      return [] if at_bottom? || line_count.zero? || @lines.empty?

      self.y_offset = @y_offset + line_count
      visible_lines
    end

    #: (Integer) -> Array[String]
    def scroll_up(line_count)
      return [] if at_top? || line_count.zero? || @lines.empty?

      self.y_offset = @y_offset - line_count
      visible_lines
    end

    #: (Integer) -> void
    def scroll_left(column_count)
      self.x_offset = @x_offset - column_count
    end

    #: (Integer) -> void
    def scroll_right(column_count)
      self.x_offset = @x_offset + column_count
    end

    #: () -> Array[String]
    def page_down
      return [] if at_bottom?

      scroll_down(@height)
    end

    #: () -> Array[String]
    def page_up
      return [] if at_top?

      scroll_up(@height)
    end

    #: () -> Array[String]
    def half_page_down
      return [] if at_bottom?

      scroll_down(@height / 2)
    end

    #: () -> Array[String]
    def half_page_up
      return [] if at_top?

      scroll_up(@height / 2)
    end

    #: () -> Array[String]
    def goto_top
      return [] if at_top?

      self.y_offset = 0
      visible_lines
    end

    #: () -> Array[String]
    def goto_bottom
      self.y_offset = max_y_offset
      visible_lines
    end

    #: () -> Integer
    def total_line_count
      @lines.length
    end

    #: () -> Integer
    def visible_line_count
      visible_lines.length
    end

    #: (Bubbletea::Message) -> [Viewport, Bubbletea::Command?]
    def update(message)
      case message
      when Bubbletea::KeyMessage
        handle_key(message)
      when Bubbletea::MouseMessage
        handle_mouse(message) if @mouse_wheel_enabled
      end

      [self, nil]
    end

    #: () -> String
    def view
      lines = visible_lines
      content = lines.join("\n")

      content += "\n" * (@height - lines.length) if lines.length < @height

      if (style = @style)
        style.width(@width).height(@height).render(content)
      else
        content
      end
    end

    private

    #: (Bubbletea::KeyMessage) -> void
    def handle_key(message)
      case message.to_s
      when "pgdown", "ctrl+f"
        page_down
      when "pgup", "ctrl+b"
        page_up
      when "ctrl+d"
        half_page_down
      when "ctrl+u"
        half_page_up
      when "down", "j"
        scroll_down(1)
      when "up", "k"
        scroll_up(1)
      when "left", "h"
        scroll_left(@horizontal_step) if @horizontal_step.positive?
      when "right", "l"
        scroll_right(@horizontal_step) if @horizontal_step.positive?
      when "home", "g"
        goto_top
      when "end", "G"
        goto_bottom
      end
    end

    #: (Bubbletea::MouseMessage) -> void
    def handle_mouse(message)
      # Mouse wheel support would go here
      # Depends on bubbletea-ruby mouse message support
    end

    #: () -> Integer
    def max_y_offset
      frame_size = if (style = @style) && style.respond_to?(:vertical_frame_size)
                     style.send(:vertical_frame_size).to_i
                   else
                     0
                   end

      [0, @lines.length - @height + frame_size].max
    end

    #: () -> Array[String]
    def visible_lines
      h = @height
      if (style = @style) && style.respond_to?(:vertical_frame_size)
        h -= style.send(:vertical_frame_size).to_i
      end

      return [] if @lines.empty?

      top = [0, @y_offset].max
      bottom = (@y_offset + h).clamp(top, @lines.length)
      lines = @lines[top...bottom] || []

      if @x_offset.positive? || @longest_line_width > @width
        w = @width
        if (style = @style) && style.respond_to?(:horizontal_frame_size)
          w -= style.send(:horizontal_frame_size).to_i
        end

        lines = lines.map do |line|
          cut_string(line, @x_offset, @x_offset + w)
        end
      end

      lines
    end

    #: (String, Integer, Integer) -> String
    def cut_string(string, start_column, end_column)
      plain = strip_ansi(string)
      return "" if start_column >= plain.length

      plain[start_column...end_column] || ""
    end

    #: (String) -> String
    def strip_ansi(string)
      string.gsub(/\e\[[0-9;]*[A-Za-z]/, "")
    end
  end
end
