import gui

fn tabbar_view(window &gui.Window) gui.View {
	app := window.state[EditorApp]()
	if app.tabs.len == 0 {
		return gui.row(
			sizing:  gui.fill_fit
			color:   gui.Color{30, 32, 38, 255}
			padding: gui.Padding{0, 8, 0, 8}
			content: [
				gui.text(
					text:       'No files open'
					text_style: gui.TextStyle{
						...gui.theme().b2
						family: editor_font
						color:  gui.Color{100, 110, 130, 255}
					}
				),
			]
		)
	}

	tab_style := gui.TextStyle{
		...gui.theme().b2
		family: editor_font
		color:  gui.Color{160, 170, 190, 255}
	}
	active_style := gui.TextStyle{
		...gui.theme().b2
		family: editor_font
		color:  gui.Color{230, 235, 245, 255}
	}
	close_style := gui.TextStyle{
		...gui.theme().b2
		family: editor_font
		color:  gui.Color{100, 110, 130, 255}
	}

	mut tab_views := []gui.View{cap: app.tabs.len}
	for i, tab in app.tabs {
		is_active := i == app.active_tab
		idx := i
		tab_views << gui.row(
			padding: gui.Padding{6, 12, 6, 12}
			spacing: 8
			color:   if is_active { gui.Color{36, 39, 46, 255} } else { gui.Color{30, 32, 38, 255} }
			on_click: fn [idx] (_ &gui.Layout, mut _ gui.Event, mut w gui.Window) {
				mut a := w.state[EditorApp]()
				a.active_tab = idx
				w.update_window()
			}
			content: [
				gui.text(
					text:       tab.name
					text_style: if is_active { active_style } else { tab_style }
				),
				gui.row(
					padding: gui.Padding{0, 2, 0, 2}
					on_click: fn [idx] (_ &gui.Layout, mut _ gui.Event, mut w gui.Window) {
						mut a := w.state[EditorApp]()
						a.close_tab(idx)
						w.update_window()
					}
					content: [
						gui.text(
							text:       '\u00d7'
							text_style: close_style
						),
					]
				),
			]
		)
	}

	return gui.row(
		sizing:          gui.fill_fit
		color:           gui.Color{25, 27, 33, 255}
		padding:         gui.padding_none
		spacing:         0
		scrollbar_cfg_x: &gui.ScrollbarCfg{overflow: .hidden}
		content:         tab_views
	)
}
