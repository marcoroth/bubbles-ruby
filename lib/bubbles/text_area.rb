# frozen_string_literal: true
# rbs_inline: enabled

module Bubbles
  # TextArea is a multi-line text input component.
  #
  # Example:
  #   textarea = Bubbles::TextArea.new
  #   textarea.placeholder = "Enter text..."
  #   textarea.focus
  #
  #   # In update:
  #   textarea, command = textarea.update(message)
  #
  #   # In view:
  #   textarea.view
  #
  class TextArea
    DEFAULT_WIDTH = 40 #: Integer
    DEFAULT_HEIGHT = 6 #: Integer
    DEFAULT_CHAR_LIMIT = 0 #: Integer

    class PasteMessage < Bubbletea::Message
      attr_reader :text #: String

      #: (String) -> void
      def initialize(text)
        super()

        @text = text
      end
    end

    attr_accessor :width #: Integer
    attr_accessor :height #: Integer
    attr_accessor :char_limit #: Integer
    attr_accessor :placeholder #: String
    attr_accessor :prompt #: String
    attr_accessor :show_line_numbers #: bool
    attr_accessor :end_of_buffer_character #: String
    attr_accessor :placeholder_style #: Lipgloss::Style?
    attr_accessor :prompt_style #: Lipgloss::Style?
    attr_accessor :text_style #: Lipgloss::Style?
    attr_accessor :line_number_style #: Lipgloss::Style?

    attr_reader :cursor #: Cursor
    attr_reader :error #: StandardError?

    attr_reader :row #: Integer
    attr_reader :col #: Integer

    #: (?width: Integer, ?height: Integer) -> void
    def initialize(width: DEFAULT_WIDTH, height: DEFAULT_HEIGHT)
      @width = width
      @height = height
      @char_limit = DEFAULT_CHAR_LIMIT

      @placeholder = ""
      @prompt = ""
      @show_line_numbers = false
      @end_of_buffer_character = "~"

      @placeholder_style = nil
      @prompt_style = nil
      @text_style = nil
      @line_number_style = nil

      @cursor = Cursor.new
      @lines = [""]
      @row = 0
      @col = 0
      @focus = false
      @viewport_offset = 0

      @error = nil
    end

    #: () -> String
    def value
      @lines.join("\n")
    end

    #: (String) -> void
    def value=(text)
      @lines = text.split("\n", -1)
      @lines = [""] if @lines.empty?
      @row = @lines.length - 1
      @col = @lines[@row].length
      update_viewport
    end

    #: () -> Integer
    def line_count
      @lines.length
    end

    #: () -> String
    def current_line
      @lines[@row] || ""
    end

    #: () -> bool
    def focused?
      @focus
    end

    #: () -> Bubbletea::Command?
    def focus
      @focus = true
      @cursor.focus
    end

    #: () -> void
    def blur
      @focus = false
      @cursor.blur
    end

    #: () -> void
    def reset
      @lines = [""]
      @row = 0
      @col = 0
      @viewport_offset = 0
    end

    #: (Bubbletea::Message) -> [TextArea, Bubbletea::Command?]
    def update(message)
      return [self, nil] unless @focus

      case message
      when Bubbletea::KeyMessage
        handle_key(message)
      when PasteMessage
        insert_text(message.text)
      when Cursor::BlinkMessage, Cursor::InitialBlinkMessage
        @cursor, command = @cursor.update(message)
        return [self, command]
      end

      commands = [] #: Array[Bubbletea::Command]
      @cursor, command = @cursor.update(message)
      commands << command if command

      update_viewport

      [self, commands.empty? ? nil : Bubbletea.batch(*commands)]
    end

    #: () -> String
    def view
      return placeholder_view if @lines == [""] && !@placeholder.empty?

      visible_lines = [] #: Array[String]
      end_row = [@viewport_offset + @height, @lines.length].min

      (@viewport_offset...end_row).each do |i|
        line = render_line(i)
        visible_lines << line
      end

      while visible_lines.length < @height
        visible_lines << if @show_line_numbers
                           "   #{render_end_of_buffer}"
                         else
                           render_end_of_buffer
                         end
      end

      visible_lines.join("\n")
    end

    private

    #: (Bubbletea::KeyMessage) -> void
    def handle_key(message)
      key_name = message.to_s

      case key_name
      when "enter"
        insert_newline
      when "backspace", "ctrl+h"
        delete_backward
      when "delete", "ctrl+d"
        delete_forward
      when "left", "ctrl+b"
        move_left
      when "right", "ctrl+f"
        move_right
      when "up", "ctrl+p"
        move_up
      when "down", "ctrl+n"
        move_down
      when "home", "ctrl+a"
        line_start
      when "end", "ctrl+e"
        line_end
      when "ctrl+k"
        delete_to_end
      when "ctrl+u"
        delete_to_start
      when "alt+backspace", "ctrl+w"
        delete_word_backward
      when "alt+b", "alt+left"
        word_backward
      when "alt+f", "alt+right"
        word_forward
      else
        return if key_name.start_with?("ctrl+", "alt+", "meta+", "shift+")
        return if key_name.start_with?("f") && key_name.length > 1 && key_name[1..].match?(/^\d+$/) # F1-F12

        if message.respond_to?(:runes) && message.runes && !message.runes.empty?
          chars = message.runes.map do |rune|
            rune.chr(Encoding::UTF_8)
          rescue StandardError
            nil
          end.compact

          insert_text(chars.join) unless chars.empty?
        elsif key_name.length == 1
          insert_text(key_name)
        end
      end
    end

    #: (String) -> void
    def insert_text(text)
      return if text.empty?

      insert_str = text

      if @char_limit.positive?
        current_len = total_length
        available = @char_limit - current_len
        return if available <= 0

        insert_str = text[0...available] || "" if text.length > available
      end

      if insert_str.include?("\n")
        parts = insert_str.split("\n", -1)
        before = @lines[@row][0...@col]
        after = @lines[@row][@col..]

        @lines[@row] = before + parts[0]

        rest_parts = parts[1..] || [] #: Array[String]
        rest_parts.each do |part|
          @row += 1
          @lines.insert(@row, part)
        end

        @lines[@row] += after
        @col = @lines[@row].length - after.length
      else
        @lines[@row] = @lines[@row][0...@col] + insert_str + @lines[@row][@col..]
        @col += insert_str.length
      end
    end

    #: () -> void
    def insert_newline
      before = @lines[@row][0...@col]
      after = @lines[@row][@col..]

      @lines[@row] = before
      @row += 1
      @lines.insert(@row, after)
      @col = 0
    end

    #: () -> void
    def delete_backward
      if @col.positive?
        @lines[@row] = @lines[@row][0...(@col - 1)] + @lines[@row][@col..]
        @col -= 1
      elsif @row.positive?
        prev_line_len = @lines[@row - 1].length
        @lines[@row - 1] += @lines[@row]
        @lines.delete_at(@row)
        @row -= 1
        @col = prev_line_len
      end
    end

    #: () -> void
    def delete_forward
      if @col < @lines[@row].length
        @lines[@row] = @lines[@row][0...@col] + @lines[@row][(@col + 1)..]
      elsif @row < @lines.length - 1
        @lines[@row] += @lines[@row + 1]
        @lines.delete_at(@row + 1)
      end
    end

    #: () -> void
    def delete_to_end
      @lines[@row] = @lines[@row][0...@col]
    end

    #: () -> void
    def delete_to_start
      @lines[@row] = @lines[@row][@col..]
      @col = 0
    end

    #: () -> void
    def delete_word_backward
      return if @col.zero?

      @col -= 1 while @col.positive? && @lines[@row][@col - 1] =~ /\s/

      start_col = @col

      @col -= 1 while @col.positive? && @lines[@row][@col - 1] !~ /\s/

      @lines[@row] = @lines[@row][0...@col] + @lines[@row][start_col..]
    end

    #: () -> void
    def move_left
      if @col.positive?
        @col -= 1
      elsif @row.positive?
        @row -= 1
        @col = @lines[@row].length
      end
    end

    #: () -> void
    def move_right
      if @col < @lines[@row].length
        @col += 1
      elsif @row < @lines.length - 1
        @row += 1
        @col = 0
      end
    end

    #: () -> void
    def move_up
      return unless @row.positive?

      @row -= 1
      @col = [@col, @lines[@row].length].min
    end

    #: () -> void
    def move_down
      return unless @row < @lines.length - 1

      @row += 1
      @col = [@col, @lines[@row].length].min
    end

    #: () -> void
    def line_start
      @col = 0
    end

    #: () -> void
    def line_end
      @col = @lines[@row].length
    end

    #: () -> void
    def word_backward
      return if @col.zero?

      @col -= 1 while @col.positive? && @lines[@row][@col - 1] =~ /\s/
      @col -= 1 while @col.positive? && @lines[@row][@col - 1] !~ /\s/
    end

    #: () -> void
    def word_forward
      return if @col >= @lines[@row].length

      @col += 1 while @col < @lines[@row].length && @lines[@row][@col] =~ /\s/
      @col += 1 while @col < @lines[@row].length && @lines[@row][@col] !~ /\s/
    end

    #: () -> void
    def update_viewport
      if @row < @viewport_offset
        @viewport_offset = @row
      elsif @row >= @viewport_offset + @height
        @viewport_offset = @row - @height + 1
      end
    end

    #: () -> Integer
    def total_length
      @lines.sum(&:length) + @lines.length - 1 # Account for newlines
    end

    #: (Integer) -> String
    def render_line(index)
      line = @lines[index] || ""
      is_cursor_line = index == @row && @focus

      prefix_width = 0
      prefix = ""

      if @show_line_numbers
        num = (index + 1).to_s.rjust(2)
        prefix = (style = @line_number_style) ? style.render("#{num} ") : "#{num} "
        prefix_width += 3 # "NN "
      end

      unless @prompt.empty?
        prefix += (style = @prompt_style) ? style.render(@prompt) : @prompt
        prefix_width += @prompt.length
      end

      available_width = @width - prefix_width

      h_offset = 0
      h_offset = @col - available_width + 1 if is_cursor_line && @col >= available_width

      visible_line = line[h_offset, available_width] || ""

      if is_cursor_line
        cursor_pos = @col - h_offset
        before = visible_line[0...cursor_pos] || ""
        char = visible_line[cursor_pos] || " "
        after = visible_line[(cursor_pos + 1)..] || ""

        @cursor.char = char

        text = render_text(before) + @cursor.view
        text += render_text(after) unless after.empty?
        content_width = [visible_line.length, cursor_pos + 1].max
      else
        text = render_text(visible_line)
        content_width = visible_line.length
      end

      padding_needed = [available_width - content_width, 0].max
      text += " " * padding_needed

      prefix + text
    end

    #: (String) -> String
    def render_text(text)
      (style = @text_style) ? style.render(text) : text
    end

    #: () -> String
    def render_end_of_buffer
      char = @end_of_buffer_character
      prefix_width = @show_line_numbers ? 3 : 0
      prefix_width += @prompt.length unless @prompt.empty?
      available_width = @width - prefix_width
      padding = " " * [available_width - 1, 0].max

      styled_char = (style = @placeholder_style) ? style.render(char) : "\e[90m#{char}\e[0m"
      styled_char + padding
    end

    #: () -> String
    def placeholder_view
      first_char = @placeholder[0] || ""
      rest = @placeholder[1..] || ""

      @cursor.char = first_char

      prefix = ""
      prefix_width = 0

      if @show_line_numbers
        prefix = "   "
        prefix_width = 3
      end

      unless @prompt.empty?
        prefix += (style = @prompt_style) ? style.render(@prompt) : @prompt
        prefix_width += @prompt.length
      end

      text = @cursor.view
      text += (style = @placeholder_style) ? style.render(rest) : "\e[90m#{rest}\e[0m"

      available_width = @width - prefix_width
      content_width = @placeholder.length
      padding_needed = [available_width - content_width, 0].max

      text += " " * padding_needed

      lines = [prefix + text]

      while lines.length < @height
        lines << if @show_line_numbers
                   "   #{render_end_of_buffer}"
                 else
                   render_end_of_buffer
                 end
      end

      lines.join("\n")
    end
  end
end
