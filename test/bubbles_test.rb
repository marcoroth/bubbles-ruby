# frozen_string_literal: true

require "test_helper"

class BubblesTest < Minitest::Spec
  it "has a version number" do
    refute_nil ::Bubbles::VERSION
  end

  it "spinner is available" do
    assert defined?(Bubbles::Spinner)
  end

  it "timer is available" do
    assert defined?(Bubbles::Timer)
  end

  it "stopwatch is available" do
    assert defined?(Bubbles::Stopwatch)
  end

  it "spinners module is available" do
    assert defined?(Bubbles::Spinners)
  end

  it "key is available" do
    assert defined?(Bubbles::Key)
  end

  it "help is available" do
    assert defined?(Bubbles::Help)
  end

  it "paginator is available" do
    assert defined?(Bubbles::Paginator)
  end

  it "progress is available" do
    assert defined?(Bubbles::Progress)
  end
end
