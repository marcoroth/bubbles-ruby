# frozen_string_literal: true
# rbs_inline: enabled

module Bubbles
  module ANSI
    PATTERN = /\e\[[0-9;]*[A-Za-z]/ #: Regexp

    # Extracts a visible character range from a string while preserving ANSI escape codes.
    # ANSI codes before the start position are carried forward and applied to the result.
    # A reset sequence is appended if the result contains any ANSI codes.
    #
    # @rbs string String -- the input string potentially containing ANSI codes
    # @rbs start_column Integer -- the starting visible character position (0-indexed)
    # @rbs end_column Integer -- the ending visible character position (exclusive)
    # @rbs return String -- the extracted substring with ANSI codes preserved
    #
    def self.cut_string(string, start_column, end_column)
      result = +""
      active_codes = +""
      visible_position = 0
      scanner_position = 0

      while scanner_position < string.length
        if string[scanner_position..] =~ /\A(#{PATTERN})/
          ansi_sequence = ::Regexp.last_match(1)
          next unless ansi_sequence

          if visible_position < start_column
            if ansi_sequence == "\e[0m"
              active_codes = +""
            else
              active_codes << ansi_sequence
            end
          elsif visible_position < end_column
            result << ansi_sequence
          end

          scanner_position += ansi_sequence.length
        else
          char = string[scanner_position]
          next unless char

          if visible_position >= start_column && visible_position < end_column
            result << active_codes unless active_codes.empty?
            active_codes = +""
            result << char
          end

          visible_position += 1
          scanner_position += 1
        end
      end

      stripped = strip(result)
      return "" if stripped.empty?

      result << "\e[0m" unless result == stripped

      result
    end

    # Removes all ANSI escape codes from a string.
    #
    # @rbs string String -- the input string
    # @rbs return String -- the string with all ANSI codes removed
    #
    def self.strip(string)
      string.gsub(PATTERN, "")
    end
  end
end
