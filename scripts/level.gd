class_name Level
extends Node2D
## Root of every level scene. Wires the camera to the map bounds, counts
## coins, ends the attempt when Pip falls out of the world and handles quick restart.

const FALL_MARGIN := 40.0

@export var level_name := "Level"

var _kill_y := 0.0

@onready var _ground: TileMapLayer = $Ground
@onready var _player: Player = $Player


func _ready() -> void:
	var coin_count := get_tree().get_nodes_in_group("coin").size()
	GameManager.register_level(coin_count, level_name)
	Audio.play_music(Audio.MUSIC_LEVEL)
	var bounds := _world_bounds()
	_player.set_camera_limits(bounds)
	_kill_y = bounds.end.y + FALL_MARGIN


func _physics_process(_delta: float) -> void:
	if _player.global_position.y > _kill_y:
		_player.die()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and not _player.is_dead():
		GameManager.restart_level()


## Map area in pixels, without the invisible side walls the builder adds.
func _world_bounds() -> Rect2i:
	var used := _ground.get_used_rect().grow_individual(-1, 0, -1, 0)
	var tile := _ground.tile_set.tile_size
	return Rect2i(used.position * tile, used.size * tile)
