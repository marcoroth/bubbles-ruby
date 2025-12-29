# frozen_string_literal: true

require "test_helper"

class PaginatorTest < Minitest::Spec
  it "initialization defaults" do
    paginator = Bubbles::Paginator.new

    assert_equal Bubbles::Paginator::ARABIC, paginator.type
    assert_equal 0, paginator.page
    assert_equal 10, paginator.per_page
    assert_equal 1, paginator.total_pages
    assert_equal "●", paginator.active_dot
    assert_equal "○", paginator.inactive_dot
    assert_equal "%d/%d", paginator.arabic_format
  end

  it "initialization with options" do
    paginator = Bubbles::Paginator.new(type: Bubbles::Paginator::DOTS, per_page: 5)

    assert_equal Bubbles::Paginator::DOTS, paginator.type
    assert_equal 5, paginator.per_page
  end

  it "set total pages" do
    paginator = Bubbles::Paginator.new(per_page: 10)

    paginator.update_total_pages(25)

    assert_equal 3, paginator.total_pages
  end

  it "set total pages rounds up" do
    paginator = Bubbles::Paginator.new(per_page: 10)

    paginator.update_total_pages(21)

    assert_equal 3, paginator.total_pages
  end

  it "set total pages minimum one" do
    paginator = Bubbles::Paginator.new(per_page: 10)

    paginator.update_total_pages(0)

    assert_equal 1, paginator.total_pages
  end

  it "set total pages clamps current page" do
    paginator = Bubbles::Paginator.new(per_page: 10)

    paginator.page = 5
    paginator.update_total_pages(30) # 3 pages

    assert_equal 2, paginator.page # Clamped to last page (0-indexed)
  end

  it "items on page" do
    paginator = Bubbles::Paginator.new(per_page: 10)
    paginator.update_total_pages(25)

    assert_equal 10, paginator.items_on_page(25)

    paginator.page = 2
    assert_equal 5, paginator.items_on_page(25) # Last page has 5 items
  end

  it "items on page empty" do
    paginator = Bubbles::Paginator.new(per_page: 10)

    assert_equal 0, paginator.items_on_page(0)
  end

  it "slice bounds" do
    paginator = Bubbles::Paginator.new(per_page: 10)
    paginator.update_total_pages(25)

    assert_equal [0, 10], paginator.slice_bounds(25)

    paginator.page = 1
    assert_equal [10, 20], paginator.slice_bounds(25)

    paginator.page = 2
    assert_equal [20, 25], paginator.slice_bounds(25)
  end

  it "prev page?" do
    paginator = Bubbles::Paginator.new(per_page: 10)
    paginator.update_total_pages(25)

    refute paginator.prev_page?

    paginator.page = 1
    assert paginator.prev_page?
  end

  it "next page?" do
    paginator = Bubbles::Paginator.new(per_page: 10)
    paginator.update_total_pages(25)

    assert paginator.next_page?

    paginator.page = 2
    refute paginator.next_page?
  end

  it "prev page" do
    paginator = Bubbles::Paginator.new(per_page: 10)
    paginator.update_total_pages(25)
    paginator.page = 1

    result = paginator.prev_page

    assert result
    assert_equal 0, paginator.page
  end

  it "prev page returns false at start" do
    paginator = Bubbles::Paginator.new(per_page: 10)
    paginator.update_total_pages(25)

    result = paginator.prev_page

    refute result
    assert_equal 0, paginator.page
  end

  it "next page" do
    paginator = Bubbles::Paginator.new(per_page: 10)
    paginator.update_total_pages(25)

    result = paginator.next_page

    assert result
    assert_equal 1, paginator.page
  end

  it "next page returns false at end" do
    paginator = Bubbles::Paginator.new(per_page: 10)
    paginator.update_total_pages(25)
    paginator.page = 2

    result = paginator.next_page

    refute result
    assert_equal 2, paginator.page
  end

  it "go to page" do
    paginator = Bubbles::Paginator.new(per_page: 10)
    paginator.update_total_pages(50)

    result = paginator.go_to_page(3)

    assert result
    assert_equal 3, paginator.page
  end

  it "go to page clamps to bounds" do
    paginator = Bubbles::Paginator.new(per_page: 10)
    paginator.update_total_pages(30)  # 3 pages (0, 1, 2)

    paginator.go_to_page(-1)
    assert_equal 0, paginator.page

    paginator.go_to_page(10)
    assert_equal 2, paginator.page
  end

  it "go to page returns false if no change" do
    paginator = Bubbles::Paginator.new(per_page: 10)
    paginator.update_total_pages(25)
    paginator.page = 1

    result = paginator.go_to_page(1)

    refute result
  end

  it "arabic view" do
    paginator = Bubbles::Paginator.new(type: Bubbles::Paginator::ARABIC, per_page: 10)
    paginator.update_total_pages(25)

    assert_equal "1/3", paginator.view

    paginator.next_page
    assert_equal "2/3", paginator.view
  end

  it "arabic view custom format" do
    paginator = Bubbles::Paginator.new(per_page: 10)
    paginator.update_total_pages(25)
    paginator.arabic_format = "Page %d of %d"

    assert_equal "Page 1 of 3", paginator.view
  end

  it "dots view" do
    paginator = Bubbles::Paginator.new(type: Bubbles::Paginator::DOTS, per_page: 10)
    paginator.update_total_pages(30)  # 3 pages

    assert_equal "● ○ ○", paginator.view

    paginator.next_page
    assert_equal "○ ● ○", paginator.view

    paginator.next_page
    assert_equal "○ ○ ●", paginator.view
  end

  it "dots view custom characters" do
    paginator = Bubbles::Paginator.new(type: Bubbles::Paginator::DOTS, per_page: 10)
    paginator.update_total_pages(20)
    paginator.active_dot = "■"
    paginator.inactive_dot = "□"

    assert_equal "■ □", paginator.view
  end

  it "single page" do
    paginator = Bubbles::Paginator.new(per_page: 10)
    paginator.update_total_pages(5)

    assert_equal 1, paginator.total_pages
    refute paginator.prev_page?
    refute paginator.next_page?
    assert_equal "1/1", paginator.view
  end
end
