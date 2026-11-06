extends Area2D
## Blue gem that gives Pip's mid-air jump back. Only used up when needed,
## then grows back after a short delay.

const RESPAWN_TIME := 1.8
const BOB_HEIGHT := 2.0
const BOB_SPEED := 2.5

var _active := true
var _time := 0.0

@onready var _sprite: Sprite2D = $Sprite


func _physics_process(delta: float) -> void:
	_time += delta
	_sprite.position.y = roundf(sin(_time * BOB_SPEED) * BOB_HEIGHT)
	if not _active:
		return
	# Polling (instead of body_entered) also catches Pip hovering inside the
	# gem while the air jump is still unused.
	for body in get_overlapping_bodies():
		if body is Player and body.refill_air_jump():
			_consume()
			return


func _consume() -> void:
	_active = false
	Audio.play("gem")
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2.ZERO, 0.15)
	tween.tween_interval(RESPAWN_TIME)
	tween.tween_property(_sprite, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: _active = true)
