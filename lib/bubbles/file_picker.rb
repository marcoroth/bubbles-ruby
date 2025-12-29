# frozen_string_literal: true
# rbs_inline: enabled

module Bubbles
  # FilePicker is a component for browsing and selecting files.
  #
  # Example:
  #   picker = Bubbles::FilePicker.new
  #   picker.current_directory = "."
  #
  #   # In update:
  #   picker, command = picker.update(message)
  #
  #   # Check if a file was selected:
  #   if picker.did_select_file?
  #     selected_file = picker.path
  #   end
  #
  #   # In view:
  #   picker.view
  #
  class FilePicker
    class ReadDirMessage < Bubbletea::Message
      attr_reader :id #: Integer
      attr_reader :entries #: Array[Hash[Symbol, untyped]]

      #: (id: Integer, entries: Array[Hash[Symbol, untyped]]) -> void
      def initialize(id:, entries:)
        super()
        @id = id
        @entries = entries
      end
    end

    class ErrorMessage < Bubbletea::Message
      attr_reader :error #: StandardError

      #: (StandardError) -> void
      def initialize(error)
        super()
        @error = error
      end
    end

    # rubocop:disable Style/ClassVars
    @@last_id = 0 # @rbs skip
    @@id_mutex = Mutex.new # @rbs skip

    #: () -> Integer
    def self.next_id
      @@id_mutex.synchronize do
        @@last_id += 1
      end
    end
    # rubocop:enable Style/ClassVars

    attr_accessor :height #: Integer
    attr_accessor :cursor_char #: String
    attr_accessor :show_permissions #: bool
    attr_accessor :show_size #: bool
    attr_accessor :show_hidden #: bool
    attr_accessor :dir_allowed #: bool
    attr_accessor :file_allowed #: bool
    attr_accessor :allowed_types #: Array[String]
    attr_accessor :cursor_style #: Lipgloss::Style?
    attr_accessor :dir_style #: Lipgloss::Style?
    attr_accessor :file_style #: Lipgloss::Style?
    attr_accessor :selected_style #: Lipgloss::Style?
    attr_accessor :permission_style #: Lipgloss::Style?
    attr_accessor :size_style #: Lipgloss::Style?
    attr_accessor :disabled_style #: Lipgloss::Style?

    attr_reader :id #: Integer
    attr_reader :current_directory #: String
    attr_reader :path #: String?
    attr_reader :files #: Array[Hash[Symbol, untyped]]

    # @rbs directory: String -- Starting directory
    # @rbs return: void
    def initialize(directory: ".")
      @id = self.class.next_id
      @current_directory = File.expand_path(directory)
      @cursor_char = ">"
      @path = nil
      @selected = 0
      @offset = 0
      @height = 10

      @show_permissions = true
      @show_size = true
      @show_hidden = false
      @dir_allowed = false
      @file_allowed = true
      @allowed_types = [] #: Array[String]

      @files = [] #: Array[Hash[Symbol, untyped]]
      @did_select = false
      @directory_stack = [] #: Array[Hash[Symbol, untyped]]

      @cursor_style = nil
      @dir_style = nil
      @file_style = nil
      @selected_style = nil
      @permission_style = nil
      @size_style = nil
      @disabled_style = nil

      read_directory
    end

    #: (String) -> void
    def current_directory=(dir)
      @current_directory = File.expand_path(dir)
      read_directory
    end

    #: () -> bool
    def did_select_file?
      @did_select
    end

    #: () -> bool
    def selected?
      !@path.nil?
    end

    #: () -> void
    def clear_selected
      @path = nil
      @did_select = false
    end

    #: () -> Integer
    def cursor
      @selected
    end

    #: (Bubbletea::Message) -> [FilePicker, Bubbletea::Command?]
    def update(message)
      @did_select = false

      case message
      when ReadDirMessage
        return [self, nil] if message.id != @id

        @files = message.entries
        @selected = @selected.clamp(0, [@files.length - 1, 0].max)
        update_offset

      when ErrorMessage
        # Handle error
      when Bubbletea::KeyMessage
        handle_key(message)
      end

      [self, nil]
    end

    #: () -> String
    def view
      lines = [] #: Array[String]

      lines << render_path(@current_directory)
      lines << ""

      if @files.empty?
        lines << "  No files found"
      else
        visible_end = [@offset + @height, @files.length].min
        (@offset...visible_end).each do |i|
          lines << render_entry(@files[i], i == @selected)
        end
      end

      lines << "" while lines.length < @height + 2

      lines.join("\n")
    end

    private

    #: (Bubbletea::KeyMessage) -> void
    def handle_key(message)
      case message.to_s
      when "up", "k", "ctrl+p"
        @selected = [@selected - 1, 0].max
        update_offset
      when "down", "j", "ctrl+n"
        @selected = [@selected + 1, @files.length - 1].min
        update_offset
      when "pgup", "K"
        @selected = [@selected - @height, 0].max
        update_offset
      when "pgdown", "J"
        @selected = [@selected + @height, @files.length - 1].min
        update_offset
      when "home", "g"
        @selected = 0
        update_offset
      when "end", "G"
        @selected = @files.length - 1
        update_offset
      when "left", "h", "backspace"
        go_up
      when "right", "l", "enter"
        entry = @files[@selected]

        if entry
          if entry[:directory]
            enter_directory(entry)
          elsif can_select?(entry)
            select_file(entry)
          end
        end
      end
    end

    #: () -> void
    def read_directory
      entries = [] #: Array[Hash[Symbol, untyped]]

      begin
        Dir.foreach(@current_directory) do |name|
          next if name == "."
          next if name == ".." && @directory_stack.empty?
          next if !@show_hidden && name.start_with?(".") && name != ".."

          full_path = File.join(@current_directory, name)

          begin
            stat = File.stat(full_path)
            is_dir = stat.directory?
            is_symlink = File.symlink?(full_path)

            entries << {
              name: name,
              path: full_path,
              directory: is_dir,
              symlink: is_symlink,
              size: is_dir ? 0 : stat.size,
              permissions: format_permissions(stat.mode),
              extension: is_dir ? "" : File.extname(name).delete("."),
            }
          rescue SystemCallError
            # Skip files we can't stat
          end
        end
      rescue SystemCallError
        @files = []
        return
      end

      entries.sort_by! do |entry|
        [entry[:name] == ".." ? 0 : 1, entry[:directory] ? 0 : 1, entry[:name].downcase]
      end

      @files = entries
      @selected = @selected.clamp(0, [@files.length - 1, 0].max)

      update_offset
    end

    #: (Hash[Symbol, untyped]) -> void
    def enter_directory(entry)
      @directory_stack.push({ directory: @current_directory, selected: @selected, offset: @offset })
      @current_directory = File.expand_path(entry[:path])
      @selected = 0
      @offset = 0

      read_directory
    end

    #: () -> void
    def go_up
      return if @directory_stack.empty?

      state = @directory_stack.pop
      @current_directory = state[:directory]
      @selected = state[:selected]
      @offset = state[:offset]

      read_directory
    end

    #: (Hash[Symbol, untyped]) -> void
    def select_file(entry)
      @path = entry[:path]
      @did_select = true
    end

    #: (Hash[Symbol, untyped]) -> bool
    def can_select?(entry)
      return @dir_allowed if entry[:directory]
      return false unless @file_allowed

      @allowed_types.empty? || @allowed_types.include?(entry[:extension])
    end

    #: (String) -> String
    def render_path(path)
      home = Dir.home
      display = path.start_with?(home) ? path.sub(home, "~") : path
      (style = @dir_style) ? style.render(display) : "\e[34m#{display}\e[0m"
    end

    #: (Hash[Symbol, untyped], bool) -> String
    def render_entry(entry, selected)
      cursor = selected ? "#{@cursor_char} " : "  "

      if (style = @cursor_style)
        cursor = style.render(cursor)
      end

      name = entry[:name]
      is_disabled = !can_select?(entry) && !entry[:directory]

      name_rendered = if entry[:directory]
                        if entry[:name] == ".."
                          ".."
                        else
                          (style = @dir_style) ? style.render("#{name}/") : "\e[34m#{name}/\e[0m"
                        end
                      elsif is_disabled
                        (style = @disabled_style) ? style.render(name) : "\e[90m#{name}\e[0m"
                      else
                        (style = @file_style) ? style.render(name) : name
                      end

      if selected && !is_disabled
        name_rendered = (style = @selected_style) ? style.render(name) : "\e[1m#{name}\e[0m"
        name_rendered += "/" if entry[:directory] && entry[:name] != ".."
      end

      parts = [cursor, name_rendered]

      if @show_size && !entry[:directory]
        size = format_size(entry[:size])
        size_rendered = (style = @size_style) ? style.render(size) : "\e[90m#{size}\e[0m"

        parts << size_rendered
      end

      if @show_permissions
        perms = entry[:permissions]
        perms_rendered = (style = @permission_style) ? style.render(perms) : "\e[90m#{perms}\e[0m"
        parts << perms_rendered
      end

      parts.join(" ")
    end

    #: (Integer) -> String
    def format_permissions(mode)
      permissions = ""

      permissions += mode.nobits?(0o400) ? "-" : "r"
      permissions += mode.nobits?(0o200) ? "-" : "w"
      permissions += mode.nobits?(0o100) ? "-" : "x"
      permissions += mode.nobits?(0o040) ? "-" : "r"
      permissions += mode.nobits?(0o020) ? "-" : "w"
      permissions += mode.nobits?(0o010) ? "-" : "x"
      permissions += mode.nobits?(0o004) ? "-" : "r"
      permissions += mode.nobits?(0o002) ? "-" : "w"
      permissions += mode.nobits?(0o001) ? "-" : "x"

      permissions
    end

    #: (Integer) -> String
    def format_size(bytes)
      return "0 B" if bytes.zero?

      units = ["B", "K", "M", "G", "T"]
      exp = (Math.log(bytes) / Math.log(1024)).to_i
      exp = [exp, units.length - 1].min

      size = bytes.to_f / (1024**exp)

      if size >= 100
        format("%<size>.0f%<unit>s", size: size, unit: units[exp])
      else
        format("%<size>.1f%<unit>s", size: size, unit: units[exp])
      end
    end

    #: () -> void
    def update_offset
      if @selected < @offset
        @offset = @selected
      elsif @selected >= @offset + @height
        @offset = @selected - @height + 1
      end

      @offset = @offset.clamp(0, [0, @files.length - @height].max)
    end
  end
end
