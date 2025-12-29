# frozen_string_literal: true
# rbs_inline: enabled

module Bubbles
  # Help renders help text from key bindings.
  #
  # Example:
  #   help = Bubbles::Help.new
  #   help.width = 80
  #
  #   # Define a keymap with short_help and full_help methods
  #   class MyKeyMap
  #     BINDINGS = {
  #       up: Bubbles::Key.binding(keys: ["up", "k"], help: ["↑/k", "up"]),
  #       down: Bubbles::Key.binding(keys: ["down", "j"], help: ["↓/j", "down"]),
  #       help: Bubbles::Key.binding(keys: ["?"], help: ["?", "help"]),
  #       quit: Bubbles::Key.binding(keys: ["q"], help: ["q", "quit"])
  #     }
  #
  #     def short_help
  #       [BINDINGS[:help], BINDINGS[:quit]]
  #     end
  #
  #     def full_help
  #       [
  #         [BINDINGS[:up], BINDINGS[:down]],
  #         [BINDINGS[:help], BINDINGS[:quit]]
  #       ]
  #     end
  #   end
  #
  #   keymap = MyKeyMap.new
  #   puts help.view(keymap)
  #
  class Help
    DEFAULT_KEY_STYLE = nil #: Lipgloss::Style?
    DEFAULT_DESC_STYLE = nil #: Lipgloss::Style?
    DEFAULT_SEPARATOR_STYLE = nil #: Lipgloss::Style?

    attr_accessor :width #: Integer
    attr_accessor :show_all #: bool
    attr_accessor :short_separator #: String
    attr_accessor :full_separator #: String
    attr_accessor :full_help_column_gap #: Integer
    attr_accessor :key_style #: Lipgloss::Style?
    attr_accessor :desc_style #: Lipgloss::Style?
    attr_accessor :separator_style #: Lipgloss::Style?

    #: () -> void
    def initialize
      @width = 0
      @show_all = false
      @short_separator = " • "
      @full_separator = "    "
      @full_help_column_gap = 2
      @key_style = nil
      @desc_style = nil
      @separator_style = nil
    end

    #: (untyped) -> String
    def view(keymap)
      if @show_all && keymap.respond_to?(:full_help)
        full_help_view(keymap.full_help)
      elsif keymap.respond_to?(:short_help)
        short_help_view(keymap.short_help)
      else
        ""
      end
    end

    #: (Array[Key::Binding]?) -> String
    def short_help_view(bindings)
      return "" if bindings.nil? || bindings.empty?

      parts = bindings.filter_map do |binding|
        next unless binding.is_a?(Key::Binding)
        next unless binding.enabled? && binding.help?

        render_binding(binding)
      end

      return "" if parts.empty?

      separator = render_separator(@short_separator)
      result = parts.join(separator)

      truncate_to_width(result)
    end

    #: (Array[Array[Key::Binding]]?) -> String
    def full_help_view(binding_groups)
      return "" if binding_groups.nil? || binding_groups.empty?

      columns = binding_groups.map do |group|
        group.filter_map do |binding|
          next unless binding.is_a?(Key::Binding)
          next unless binding.enabled? && binding.help?

          render_binding(binding)
        end
      end

      columns.reject!(&:empty?)
      return "" if columns.empty?

      max_rows = columns.map(&:length).max

      rows = (0...max_rows).map do |row_index|
        row_parts = columns.map do |col|
          col[row_index] || ""
        end

        row_parts.join(@full_separator)
      end

      result = rows.join("\n")

      truncate_to_width(result)
    end

    private

    #: (Key::Binding) -> String
    def render_binding(binding)
      key, desc = binding.help
      key_rendered = render_key(key)
      desc_rendered = render_desc(desc)

      "#{key_rendered} #{desc_rendered}"
    end

    #: (String) -> String
    def render_key(text)
      (style = @key_style) ? style.render(text) : text
    end

    #: (String) -> String
    def render_desc(text)
      (style = @desc_style) ? style.render(text) : text
    end

    #: (String) -> String
    def render_separator(text)
      (style = @separator_style) ? style.render(text) : text
    end

    #: (String) -> String
    def truncate_to_width(text)
      return text if @width <= 0

      lines = text.split("\n")

      lines.map do |line|
        plain = strip_ansi(line)

        if plain.length > @width
          line[0, @width]
        else
          line
        end
      end.join("\n")
    end

    #: (String) -> String
    def strip_ansi(str)
      str.gsub(/\e\[[0-9;]*[A-Za-z]/, "")
    end
  end
end
