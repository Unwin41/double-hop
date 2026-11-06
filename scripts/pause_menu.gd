extends CanvasLayer
## Pause overlay: Esc / P / Start toggles it.

@onready var _resume: Button = %Resume


func _ready() -> void:
	hide()
	%Resume.pressed.connect(close)
	%Restart.pressed.connect(_on_restart)
	%Title.pressed.connect(_on_title)
	UiSounds.wire(self)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if visible:
			close()
		else:
			open()


func open() -> void:
	get_tree().paused = true
	show()
	_resume.grab_focus()


func close() -> void:
	hide()
	get_tree().paused = false


func _on_restart() -> void:
	close()
	GameManager.restart_level()


func _on_title() -> void:
	GameManager.go_to_title()
