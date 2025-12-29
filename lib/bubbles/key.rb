# frozen_string_literal: true
# rbs_inline: enabled

module Bubbles
  # Key provides helpers for defining and matching key bindings.
  #
  # Example:
  #   # Define key bindings
  #   KEYS = {
  #     up: Bubbles::Key.binding(
  #       keys: ["up", "k"],
  #       help: ["↑/k", "move up"]
  #     ),
  #     down: Bubbles::Key.binding(
  #       keys: ["down", "j"],
  #       help: ["↓/j", "move down"]
  #     ),
  #     quit: Bubbles::Key.binding(
  #       keys: ["q", "esc", "ctrl+c"],
  #       help: ["q", "quit"]
  #     )
  #   }
  #
  #   # Match in update
  #   def update(message)
  #     case message
  #     when Bubbletea::KeyMessage
  #       if Bubbles::Key.matches?(message, KEYS[:up])
  #         # handle up
  #       elsif Bubbles::Key.matches?(message, KEYS[:down])
  #         # handle down
  #       end
  #     end
  #   end
  #
  module Key
    class Binding
      attr_accessor :keys #: Array[String]
      attr_accessor :help_key #: String?
      attr_accessor :help_desc #: String?
      attr_accessor :enabled #: bool

      #: (keys: Array[String], ?help_key: String?, ?help_desc: String?, ?enabled: bool) -> void
      def initialize(keys:, help_key: nil, help_desc: nil, enabled: true)
        @keys = Array(keys)
        @help_key = help_key
        @help_desc = help_desc
        @enabled = enabled
      end

      #: () -> bool
      def enabled?
        @enabled
      end

      #: () -> bool
      def help?
        !!((key = @help_key) && !key.empty? && (desc = @help_desc) && !desc.empty?)
      end

      #: () -> [String, String]
      def help
        [@help_key || "", @help_desc || ""]
      end
    end

    class << self
      #: (keys: Array[String] | String, ?help: Array[String]?, ?enabled: bool) -> Binding
      def binding(keys:, help: nil, enabled: true)
        help_key, help_desc = help || [nil, nil]
        keys_array = keys.is_a?(Array) ? keys : [keys] #: Array[String]

        Binding.new(
          keys: keys_array,
          help_key: help_key,
          help_desc: help_desc,
          enabled: enabled
        )
      end

      #: (Bubbletea::KeyMessage, *Binding) -> bool
      def matches?(message, *bindings)
        return false unless message.is_a?(Bubbletea::KeyMessage)

        key_string = message.to_s

        bindings.flatten.any? do |binding|
          next false unless binding.is_a?(Binding)
          next false unless binding.enabled?

          binding.keys.any? { |k| k == key_string }
        end
      end
    end
  end
end
