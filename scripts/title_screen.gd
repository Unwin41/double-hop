extends Control
## Title screen: Play (and Quit on desktop builds).

const BOB_SPEED := 3.0
const BOB_HEIGHT := 3.0

var _time := 0.0

@onready var _play: Button = %Play
@onready var _quit: Button = %Quit
@onready var _pip: TextureRect = %Pip


func _ready() -> void:
	Audio.play_music(Audio.MUSIC_LEVEL)
	_play.pressed.connect(GameManager.start_new_run)
	_quit.pressed.connect(get_tree().quit)
	_quit.visible = not GameManager.is_web()
	UiSounds.wire(self)
	_play.grab_focus.call_deferred()


func _process(delta: float) -> void:
	_time += delta
	_pip.position.y = roundf(sin(_time * BOB_SPEED) * BOB_HEIGHT)
