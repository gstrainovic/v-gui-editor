import gui

fn editor_view(mut window gui.Window) gui.View {
	w, h := window.window_size()
	app := window.state[EditorApp]()
	splitter_ratio := app.splitter_ratio

	return gui.column(
		width:   w
		height:  h
		sizing:  gui.fixed_fixed
		spacing: 0
		padding: gui.padding_none
		content: [
			gui.splitter(
				id:          'main_split'
				orientation: .horizontal
				ratio:       splitter_ratio
				sizing:      gui.fill_fill
				on_change:   fn (ratio f32, _ gui.SplitterCollapsed, mut _ gui.Event, mut w gui.Window) {
					mut a := w.state[EditorApp]()
					a.splitter_ratio = ratio
				}
				first:       gui.SplitterPaneCfg{
					min_size: 120
					content:  [explorer_view(mut window)]
				}
				second:      gui.SplitterPaneCfg{
					min_size: 200
					content:  [editor_panel_view(window)]
				}
			),
			statusbar_view(window),
		]
	)
}

fn editor_panel_view(window &gui.Window) gui.View {
	app := window.state[EditorApp]()

	text := app.active_text()
	line_count := text.count('\n') + 1
	scroll_pct := app.scroll_pct
	font_mult := app.font_size_mult
	adjusted_size := gui.theme().b1.size * font_mult

	cpos := gui.input_cursor_pos(editor_id_focus, window)
	cursor_line := get_cursor_line(text, cpos)

	// Gutter text: right-aligned line numbers
	max_digits := '${line_count}'.len
	mut line_nums := []string{cap: line_count}
	for i in 1 .. line_count + 1 {
		s := '${i}'
		line_nums << ' '.repeat(max_digits - s.len) + s
	}

	// Build rich text gutter with current line in white
	mut gutter_runs := []gui.RichTextRun{}
	for i, line_num in line_nums {
		is_current := i + 1 == cursor_line
		color := if is_current { gui.Color{255, 255, 255, 255} } else { gui.Color{100, 110, 130, 255} }
		gutter_runs << gui.RichTextRun{
			text: line_num
			style: gui.TextStyle{
				...gui.theme().b1
				family: editor_font
				size:   adjusted_size
				color:  color
			}
		}
		if i < line_nums.len - 1 {
			gutter_runs << gui.RichTextRun{
				text:  '\n'
				style: gui.TextStyle{...gui.theme().b1, size: adjusted_size}
			}
		}
	}
	gutter_rt := gui.RichText{runs: gutter_runs}

	// Scale gutter width with font size
	gutter_width := f32(max_digits) * adjusted_size * 0.65 + 24 * font_mult

	return gui.column(
		sizing:  gui.fill_fill
		spacing: 0
		padding: gui.padding_none
		content: [
			// Tab bar
			tabbar_view(window),
			// Editor area (gutter + input with highlight)
			gui.row(
				sizing:  gui.fill_fill
				padding: gui.padding_none
				spacing: 0
				amend_layout: fn [cursor_line, line_count, scroll_pct] (mut layout gui.Layout, mut _ gui.Window) {
					if layout.children.len < 1 || layout.children[0].children.len < 1 {
						return
					}
					gutter_text_shape := layout.children[0].children[0].shape
					gutter_text_h     := gutter_text_shape.height
					gutter_text_y     := gutter_text_shape.y
					actual_lh         := if line_count > 0 { gutter_text_h / f32(line_count) } else { f32(20) }

					total_h        := gutter_text_h + 8
					visible_h      := layout.shape.height
					max_scroll     := if total_h > visible_h { total_h - visible_h } else { f32(0) }
					scroll_offset  := scroll_pct * max_scroll

					hl_y := gutter_text_y + f32(cursor_line - 1) * actual_lh - scroll_offset

					top    := layout.shape.y
					bottom := layout.shape.y + visible_h
					if hl_y + actual_lh <= top || hl_y >= bottom {
						return
					}
					clipped_y := if hl_y < top { top } else { hl_y }
					clipped_h := if hl_y + actual_lh > bottom { bottom - clipped_y } else { actual_lh }

					highlight := gui.Layout{
						shape: &gui.Shape{
							shape_type: .rectangle
							x:          layout.shape.x
							y:          clipped_y
							width:      layout.shape.width
							height:     clipped_h
							color:      gui.Color{70, 80, 150, 40}
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
						padding:         gui.Padding{12, 8, 4, 8}
						color:           gui.Color{30, 32, 38, 255}
						h_align:         .right
						clip:            true
						on_scroll:       fn (_ &gui.Layout, mut win gui.Window) {
							mut a := win.state[EditorApp]()
							a.scroll_pct = win.scroll_vertical_pct(editor_id_scroll)
						}
						content:         [
							gui.rtf(
								rich_text: gutter_rt
							),
						]
					),
					// Editor area
					gui.input(
						id_focus:        editor_id_focus
						id_scroll:       editor_id_scroll
						scroll_mode:     .vertical_only
						text:            text
						mode:            .multiline
						sizing:          gui.fill_fill
						color:           gui.Color{36, 39, 46, 255}
						scrollbar_cfg_y: &gui.ScrollbarCfg{overflow: .visible}
						text_style:      gui.TextStyle{
							...gui.theme().b1
							family: editor_font
							size:   adjusted_size
						}
						on_key_down:     fn (_ &gui.Layout, mut e gui.Event, mut win gui.Window) {
							mut a := win.state[EditorApp]()
							if e.modifiers.has_any(.ctrl) {
								match e.key_code {
									.right_bracket, .equal, .kp_add {
										new_mult := a.font_size_mult * 1.1
										a.font_size_mult = if new_mult > 2.5 { 2.5 } else { new_mult }
										win.update_window()
									}
									.slash, .minus, .kp_subtract {
										new_mult := a.font_size_mult / 1.1
										a.font_size_mult = if new_mult < 0.7 { 0.7 } else { new_mult }
										win.update_window()
									}
									else {}
								}
							}
						}
						on_text_changed: fn (_ &gui.Layout, s string, mut win gui.Window) {
							mut a := win.state[EditorApp]()
							if a.tabs.len > 0 {
								a.tabs[a.active_tab].text = s
							}
						}
					),
				]
			),
		]
	)
}
