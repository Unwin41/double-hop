class_name UiSounds
extends RefCounted
## Adds menu blips to every Button below `root` (focus move + press).


static func wire(root: Node) -> void:
	for node in root.find_children("*", "Button", true, false):
		var button := node as Button
		button.focus_entered.connect(Audio.play.bind("menu_move", 1.0, -4.0))
		button.mouse_entered.connect(button.grab_focus)
		button.pressed.connect(Audio.play.bind("menu_select", 1.0, 0.0))
