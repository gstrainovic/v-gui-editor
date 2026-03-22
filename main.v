import gui

// Code Editor Prototype — Feasibility Test
// ==========================================
// Tests: scrollable editor with line numbers, scrollbar, current line highlight.
// Approach: Compose existing widgets (input + gutter column) with shared id_scroll.

const editor_id_focus = u32(1)
const editor_id_scroll = u32(1)

@[heap]
struct EditorApp {
mut:
	text         string
	cursor_line  int = 1
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

fn main() {
	mut window := gui.window(
		title:        'Code Editor Prototype'
		state:        &EditorApp{text: sample_code()}
		width:        800
		height:       600
		cursor_blink: true
		on_init:      fn (mut w gui.Window) {
			w.update_view(editor_view)
			w.set_id_focus(editor_id_focus)
		}
	)
	window.set_theme(gui.theme_dark_bordered)
	window.run()
}

fn editor_view(window &gui.Window) gui.View {
	w, h := window.window_size()
	app := window.state[EditorApp]()

	line_count := app.text.count('\n') + 1

	// Build gutter text: right-aligned line numbers
	max_digits := '${line_count}'.len
	mut line_nums := []string{cap: line_count}
	for i in 1 .. line_count + 1 {
		num_str := '${i}'
		padding := ' '.repeat(max_digits - num_str.len)
		line_nums << '${padding}${num_str}'
	}
	gutter_text := line_nums.join('\n')

	gutter_width := f32(max_digits * 10 + 24)

	return gui.row(
		width:   w
		height:  h
		sizing:  gui.fixed_fixed
		padding: gui.padding_none
		spacing: 0
		content: [
			// Gutter with line numbers
			gui.column(
				id_scroll:       editor_id_scroll
				scrollbar_cfg_y: &gui.ScrollbarCfg{overflow: .hidden}
				width:           gutter_width
				sizing:          gui.fixed_fill
				padding:         gui.Padding{4, 8, 4, 8}
				color:           gui.Color{30, 32, 38, 255}
				h_align:         .right
				clip:            true
				content:         [
					gui.text(
						text:       gutter_text
						text_style: gui.TextStyle{
							...gui.theme().b3
							color: gui.Color{100, 110, 130, 255}
						}
					),
				]
			),
			// Editor area
			gui.input(
				id_focus:        editor_id_focus
				id_scroll:       editor_id_scroll
				scroll_mode:     .vertical_only
				text:            app.text
				mode:            .multiline
				sizing:          gui.fill_fill
				color:           gui.Color{36, 39, 46, 255}
				scrollbar_cfg_y: &gui.ScrollbarCfg{
					overflow: .auto
				}
				on_text_changed: fn (_ &gui.Layout, s string, mut w gui.Window) {
					mut a := w.state[EditorApp]()
					a.text = s
				}
			),
		]
	)
}
