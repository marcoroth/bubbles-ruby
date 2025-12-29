# frozen_string_literal: true

require_relative "lib/bubbles/version"

Gem::Specification.new do |spec|
  spec.name = "bubbles"
  spec.version = Bubbles::VERSION
  spec.authors = ["Marco Roth"]
  spec.email = ["marco.roth@intergga.ch"]

  spec.summary = "TUI components for Bubble Tea."
  spec.description = "Ruby port of Charm's Bubbles. Common UI components for building terminal applications with Bubble Tea."
  spec.homepage = "https://github.com/marcoroth/bubbles-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/marcoroth/bubbles-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/marcoroth/bubbles-ruby/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "bubbles.gemspec",
    "LICENSE.txt",
    "README.md",
    "{lib,sig}/**/*"
  ]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "bubbletea"
  spec.add_dependency "harmonica"
  spec.add_dependency "lipgloss"
end
