# frozen_string_literal: true

require "test_helper"

class ListTest < Minitest::Spec
  it "initialization defaults" do
    list = Bubbles::List.new

    assert_equal 40, list.width
    assert_equal 10, list.height
    assert_equal "List", list.title

    assert list.show_title
    assert list.show_filter
    assert list.show_pagination

    assert_equal Bubbles::List::UNFILTERED, list.filter_state
  end

  it "initialization with items" do
    items = [{ title: "One" }, { title: "Two" }, { title: "Three" }]
    list = Bubbles::List.new(items)

    assert_equal 3, list.items.length
    assert_equal 3, list.visible_items.length
  end

  it "selection" do
    items = [{ title: "One" }, { title: "Two" }, { title: "Three" }]
    list = Bubbles::List.new(items)

    assert_equal 0, list.selected_index
    assert_equal({ title: "One" }, list.selected_item)

    list.select_next

    assert_equal 1, list.selected_index
    assert_equal({ title: "Two" }, list.selected_item)

    list.select_prev

    assert_equal 0, list.selected_index
  end

  it "select clamps to bounds" do
    items = [{ title: "One" }, { title: "Two" }]
    list = Bubbles::List.new(items)

    list.select(-5)
    assert_equal 0, list.selected_index

    list.select(100)
    assert_equal 1, list.selected_index
  end

  it "set items" do
    list = Bubbles::List.new
    items = [{ title: "New Item" }]

    list.items = items

    assert_equal 1, list.items.length
  end

  it "filtering" do
    items = [
      { title: "Apple" },
      { title: "Banana" },
      { title: "Cherry" },
      { title: "Apricot" },
    ]
    list = Bubbles::List.new(items, height: 20)

    list.start_filtering
    assert_equal Bubbles::List::FILTERING, list.filter_state

    list.filter_input.value = "ap"
    list.send(:do_filter)

    assert_equal 2, list.visible_items.length
  end

  it "apply filter" do
    items = [{ title: "Apple" }, { title: "Banana" }]
    list = Bubbles::List.new(items, height: 20)

    list.start_filtering
    list.filter_input.value = "ban"
    list.apply_filter

    assert_equal Bubbles::List::FILTER_APPLIED, list.filter_state
    assert_equal 1, list.visible_items.length
  end

  it "reset filter" do
    items = [{ title: "Apple" }, { title: "Banana" }]
    list = Bubbles::List.new(items, height: 20)

    list.start_filtering
    list.filter_input.value = "ban"
    list.apply_filter

    list.reset_filter

    assert_equal Bubbles::List::UNFILTERED, list.filter_state
    assert_equal 2, list.visible_items.length
  end

  it "view contains items" do
    items = [{ title: "First" }, { title: "Second" }]
    list = Bubbles::List.new(items, height: 10)

    view = list.view

    assert_includes view, "First"
    assert_includes view, "Second"
  end

  it "view contains title" do
    list = Bubbles::List.new
    list.title = "My List"

    view = list.view

    assert_includes view, "My List"
  end

  it "update navigation" do
    items = [{ title: "One" }, { title: "Two" }, { title: "Three" }]
    list = Bubbles::List.new(items)

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_DOWN, name: "down")
    list, _command = list.update(message)

    assert_equal 1, list.selected_index

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_UP, name: "up")
    list, _command = list.update(message)

    assert_equal 0, list.selected_index
  end

  it "update start filter" do
    list = Bubbles::List.new([{ title: "Item" }])

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [47], name: "/")
    list, _command = list.update(message)

    assert_equal Bubbles::List::FILTERING, list.filter_state
  end

  it "status message" do
    list = Bubbles::List.new

    command = list.set_status_message("Hello")

    assert_includes list.view, "Hello"
    assert_instance_of Bubbletea::TickCommand, command
  end

  it "items with filter value method" do
    item_class = Struct.new(:name) do
      def filter_value
        name
      end
    end

    items = [item_class.new("Apple"), item_class.new("Banana")]
    list = Bubbles::List.new(items, height: 20)

    list.start_filtering
    list.filter_input.value = "app"
    list.send(:do_filter)

    assert_equal 1, list.visible_items.length
  end

  it "empty list" do
    list = Bubbles::List.new

    view = list.view

    assert_includes view, "No items"
  end
end
