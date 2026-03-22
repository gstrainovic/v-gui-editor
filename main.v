import gui
import os

fn main() {
	root := os.getwd()
	mut window := gui.window(
		title:        'Code Editor'
		state:        &EditorApp{root_path: root}
		width:        1024
		height:       700
		cursor_blink: true
		on_init:      fn (mut w gui.Window) {
			w.update_view(editor_view)
			w.set_id_focus(editor_id_focus)
		}
	)
	window.set_theme(gui.theme_dark_bordered)
	window.run()
}
