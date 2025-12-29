# frozen_string_literal: true

require "test_helper"

class SpinnerTest < Minitest::Spec
  it "spinner initialization with defaults" do
    spinner = Bubbles::Spinner.new

    assert_equal Bubbles::Spinners::DEFAULT, spinner.spinner
    assert_nil spinner.style
    assert spinner.id.positive?
  end

  it "spinner initialization with custom spinner" do
    spinner = Bubbles::Spinner.new(spinner: Bubbles::Spinners::DOT)

    assert_equal Bubbles::Spinners::DOT, spinner.spinner
  end

  it "spinner unique ids" do
    spinner1 = Bubbles::Spinner.new
    spinner2 = Bubbles::Spinner.new

    refute_equal spinner1.id, spinner2.id
  end

  it "spinner init returns tick command" do
    spinner = Bubbles::Spinner.new
    result, command = spinner.init

    assert_equal spinner, result
    assert_instance_of Bubbletea::TickCommand, command
  end

  it "spinner view returns frame" do
    spinner = Bubbles::Spinner.new(spinner: Bubbles::Spinners::LINE)

    view = spinner.view

    assert_includes Bubbles::Spinners::LINE[:frames], view
  end

  it "spinner update advances frame" do
    spinner = Bubbles::Spinner.new(spinner: Bubbles::Spinners::LINE)
    initial_view = spinner.view

    tick_message = Bubbles::Spinner::TickMessage.new(id: spinner.id, tag: 0)
    spinner, _command = spinner.update(tick_message)

    new_view = spinner.view
    refute_equal initial_view, new_view
  end

  it "spinner ignores other spinner messages" do
    spinner1 = Bubbles::Spinner.new
    spinner2 = Bubbles::Spinner.new

    initial_view = spinner1.view

    tick_message = Bubbles::Spinner::TickMessage.new(id: spinner2.id, tag: 0)
    spinner1, command = spinner1.update(tick_message)

    assert_equal initial_view, spinner1.view
    assert_nil command
  end

  it "spinner tick returns command" do
    spinner = Bubbles::Spinner.new
    command = spinner.tick

    assert_instance_of Bubbletea::TickCommand, command
  end
end

class SpinnersTest < Minitest::Spec
  it "all spinners have frames and fps" do
    spinners = [
      Bubbles::Spinners::LINE,
      Bubbles::Spinners::DOT,
      Bubbles::Spinners::MINI_DOT,
      Bubbles::Spinners::JUMP,
      Bubbles::Spinners::PULSE,
      Bubbles::Spinners::POINTS,
      Bubbles::Spinners::GLOBE,
      Bubbles::Spinners::MOON,
      Bubbles::Spinners::MONKEY,
      Bubbles::Spinners::METER,
      Bubbles::Spinners::HAMBURGER,
      Bubbles::Spinners::ELLIPSIS,
    ]

    spinners.each do |spinner|
      assert spinner.key?(:frames), "Spinner missing :frames"
      assert spinner.key?(:fps), "Spinner missing :fps"
      assert spinner[:frames].is_a?(Array), "Frames should be an array"
      assert spinner[:fps].is_a?(Numeric), "FPS should be a number"
      assert spinner[:frames].length.positive?, "Frames should not be empty"
    end
  end

  it "default spinner is line" do
    assert_equal Bubbles::Spinners::LINE, Bubbles::Spinners::DEFAULT
  end
end
