extends Area2D
## Collectible coin: bobs, "spins" between two frames, pops when collected.

const FRAME_FRONT := 151
const FRAME_SIDE := 152
const SPIN_TIME := 0.3
const BOB_HEIGHT := 1.5
const BOB_SPEED := 3.0

var _time := 0.0
var _collected := false

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_time = position.x * 0.07  # desync neighbours so rows of coins ripple
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _collected:
		return
	_time += delta
	_sprite.position.y = roundf(sin(_time * BOB_SPEED) * BOB_HEIGHT)
	_sprite.frame = FRAME_FRONT if fmod(_time, SPIN_TIME * 2.0) < SPIN_TIME else FRAME_SIDE


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body is Player:
		return
	_collected = true
	set_deferred("monitoring", false)
	GameManager.collect_coin()
	Audio.play("coin", randf_range(0.97, 1.08))
	_sprite.frame = FRAME_FRONT
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, "position:y", -12.0, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)
