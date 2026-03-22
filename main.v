import gui

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
