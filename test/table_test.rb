# frozen_string_literal: true

require "test_helper"

class TableTest < Minitest::Spec
  it "initialization defaults" do
    table = Bubbles::Table.new

    assert_equal [], table.columns
    assert_equal [], table.rows
    assert_equal 10, table.height
    assert_equal 0, table.cursor
    assert table.focused?
  end

  it "initialization with data" do
    columns = [
      { title: "Name", width: 10 },
      { title: "Age", width: 5 },
    ]
    rows = [["Alice", "30"], ["Bob", "25"]]

    table = Bubbles::Table.new(columns: columns, rows: rows)

    assert_equal 2, table.columns.length
    assert_equal 2, table.rows.length
  end

  it "set columns" do
    table = Bubbles::Table.new

    table.columns = [{ title: "ID", width: 5 }]

    assert_equal 1, table.columns.length
    assert_equal "ID", table.columns[0].title
    assert_equal 5, table.columns[0].width
  end

  it "set rows" do
    table = Bubbles::Table.new

    table.rows = [["A", "B"], ["C", "D"]]

    assert_equal 2, table.rows.length
  end

  it "navigation" do
    table = Bubbles::Table.new(rows: [["1"], ["2"], ["3"]])

    assert_equal 0, table.selected_row

    table.move_down

    assert_equal 1, table.selected_row

    table.move_up

    assert_equal 0, table.selected_row
  end

  it "go to row" do
    table = Bubbles::Table.new(rows: [["1"], ["2"], ["3"]])

    table.go_to_row(2)

    assert_equal 2, table.selected_row
    assert_equal ["3"], table.selected_row_data
  end

  it "go to row clamps" do
    table = Bubbles::Table.new(rows: [["1"], ["2"]])

    table.go_to_row(100)

    assert_equal 1, table.selected_row

    table.go_to_row(-5)

    assert_equal 0, table.selected_row
  end

  it "go to top and bottom" do
    table = Bubbles::Table.new(rows: [["1"], ["2"], ["3"], ["4"], ["5"]])
    table.go_to_row(2)

    table.go_to_top

    assert_equal 0, table.selected_row

    table.go_to_bottom

    assert_equal 4, table.selected_row
  end

  it "focus and blur" do
    table = Bubbles::Table.new

    table.blur

    refute table.focused?

    table.focus!

    assert table.focused?
  end

  it "update navigation" do
    table = Bubbles::Table.new(rows: [["1"], ["2"], ["3"]])

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_DOWN, name: "down")
    table, _command = table.update(message)

    assert_equal 1, table.selected_row

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_UP, name: "up")
    table, _command = table.update(message)

    assert_equal 0, table.selected_row
  end

  it "update ignored when blurred" do
    table = Bubbles::Table.new(rows: [["1"], ["2"]])
    table.blur

    message = Bubbletea::KeyMessage.new(key_type: Bubbletea::KeyMessage::KEY_DOWN, name: "down")
    table, _command = table.update(message)

    assert_equal 0, table.selected_row # Unchanged
  end

  it "view contains header" do
    columns = [{ title: "Name", width: 10 }]
    table = Bubbles::Table.new(columns: columns)

    view = table.view

    assert_includes view, "Name"
  end

  it "view contains rows" do
    columns = [{ title: "ID", width: 5 }]
    rows = [["1"], ["2"]]
    table = Bubbles::Table.new(columns: columns, rows: rows)

    view = table.view

    assert_includes view, "1"
    assert_includes view, "2"
  end

  it "view shows no data when empty" do
    columns = [{ title: "ID", width: 5 }]
    table = Bubbles::Table.new(columns: columns, rows: [])

    view = table.view

    assert_includes view, "No data"
  end

  it "column struct" do
    col = Bubbles::Table::Column.new(title: "Test", width: 15)

    assert_equal "Test", col.title
    assert_equal 15, col.width
  end

  it "selected row data" do
    rows = [["Alice", "30"], ["Bob", "25"]]
    table = Bubbles::Table.new(rows: rows)

    assert_equal ["Alice", "30"], table.selected_row_data

    table.move_down

    assert_equal ["Bob", "25"], table.selected_row_data
  end

  it "empty table returns empty view" do
    table = Bubbles::Table.new

    view = table.view

    assert_equal "", view
  end
end
