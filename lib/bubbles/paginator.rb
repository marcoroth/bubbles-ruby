# frozen_string_literal: true
# rbs_inline: enabled

module Bubbles
  # Paginator provides pagination logic and rendering.
  #
  # Example:
  #   items = (1..100).to_a
  #   paginator = Bubbles::Paginator.new(per_page: 10)
  #   paginator.update_total_pages(items.length)
  #
  #   # Get current page items
  #   start_index, end_index = paginator.slice_bounds(items.length)
  #   current_items = items[start_index...end_index]
  #
  #   # Navigation
  #   paginator.next_page
  #   paginator.prev_page
  #
  #   # Render pagination indicator
  #   puts paginator.view
  #
  class Paginator
    ARABIC = :arabic #: Symbol
    DOTS = :dots #: Symbol

    attr_accessor :type #: Symbol
    attr_accessor :page #: Integer
    attr_accessor :per_page #: Integer
    attr_accessor :total_pages #: Integer
    attr_accessor :active_dot #: String
    attr_accessor :inactive_dot #: String
    attr_accessor :arabic_format #: String
    attr_accessor :key_style #: Lipgloss::Style?
    attr_accessor :active_dot_style #: Lipgloss::Style?
    attr_accessor :inactive_dot_style #: Lipgloss::Style?

    #: (?type: Symbol, ?per_page: Integer) -> void
    def initialize(type: ARABIC, per_page: 10)
      @type = type
      @page = 0
      @per_page = per_page
      @total_pages = 1

      @active_dot = "●"
      @inactive_dot = "○"

      @arabic_format = "%d/%d"

      @key_style = nil
      @active_dot_style = nil
      @inactive_dot_style = nil
    end

    #: (Integer) -> void
    def update_total_pages(total_items)
      @total_pages = [(total_items.to_f / @per_page).ceil, 1].max
      # Clamp current page
      @page = @page.clamp(0, @total_pages - 1)
    end

    #: (Integer) -> Integer
    def items_on_page(total_items)
      return 0 if total_items <= 0

      start_index = @page * @per_page
      remaining = total_items - start_index

      [remaining, @per_page].min
    end

    #: (Integer) -> [Integer, Integer]
    def slice_bounds(total_items)
      start_index = @page * @per_page
      end_index = [start_index + @per_page, total_items].min
      [start_index, end_index]
    end

    #: () -> bool
    def prev_page?
      @page.positive?
    end

    #: () -> bool
    def next_page?
      @page < @total_pages - 1
    end

    #: () -> bool
    def prev_page # rubocop:disable Naming/PredicateMethod
      return false unless prev_page?

      @page -= 1

      true
    end

    #: () -> bool
    def next_page # rubocop:disable Naming/PredicateMethod
      return false unless next_page?

      @page += 1

      true
    end

    #: (Integer) -> bool
    def go_to_page(page) # rubocop:disable Naming/PredicateMethod
      new_page = page.clamp(0, @total_pages - 1)
      return false if new_page == @page

      @page = new_page

      true
    end

    #: () -> String
    def view
      case @type
      when DOTS
        dots_view
      else
        arabic_view
      end
    end

    private

    #: () -> String
    def arabic_view
      text = format(@arabic_format, @page + 1, @total_pages)
      (key_style = @key_style) ? key_style.render(text) : text
    end

    #: () -> String
    def dots_view
      dots = (0...@total_pages).map do |i|
        if i == @page
          render_active_dot
        else
          render_inactive_dot
        end
      end

      dots.join(" ")
    end

    #: () -> String
    def render_active_dot
      (style = @active_dot_style) ? style.render(@active_dot) : @active_dot
    end

    #: () -> String
    def render_inactive_dot
      (style = @inactive_dot_style) ? style.render(@inactive_dot) : @inactive_dot
    end
  end
end
