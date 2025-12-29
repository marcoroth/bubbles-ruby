# frozen_string_literal: true

require "test_helper"

class KeyBindingTest < Minitest::Spec
  it "binding initialization" do
    binding = Bubbles::Key::Binding.new(
      keys: ["up", "k"],
      help_key: "↑/k",
      help_desc: "move up"
    )

    assert_equal ["up", "k"], binding.keys
    assert_equal "↑/k", binding.help_key
    assert_equal "move up", binding.help_desc
    assert binding.enabled?
  end

  it "binding with single key" do
    binding = Bubbles::Key::Binding.new(keys: "q")

    assert_equal ["q"], binding.keys
  end

  it "binding disabled" do
    binding = Bubbles::Key::Binding.new(keys: ["q"], enabled: false)

    refute binding.enabled?
  end

  it "binding help?" do
    with_help = Bubbles::Key::Binding.new(
      keys: ["q"],
      help_key: "q",
      help_desc: "quit"
    )
    without_help = Bubbles::Key::Binding.new(keys: ["q"])

    assert with_help.help?
    refute without_help.help?
  end

  it "binding help returns array" do
    binding = Bubbles::Key::Binding.new(
      keys: ["q"],
      help_key: "q",
      help_desc: "quit"
    )

    assert_equal ["q", "quit"], binding.help
  end

  it "binding help returns empty strings when nil" do
    binding = Bubbles::Key::Binding.new(keys: ["q"])

    assert_equal ["", ""], binding.help
  end
end

class KeyModuleTest < Minitest::Spec
  it "key binding helper" do
    binding = Bubbles::Key.binding(
      keys: ["up", "k"],
      help: ["↑/k", "move up"]
    )

    assert_instance_of Bubbles::Key::Binding, binding
    assert_equal ["up", "k"], binding.keys
    assert_equal "↑/k", binding.help_key
    assert_equal "move up", binding.help_desc
  end

  it "key binding helper without help" do
    binding = Bubbles::Key.binding(keys: ["q"])

    assert_instance_of Bubbles::Key::Binding, binding
    refute binding.help?
  end

  it "key binding helper disabled" do
    binding = Bubbles::Key.binding(keys: ["q"], enabled: false)

    refute binding.enabled?
  end

  it "matches single binding" do
    binding = Bubbles::Key.binding(keys: ["up", "k"])
    up_message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_UP, name: "up")
    k_message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [107], name: "k")
    other_message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_DOWN, name: "down")

    assert Bubbles::Key.matches?(up_message, binding)
    assert Bubbles::Key.matches?(k_message, binding)
    refute Bubbles::Key.matches?(other_message, binding)
  end

  it "matches multiple bindings" do
    up = Bubbles::Key.binding(keys: ["up"])
    down = Bubbles::Key.binding(keys: ["down"])

    up_message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_UP, name: "up")

    assert Bubbles::Key.matches?(up_message, up, down)
    assert Bubbles::Key.matches?(up_message, [up, down])
  end

  it "matches disabled binding" do
    binding = Bubbles::Key.binding(keys: ["q"], enabled: false)
    q_message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, runes: [113], name: "q")

    refute Bubbles::Key.matches?(q_message, binding)
  end

  it "matches returns false for non key message" do
    binding = Bubbles::Key.binding(keys: ["q"])

    refute Bubbles::Key.matches?("not a message", binding)
    refute Bubbles::Key.matches?(nil, binding)
  end
end
