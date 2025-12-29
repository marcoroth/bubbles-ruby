# frozen_string_literal: true
# rbs_inline: enabled

module Bubbles
  # Table is a simple table component for displaying tabular data.
  #
  # Example:
  #   columns = [
  #     { title: "Name", width: 20 },
  #     { title: "Age", width: 5 }
  #   ]
  #   rows = [
  #     ["Alice", "30"],
  #     ["Bob", "25"]
  #   ]
  #   table = Bubbles::Table.new(columns: columns, rows: rows)
  #
  #   # In update:
  #   table, command = table.update(message)
  #
  #   # In view:
  #   table.view
  #
  class Table
    Column = Struct.new(:title, :width, keyword_init: true)

    attr_accessor :height #: Integer
    attr_accessor :focus #: bool

    attr_reader :cursor #: Integer
    attr_reader :columns #: Array[Column]
    attr_reader :rows #: Array[Array[String]]

    attr_accessor :header_style #: Lipgloss::Style?
    attr_accessor :cell_style #: Lipgloss::Style?
    attr_accessor :selected_style #: Lipgloss::Style?

    # @rbs columns: Array[Hash[Symbol, untyped] | Column] -- Column definitions with :title and :width
    # @rbs rows: Array[Array[String]] -- Row data
    # @rbs height: Integer -- Visible rows (excluding header)
    # @rbs return: void
    def initialize(columns: [], rows: [], height: 10)
      @columns = columns.map do |col|
        col.is_a?(Column) ? col : Column.new(**col)
      end

      @rows = rows
      @height = height
      @cursor = 0
      @focus = true
      @offset = 0

      @header_style = nil
      @cell_style = nil
      @selected_style = nil
    end

    #: (Array[Hash[Symbol, untyped] | Column]) -> void
    def columns=(columns)
      @columns = columns.map do |col|
        col.is_a?(Column) ? col : Column.new(**col)
      end
    end

    #: (Array[Array[String]]) -> void
    def rows=(rows)
      @rows = rows
      @cursor = @cursor.clamp(0, [@rows.length - 1, 0].max)
      update_offset
    end

    #: () -> Integer
    def selected_row
      @cursor
    end

    #: () -> Array[String]?
    def selected_row_data
      @rows[@cursor]
    end

    #: (Integer) -> void
    def go_to_row(index)
      @cursor = index.clamp(0, [@rows.length - 1, 0].max)
      update_offset
    end

    #: (?Integer) -> void
    def move_up(count = 1)
      go_to_row(@cursor - count)
    end

    #: (?Integer) -> void
    def move_down(count = 1)
      go_to_row(@cursor + count)
    end

    #: () -> void
    def go_to_top
      go_to_row(0)
    end

    #: () -> void
    def go_to_bottom
      go_to_row(@rows.length - 1)
    end

    #: () -> void
    def page_up
      move_up(@height)
    end

    #: () -> void
    def page_down
      move_down(@height)
    end

    #: () -> void
    def focus!
      @focus = true
    end

    #: () -> void
    def blur
      @focus = false
    end

    #: () -> bool
    def focused?
      @focus
    end

    #: (Bubbletea::Message) -> [Table, Bubbletea::Command?]
    def update(message)
      return [self, nil] unless @focus

      case message
      when Bubbletea::KeyMessage
        case message.to_s
        when "up", "k"
          move_up
        when "down", "j"
          move_down
        when "pgup", "b"
          page_up
        when "pgdown", "f", " ", "space"
          page_down
        when "ctrl+u", "u"
          move_up(@height / 2)
        when "ctrl+d", "d"
          move_down(@height / 2)
        when "home", "g"
          go_to_top
        when "end", "G"
          go_to_bottom
        end
      end

      [self, nil]
    end

    #: () -> String
    def view
      return "" if @columns.empty?

      lines = [] #: Array[String]

      lines << render_header
      lines << render_separator

      if @rows.empty?
        lines << "  No data"
      else
        visible_end = [@offset + @height, @rows.length].min
        (@offset...visible_end).each do |i|
          lines << render_row(i)
        end
      end

      lines << "" while lines.length < @height + 2 # +2 for header and separator

      lines.join("\n")
    end

    private

    #: () -> String
    def render_header
      header_style = @header_style
      cells = @columns.map do |col|
        text = truncate_or_pad(col.title, col.width)
        header_style ? header_style.render(text) : "\e[1m#{text}\e[0m"
      end

      cells.join(" ")
    end

    #: () -> String
    def render_separator
      cells = @columns.map do |col|
        "─" * col.width
      end

      cells.join("─")
    end

    #: (Integer) -> String
    def render_row(index)
      row = @rows[index] || []
      is_selected = index == @cursor && @focus
      selected_style = @selected_style
      cell_style = @cell_style

      cells = @columns.each_with_index.map do |col, i|
        text = truncate_or_pad(row[i] || "", col.width)

        if is_selected
          selected_style ? selected_style.render(text) : "\e[7m#{text}\e[0m"
        else
          cell_style ? cell_style.render(text) : text
        end
      end

      cells.join(" ")
    end

    #: (String, Integer) -> String
    def truncate_or_pad(text, width)
      text = text.to_s
      if text.length > width
        "#{text[0...(width - 1)]}…"
      else
        text.ljust(width)
      end
    end

    #: () -> void
    def update_offset
      if @cursor < @offset
        @offset = @cursor
      elsif @cursor >= @offset + @height
        @offset = @cursor - @height + 1
      end

      @offset = @offset.clamp(0, [0, @rows.length - @height].max)
    end
  end
end
