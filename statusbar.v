import gui

fn statusbar_view(window &gui.Window) gui.View {
	app := window.state[EditorApp]()

	// Get cursor position
	cpos := gui.input_cursor_pos(editor_id_focus, window)
	line := get_cursor_line(app.text, cpos)
	col := get_cursor_col(app.text, cpos)

	// Line and column display
	status_text := 'Line ${line}, Column ${col}'

	return gui.row(
		height:  30
		sizing:  gui.fixed_fit
		padding: gui.Padding{0, 12, 0, 12}
		color:   gui.Color{30, 32, 38, 255}
		v_align: .middle
		content: [
			gui.text(
				text: status_text
				text_style: gui.TextStyle{
					...gui.theme().b3
					color: gui.Color{150, 160, 180, 255}
				}
			),
		]
	)
}
