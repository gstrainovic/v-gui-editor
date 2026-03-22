const editor_id_focus  = u32(1)
const editor_id_scroll = u32(1)
const editor_font      = 'JetBrains Mono'

@[heap]
struct EditorApp {
mut:
	text       string
	scroll_pct f32 // cached scroll position (0.0 = top, 1.0 = bottom)
}

fn sample_code() string {
	return 'module main

import os
import strings

// A simple program to demonstrate
// the code editor prototype.

fn main() {
	args := os.args[1..]
	if args.len == 0 {
		eprintln("Usage: program <file>")
		exit(1)
	}

	filename := args[0]
	content := os.read_file(filename) or {
		eprintln("Error: cannot read file")
		exit(1)
	}

	lines := content.split_into_lines()
	for i, line in lines {
		println("line | text")
		_ = i
		_ = line
	}

	println("Done")
}

fn helper(s string) string {
	if s.len == 0 {
		return "<empty>"
	}
	return s.trim_space()
}

struct Config {
	filename string
	verbose  bool
	output   string
}

fn (c Config) validate() ! {
	if c.filename.len == 0 {
		return error("filename required")
	}
}

// End of file
'
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
	// Find start of current line
	line_start := text[..cpos].last_index('\n') or { -1 } + 1
	return cpos - line_start
}
