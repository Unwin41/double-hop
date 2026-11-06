extends Control
## Shown after the last level: run statistics and a way to play again.

const HOP_SPEED := 5.0
const HOP_HEIGHT := 8.0

var _time := 0.0

@onready var _stats: Label = %Stats
@onready var _again: Button = %Again
@onready var _pip: TextureRect = %Pip


func _ready() -> void:
	Audio.play_music(Audio.MUSIC_ENDING)
	_stats.text = "Coins  %d / %d\nTumbles  %d\nTime  %s" % [
		GameManager.coins_banked,
		GameManager.coins_possible,
		GameManager.deaths,
		GameManager.format_time(GameManager.run_time),
	]
	_again.pressed.connect(GameManager.start_new_run)
	%Title.pressed.connect(GameManager.go_to_title)
	UiSounds.wire(self)
	_again.grab_focus.call_deferred()


func _process(delta: float) -> void:
	_time += delta
	_pip.position.y = -roundf(absf(sin(_time * HOP_SPEED)) * HOP_HEIGHT)
