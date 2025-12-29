# frozen_string_literal: true

require "test_helper"

class TimerTest < Minitest::Spec
  it "timer initialization" do
    timer = Bubbles::Timer.new(60.0)

    assert_equal 60.0, timer.timeout
    assert_equal 1.0, timer.interval
    assert timer.id.positive?
  end

  it "timer initialization with custom interval" do
    timer = Bubbles::Timer.new(30.0, interval: 0.5)

    assert_equal 30.0, timer.timeout
    assert_equal 0.5, timer.interval
  end

  it "timer unique ids" do
    timer1 = Bubbles::Timer.new(10.0)
    timer2 = Bubbles::Timer.new(20.0)

    refute_equal timer1.id, timer2.id
  end

  it "timer init starts running" do
    timer = Bubbles::Timer.new(10.0)
    command = timer.init

    assert timer.running?
    assert_instance_of Bubbletea::TickCommand, command
  end

  it "timer not timed out initially" do
    timer = Bubbles::Timer.new(10.0)

    refute timer.timed_out?
  end

  it "timer view shows time" do
    timer = Bubbles::Timer.new(65.0)

    view = timer.view

    assert_equal "1m5s", view
  end

  it "timer view shows hours" do
    timer = Bubbles::Timer.new(3665.0)

    view = timer.view

    assert_equal "1h1m5s", view
  end

  it "timer view shows zero when timed out" do
    timer = Bubbles::Timer.new(0.0)

    view = timer.view

    assert_equal "0s", view
  end

  it "timer update decrements timeout" do
    timer = Bubbles::Timer.new(10.0)
    timer.init

    tick_message = Bubbles::Timer::TickMessage.new(id: timer.id, tag: 0)
    timer, _command = timer.update(tick_message)

    assert_equal 9.0, timer.timeout
  end

  it "timer timed out after countdown" do
    timer = Bubbles::Timer.new(1.0)
    timer.init

    tick_message = Bubbles::Timer::TickMessage.new(id: timer.id, tag: 0)
    timer, _command = timer.update(tick_message)

    assert timer.timed_out?
    refute timer.running?
  end

  it "timer stop returns command" do
    timer = Bubbles::Timer.new(10.0)
    timer.init

    command = timer.stop

    assert_instance_of Bubbletea::SendMessage, command
  end

  it "timer start returns command" do
    timer = Bubbles::Timer.new(10.0)

    command = timer.start

    assert_instance_of Bubbletea::SendMessage, command
  end

  it "timer toggle returns command" do
    timer = Bubbles::Timer.new(10.0)

    command = timer.toggle

    assert_instance_of Bubbletea::SendMessage, command
  end

  it "timer ignores other timer messages" do
    timer1 = Bubbles::Timer.new(10.0)
    timer2 = Bubbles::Timer.new(20.0)
    timer1.init

    tick_message = Bubbles::Timer::TickMessage.new(id: timer2.id, tag: 0)
    timer1, command = timer1.update(tick_message)

    assert_equal 10.0, timer1.timeout
    assert_nil command
  end
end

class TimerMessagesTest < Minitest::Spec
  it "tick message" do
    message = Bubbles::Timer::TickMessage.new(id: 1, tag: 2, timeout: true)

    assert_equal 1, message.id
    assert_equal 2, message.tag
    assert message.timeout
  end

  it "timeout message" do
    message = Bubbles::Timer::TimeoutMessage.new(id: 1)

    assert_equal 1, message.id
  end

  it "start stop message" do
    message = Bubbles::Timer::StartStopMessage.new(id: 1, running: true)

    assert_equal 1, message.id
    assert message.running
  end
end
