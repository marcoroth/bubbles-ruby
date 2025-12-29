# frozen_string_literal: true

require "test_helper"

class TextAreaTest < Minitest::Spec
  it "initialization defaults" do
    textarea = Bubbles::TextArea.new

    assert_equal Bubbles::TextArea::DEFAULT_WIDTH, textarea.width
    assert_equal Bubbles::TextArea::DEFAULT_HEIGHT, textarea.height
    assert_equal 0, textarea.char_limit
    assert_equal "", textarea.value
    assert_equal 0, textarea.row
    assert_equal 0, textarea.col
    assert_equal 1, textarea.line_count
    refute textarea.focused?
  end

  it "initialization with dimensions" do
    textarea = Bubbles::TextArea.new(width: 80, height: 10)

    assert_equal 80, textarea.width
    assert_equal 10, textarea.height
  end

  it "set value" do
    textarea = Bubbles::TextArea.new

    textarea.value = "Hello\nWorld"

    assert_equal "Hello\nWorld", textarea.value
    assert_equal 2, textarea.line_count
  end

  it "focus and blur" do
    textarea = Bubbles::TextArea.new

    command = textarea.focus

    assert textarea.focused?
    assert_instance_of Bubbletea::TickCommand, command

    textarea.blur

    refute textarea.focused?
  end

  it "reset" do
    textarea = Bubbles::TextArea.new
    textarea.value = "Hello\nWorld"

    textarea.reset

    assert_equal "", textarea.value
    assert_equal 0, textarea.row
    assert_equal 0, textarea.col
    assert_equal 1, textarea.line_count
  end

  it "current line" do
    textarea = Bubbles::TextArea.new
    textarea.value = "Line 1\nLine 2\nLine 3"

    assert_equal "Line 3", textarea.current_line
  end

  it "view shows placeholder when empty" do
    textarea = Bubbles::TextArea.new(width: 40, height: 3)
    textarea.placeholder = "Enter text..."
    textarea.focus

    view = textarea.view

    assert_includes view, "nter text..." # After cursor on first char
  end

  it "view shows content" do
    textarea = Bubbles::TextArea.new(width: 40, height: 5)
    textarea.value = "Line 1\nLine 2\nLine 3"
    textarea.focus

    view = textarea.view

    assert_includes view, "Line 1"
    assert_includes view, "Line 2"
  end

  it "line numbers" do
    textarea = Bubbles::TextArea.new(width: 40, height: 5)
    textarea.show_line_numbers = true
    textarea.value = "First\nSecond"
    textarea.focus

    view = textarea.view

    assert_includes view, " 1 "
    assert_includes view, " 2 "
  end

  it "update ignores when not focused" do
    textarea = Bubbles::TextArea.new
    # Not focused

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [97], name: "a")
    textarea, command = textarea.update(message)

    assert_equal "", textarea.value
    assert_nil command
  end

  it "insert character" do
    textarea = Bubbles::TextArea.new
    textarea.focus

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [97], name: "a")
    textarea, _command = textarea.update(message)

    assert_equal "a", textarea.value
    assert_equal 1, textarea.col
  end

  it "insert newline" do
    textarea = Bubbles::TextArea.new
    textarea.value = "Hello"
    textarea.focus

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_ENTER, name: "enter")
    textarea, _command = textarea.update(message)

    assert_equal "Hello\n", textarea.value
    assert_equal 2, textarea.line_count
    assert_equal 1, textarea.row
    assert_equal 0, textarea.col
  end

  it "backspace" do
    textarea = Bubbles::TextArea.new
    textarea.value = "Hello"
    textarea.focus

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_BACKSPACE, name: "backspace")
    textarea, _command = textarea.update(message)

    assert_equal "Hell", textarea.value
  end

  it "backspace joins lines" do
    textarea = Bubbles::TextArea.new
    textarea.value = "Hello\nWorld"
    textarea.focus
    textarea.instance_variable_set(:@col, 0)

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_BACKSPACE, name: "backspace")
    textarea, _command = textarea.update(message)

    assert_equal "HelloWorld", textarea.value
    assert_equal 1, textarea.line_count
  end

  it "arrow navigation" do
    textarea = Bubbles::TextArea.new
    textarea.value = "Hello\nWorld"
    textarea.focus

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_UP, name: "up")
    textarea, _command = textarea.update(message)

    assert_equal 0, textarea.row

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_DOWN, name: "down")
    textarea, _command = textarea.update(message)

    assert_equal 1, textarea.row
  end

  it "char limit" do
    textarea = Bubbles::TextArea.new
    textarea.char_limit = 5
    textarea.focus

    textarea.value = ""
    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: "hello world".bytes, name: "h")

    "hello world".each_char do |char|
      message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [char.ord], name: char)
      textarea, _command = textarea.update(message)
    end

    assert textarea.value.length <= 5
  end

  it "cursor accessor" do
    textarea = Bubbles::TextArea.new

    assert_instance_of Bubbles::Cursor, textarea.cursor
  end
end
