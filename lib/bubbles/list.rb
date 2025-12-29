# frozen_string_literal: true
# rbs_inline: enabled

module Bubbles
  # List is a feature-rich component for browsing a list of items.
  # It features optional filtering, pagination, and status messages.
  #
  # Example:
  #   items = [
  #     { title: "Item 1", description: "Description 1" },
  #     { title: "Item 2", description: "Description 2" }
  #   ]
  #   list = Bubbles::List.new(items, width: 40, height: 10)
  #
  #   # In update:
  #   list, command = list.update(message)
  #
  #   # In view:
  #   list.view
  #
  class List
    UNFILTERED = :unfiltered #: Symbol
    FILTERING = :filtering #: Symbol
    FILTER_APPLIED = :filter_applied #: Symbol

    class StatusMessageTimeoutMessage < Bubbletea::Message
    end

    attr_accessor :width #: Integer
    attr_accessor :height #: Integer
    attr_accessor :title #: String
    attr_accessor :show_title #: bool
    attr_accessor :show_filter #: bool
    attr_accessor :show_pagination #: bool
    attr_accessor :show_status_bar #: bool
    attr_accessor :status_message_lifetime #: Float
    attr_accessor :fill_height #: bool
    attr_accessor :title_style #: Lipgloss::Style?
    attr_accessor :item_style #: Lipgloss::Style?
    attr_accessor :selected_item_style #: Lipgloss::Style?
    attr_accessor :filter_prompt #: String
    attr_accessor :filter_style #: Lipgloss::Style?
    attr_accessor :status_bar_style #: Lipgloss::Style?
    attr_accessor :pagination_style #: Lipgloss::Style?

    attr_reader :filter_state #: Symbol
    attr_reader :filter_input #: TextInput

    #: (?Array[untyped], ?width: Integer, ?height: Integer) -> void
    def initialize(items = [], width: 40, height: 10)
      @width = width
      @height = height

      @items = items
      @filtered_items = items.dup
      @selected = 0
      @offset = 0

      @title = "List"
      @show_title = true
      @show_filter = true
      @show_pagination = true
      @show_status_bar = true
      @fill_height = true

      @filter_state = UNFILTERED
      @filter_input = TextInput.new
      @filter_input.prompt = "Filter: "
      @filter_prompt = "/"

      @paginator = Paginator.new(type: Paginator::DOTS)
      @status_message = ""
      @status_message_lifetime = 1.0

      @title_style = nil
      @item_style = nil
      @selected_item_style = nil
      @filter_style = nil
      @status_bar_style = nil
      @pagination_style = nil

      update_pagination
    end

    #: (Array[untyped]) -> void
    def items=(items)
      @items = items
      reset_filter
    end

    attr_reader :items #: Array[untyped]

    #: () -> Array[untyped]
    def visible_items
      @filtered_items
    end

    #: () -> Integer
    def selected_index
      @selected
    end

    #: () -> untyped
    def selected_item
      @filtered_items[@selected]
    end

    #: (Integer) -> void
    def select(index)
      @selected = index.clamp(0, [@filtered_items.length - 1, 0].max)
      update_offset
    end

    #: () -> void
    def select_next
      select(@selected + 1)
    end

    #: () -> void
    def select_prev
      select(@selected - 1)
    end

    #: (String) -> Bubbletea::Command
    def set_status_message(message) # rubocop:disable Naming/AccessorMethodName
      @status_message = message
      Bubbletea.tick(@status_message_lifetime) { StatusMessageTimeoutMessage.new }
    end

    #: () -> void
    def clear_status_message
      @status_message = ""
    end

    #: () -> Bubbletea::Command?
    def start_filtering
      @filter_state = FILTERING
      @filter_input.focus
    end

    #: () -> void
    def apply_filter
      return if @filter_state != FILTERING

      if @filter_input.value.empty?
        reset_filter
      else
        @filter_state = FILTER_APPLIED
        @filter_input.blur

        do_filter
      end
    end

    #: () -> void
    def reset_filter
      @filter_state = UNFILTERED
      @filter_input.reset
      @filter_input.blur
      @filtered_items = @items.dup
      @selected = 0

      update_pagination
    end

    #: (Bubbletea::Message) -> [List, Bubbletea::Command?]
    def update(message)
      commands = [] #: Array[Bubbletea::Command]

      case message
      when StatusMessageTimeoutMessage
        clear_status_message

        return [self, nil]
      when Bubbletea::KeyMessage
        if @filter_state == FILTERING
          case message.to_s
          when "enter"
            apply_filter
          when "esc"
            reset_filter
          else
            @filter_input, command = @filter_input.update(message)
            commands << command if command

            do_filter
          end
        else
          case message.to_s
          when "up", "k"
            select_prev
          when "down", "j"
            select_next
          when "home", "g"
            select(0)
          when "end", "G"
            select(@filtered_items.length - 1)
          when "pgup", "ctrl+b"
            select(@selected - visible_item_count)
          when "pgdown", "ctrl+f"
            select(@selected + visible_item_count)
          when "/"
            return [self, start_filtering] if @show_filter
          when "esc"
            reset_filter if @filter_state == FILTER_APPLIED
          end
        end
      end

      update_pagination

      [self, commands.empty? ? nil : Bubbletea.batch(*commands)]
    end

    #: () -> String
    def view
      sections = [] #: Array[String]

      if @show_title
        title = (style = @title_style) ? style.render(@title) : @title
        sections << title
        sections << ""
      end

      if @show_filter && @filter_state != UNFILTERED
        sections << @filter_input.view
        sections << ""
      end

      sections << items_view

      if @show_pagination && @filtered_items.length > visible_item_count
        sections << ""
        pagination = @paginator.view
        sections << ((style = @pagination_style) ? style.render(pagination) : pagination)
      end

      if @show_status_bar && !@status_message.empty?
        sections << ""
        status = (style = @status_bar_style) ? style.render(@status_message) : @status_message
        sections << status
      end

      sections.join("\n")
    end

    private

    #: () -> String
    def items_view
      return "No items" if @filtered_items.empty?

      lines = [] #: Array[String]
      end_index = [@offset + visible_item_count, @filtered_items.length].min

      (@offset...end_index).each do |i|
        item = @filtered_items[i]
        is_selected = i == @selected

        line = render_item(item, i, is_selected)
        lines << line
      end

      (lines << "" while lines.length < visible_item_count) if @fill_height

      lines.join("\n")
    end

    #: (untyped, Integer, bool) -> String
    def render_item(item, _index, selected)
      text = item_title(item)

      if selected
        prefix = "> "
        if (style = @selected_item_style)
          style.render(prefix + text)
        else
          "\e[7m#{prefix}#{text}\e[0m"
        end
      else
        prefix = "  "
        if (style = @item_style)
          style.render(prefix + text)
        else
          prefix + text
        end
      end
    end

    #: (untyped) -> String
    def item_title(item)
      if item.respond_to?(:title)
        item.title
      elsif item.is_a?(Hash) && item[:title]
        item[:title]
      elsif item.respond_to?(:filter_value)
        item.filter_value
      else
        item.to_s
      end
    end

    #: (untyped) -> String
    def item_filter_value(item)
      if item.respond_to?(:filter_value)
        item.filter_value
      elsif item.respond_to?(:title)
        item.title
      elsif item.is_a?(Hash) && item[:title]
        item[:title]
      else
        item.to_s
      end
    end

    #: () -> void
    def do_filter
      query = @filter_input.value.downcase

      @filtered_items = if query.empty?
                          @items.dup
                        else
                          @items.select do |item|
                            item_filter_value(item).downcase.include?(query)
                          end
                        end

      @selected = 0 if @selected >= @filtered_items.length
      update_offset
      update_pagination
    end

    #: () -> Integer
    def visible_item_count
      overhead = 0

      overhead += 2 if @show_title # Title + blank line
      overhead += 2 if @show_filter && @filter_state != UNFILTERED # Filter + blank line
      overhead += 2 if @show_pagination && @filtered_items.length > @height - overhead
      overhead += 2 if @show_status_bar && !@status_message.empty?

      [@height - overhead, 1].max
    end

    #: () -> void
    def update_offset
      visible = visible_item_count

      if @selected < @offset
        @offset = @selected
      elsif @selected >= @offset + visible
        @offset = @selected - visible + 1
      end

      @offset = @offset.clamp(0, [@filtered_items.length - visible, 0].max)
    end

    #: () -> void
    def update_pagination
      @paginator.per_page = visible_item_count
      @paginator.update_total_pages(@filtered_items.length)
      @paginator.page = @offset / [visible_item_count, 1].max
    end
  end
end
