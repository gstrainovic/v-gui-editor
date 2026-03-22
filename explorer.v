import gui
import os

fn build_tree_nodes(dir string, depth int) []gui.TreeNodeCfg {
	if depth > 4 {
		return []
	}
	entries := os.ls(dir) or { return [] }
	mut dirs := []string{}
	mut files := []string{}
	for entry in entries {
		if entry.starts_with('.') {
			continue
		}
		full := os.join_path(dir, entry)
		if os.is_dir(full) {
			dirs << entry
		} else {
			files << entry
		}
	}
	dirs.sort()
	files.sort()

	mut nodes := []gui.TreeNodeCfg{cap: dirs.len + files.len}
	for d in dirs {
		full := os.join_path(dir, d)
		nodes << gui.TreeNodeCfg{
			id:    full
			text:  d
			icon:  gui.icon_folder
			nodes: build_tree_nodes(full, depth + 1)
		}
	}
	for f in files {
		full := os.join_path(dir, f)
		nodes << gui.TreeNodeCfg{
			id:   full
			text: f
			icon: gui.icon_file
		}
	}
	return nodes
}

fn explorer_view(mut window gui.Window) gui.View {
	app := window.state[EditorApp]()
	nodes := build_tree_nodes(app.root_path, 0)
	root_name := os.base(app.root_path)

	return gui.column(
		sizing:          gui.fill_fill
		color:           gui.Color{25, 27, 33, 255}
		padding:         gui.padding_none
		spacing:         0
		content: [
			// Explorer header
			gui.row(
				sizing:  gui.fill_fit
				padding: gui.Padding{8, 12, 8, 12}
				color:   gui.Color{30, 32, 38, 255}
				content: [
					gui.text(
						text:       root_name
						text_style: gui.TextStyle{
							...gui.theme().b2
							family: editor_font
							color:  gui.Color{140, 150, 170, 255}
						}
					),
				]
			),
			// Tree
			window.tree(
				id:        'explorer'
				id_scroll: explorer_id_scroll
				on_select: fn (id string, mut w gui.Window) {
					if os.is_file(id) {
						mut a := w.state[EditorApp]()
						a.open_file(id)
						w.update_window()
					}
				}
				nodes:     nodes
			),
		]
	)
}
