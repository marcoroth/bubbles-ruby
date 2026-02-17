# frozen_string_literal: true

require "test_helper"

class CrypticSpinnerTest < Minitest::Spec
  describe "initialization" do
    it "initializes with defaults" do
      spinner = Bubbles::CrypticSpinner.new

      assert_equal Bubbles::CrypticSpinner::DEFAULT_SIZE, spinner.size
      assert_equal Bubbles::CrypticSpinner::DEFAULT_ROWS, spinner.rows
      assert_equal "", spinner.label
      assert_equal Bubbles::CrypticSpinner::DEFAULT_COLOR_A, spinner.color_a
      assert_equal Bubbles::CrypticSpinner::DEFAULT_COLOR_B, spinner.color_b
      assert_equal Bubbles::CrypticSpinner::DEFAULT_LABEL_COLOR, spinner.label_color
      assert_equal false, spinner.cycle_colors
      assert spinner.id.positive?
    end

    it "initializes with custom size" do
      spinner = Bubbles::CrypticSpinner.new(size: 20)

      assert_equal 20, spinner.size
    end

    it "initializes with custom rows" do
      spinner = Bubbles::CrypticSpinner.new(rows: 3)

      assert_equal 3, spinner.rows
    end

    it "initializes with custom label" do
      spinner = Bubbles::CrypticSpinner.new(label: "Loading")

      assert_equal "Loading", spinner.label
    end

    it "initializes with custom colors" do
      spinner = Bubbles::CrypticSpinner.new(
        color_a: "#ff0000",
        color_b: "#00ff00",
        label_color: "#0000ff"
      )

      assert_equal "#ff0000", spinner.color_a
      assert_equal "#00ff00", spinner.color_b
      assert_equal "#0000ff", spinner.label_color
    end

    it "initializes with cycle_colors enabled" do
      spinner = Bubbles::CrypticSpinner.new(cycle_colors: true)

      assert_equal true, spinner.cycle_colors
    end
  end

  describe "unique ids" do
    it "generates unique ids for each instance" do
      spinner1 = Bubbles::CrypticSpinner.new
      spinner2 = Bubbles::CrypticSpinner.new

      refute_equal spinner1.id, spinner2.id
    end
  end

  describe "#init" do
    it "returns tick command" do
      spinner = Bubbles::CrypticSpinner.new
      result, command = spinner.init

      assert_equal spinner, result
      assert_instance_of Bubbletea::TickCommand, command
    end
  end

  describe "#view" do
    it "returns string for single row" do
      spinner = Bubbles::CrypticSpinner.new(size: 10)
      view = spinner.view

      assert_instance_of String, view
      refute_includes view, "\n"
    end

    it "returns multi-line string for multiple rows" do
      spinner = Bubbles::CrypticSpinner.new(size: 10, rows: 3)
      view = spinner.view

      assert_instance_of String, view
      assert_equal 2, view.count("\n")
    end

    it "includes label when provided" do
      spinner = Bubbles::CrypticSpinner.new(size: 5, label: "Test")
      view = spinner.view

      assert_includes view, "Test"
    end

    it "label appears only on last row for multi-row" do
      spinner = Bubbles::CrypticSpinner.new(size: 5, rows: 3, label: "Loading")
      view = spinner.view
      lines = view.split("\n")

      refute_includes lines[0], "Loading"
      refute_includes lines[1], "Loading"
      assert_includes lines[2], "Loading"
    end
  end

  describe "#update" do
    it "advances frame on tick message" do
      spinner = Bubbles::CrypticSpinner.new
      tick_message = Bubbles::CrypticSpinner::TickMessage.new(id: spinner.id, tag: 0)

      spinner, command = spinner.update(tick_message)

      assert_instance_of Bubbles::CrypticSpinner, spinner
      assert_instance_of Bubbletea::TickCommand, command
    end

    it "ignores tick messages from other spinners" do
      spinner1 = Bubbles::CrypticSpinner.new
      spinner2 = Bubbles::CrypticSpinner.new

      tick_message = Bubbles::CrypticSpinner::TickMessage.new(id: spinner2.id, tag: 0)
      _, command = spinner1.update(tick_message)

      assert_nil command
    end

    it "ignores non-tick messages" do
      spinner = Bubbles::CrypticSpinner.new
      _, command = spinner.update("some message")

      assert_nil command
    end
  end

  describe "#tick" do
    it "returns tick command" do
      spinner = Bubbles::CrypticSpinner.new
      command = spinner.tick

      assert_instance_of Bubbletea::TickCommand, command
    end
  end

  describe "#width" do
    it "returns size when no label" do
      spinner = Bubbles::CrypticSpinner.new(size: 15)

      assert_equal 15, spinner.width
    end

    it "includes label and ellipsis width" do
      spinner = Bubbles::CrypticSpinner.new(size: 10, label: "Test")

      # size + space + label + max ellipsis (...)
      assert_equal 10 + 1 + 4 + 3, spinner.width
    end
  end

  describe "#height" do
    it "returns number of rows" do
      spinner = Bubbles::CrypticSpinner.new(rows: 5)

      assert_equal 5, spinner.height
    end
  end

  describe "#label=" do
    it "updates the label" do
      spinner = Bubbles::CrypticSpinner.new(label: "Loading")

      spinner.label = "Processing"

      assert_equal "Processing", spinner.label
    end
  end

  describe "constants" do
    it "has correct default colors (CharmTone)" do
      assert_equal "#6B50FF", Bubbles::CrypticSpinner::DEFAULT_COLOR_A
      assert_equal "#FF60FF", Bubbles::CrypticSpinner::DEFAULT_COLOR_B
      assert_equal "#DFDBDD", Bubbles::CrypticSpinner::DEFAULT_LABEL_COLOR
    end

    it "has available characters" do
      chars = Bubbles::CrypticSpinner::AVAILABLE_CHARS

      assert_instance_of Array, chars
      assert chars.length > 30
      assert_includes chars, "0"
      assert_includes chars, "a"
      assert_includes chars, "F"
      assert_includes chars, "#"
      assert_includes chars, "@"
    end

    it "has correct FPS" do
      assert_equal 20, Bubbles::CrypticSpinner::FPS
    end
  end

  describe "TickMessage" do
    it "stores id and tag" do
      message = Bubbles::CrypticSpinner::TickMessage.new(id: 42, tag: 7)

      assert_equal 42, message.id
      assert_equal 7, message.tag
    end
  end
end
