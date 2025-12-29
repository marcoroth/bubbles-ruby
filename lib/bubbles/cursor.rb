# frozen_string_literal: true
# rbs_inline: enabled

module Bubbles
  # Cursor provides cursor functionality for text input components.
  #
  # Example:
  #   cursor = Bubbles::Cursor.new
  #   cursor.char = "a"
  #   cursor.focus
  #
  #   # In update:
  #   cursor, command = cursor.update(message)
  #
  #   # In view:
  #   cursor.view
  #
  class Cursor
    MODE_BLINK = :blink #: Symbol
    MODE_STATIC = :static #: Symbol
    MODE_HIDE = :hide #: Symbol

    DEFAULT_BLINK_SPEED = 0.53 #: Float

    class InitialBlinkMessage < Bubbletea::Message
    end

    class BlinkMessage < Bubbletea::Message
      attr_reader :id #: Integer
      attr_reader :tag #: Integer

      #: (id: Integer, tag: Integer) -> void
      def initialize(id:, tag:)
        super()

        @id = id
        @tag = tag
      end
    end

    class BlinkCanceledMessage < Bubbletea::Message
    end

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

    attr_reader :id #: Integer
    attr_reader :mode #: Symbol
    attr_accessor :char #: String

    attr_accessor :blink_speed #: Float
    attr_accessor :style #: Lipgloss::Style?
    attr_accessor :text_style #: Lipgloss::Style?

    #: () -> void
    def initialize
      @id = self.class.next_id
      @blink_speed = DEFAULT_BLINK_SPEED
      @style = nil
      @text_style = nil
      @char = ""
      @focus = false
      @blink = true
      @blink_tag = 0
      @mode = MODE_BLINK
    end

    #: () -> bool
    def blink?
      @blink
    end

    #: () -> bool
    def focused?
      @focus
    end

    #: (Bubbletea::Message) -> [Cursor, Bubbletea::Command?]
    def update(message)
      case message
      when InitialBlinkMessage
        return [self, nil] if @mode != MODE_BLINK || !@focus

        [self, blink_command]
      when BlinkMessage
        return [self, nil] if @mode != MODE_BLINK || !@focus
        return [self, nil] if message.id != @id || message.tag != @blink_tag

        @blink = !@blink

        [self, blink_command]
      when BlinkCanceledMessage
        [self, nil]
      else # rubocop:disable Lint/DuplicateBranch
        [self, nil]
      end
    end

    #: (Symbol) -> Bubbletea::Command?
    def set_mode(mode) # rubocop:disable Naming/AccessorMethodName
      return nil unless [MODE_BLINK, MODE_STATIC, MODE_HIDE].include?(mode)

      @mode = mode
      @blink = @mode == MODE_HIDE || !@focus

      mode == MODE_BLINK ? self.class.blink : nil
    end

    #: () -> Bubbletea::Command?
    def focus
      @focus = true
      @blink = @mode == MODE_HIDE

      return unless @mode == MODE_BLINK && @focus

      blink_command
    end

    #: () -> void
    def blur
      @focus = false
      @blink = true
    end

    #: () -> String
    def view
      if @blink
        if (text_style = @text_style)
          text_style.render(@char)
        else
          @char
        end
      elsif (style = @style)
        style.reverse(true).render(@char)
      else
        "\e[7m#{@char}\e[0m"
      end
    end

    #: () -> Bubbletea::SendMessage
    def self.blink
      Bubbletea.send_message(InitialBlinkMessage.new)
    end

    private

    #: () -> Bubbletea::Command?
    def blink_command
      return nil unless @mode == MODE_BLINK

      @blink_tag += 1
      current_id = @id
      current_tag = @blink_tag

      Bubbletea.tick(@blink_speed) do
        BlinkMessage.new(id: current_id, tag: current_tag)
      end
    end
  end
end
