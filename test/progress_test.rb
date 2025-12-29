# frozen_string_literal: true

require "test_helper"

class ProgressTest < Minitest::Spec
  it "initialization defaults" do
    progress = Bubbles::Progress.new

    assert_equal Bubbles::Progress::DEFAULT_WIDTH, progress.width
    assert_equal "█", progress.full
    assert_equal "░", progress.empty
    assert_equal "#7571F9", progress.full_color
    assert_equal "#606060", progress.empty_color
    assert progress.show_percentage
    assert_equal " %3.0f%%", progress.percent_format
    refute progress.use_gradient
  end

  it "initialization with width" do
    progress = Bubbles::Progress.new(width: 60)

    assert_equal 60, progress.width
  end

  it "initialization with gradient" do
    progress = Bubbles::Progress.new(gradient: ["#ff0000", "#0000ff"])

    assert progress.use_gradient
    assert_equal "#ff0000", progress.gradient_a
    assert_equal "#0000ff", progress.gradient_b
    refute progress.scale_gradient
  end

  it "initialization with scaled gradient" do
    progress = Bubbles::Progress.new(scaled_gradient: ["#ff0000", "#0000ff"])

    assert progress.use_gradient
    assert_equal "#ff0000", progress.gradient_a
    assert_equal "#0000ff", progress.gradient_b
    assert progress.scale_gradient
  end

  it "initialization with solid fill" do
    progress = Bubbles::Progress.new(solid_fill: "#00ff00")

    refute progress.use_gradient
    assert_equal "#00ff00", progress.full_color
  end

  it "unique ids" do
    progress1 = Bubbles::Progress.new
    progress2 = Bubbles::Progress.new

    refute_equal progress1.id, progress2.id
  end

  it "view as zero" do
    progress = Bubbles::Progress.new(width: 20)
    progress.show_percentage = false

    result = progress.view_as(0.0)

    assert_match(/░/, result)
    refute_match(/█/, result)
  end

  it "view as full" do
    progress = Bubbles::Progress.new(width: 20)
    progress.show_percentage = false

    result = progress.view_as(1.0)

    assert_match(/█/, result)
    refute_match(/░/, result)
  end

  it "view as half" do
    progress = Bubbles::Progress.new(width: 20)
    progress.show_percentage = false

    result = progress.view_as(0.5)

    assert_match(/█/, result)
    assert_match(/░/, result)
  end

  it "view as with percentage" do
    progress = Bubbles::Progress.new(width: 30)
    progress.show_percentage = true

    result = progress.view_as(0.5)

    assert_match(/50%/, result)
  end

  it "view as clamps values" do
    progress = Bubbles::Progress.new(width: 20)
    progress.show_percentage = false

    result_negative = progress.view_as(-0.5)
    result_over = progress.view_as(1.5)

    refute_match(/█/, result_negative)
    refute_match(/░/, result_over)
  end

  it "set percent returns command" do
    progress = Bubbles::Progress.new

    command = progress.set_percent(0.5)

    assert_instance_of Bubbletea::TickCommand, command
    assert_equal 0.5, progress.percent
  end

  it "set percent clamps values" do
    progress = Bubbles::Progress.new

    progress.set_percent(-0.5)
    assert_equal 0.0, progress.percent

    progress.set_percent(1.5)
    assert_equal 1.0, progress.percent
  end

  it "increment percent" do
    progress = Bubbles::Progress.new
    progress.set_percent(0.3)

    progress.increment_percent(0.2)

    assert_in_delta 0.5, progress.percent, 0.001
  end

  it "decrement percent" do
    progress = Bubbles::Progress.new
    progress.set_percent(0.5)

    progress.decrement_percent(0.2)

    assert_in_delta 0.3, progress.percent, 0.001
  end

  it "animating initially false" do
    progress = Bubbles::Progress.new

    refute progress.animating?
  end

  it "animating after set percent" do
    progress = Bubbles::Progress.new

    progress.set_percent(0.5)

    assert progress.animating?
  end

  it "update with wrong message id" do
    progress = Bubbles::Progress.new
    progress.set_percent(0.5)

    message = Bubbles::Progress::FrameMessage.new(id: progress.id + 999, tag: 0)

    _progress, command = progress.update(message)

    assert_nil command
  end

  it "update with wrong tag" do
    progress = Bubbles::Progress.new
    progress.set_percent(0.5)

    message = Bubbles::Progress::FrameMessage.new(id: progress.id, tag: 999)

    _progress, command = progress.update(message)

    assert_nil command
  end

  it "update advances animation" do
    progress = Bubbles::Progress.new
    progress.set_percent(0.5)

    message = Bubbles::Progress::FrameMessage.new(id: progress.id, tag: 1)
    _progress, command = progress.update(message)

    assert progress.animating?
    assert_instance_of Bubbletea::TickCommand, command
  end

  it "custom characters" do
    progress = Bubbles::Progress.new(width: 20)
    progress.show_percentage = false
    progress.full = "="
    progress.empty = "-"

    result = progress.view_as(0.5)

    assert_match(/=/, result)
    assert_match(/-/, result)
  end

  it "gradient fill" do
    progress = Bubbles::Progress.new(width: 20, gradient: ["#ff0000", "#00ff00"])
    progress.show_percentage = false

    result = progress.view_as(0.5)

    assert_match(/█/, result)
  end

  it "set gradient" do
    progress = Bubbles::Progress.new

    progress.gradient("#ff0000", "#0000ff", scaled: true)

    assert progress.use_gradient
    assert_equal "#ff0000", progress.gradient_a
    assert_equal "#0000ff", progress.gradient_b
    assert progress.scale_gradient
  end

  it "percent format" do
    progress = Bubbles::Progress.new(width: 30)
    progress.percent_format = " %.1f%%"

    result = progress.view_as(0.333)

    assert_match(/33\.3%/, result)
  end

  it "init returns nil" do
    progress = Bubbles::Progress.new

    assert_nil progress.init
  end

  it "view uses percent shown" do
    progress = Bubbles::Progress.new(width: 20)
    progress.show_percentage = false

    result = progress.view

    refute_match(/█/, result)
  end
end
