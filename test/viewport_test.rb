# frozen_string_literal: true

require "test_helper"

class ViewportTest < Minitest::Spec
  it "initialization defaults" do
    viewport = Bubbles::Viewport.new

    assert_equal 80, viewport.width
    assert_equal 24, viewport.height
    assert_equal 0, viewport.y_offset
    assert_equal 0, viewport.x_offset
    assert viewport.mouse_wheel_enabled
    assert_equal 3, viewport.mouse_wheel_delta
  end

  it "initialization with dimensions" do
    viewport = Bubbles::Viewport.new(width: 40, height: 10)

    assert_equal 40, viewport.width
    assert_equal 10, viewport.height
  end

  it "set content" do
    viewport = Bubbles::Viewport.new(width: 80, height: 5)
    content = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7"

    viewport.content = content

    assert_equal 7, viewport.total_line_count
    assert_equal 5, viewport.visible_line_count
  end

  it "at top" do
    viewport = Bubbles::Viewport.new(width: 80, height: 5)
    viewport.content = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10"

    assert viewport.at_top?

    viewport.scroll_down(3)

    refute viewport.at_top?
  end

  it "at bottom" do
    viewport = Bubbles::Viewport.new(width: 80, height: 5)
    viewport.content = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10"

    refute viewport.at_bottom?

    viewport.goto_bottom

    assert viewport.at_bottom?
  end

  it "scroll down" do
    viewport = Bubbles::Viewport.new(width: 80, height: 5)

    viewport.content = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10"
    viewport.scroll_down(2)

    assert_equal 2, viewport.y_offset
  end

  it "scroll up" do
    viewport = Bubbles::Viewport.new(width: 80, height: 5)

    viewport.content = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10"
    viewport.scroll_down(5)
    viewport.scroll_up(2)

    assert_equal 3, viewport.y_offset
  end

  it "page down" do
    viewport = Bubbles::Viewport.new(width: 80, height: 5)

    viewport.content = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11\n12\n13\n14\n15"
    viewport.page_down

    assert_equal 5, viewport.y_offset
  end

  it "page up" do
    viewport = Bubbles::Viewport.new(width: 80, height: 5)

    viewport.content = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11\n12\n13\n14\n15"
    viewport.y_offset = 10
    viewport.page_up

    assert_equal 5, viewport.y_offset
  end

  it "goto top" do
    viewport = Bubbles::Viewport.new(width: 80, height: 5)

    viewport.content = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10"
    viewport.scroll_down(5)
    viewport.goto_top

    assert_equal 0, viewport.y_offset
    assert viewport.at_top?
  end

  it "goto bottom" do
    viewport = Bubbles::Viewport.new(width: 80, height: 5)
    viewport.content = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10"

    viewport.goto_bottom

    assert viewport.at_bottom?
  end

  it "scroll percent" do
    viewport = Bubbles::Viewport.new(width: 80, height: 5)
    viewport.content = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10"

    assert_in_delta 0.0, viewport.scroll_percent, 0.01

    viewport.goto_bottom

    assert_in_delta 1.0, viewport.scroll_percent, 0.01
  end

  it "scroll percent half" do
    viewport = Bubbles::Viewport.new(width: 80, height: 5)
    viewport.content = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11\n12\n13\n14\n15"

    # 15 lines, 5 visible, max offset = 10
    # Half would be offset 5

    viewport.y_offset = 5

    assert_in_delta 0.5, viewport.scroll_percent, 0.01
  end

  it "view shows visible lines" do
    viewport = Bubbles::Viewport.new(width: 80, height: 3)
    viewport.content = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5"

    view = viewport.view

    assert_includes view, "Line 1"
    assert_includes view, "Line 2"
    assert_includes view, "Line 3"
    refute_includes view, "Line 4"
  end

  it "view after scroll" do
    viewport = Bubbles::Viewport.new(width: 80, height: 3)
    viewport.content = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5"
    viewport.scroll_down(2)

    view = viewport.view

    refute_includes view, "Line 1"
    assert_includes view, "Line 3"
    assert_includes view, "Line 4"
    assert_includes view, "Line 5"
  end

  it "horizontal scrolling" do
    viewport = Bubbles::Viewport.new(width: 10, height: 3)

    viewport.content = "This is a very long line of text"
    viewport.horizontal_step = 5
    viewport.scroll_right(5)

    assert_equal 5, viewport.x_offset
  end

  it "content getter" do
    viewport = Bubbles::Viewport.new
    content = "Hello\nWorld"
    viewport.content = content

    assert_equal content, viewport.content
  end

  it "update with key down" do
    viewport = Bubbles::Viewport.new(width: 80, height: 3)
    viewport.content = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10"

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_DOWN, name: "down")
    viewport, _command = viewport.update(message)

    assert_equal 1, viewport.y_offset
  end

  it "update with key up" do
    viewport = Bubbles::Viewport.new(width: 80, height: 3)
    viewport.content = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10"
    viewport.scroll_down(5)

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_UP, name: "up")
    viewport, _command = viewport.update(message)

    assert_equal 4, viewport.y_offset
  end

  it "init returns nil" do
    viewport = Bubbles::Viewport.new

    assert_nil viewport.init
  end

  it "should clamp to max (0) since content fits" do
    viewport = Bubbles::Viewport.new(width: 80, height: 5)

    viewport.content = "1\n2\n3"
    viewport.y_offset = 100

    assert_equal 0, viewport.y_offset
  end
end
