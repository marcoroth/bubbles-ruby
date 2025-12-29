# frozen_string_literal: true
# rbs_inline: enabled

module Bubbles
  # TextInput is a single-line text input component.
  #
  # Example:
  #   input = Bubbles::TextInput.new
  #   input.placeholder = "Enter your name..."
  #   input.focus
  #
  #   # In update:
  #   input, command = input.update(message)
  #
  #   # In view:
  #   input.view
  #
  class TextInput
    ECHO_NORMAL = :normal #: Symbol
    ECHO_PASSWORD = :password #: Symbol
    ECHO_NONE = :none #: Symbol

    class PasteMessage < Bubbletea::Message
      attr_reader :text #: String

      #: (String) -> void
      def initialize(text)
        super()
        @text = text
      end
    end

    class PasteErrorMessage < Bubbletea::Message
      attr_reader :error #: StandardError

      #: (StandardError) -> void
      def initialize(error)
        super()

        @error = error
      end
    end

    attr_accessor :prompt #: String
    attr_accessor :placeholder #: String
    attr_accessor :echo_mode #: Symbol
    attr_accessor :echo_character #: String
    attr_accessor :char_limit #: Integer
    attr_accessor :width #: Integer
    attr_accessor :prompt_style #: Lipgloss::Style?
    attr_accessor :text_style #: Lipgloss::Style?
    attr_accessor :placeholder_style #: Lipgloss::Style?
    attr_accessor :cursor_style #: Lipgloss::Style?
    attr_accessor :validate #: (^(String) -> StandardError?)?
    attr_accessor :show_suggestions #: bool

    attr_reader :position #: Integer
    attr_reader :cursor #: Cursor
    attr_reader :error #: StandardError?

    #: () -> void
    def initialize
      @prompt = "> "
      @placeholder = ""
      @echo_mode = ECHO_NORMAL
      @echo_character = "*"
      @char_limit = 0
      @width = 0

      @prompt_style = nil
      @text_style = nil
      @placeholder_style = nil
      @cursor_style = nil

      @cursor = Cursor.new
      @value = [] #: Array[String]
      @position = 0
      @focus = false
      @offset = 0
      @offset_right = 0

      @validate = nil
      @error = nil

      @show_suggestions = false
      @suggestions = [] #: Array[Array[String]]
      @matched_suggestions = [] #: Array[Array[String]]
      @current_suggestion_index = 0
    end

    #: () -> String
    def value
      @value.join
    end

    #: (String) -> void
    def value=(text)
      runes = sanitize(text.chars)
      @error = run_validate(runes)
      apply_value(runes)
      update_suggestions
    end

    #: (Integer) -> void
    def position=(position)
      @position = position.clamp(0, @value.length)

      handle_overflow
    end

    #: () -> void
    def cursor_start
      self.position = 0
    end

    #: () -> void
    def cursor_end
      self.position = @value.length
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
      @value = [] #: Array[String]
      self.position = 0
    end

    #: (Array[String]) -> void
    def suggestions=(suggestions)
      @suggestions = suggestions.map(&:chars)
      update_suggestions
    end

    #: (Bubbletea::Message) -> [TextInput, Bubbletea::Command?]
    def update(message)
      return [self, nil] unless @focus

      old_pos = @position

      case message
      when Bubbletea::KeyMessage
        handle_key(message)
        update_suggestions

      when PasteMessage
        insert_runes(message.text.chars)

      when PasteErrorMessage
        @error = message.error

      when Cursor::BlinkMessage, Cursor::InitialBlinkMessage
        @cursor, command = @cursor.update(message)
        return [self, command]
      end

      commands = [] #: Array[Bubbletea::Command]

      @cursor, command = @cursor.update(message)
      commands << command if command

      if old_pos != @position && @cursor.mode == Cursor::MODE_BLINK
        @cursor.instance_variable_set(:@blink, false)
        commands << @cursor.send(:blink_command)
      end

      handle_overflow

      [self, commands.empty? ? nil : Bubbletea.batch(*commands)]
    end

    #: () -> String
    def view
      return placeholder_view if @value.empty? && !@placeholder.empty?

      prompt_text = render_prompt

      visible_value = @value[@offset...@offset_right] || []
      position = [0, @position - @offset].max

      before = echo_transform(visible_value[0...position].join)
      v = render_text(before)

      if position < visible_value.length
        char = echo_transform(visible_value[position])
        @cursor.char = char
        v += @cursor.view
        after = echo_transform(visible_value[(position + 1)..].join)
        v += render_text(after)
      else
        suggestion_text = current_suggestion_remainder

        if suggestion_text && !suggestion_text.empty? && (first_char = suggestion_text[0])
          @cursor.char = first_char
          v += @cursor.view
          v += "\e[90m#{suggestion_text[1..]}\e[0m" if suggestion_text.length > 1
        else
          @cursor.char = " "
          v += @cursor.view
        end
      end

      prompt_text + v
    end

    private

    #: (Bubbletea::KeyMessage) -> void
    def handle_key(message)
      key_name = message.to_s

      case key_name
      when "backspace", "ctrl+h"
        delete_character_backward
      when "delete", "ctrl+d"
        delete_character_forward
      when "left", "ctrl+b"
        self.position = @position - 1 if @position.positive?
      when "right", "ctrl+f"
        self.position = @position + 1 if @position < @value.length
      when "home", "ctrl+a"
        cursor_start
      when "end", "ctrl+e"
        cursor_end
      when "ctrl+k"
        delete_after_cursor
      when "ctrl+u"
        delete_before_cursor
      when "ctrl+w", "alt+backspace"
        delete_word_backward
      when "alt+d", "alt+delete"
        delete_word_forward
      when "alt+b", "alt+left", "ctrl+left"
        word_backward
      when "alt+f", "alt+right", "ctrl+right"
        word_forward
      when "tab"
        accept_suggestion if can_accept_suggestion?
      when "down", "ctrl+n"
        next_suggestion
      when "up", "ctrl+p"
        previous_suggestion
      else
        return if key_name.start_with?("ctrl+", "alt+", "meta+", "shift+")
        return if key_name.start_with?("f") && key_name.length > 1 && key_name[1..].match?(/^\d+$/) # F1-F12

        if message.respond_to?(:runes) && message.runes && !message.runes.empty?
          chars = message.runes.map do |r|
            r.chr(Encoding::UTF_8)
          rescue StandardError
            nil
          end.compact
          insert_runes(chars) unless chars.empty?
        elsif key_name.length == 1
          insert_runes([key_name])
        end
      end
    end

    #: () -> void
    def delete_character_backward
      return if @value.empty? || @position.zero?

      @value = @value[0...(@position - 1)] + @value[@position..]
      @error = run_validate(@value)
      self.position = @position - 1
    end

    #: () -> void
    def delete_character_forward
      return if @value.empty? || @position >= @value.length

      @value = @value[0...@position] + @value[(@position + 1)..]
      @error = run_validate(@value)
    end

    #: () -> void
    def delete_before_cursor
      @value = @value[@position..]
      @error = run_validate(@value)
      @offset = 0
      self.position = 0
    end

    #: () -> void
    def delete_after_cursor
      @value = @value[0...@position]
      @error = run_validate(@value)
      self.position = @value.length
    end

    #: () -> void
    def delete_word_backward
      return if @position.zero? || @value.empty?

      return delete_before_cursor if @echo_mode != ECHO_NORMAL

      old_pos = @position

      self.position = @position - 1 while @position.positive? && @value[@position - 1] =~ /\s/
      self.position = @position - 1 while @position.positive? && @value[@position - 1] !~ /\s/

      @value = @value[0...@position] + @value[old_pos..]
      @error = run_validate(@value)
    end

    #: () -> void
    def delete_word_forward
      return if @position >= @value.length || @value.empty?

      return delete_after_cursor if @echo_mode != ECHO_NORMAL

      old_pos = @position

      self.position = @position + 1 while @position < @value.length && @value[@position] =~ /\s/
      self.position = @position + 1 while @position < @value.length && @value[@position] !~ /\s/

      @value = @value[0...old_pos] + @value[@position..]
      @error = run_validate(@value)

      self.position = old_pos
    end

    #: () -> void
    def word_backward
      return if @position.zero? || @value.empty?

      return cursor_start if @echo_mode != ECHO_NORMAL

      self.position = @position - 1 while @position.positive? && @value[@position - 1] =~ /\s/
      self.position = @position - 1 while @position.positive? && @value[@position - 1] !~ /\s/
    end

    #: () -> void
    def word_forward
      return if @position >= @value.length || @value.empty?

      return cursor_end if @echo_mode != ECHO_NORMAL

      self.position = @position + 1 while @position < @value.length && @value[@position] =~ /\s/
      self.position = @position + 1 while @position < @value.length && @value[@position] !~ /\s/
    end

    #: (Array[String]) -> void
    def insert_runes(runes)
      insert_chars = sanitize(runes)

      if @char_limit.positive?
        avail = @char_limit - @value.length
        return if avail <= 0

        insert_chars = insert_chars[0...avail] || [] if insert_chars.length > avail
      end

      head = @value[0...@position] || [] #: Array[String]
      tail = @value[@position..] || [] #: Array[String]

      insert_chars.each do |r|
        head << r
        @position += 1
      end

      @value = head + tail
      @error = run_validate(@value)
      handle_overflow
    end

    #: (Array[String]) -> Array[String]
    def sanitize(runes)
      runes.map { |r| r =~ /[\t\n\r]/ ? " " : r }
    end

    #: () -> void
    def handle_overflow
      if @width <= 0
        @offset = 0
        @offset_right = @value.length
        return
      end

      text_width = @value.join.length

      if text_width <= @width
        @offset = 0
        @offset_right = @value.length
        return
      end

      @offset_right = [@offset_right, @value.length].min

      if @position < @offset
        @offset = @position
        @offset_right = [@offset + @width, @value.length].min
      elsif @position >= @offset_right
        @offset_right = @position + 1
        @offset = [@offset_right - @width, 0].max
      end
    end

    #: (String) -> String
    def echo_transform(text)
      case @echo_mode
      when ECHO_PASSWORD
        @echo_character * text.length
      when ECHO_NONE
        ""
      else
        text
      end
    end

    #: (Array[String]) -> void
    def apply_value(runes)
      @value = if @char_limit.positive? && runes.length > @char_limit
                 runes[0...@char_limit]
               else
                 runes
               end

      self.position = @value.length if @position.zero? || @position > @value.length

      handle_overflow
    end

    #: (Array[String]) -> StandardError?
    def run_validate(runes)
      validate = @validate
      return nil unless validate

      validate.call(runes.join)
    rescue StandardError => e
      e
    end

    #: () -> String
    def render_prompt
      (style = @prompt_style) ? style.render(@prompt) : @prompt
    end

    #: (String) -> String
    def render_text(text)
      (style = @text_style) ? style.render(text) : text
    end

    #: (String) -> String
    def render_placeholder(text)
      (style = @placeholder_style) ? style.render(text) : "\e[90m#{text}\e[0m"
    end

    #: () -> String
    def placeholder_view
      prompt_text = render_prompt

      first_char = @placeholder[0] || ""
      rest = @placeholder[1..] || ""

      @cursor.char = first_char
      @cursor.text_style = @placeholder_style

      v = @cursor.view
      v += render_placeholder(rest)

      @cursor.text_style = nil

      prompt_text + v
    end

    #: () -> String?
    def current_suggestion_remainder
      return nil unless @show_suggestions
      return nil if @matched_suggestions.empty?
      return nil if @value.empty?

      suggestion = @matched_suggestions[@current_suggestion_index]
      return nil unless suggestion

      remaining = suggestion[@value.length..]
      return nil if remaining.nil? || remaining.empty?

      remaining.join
    end

    #: () -> void
    def update_suggestions
      return unless @show_suggestions

      if @value.empty? || @suggestions.empty?
        @matched_suggestions = [] #: Array[Array[String]]
        return
      end

      value_string = @value.join.downcase
      matches = @suggestions.select do |suggestion|
        suggestion.join.downcase.start_with?(value_string)
      end

      @current_suggestion_index = 0 if matches != @matched_suggestions

      @matched_suggestions = matches
    end

    #: () -> bool
    def can_accept_suggestion?
      !@matched_suggestions.empty?
    end

    #: () -> void
    def accept_suggestion
      return unless can_accept_suggestion?

      suggestion = @matched_suggestions[@current_suggestion_index]
      @value = suggestion.dup

      cursor_end
    end

    #: () -> void
    def next_suggestion
      @current_suggestion_index = (@current_suggestion_index + 1) % [@matched_suggestions.length, 1].max
    end

    #: () -> void
    def previous_suggestion
      @current_suggestion_index -= 1
      @current_suggestion_index = @matched_suggestions.length - 1 if @current_suggestion_index.negative?
    end
  end
end
