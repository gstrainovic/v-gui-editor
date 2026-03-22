import gui

fn statusbar_view(window &gui.Window) gui.View {
	app  := window.state[EditorApp]()
	sw, _ := window.window_size()

	text := app.active_text()
	cpos := gui.input_cursor_pos(editor_id_focus, window)
	line := get_cursor_line(text, cpos)
	col  := get_cursor_col(text, cpos)

	zoom_pct := int(app.font_size_mult * 100 + 0.5)

	status_style := gui.TextStyle{
		...gui.theme().b2
		family: editor_font
		color:  gui.Color{200, 210, 230, 255}
	}
	dim_style := gui.TextStyle{
		...gui.theme().b2
		family: editor_font
		color:  gui.Color{100, 110, 130, 255}
	}
	status_rt := gui.RichText{
		runs: [
			gui.RichTextRun{text: 'Line ${line}, Column ${col}', style: status_style},
			gui.RichTextRun{text: '    ', style: dim_style},
			gui.RichTextRun{text: '${zoom_pct}%', style: if zoom_pct != 100 { status_style } else { dim_style }},
			gui.RichTextRun{text: '    ', style: dim_style},
			gui.RichTextRun{text: app.active_name(), style: dim_style},
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
