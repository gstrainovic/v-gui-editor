import gui

// Code Editor Prototype
// Approach: Compose existing widgets (input + gutter column) with shared id_scroll.
// Current-line highlight injected via amend_layout on the outer row.

const editor_id_focus  = u32(1)
const editor_id_scroll = u32(1)

@[heap]
struct EditorApp {
mut:
	text            string
	cursor_line     int = 1
	last_line_count int = 1
	scroll_pct      f32 // cached scroll position (0.0 = top, 1.0 = bottom)
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
		state:        &EditorApp{
			text:            sample_code()
			last_line_count: sample_code().count('\n') + 1
		}
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

	line_count  := app.text.count('\n') + 1
	cursor_line := app.cursor_line
	scroll_pct  := app.scroll_pct

	// Gutter text: right-aligned line numbers
	max_digits := '${line_count}'.len
	mut line_nums := []string{cap: line_count}
	for i in 1 .. line_count + 1 {
		s := '${i}'
		line_nums << ' '.repeat(max_digits - s.len) + s
	}
	gutter_text := line_nums.join('\n')

	// 14px per digit + 24px padding — wide enough for up to 4-digit line numbers
	gutter_width := f32(max_digits * 14 + 24)

	return gui.row(
		width:   w
		height:  h
		sizing:  gui.fixed_fixed
		padding: gui.padding_none
		spacing: 0
		// Inject full-row current-line highlight rectangle behind gutter + editor
		amend_layout: fn [cursor_line, line_count, scroll_pct] (mut layout gui.Layout, mut _ gui.Window) {
			// Read actual line height from the gutter text child layout.
			// layout.children[0] = gutter column, .children[0] = text widget.
			// text.shape.height = total rendered height of all line-number lines.
			if layout.children.len < 1 || layout.children[0].children.len < 1 {
				return
			}
			gutter_text_h := layout.children[0].children[0].shape.height
			actual_lh     := if line_count > 0 { gutter_text_h / f32(line_count) } else { f32(20) }

			// Total scrollable content height (text + top/bottom gutter padding 4+4)
			total_h        := gutter_text_h + 8
			visible_h      := layout.shape.height
			max_scroll     := if total_h > visible_h { total_h - visible_h } else { f32(0) }
			scroll_offset  := scroll_pct * max_scroll

			// Absolute Y of the highlighted line (4px = gutter top padding)
			hl_y := layout.shape.y + f32(cursor_line - 1) * actual_lh + 4 - scroll_offset

			// Clamp to visible area
			top    := layout.shape.y
			bottom := layout.shape.y + visible_h
			if hl_y + actual_lh <= top || hl_y >= bottom {
				return
			}
			clipped_y := if hl_y < top { top } else { hl_y }
			clipped_h := if hl_y + actual_lh > bottom { bottom - clipped_y } else { actual_lh }

			// Append highlight rect as last child → drawn on top of gutter/editor
			highlight := gui.Layout{
				shape: &gui.Shape{
					shape_type: .rectangle
					x:          layout.shape.x
					y:          clipped_y
					width:      layout.shape.width
					height:     clipped_h
					color:      gui.Color{70, 80, 150, 200}
				}
			}
			mut new_children := layout.children.clone()
			new_children << highlight
			layout.children = new_children
		}
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
				on_scroll:       fn (_ &gui.Layout, mut win gui.Window) {
					mut a := win.state[EditorApp]()
					a.scroll_pct = win.scroll_vertical_pct(editor_id_scroll)
				}
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
				scrollbar_cfg_y: &gui.ScrollbarCfg{overflow: .auto}
				on_key_down:     fn (_ &gui.Layout, mut e gui.Event, mut win gui.Window) {
					mut a := win.state[EditorApp]()
					lc := a.text.count('\n') + 1
					match e.key_code {
						.up       { if a.cursor_line > 1  { a.cursor_line-- } }
						.down     { if a.cursor_line < lc { a.cursor_line++ } }
						.home     {
							// Ctrl+Home → first line
							if e.modifiers.has_any(.ctrl) { a.cursor_line = 1 }
						}
						.end      {
							// Ctrl+End → last line
							if e.modifiers.has_any(.ctrl) { a.cursor_line = lc }
						}
						else      {}
					}
				}
				on_text_changed: fn (_ &gui.Layout, s string, mut win gui.Window) {
					mut a := win.state[EditorApp]()
					new_lc := s.count('\n') + 1
					delta  := new_lc - a.last_line_count
					if delta != 0 {
						new_pos := a.cursor_line + delta
						a.cursor_line = if new_pos < 1 { 1 } else if new_pos > new_lc { new_lc } else { new_pos }
					}
					a.text            = s
					a.last_line_count = new_lc
				}
			),
		]
	)
}
