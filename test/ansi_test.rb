# frozen_string_literal: true

require "test_helper"

class ANSITest < Minitest::Spec
  describe "cut_string" do
    it "returns substring from start to end" do
      assert_equal "ello", Bubbles::ANSI.cut_string("Hello World", 1, 5)
    end

    it "returns from start to end of string when end exceeds length" do
      assert_equal "World", Bubbles::ANSI.cut_string("Hello World", 6, 100)
    end

    it "returns empty string when start exceeds length" do
      assert_equal "", Bubbles::ANSI.cut_string("Hello", 10, 15)
    end

    it "returns empty string for empty input" do
      assert_equal "", Bubbles::ANSI.cut_string("", 0, 5)
    end

    it "returns full string when range covers entire string" do
      assert_equal "Hello", Bubbles::ANSI.cut_string("Hello", 0, 10)
    end

    it "returns empty when start equals end" do
      assert_equal "", Bubbles::ANSI.cut_string("Hello", 2, 2)
    end

    it "preserves ANSI codes within visible range" do
      input = "\e[31mHello\e[0m World"

      assert_equal "\e[31mHello\e[0m", Bubbles::ANSI.cut_string(input, 0, 5)
    end

    it "carries forward ANSI codes from before cut start" do
      input = "\e[31mHello World\e[0m"

      assert_equal "\e[31mWorld\e[0m", Bubbles::ANSI.cut_string(input, 6, 11)
    end

    it "handles multiple ANSI codes before cut start" do
      input = "\e[1m\e[31m\e[4mHello World\e[0m"

      assert_equal "\e[1m\e[31m\e[4mWorld\e[0m", Bubbles::ANSI.cut_string(input, 6, 11)
    end

    it "preserves ANSI codes that appear mid-string" do
      input = "Hello \e[32mGreen\e[0m World"

      assert_equal "Hello \e[32mGreen\e[0m", Bubbles::ANSI.cut_string(input, 0, 11)
    end

    it "handles cutting through styled text" do
      input = "AB\e[31mCDE\e[0mFG"

      assert_equal "B\e[31mCDE\e[0mF\e[0m", Bubbles::ANSI.cut_string(input, 1, 6)
    end

    it "does not add reset when result has no ANSI codes" do
      input = "\e[31mHello\e[0m World"

      assert_equal "World", Bubbles::ANSI.cut_string(input, 6, 11)
    end

    it "handles complex SGR parameters" do
      input = "\e[38;5;196mColorful\e[0m"

      assert_equal "\e[38;5;196mColorful\e[0m", Bubbles::ANSI.cut_string(input, 0, 8)
    end

    it "handles RGB color codes" do
      input = "\e[38;2;255;0;0mRGB Text\e[0m"

      assert_equal "\e[38;2;255;0;0mRGB Text\e[0m", Bubbles::ANSI.cut_string(input, 0, 8)
    end

    it "handles string with only ANSI codes" do
      input = "\e[31m\e[0m"

      assert_equal "", Bubbles::ANSI.cut_string(input, 0, 5)
    end

    it "handles consecutive ANSI codes" do
      input = "\e[1m\e[31m\e[4mBold Red Underline\e[0m"

      assert_equal "\e[1m\e[31m\e[4mBold\e[0m", Bubbles::ANSI.cut_string(input, 0, 4)
    end

    it "handles ANSI code at exact cut boundary" do
      input = "ABC\e[31mDEF"

      assert_equal "ABC", Bubbles::ANSI.cut_string(input, 0, 3)
    end

    it "handles cut starting exactly at ANSI code position" do
      input = "ABC\e[31mDEF"

      assert_equal "\e[31mDEF\e[0m", Bubbles::ANSI.cut_string(input, 3, 6)
    end
  end

  describe "strip" do
    it "removes ANSI codes from string" do
      assert_equal "Hello World", Bubbles::ANSI.strip("\e[31mHello\e[0m World")
    end

    it "handles multiple ANSI codes" do
      input = "\e[1m\e[31m\e[4mBold Red Underline\e[0m"

      assert_equal "Bold Red Underline", Bubbles::ANSI.strip(input)
    end

    it "returns plain text unchanged" do
      assert_equal "Hello World", Bubbles::ANSI.strip("Hello World")
    end

    it "handles empty string" do
      assert_equal "", Bubbles::ANSI.strip("")
    end

    it "handles string with only ANSI codes" do
      assert_equal "", Bubbles::ANSI.strip("\e[31m\e[0m")
    end
  end
end
