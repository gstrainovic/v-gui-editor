import gui

fn statusbar_view(window &gui.Window) gui.View {
	app  := window.state[EditorApp]()
	sw, _ := window.window_size()

	// Get cursor position
	cpos := gui.input_cursor_pos(editor_id_focus, window)
	line := get_cursor_line(app.text, cpos)
	col  := get_cursor_col(app.text, cpos)

	// Build rich text status display
	status_rt := gui.RichText{
		runs: [
			gui.RichTextRun{
				text: 'Line ${line}, Column ${col}'
				style: gui.TextStyle{
					...gui.theme().b2
					family: editor_font
					color:  gui.Color{200, 210, 230, 255}
				}
			},
		]
	}

	return gui.row(
		width:   sw
		height:  35
		sizing:  gui.fixed_fixed
		padding: gui.Padding{0, 12, 0, 12}
		color:   gui.Color{40, 42, 50, 255}
		v_align: .middle
		spacing: 16
		content: [
			gui.rtf(rich_text: status_rt),
		]
	)
}
