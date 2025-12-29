# frozen_string_literal: true

require "test_helper"

class HelpTest < Minitest::Spec
  before do
    @help = Bubbles::Help.new
  end

  it "initialization defaults" do
    assert_equal 0, @help.width
    refute @help.show_all
    assert_equal " • ", @help.short_separator
  end

  it "short help view" do
    bindings = [
      Bubbles::Key.binding(keys: ["?"], help: ["?", "help"]),
      Bubbles::Key.binding(keys: ["q"], help: ["q", "quit"]),
    ]

    result = @help.short_help_view(bindings)

    assert_includes result, "?"
    assert_includes result, "help"
    assert_includes result, "q"
    assert_includes result, "quit"
    assert_includes result, " • "
  end

  it "short help view empty" do
    result = @help.short_help_view([])

    assert_equal "", result
  end

  it "short help view nil" do
    result = @help.short_help_view(nil)

    assert_equal "", result
  end

  it "short help view skips disabled" do
    bindings = [
      Bubbles::Key.binding(keys: ["?"], help: ["?", "help"]),
      Bubbles::Key.binding(keys: ["q"], help: ["q", "quit"], enabled: false),
    ]

    result = @help.short_help_view(bindings)

    assert_includes result, "?"
    refute_includes result, " • "
  end

  it "short help view skips no help" do
    bindings = [
      Bubbles::Key.binding(keys: ["?"], help: ["?", "help"]),
      Bubbles::Key.binding(keys: ["q"]),
    ]

    result = @help.short_help_view(bindings)

    assert_includes result, "?"
    refute_includes result, " • "
  end

  it "full help view" do
    binding_groups = [
      [
        Bubbles::Key.binding(keys: ["up"], help: ["↑", "up"]),
        Bubbles::Key.binding(keys: ["down"], help: ["↓", "down"]),
      ],
      [
        Bubbles::Key.binding(keys: ["?"], help: ["?", "help"]),
        Bubbles::Key.binding(keys: ["q"], help: ["q", "quit"]),
      ],
    ]

    result = @help.full_help_view(binding_groups)

    assert_includes result, "↑"
    assert_includes result, "up"
    assert_includes result, "?"
    assert_includes result, "quit"
    assert_includes result, "\n"
  end

  it "full help view empty" do
    result = @help.full_help_view([])

    assert_equal "", result
  end

  it "view with short help keymap" do
    keymap = Object.new
    def keymap.short_help
      [
        Bubbles::Key.binding(keys: ["q"], help: ["q", "quit"]),
      ]
    end

    result = @help.view(keymap)

    assert_includes result, "q"
    assert_includes result, "quit"
  end

  it "view with full help keymap" do
    @help.show_all = true

    keymap = Object.new
    def keymap.short_help
      [Bubbles::Key.binding(keys: ["q"], help: ["q", "quit"])]
    end

    def keymap.full_help
      [
        [Bubbles::Key.binding(keys: ["up"], help: ["↑", "up"])],
        [Bubbles::Key.binding(keys: ["q"], help: ["q", "quit"])],
      ]
    end

    result = @help.view(keymap)

    assert_includes result, "↑"
    assert_includes result, "up"
  end

  it "view with no methods" do
    keymap = Object.new

    result = @help.view(keymap)

    assert_equal "", result
  end

  it "custom separator" do
    @help.short_separator = " | "

    bindings = [
      Bubbles::Key.binding(keys: ["?"], help: ["?", "help"]),
      Bubbles::Key.binding(keys: ["q"], help: ["q", "quit"]),
    ]

    result = @help.short_help_view(bindings)

    assert_includes result, " | "
  end

  it "width truncation" do
    @help.width = 10

    bindings = [
      Bubbles::Key.binding(keys: ["?"], help: ["?", "this is a very long help text"]),
    ]

    result = @help.short_help_view(bindings)

    assert result.length <= 10
  end
end
