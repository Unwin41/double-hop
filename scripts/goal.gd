extends Area2D
## The level's goal flag. Touching it finishes the level.

const FLAG_FRAMES := [111, 112]
const WAVE_TIME := 0.3
const CELEBRATE_TIME := 1.1

var _time := 0.0
var _reached := false

@onready var _flag: Sprite2D = $Flag


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_flag.frame = FLAG_FRAMES[int(_time / WAVE_TIME) % FLAG_FRAMES.size()]


func _on_body_entered(body: Node2D) -> void:
	if _reached or not body is Player or body.is_dead():
		return
	_reached = true
	Audio.play("win")
	body.celebrate()
	# A child Timer pauses with the game and dies with the level, so leaving
	# through the pause menu can't fire a stale complete_level().
	var timer := Timer.new()
	timer.one_shot = true
	timer.timeout.connect(GameManager.complete_level)
	add_child(timer)
	timer.start(CELEBRATE_TIME)
