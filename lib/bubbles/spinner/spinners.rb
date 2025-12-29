# frozen_string_literal: true
# rbs_inline: enabled

module Bubbles
  module Spinners
    LINE = {
      frames: ["|", "/", "-", "\\"],
      fps: 0.1,
    }.freeze #: Hash[Symbol, Array[String] | Float]

    DOT = {
      frames: ["⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"],
      fps: 0.1,
    }.freeze #: Hash[Symbol, Array[String] | Float]

    MINI_DOT = {
      frames: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"],
      fps: 0.083,
    }.freeze #: Hash[Symbol, Array[String] | Float]

    JUMP = {
      frames: ["⢄", "⢂", "⢁", "⡁", "⡈", "⡐", "⡠"],
      fps: 0.1,
    }.freeze #: Hash[Symbol, Array[String] | Float]

    PULSE = {
      frames: ["█", "▓", "▒", "░"],
      fps: 0.125,
    }.freeze #: Hash[Symbol, Array[String] | Float]

    POINTS = {
      frames: ["∙∙∙", "●∙∙", "∙●∙", "∙∙●"],
      fps: 0.143,
    }.freeze #: Hash[Symbol, Array[String] | Float]

    GLOBE = {
      frames: ["🌍", "🌎", "🌏"],
      fps: 0.25,
    }.freeze #: Hash[Symbol, Array[String] | Float]

    MOON = {
      frames: ["🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"],
      fps: 0.125,
    }.freeze #: Hash[Symbol, Array[String] | Float]

    MONKEY = {
      frames: ["🙈", "🙉", "🙊"],
      fps: 0.333,
    }.freeze #: Hash[Symbol, Array[String] | Float]

    METER = {
      frames: [
        "▱▱▱",
        "▰▱▱",
        "▰▰▱",
        "▰▰▰",
        "▰▰▱",
        "▰▱▱",
        "▱▱▱",
      ],
      fps: 0.143,
    }.freeze #: Hash[Symbol, Array[String] | Float]

    HAMBURGER = {
      frames: ["☱", "☲", "☴", "☲"],
      fps: 0.333,
    }.freeze #: Hash[Symbol, Array[String] | Float]

    ELLIPSIS = {
      frames: ["", ".", "..", "..."],
      fps: 0.333,
    }.freeze #: Hash[Symbol, Array[String] | Float]

    # @rbs DEFAULT:
    DEFAULT = LINE #: Hash[Symbol, Array[String] | Float]
  end
end
