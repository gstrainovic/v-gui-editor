import os

const editor_id_focus  = u32(1)
const editor_id_scroll = u32(1)
const explorer_id_scroll = u32(2)
const editor_font      = 'JetBrains Mono'

struct TabInfo {
mut:
	path string
	name string
	text string
}

@[heap]
struct EditorApp {
mut:
	tabs           []TabInfo
	active_tab     int       // index into tabs
	splitter_ratio f32 = 0.22
	scroll_pct     f32
	font_size_mult f32 = 1.0
	root_path      string
}

fn (app &EditorApp) active_text() string {
	if app.tabs.len == 0 {
		return ''
	}
	return app.tabs[app.active_tab].text
}

fn (app &EditorApp) active_name() string {
	if app.tabs.len == 0 {
		return 'untitled'
	}
	return app.tabs[app.active_tab].name
}

fn (mut app EditorApp) open_file(path string) {
	// Check if already open
	for i, tab in app.tabs {
		if tab.path == path {
			app.active_tab = i
			return
		}
	}
	// Read and open new tab
	content := os.read_file(path) or { '// Could not read file' }
	name := os.base(path)
	app.tabs << TabInfo{path: path, name: name, text: content}
	app.active_tab = app.tabs.len - 1
}

fn (mut app EditorApp) close_tab(idx int) {
	if idx < 0 || idx >= app.tabs.len {
		return
	}
	app.tabs.delete(idx)
	if app.tabs.len == 0 {
		app.active_tab = 0
	} else if app.active_tab >= app.tabs.len {
		app.active_tab = app.tabs.len - 1
	}
}

// Get cursor line from actual input cursor position
fn get_cursor_line(text string, cpos int) int {
	runes := text.runes()
	safe_pos := if cpos < runes.len { cpos } else { runes.len }
	return runes[..safe_pos].string().count('\n') + 1
}

// Get cursor column from actual input cursor position (0-based column in current line)
fn get_cursor_col(text string, cpos int) int {
	if cpos < 0 || cpos > text.len {
		return 0
	}
	line_start := text[..cpos].last_index('\n') or { -1 } + 1
	return cpos - line_start
}
