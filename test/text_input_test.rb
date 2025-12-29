# frozen_string_literal: true

require "test_helper"

class TextInputTest < Minitest::Spec
  it "initialization defaults" do
    input = Bubbles::TextInput.new

    assert_equal "> ", input.prompt
    assert_equal "", input.placeholder
    assert_equal :normal, input.echo_mode
    assert_equal "*", input.echo_character
    assert_equal 0, input.char_limit
    assert_equal 0, input.width
    assert_equal "", input.value
    assert_equal 0, input.position
    refute input.focused?
  end

  it "set value" do
    input = Bubbles::TextInput.new

    input.value = "hello"

    assert_equal "hello", input.value
    assert_equal 5, input.position
  end

  it "set value with char limit" do
    input = Bubbles::TextInput.new
    input.char_limit = 3

    input.value = "hello"

    assert_equal "hel", input.value
  end

  it "focus and blur" do
    input = Bubbles::TextInput.new

    command = input.focus

    assert input.focused?
    assert_instance_of Bubbletea::TickCommand, command

    input.blur

    refute input.focused?
  end

  it "reset" do
    input = Bubbles::TextInput.new
    input.value = "hello"

    input.reset

    assert_equal "", input.value
    assert_equal 0, input.position
  end

  it "cursor movement" do
    input = Bubbles::TextInput.new
    input.value = "hello"

    input.cursor_start
    assert_equal 0, input.position

    input.cursor_end
    assert_equal 5, input.position

    input.position = 2
    assert_equal 2, input.position
  end

  it "cursor clamps to bounds" do
    input = Bubbles::TextInput.new
    input.value = "hello"

    input.position = -5
    assert_equal 0, input.position

    input.position = 100
    assert_equal 5, input.position
  end

  it "echo mode password" do
    input = Bubbles::TextInput.new
    input.echo_mode = :password
    input.value = "secret"
    input.focus

    view = input.view

    assert_match(/\*+/, view)
    refute_includes view, "secret"
  end

  it "placeholder shown when empty" do
    input = Bubbles::TextInput.new
    input.placeholder = "Enter text..."
    input.focus

    view = input.view

    assert_includes view, "nter text..." # After first char which is under cursor
  end

  it "prompt in view" do
    input = Bubbles::TextInput.new
    input.prompt = "Name: "
    input.value = "test"
    input.focus

    view = input.view

    assert view.start_with?("Name: ")
  end

  it "validation" do
    input = Bubbles::TextInput.new
    input.validate = ->(v) { raise "too short" if v.length < 3 }

    input.value = "ab"

    assert_instance_of RuntimeError, input.error
    assert_equal "too short", input.error.message
  end

  it "validation passes" do
    input = Bubbles::TextInput.new
    input.validate = ->(v) { raise "too short" if v.length < 3 }

    input.value = "hello"

    assert_nil input.error
  end

  it "suggestions" do
    input = Bubbles::TextInput.new
    input.show_suggestions = true
    input.suggestions = ["hello", "help", "world"]
    input.value = "hel"

    assert input.send(:can_accept_suggestion?)
  end

  it "update ignores when not focused" do
    input = Bubbles::TextInput.new
    # Not focused

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [97], name: "a")
    input, command = input.update(message)

    assert_equal "", input.value
    assert_nil command
  end

  it "update inserts character" do
    input = Bubbles::TextInput.new
    input.focus

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [97], name: "a")
    input, _command = input.update(message)

    assert_equal "a", input.value
  end

  it "backspace deletes character" do
    input = Bubbles::TextInput.new
    input.value = "hello"
    input.focus

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_BACKSPACE, name: "backspace")
    input, _command = input.update(message)

    assert_equal "hell", input.value
  end

  it "cursor has accessor" do
    input = Bubbles::TextInput.new

    assert_instance_of Bubbles::Cursor, input.cursor
  end
end
