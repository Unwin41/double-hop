class_name Patroller
extends Hazard
## A hazard that walks or flies back and forth between min_x and max_x.
## The level builder computes the range from the tile map.

@export var min_x := 0.0
@export var max_x := 0.0
@export var speed := 30.0
@export var frames: PackedInt32Array = PackedInt32Array([18, 19])
@export var frame_time := 0.2
@export var bob_height := 0.0
@export var bob_speed := 3.0
## True if the source art looks to the left when not flipped.
@export var art_faces_left := true

var _direction := 1.0
var _time := 0.0
var _base_y := 0.0

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	super()
	_base_y = position.y
	_time = randf() * 2.0


func _physics_process(delta: float) -> void:
	_time += delta
	if max_x > min_x:
		position.x += _direction * speed * delta
		if position.x >= max_x:
			position.x = max_x
			_direction = -1.0
		elif position.x <= min_x:
			position.x = min_x
			_direction = 1.0
	if bob_height > 0.0:
		position.y = _base_y + roundf(sin(_time * bob_speed) * bob_height)
	_sprite.frame = frames[int(_time / frame_time) % frames.size()]
	_sprite.flip_h = (_direction > 0.0) == art_faces_left
