<div align="center">
  <h1>Bubbles for Ruby</h1>
  <h4>TUI components for Bubble Tea</h4>

  <p>
    <a href="https://rubygems.org/gems/bubbles"><img alt="Gem Version" src="https://img.shields.io/gem/v/bubbles"></a>
    <a href="https://github.com/marcoroth/bubbles-ruby/blob/main/LICENSE.txt"><img alt="License" src="https://img.shields.io/github/license/marcoroth/bubbles-ruby"></a>
  </p>

  <p>Ruby implementation of <a href="https://github.com/charmbracelet/bubbles">charmbracelet/bubbles</a>.<br/>Common UI components for building terminal applications with <a href="https://github.com/marcoroth/bubbletea-ruby">Bubble Tea</a>.</p>
</div>

## Installation

**Add to your Gemfile:**

```ruby
gem "bubbles"
```

**Or install directly:**

```bash
gem install bubbles
```

## Components

| Component | Description |
|-----------|-------------|
| [Spinner](#spinner) | Loading spinners with multiple styles |
| [CrypticSpinner](#crypticspinner) | Animated gradient spinner with cryptic characters |
| [Progress](#progress) | Animated progress bars |
| [Timer](#timer) | Countdown timer |
| [Stopwatch](#stopwatch) | Elapsed time counter |
| [TextInput](#textinput) | Single-line text input with cursor |
| [TextArea](#textarea) | Multi-line text input |
| [Viewport](#viewport) | Scrollable content pane |
| [List](#list) | Interactive list with filtering |
| [Table](#table) | Data table with columns |
| [FilePicker](#filepicker) | File and directory browser |
| [Paginator](#paginator) | Pagination controls |
| [Help](#help) | Help text generator |
| [Key](#key) | Key binding definitions |
| [Cursor](#cursor) | Blinking cursor for inputs |

## Usage

### Spinner

**Animated loading indicator:**

```ruby
require "bubbles"

spinner = Bubbles::Spinner.new
spinner.spinner = Bubbles::Spinners::DOT
```

**In your update method:**

```ruby
spinner, command = spinner.update(message)
```

**In your view method:**

```ruby
spinner.view
```

**Available spinner styles:**

```ruby
Bubbles::Spinners::LINE
Bubbles::Spinners::DOT
Bubbles::Spinners::MINI_DOT
Bubbles::Spinners::JUMP
Bubbles::Spinners::PULSE
Bubbles::Spinners::POINTS
Bubbles::Spinners::GLOBE
Bubbles::Spinners::MOON
Bubbles::Spinners::MONKEY
Bubbles::Spinners::METER
Bubbles::Spinners::HAMBURGER
Bubbles::Spinners::ELLIPSIS
```

### CrypticSpinner

**Animated gradient spinner with cryptic characters (inspired by [Crush](https://github.com/charmbracelet/crush)):**

```ruby
spinner = Bubbles::CrypticSpinner.new(
  size: 15,
  label: "Thinking",
  cycle_colors: true
)
```

**In your update method:**

```ruby
case message
when Bubbles::CrypticSpinner::TickMessage
  spinner, command = spinner.update(message)
end
```

**In your view method:**

```ruby
spinner.view
```

**Custom colors (using CharmTone palette):**

```ruby
spinner = Bubbles::CrypticSpinner.new(
  size: 15,
  label: "Processing",
  color_a: "#6B50FF",  # Charple (purple)
  color_b: "#FF60FF",  # Dolly (pink)
  label_color: "#DFDBDD",
  cycle_colors: true
)
```

**Multi-row (matrix style):**

```ruby
spinner = Bubbles::CrypticSpinner.new(
  size: 40,
  rows: 5,
  label: "Decrypting",
  color_a: "#00ff00",
  color_b: "#003300",
  cycle_colors: true
)
```

**Options:**

| Option | Default | Description |
|--------|---------|-------------|
| `size` | 10 | Number of cycling characters |
| `rows` | 1 | Number of rows (for matrix effect) |
| `label` | "" | Text label after the animation |
| `color_a` | "#6B50FF" | Start color of gradient |
| `color_b` | "#FF60FF" | End color of gradient |
| `label_color` | "#DFDBDD" | Color of the label text |
| `cycle_colors` | false | Animate gradient movement |

### Progress

**Animated progress bar:**

```ruby
progress = Bubbles::Progress.new(width: 40)
progress.set_percent(0.5)
```

**In your view:**

```ruby
progress.view
```

**Customization:**

```ruby
progress = Bubbles::Progress.new(
  width: 40,
  full: "█",
  empty: "░",
  show_percentage: true
)
progress.full_color = "212"
progress.empty_color = "238"
```

### Timer

**Countdown timer (60 seconds):**

```ruby
timer = Bubbles::Timer.new(60)
```

**Start the timer:**

```ruby
command = timer.start
```

**In update:**

```ruby
timer, command = timer.update(message)
```

**Check if done:**

```ruby
timer.timed_out?
```

**In view:**

```ruby
timer.view
```

### Stopwatch

**Elapsed time counter:**

```ruby
stopwatch = Bubbles::Stopwatch.new
```

**Start/stop/toggle:**

```ruby
command = stopwatch.start
stopwatch.stop
command = stopwatch.toggle
```

**In view:**

```ruby
stopwatch.view
```

### TextInput

**Single-line text input:**

```ruby
input = Bubbles::TextInput.new
input.placeholder = "Enter your name..."
input.prompt = "> "
input.focus
```

**In update:**

```ruby
input, command = input.update(message)
```

**Get value:**

```ruby
input.value
```

**In view:**

```ruby
input.view
```

**Password mode:**

```ruby
input.echo_mode = :password
input.echo_character = "*"
```

**With suggestions:**

```ruby
input.suggestions = ["apple", "apricot", "avocado"]
input.show_suggestions = true
```

### TextArea

**Multi-line text input:**

```ruby
textarea = Bubbles::TextArea.new(width: 60, height: 10)
textarea.placeholder = "Type your message..."
textarea.show_line_numbers = true
textarea.focus
```

**In update:**

```ruby
textarea, command = textarea.update(message)
```

**Get value:**

```ruby
textarea.value
```

**Position info:**

```ruby
textarea.row
textarea.col
textarea.line_count
```

### Viewport

**Scrollable content pane:**

```ruby
viewport = Bubbles::Viewport.new(width: 80, height: 20)
viewport.content = long_text
```

**In update (handles scroll keys):**

```ruby
viewport, command = viewport.update(message)
```

**Scroll info:**

```ruby
viewport.scroll_percent
viewport.at_top?
viewport.at_bottom?
```

**In view:**

```ruby
viewport.view
```

**Programmatic scrolling:**

```ruby
viewport.scroll_down(5)
viewport.scroll_up(5)
viewport.page_down
viewport.page_up
viewport.goto_top
viewport.goto_bottom
```

### List

**Interactive list with filtering:**

```ruby
items = [
  { title: "Item 1", description: "First item" },
  { title: "Item 2", description: "Second item" }
]

list = Bubbles::List.new(items, width: 40, height: 10)
list.title = "My List"
```

**In update:**

```ruby
list, command = list.update(message)
```

**Get selection:**

```ruby
list.selected_item
```

**Filter state:**

```ruby
list.filter_state
```

**Styling:**

```ruby
list.title_style = Lipgloss::Style.new.bold(true).foreground("212")
list.selected_item_style = Lipgloss::Style.new.foreground("212")
list.item_style = Lipgloss::Style.new.foreground("252")
```

### Table

**Data table with columns:**

```ruby
columns = [
  { title: "Name", width: 20 },
  { title: "Age", width: 5 },
  { title: "City", width: 15 }
]

rows = [
  ["Alice", "30", "New York"],
  ["Bob", "25", "London"]
]

table = Bubbles::Table.new(columns: columns, rows: rows, height: 10)
```

**In update:**

```ruby
table, command = table.update(message)
```

**Get selection:**

```ruby
table.selected_row
table.selected_row_data
```

**Styling:**

```ruby
table.header_style = Lipgloss::Style.new.bold(true).foreground("212")
table.cell_style = Lipgloss::Style.new.padding_left(1)
table.selected_style = Lipgloss::Style.new.bold(true).background("57")
```

### FilePicker

**File and directory browser:**

```ruby
picker = Bubbles::FilePicker.new(directory: ".")
picker.height = 15
picker.show_hidden = false
picker.allowed_types = ["rb", "txt"]
```

**In update:**

```ruby
picker, command = picker.update(message)
```

**Check for selection:**

```ruby
if picker.did_select_file?
  selected_path = picker.path
end
```

**Options:**

```ruby
picker.show_permissions = true
picker.show_size = true
picker.dir_allowed = false
picker.file_allowed = true
```

### Paginator

**Pagination controls:**

```ruby
paginator = Bubbles::Paginator.new(type: Bubbles::Paginator::DOTS)
paginator.per_page = 10
paginator.update_total_pages(100)
```

**Navigation:**

```ruby
paginator.next_page
paginator.prev_page
```

**Get slice bounds for your data:**

```ruby
start_index, end_index = paginator.slice_bounds(items.length)
visible_items = items[start_index...end_index]
```

**In view:**

```ruby
paginator.view
```

**Types:**

```ruby
Bubbles::Paginator::ARABIC
Bubbles::Paginator::DOTS
```

### Help

**Help text generator:**

```ruby
help = Bubbles::Help.new

bindings = [
  Bubbles::Key.binding(keys: ["up", "k"], help: ["↑/k", "up"]),
  Bubbles::Key.binding(keys: ["down", "j"], help: ["↓/j", "down"]),
  Bubbles::Key.binding(keys: ["q"], help: ["q", "quit"])
]

help.short_help_view(bindings)
```

### Key

**Key binding definitions:**

```ruby
quit_binding = Bubbles::Key.binding(
  keys: ["q", "ctrl+c"],
  help: ["q", "quit"]
)
```

**Check if a key matches:**

```ruby
Bubbles::Key.matches?(message, quit_binding)
```

### Cursor

**Blinking cursor for inputs:**

```ruby
cursor = Bubbles::Cursor.new
cursor.char = "_"
cursor.focus
```

**Set cursor mode:**

```ruby
cursor.set_mode(:blink)
cursor.set_mode(:static)
cursor.set_mode(:hide)
```

**In update:**

```ruby
cursor, command = cursor.update(message)
```

**In view:**

```ruby
cursor.view
```

## Complete Example

```ruby
require "bubbletea"
require "lipgloss"
require "bubbles"

class MyApp
  include Bubbletea::Model

  def initialize
    @spinner = Bubbles::Spinner.new
    @spinner.spinner = Bubbles::Spinners::DOT
  end

  def init
    [self, @spinner.tick]
  end

  def update(message)
    case message
    when Bubbletea::KeyMessage
      return [self, Bubbletea.quit] if message.to_s == "q"
    end

    @spinner, command = @spinner.update(message)
    [self, command]
  end

  def view
    "#{@spinner.view} Loading...\n\nPress q to quit"
  end
end

Bubbletea.run(MyApp.new)
```

## Development

**Requirements:**
- Ruby 3.2+
- [bubbletea-ruby](https://github.com/marcoroth/bubbletea-ruby)
- [lipgloss-ruby](https://github.com/marcoroth/lipgloss-ruby) (optional, for styling)

**Install dependencies:**

```bash
bundle install
```

**Run tests:**

```bash
bundle exec rake test
```

**Run demos:**

```bash
./demo/spinner
./demo/cryptic_spinner
./demo/progress
./demo/textinput
./demo/textarea
./demo/viewport
./demo/list
./demo/table
./demo/filepicker
./demo/timer
./demo/stopwatch
./demo/paginator
./demo/help
./demo/cursor
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcoroth/bubbles-ruby.

## License

The gem is available as open source under the terms of the MIT License.

## Acknowledgments

This gem is a Ruby implementation of [charmbracelet/bubbles](https://github.com/charmbracelet/bubbles), part of the excellent [Charm](https://charm.sh) ecosystem. Charm Ruby is not affiliated with or endorsed by Charmbracelet, Inc.

---

Part of [Charm Ruby](https://charm-ruby.dev).

<a href="https://charm-ruby.dev"><img alt="Charm Ruby" src="https://marcoroth.dev/images/heros/glamorous-christmas.png" width="400"></a>

[Lipgloss](https://github.com/marcoroth/lipgloss-ruby) • [Bubble Tea](https://github.com/marcoroth/bubbletea-ruby) • [Bubbles](https://github.com/marcoroth/bubbles-ruby) • [Glamour](https://github.com/marcoroth/glamour-ruby) • [Huh?](https://github.com/marcoroth/huh-ruby) • [Harmonica](https://github.com/marcoroth/harmonica-ruby) • [Bubblezone](https://github.com/marcoroth/bubblezone-ruby) • [Gum](https://github.com/marcoroth/gum-ruby) • [ntcharts](https://github.com/marcoroth/ntcharts-ruby)

The terminal doesn't have to be boring.
