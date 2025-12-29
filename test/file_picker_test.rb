# frozen_string_literal: true

require "test_helper"

class FilePickerTest < Minitest::Spec
  it "initialization defaults" do
    picker = Bubbles::FilePicker.new

    assert_equal 10, picker.height
    assert_equal ">", picker.cursor_char
    assert picker.show_permissions
    assert picker.show_size
    refute picker.show_hidden
    refute picker.dir_allowed
    assert picker.file_allowed
    assert_equal [], picker.allowed_types
  end

  it "initialization with directory" do
    picker = Bubbles::FilePicker.new(directory: Dir.tmpdir)

    assert_equal File.expand_path(Dir.tmpdir), picker.current_directory
  end

  it "current directory setter" do
    picker = Bubbles::FilePicker.new

    picker.current_directory = Dir.tmpdir

    assert_equal File.expand_path(Dir.tmpdir), picker.current_directory
  end

  it "did select file initially false" do
    picker = Bubbles::FilePicker.new

    refute picker.did_select_file?
  end

  it "selected initially false" do
    picker = Bubbles::FilePicker.new

    refute picker.selected?
  end

  it "clear selected" do
    picker = Bubbles::FilePicker.new

    picker.instance_variable_set(:@path, "/some/path")
    picker.instance_variable_set(:@did_select, true)

    picker.clear_selected

    assert_nil picker.path
    refute picker.did_select_file?
  end

  it "cursor returns selected index" do
    picker = Bubbles::FilePicker.new

    assert_equal 0, picker.cursor
  end

  it "files returns file entries" do
    picker = Bubbles::FilePicker.new

    assert_kind_of Array, picker.files
  end

  it "unique ids" do
    picker1 = Bubbles::FilePicker.new
    picker2 = Bubbles::FilePicker.new

    refute_equal picker1.id, picker2.id
  end

  it "update resets did select" do
    picker = Bubbles::FilePicker.new
    picker.instance_variable_set(:@did_select, true)

    picker, _command = picker.update(nil)

    refute picker.did_select_file?
  end

  it "update ignores wrong id read dir message" do
    picker = Bubbles::FilePicker.new
    original_files = picker.files.dup

    message = Bubbles::FilePicker::ReadDirMessage.new(id: -999, entries: [])
    picker, _command = picker.update(message)

    assert_equal original_files, picker.files
  end

  it "update handles read dir message" do
    picker = Bubbles::FilePicker.new
    entries = [{ name: "test.txt", path: "/test.txt", directory: false }]

    message = Bubbles::FilePicker::ReadDirMessage.new(id: picker.id, entries: entries)
    picker, _command = picker.update(message)

    assert_equal entries, picker.files
  end

  it "navigation down" do
    picker = Bubbles::FilePicker.new

    files = [
      { name: "a.txt", directory: false },
      { name: "b.txt", directory: false },
      { name: "c.txt", directory: false },
    ]

    picker.instance_variable_set(:@files, files)

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_DOWN, name: "down")
    picker, _command = picker.update(message)

    assert_equal 1, picker.cursor
  end

  it "navigation up" do
    picker = Bubbles::FilePicker.new

    files = [
      { name: "a.txt", directory: false },
      { name: "b.txt", directory: false },
    ]

    picker.instance_variable_set(:@files, files)
    picker.instance_variable_set(:@selected, 1)

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_UP, name: "up")
    picker, _command = picker.update(message)

    assert_equal 0, picker.cursor
  end

  it "navigation vim keys" do
    picker = Bubbles::FilePicker.new

    files = [
      { name: "a.txt", directory: false },
      { name: "b.txt", directory: false },
    ]

    picker.instance_variable_set(:@files, files)

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_RUNES, name: "j", runes: ["j"])
    picker, _command = picker.update(message)

    assert_equal 1, picker.cursor
  end

  it "navigation home" do
    picker = Bubbles::FilePicker.new

    files = [
      { name: "a.txt", directory: false },
      { name: "b.txt", directory: false },
      { name: "c.txt", directory: false },
    ]

    picker.instance_variable_set(:@files, files)
    picker.instance_variable_set(:@selected, 2)

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_HOME, name: "home")
    picker, _command = picker.update(message)

    assert_equal 0, picker.cursor
  end

  it "navigation end" do
    picker = Bubbles::FilePicker.new

    files = [
      { name: "a.txt", directory: false },
      { name: "b.txt", directory: false },
      { name: "c.txt", directory: false },
    ]

    picker.instance_variable_set(:@files, files)

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_END, name: "end")
    picker, _command = picker.update(message)

    assert_equal 2, picker.cursor
  end

  it "view contains directory path" do
    picker = Bubbles::FilePicker.new

    view = picker.view

    assert_match(/~/, view) || assert_match(%r{/}, view)
  end

  it "view shows files" do
    picker = Bubbles::FilePicker.new

    files =  [
      { name: "test.rb", path: "/test.rb", directory: false, size: 100, permissions: "rw-r--r--", extension: "rb" },
    ]

    picker.instance_variable_set(:@files, files)

    view = picker.view

    assert_includes view, "test.rb"
  end

  it "view shows directories with slash" do
    picker = Bubbles::FilePicker.new

    files = [
      { name: "subdir", path: "/subdir", directory: true, size: 0, permissions: "rwxr-xr-x", extension: "" },
    ]

    picker.instance_variable_set(:@files, files)

    view = picker.view

    assert_match(%r{subdir.*/}, view)
  end

  it "view shows no files message when empty" do
    picker = Bubbles::FilePicker.new
    picker.instance_variable_set(:@files, [])

    view = picker.view

    assert_includes view, "No files found"
  end

  it "allowed types filtering" do
    picker = Bubbles::FilePicker.new
    picker.allowed_types = ["rb"]

    entry = { name: "test.txt", directory: false, extension: "txt" }
    refute picker.send(:can_select?, entry)

    entry_rb = { name: "test.rb", directory: false, extension: "rb" }
    assert picker.send(:can_select?, entry_rb)
  end

  it "dir allowed option" do
    picker = Bubbles::FilePicker.new
    picker.dir_allowed = true

    entry = { name: "subdir", directory: true }
    assert picker.send(:can_select?, entry)
  end

  it "dir not allowed by default" do
    picker = Bubbles::FilePicker.new

    entry = { name: "subdir", directory: true }
    refute picker.send(:can_select?, entry)
  end

  it "file not allowed option" do
    picker = Bubbles::FilePicker.new
    picker.file_allowed = false

    entry = { name: "test.txt", directory: false, extension: "txt" }
    refute picker.send(:can_select?, entry)
  end

  it "format permissions" do
    picker = Bubbles::FilePicker.new

    perms = picker.send(:format_permissions, 0o755)
    assert_equal "rwxr-xr-x", perms

    perms = picker.send(:format_permissions, 0o644)
    assert_equal "rw-r--r--", perms
  end

  it "format size" do
    picker = Bubbles::FilePicker.new

    assert_equal "0 B", picker.send(:format_size, 0)
    assert_equal "1.0B", picker.send(:format_size, 1)
    assert_equal "1.0K", picker.send(:format_size, 1024)
    assert_equal "1.0M", picker.send(:format_size, 1024 * 1024)
    assert_equal "1.0G", picker.send(:format_size, 1024 * 1024 * 1024)
  end

  it "read dir message" do
    message = Bubbles::FilePicker::ReadDirMessage.new(id: 42, entries: [{ name: "test" }])

    assert_equal 42, message.id
    assert_equal [{ name: "test" }], message.entries
  end

  it "error message" do
    message = Bubbles::FilePicker::ErrorMessage.new("test error")

    assert_equal "test error", message.error
  end

  it "height accessor" do
    picker = Bubbles::FilePicker.new
    picker.height = 20

    assert_equal 20, picker.height
  end

  it "cursor char accessor" do
    picker = Bubbles::FilePicker.new
    picker.cursor_char = "*"

    assert_equal "*", picker.cursor_char
  end
end
