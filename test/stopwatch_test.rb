# frozen_string_literal: true

require "test_helper"

class StopwatchTest < Minitest::Spec
  it "stopwatch initialization" do
    stopwatch = Bubbles::Stopwatch.new

    assert_equal 0.0, stopwatch.elapsed
    assert_equal 1.0, stopwatch.interval
    assert stopwatch.id.positive?
  end

  it "stopwatch initialization with custom interval" do
    stopwatch = Bubbles::Stopwatch.new(interval: 0.1)

    assert_equal 0.1, stopwatch.interval
  end

  it "stopwatch unique ids" do
    sw1 = Bubbles::Stopwatch.new
    sw2 = Bubbles::Stopwatch.new

    refute_equal sw1.id, sw2.id
  end

  it "stopwatch init returns command" do
    stopwatch = Bubbles::Stopwatch.new
    command = stopwatch.init

    assert_instance_of Bubbletea::SequenceCommand, command
  end

  it "stopwatch view shows zero initially" do
    stopwatch = Bubbles::Stopwatch.new

    view = stopwatch.view

    assert_equal "0:00.00", view
  end

  it "stopwatch view shows minutes and seconds" do
    stopwatch = Bubbles::Stopwatch.new

    stopwatch.instance_variable_set(:@elapsed, 65.0)

    view = stopwatch.view

    assert_equal "1:05.00", view
  end

  it "stopwatch view shows milliseconds" do
    stopwatch = Bubbles::Stopwatch.new
    stopwatch.instance_variable_set(:@elapsed, 65.42)

    view = stopwatch.view

    assert_equal "1:05.42", view
  end

  it "stopwatch view shows hours" do
    stopwatch = Bubbles::Stopwatch.new
    stopwatch.instance_variable_set(:@elapsed, 3665.0)

    view = stopwatch.view

    assert_equal "1:01:05.00", view
  end

  it "stopwatch start returns sequence command" do
    stopwatch = Bubbles::Stopwatch.new

    command = stopwatch.start

    assert_instance_of Bubbletea::SequenceCommand, command
  end

  it "stopwatch stop returns command" do
    stopwatch = Bubbles::Stopwatch.new

    command = stopwatch.stop

    assert_instance_of Bubbletea::SendMessage, command
  end

  it "stopwatch reset returns command" do
    stopwatch = Bubbles::Stopwatch.new

    command = stopwatch.reset

    assert_instance_of Bubbletea::SendMessage, command
  end

  it "stopwatch toggle when stopped" do
    stopwatch = Bubbles::Stopwatch.new

    command = stopwatch.toggle

    assert_instance_of Bubbletea::SequenceCommand, command
  end

  it "stopwatch update increments elapsed" do
    stopwatch = Bubbles::Stopwatch.new
    stopwatch.instance_variable_set(:@running, true)

    tick_message = Bubbles::Stopwatch::TickMessage.new(id: stopwatch.id, tag: 0)
    stopwatch, _command = stopwatch.update(tick_message)

    assert_equal 1.0, stopwatch.elapsed
  end

  it "stopwatch update reset clears elapsed" do
    stopwatch = Bubbles::Stopwatch.new
    stopwatch.instance_variable_set(:@elapsed, 100.0)

    reset_message = Bubbles::Stopwatch::ResetMessage.new(id: stopwatch.id)
    stopwatch, _command = stopwatch.update(reset_message)

    assert_equal 0.0, stopwatch.elapsed
  end

  it "stopwatch ignores other stopwatch messages" do
    sw1 = Bubbles::Stopwatch.new
    sw2 = Bubbles::Stopwatch.new
    sw1.instance_variable_set(:@running, true)

    tick_message = Bubbles::Stopwatch::TickMessage.new(id: sw2.id, tag: 0)
    sw1, command = sw1.update(tick_message)

    assert_equal 0.0, sw1.elapsed
    assert_nil command
  end
end

class StopwatchMessagesTest < Minitest::Spec
  it "tick message" do
    message = Bubbles::Stopwatch::TickMessage.new(id: 1, tag: 2)

    assert_equal 1, message.id
    assert_equal 2, message.tag
  end

  it "start stop message" do
    message = Bubbles::Stopwatch::StartStopMessage.new(id: 1, running: true)

    assert_equal 1, message.id
    assert message.running
  end

  it "reset message" do
    message = Bubbles::Stopwatch::ResetMessage.new(id: 1)

    assert_equal 1, message.id
  end
end
