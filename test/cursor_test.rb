# frozen_string_literal: true

require "test_helper"

class CursorTest < Minitest::Spec
  it "initialization defaults" do
    cursor = Bubbles::Cursor.new

    assert cursor.id.positive?
    assert_equal :blink, cursor.mode
    assert_equal Bubbles::Cursor::DEFAULT_BLINK_SPEED, cursor.blink_speed
    assert cursor.blink?
    refute cursor.focused?
  end

  it "unique ids" do
    cursor1 = Bubbles::Cursor.new
    cursor2 = Bubbles::Cursor.new

    refute_equal cursor1.id, cursor2.id
  end

  it "set char" do
    cursor = Bubbles::Cursor.new

    cursor.char = "a"

    assert_equal "a", cursor.char
  end

  it "focus (cursor visible when focused)" do
    cursor = Bubbles::Cursor.new

    command = cursor.focus

    assert cursor.focused?
    refute cursor.blink?

    assert_instance_of Bubbletea::TickCommand, command
  end

  it "blur (cursor hidden when blurred)" do
    cursor = Bubbles::Cursor.new

    cursor.focus
    cursor.blur

    refute cursor.focused?
    assert cursor.blink?
  end

  it "set mode static" do
    cursor = Bubbles::Cursor.new

    command = cursor.set_mode(:static)

    assert_equal :static, cursor.mode
    assert_nil command
  end

  it "set mode blink returns command" do
    cursor = Bubbles::Cursor.new
    cursor.set_mode(:static)

    command = cursor.set_mode(:blink)

    assert_equal :blink, cursor.mode
    assert_instance_of Bubbletea::SendMessage, command
  end

  it "set mode hide (always hidden in hide mode)" do
    cursor = Bubbles::Cursor.new
    cursor.focus

    cursor.set_mode(:hide)

    assert_equal :hide, cursor.mode
    assert cursor.blink?
  end

  it "view when blinking hidden" do
    cursor = Bubbles::Cursor.new
    cursor.char = "x"

    view = cursor.view

    assert_equal "x", view
  end

  it "view when visible (after focus, blink is false)" do
    cursor = Bubbles::Cursor.new
    cursor.char = "x"
    cursor.focus

    view = cursor.view

    assert_match(/\e\[7m/, view)
    assert_includes view, "x"
  end

  it "update blink message toggles" do
    cursor = Bubbles::Cursor.new
    cursor.focus
    initial_blink = cursor.blink?

    message = Bubbles::Cursor::BlinkMessage.new(id: cursor.id, tag: 1)
    cursor.instance_variable_set(:@blink_tag, 1)
    cursor, _command = cursor.update(message)

    refute_equal initial_blink, cursor.blink?
  end

  it "update ignores wrong id" do
    cursor = Bubbles::Cursor.new
    cursor.focus
    initial_blink = cursor.blink?

    message = Bubbles::Cursor::BlinkMessage.new(id: cursor.id + 999, tag: 1)
    cursor, command = cursor.update(message)

    assert_equal initial_blink, cursor.blink?
    assert_nil command
  end

  it "update ignores wrong tag" do
    cursor = Bubbles::Cursor.new
    cursor.focus

    message = Bubbles::Cursor::BlinkMessage.new(id: cursor.id, tag: 999)
    _, command = cursor.update(message)

    assert_nil command
  end

  it "update initial blink message" do
    cursor = Bubbles::Cursor.new
    cursor.focus

    message = Bubbles::Cursor::InitialBlinkMessage.new
    _, command = cursor.update(message)

    assert_instance_of Bubbletea::TickCommand, command
  end

  it "update initial blink ignored when not focused" do
    cursor = Bubbles::Cursor.new
    # Not focused

    message = Bubbles::Cursor::InitialBlinkMessage.new
    _, command = cursor.update(message)

    assert_nil command
  end

  it "blink class method" do
    command = Bubbles::Cursor.blink

    assert_instance_of Bubbletea::SendMessage, command
  end
end
