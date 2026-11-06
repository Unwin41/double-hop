extends Node2D
## Headless movement tests. Run:
##   godot --headless --path . res://tests/test_movement.tscn
## Exits with code 0 when every test passes, 1 otherwise.

const TILE := 18
const FLOOR_ROW := 10
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const GEM_SCENE := preload("res://scenes/objects/refill_gem.tscn")
const TILESET := preload("res://assets/tileset.tres")
const GROUND_TILE := Vector2i(2, 0)

var _failures := 0
var _player: Player
var _ground: TileMapLayer


func _ready() -> void:
	await _run("single jump clears 3 tiles but not 4", _test_single_jump)
	await _run("double jump clears 5 tiles", _test_double_jump)
	await _run("tapping jump makes a small hop", _test_short_hop)
	await _run("coyote time allows a late ground jump", _test_coyote)
	await _run("jump buffer fires on landing", _test_buffer)
	await _run("gem gives the air jump back", _test_gem_refill)
	await _run("running reaches full speed quickly", _test_run_speed)
	print("\n%s (%d failed)" % ["ALL PASSED" if _failures == 0 else "FAILED", _failures])
	get_tree().quit(1 if _failures else 0)


func _run(test_name: String, test: Callable) -> void:
	_setup()
	await get_tree().physics_frame
	var error: String = await test.call()
	if error.is_empty():
		print("  PASS  ", test_name)
	else:
		_failures += 1
		print("  FAIL  ", test_name, " -> ", error)
	for action in ["move_left", "move_right", "jump"]:
		Input.action_release(action)
	_player.queue_free()
	_ground.queue_free()
	await get_tree().physics_frame


func _setup(floor_from := -20, floor_to := 60) -> void:
	_ground = _make_floor(floor_from, floor_to)
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector2(TILE / 2.0, FLOOR_ROW * TILE - 8)
	add_child(_player)


func _make_floor(from_x: int, to_x: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = TILESET
	for x in range(from_x, to_x):
		layer.set_cell(Vector2i(x, FLOOR_ROW), 0, GROUND_TILE)
	add_child(layer)
	return layer


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Holds jump for `hold` frames and returns the highest rise in pixels.
func _measure_rise(hold: int, second_jump_at := -1, total := 90) -> float:
	var start_y := _player.position.y
	var top := start_y
	Input.action_press("jump")
	for frame in total:
		if frame == hold:
			Input.action_release("jump")
		if frame == second_jump_at:
			Input.action_press("jump")
		await get_tree().physics_frame
		top = minf(top, _player.position.y)
	Input.action_release("jump")
	return start_y - top


func _test_single_jump() -> String:
	await _frames(5)
	var rise := await _measure_rise(60)
	if rise < 3 * TILE or rise > 4 * TILE:
		return "rise %.1f px, expected 54..72" % rise
	return ""


func _test_double_jump() -> String:
	await _frames(5)
	var rise := await _measure_rise(22, 24, 120)
	if rise < 5 * TILE or rise > 6 * TILE:
		return "rise %.1f px, expected 90..108" % rise
	return ""


func _test_short_hop() -> String:
	await _frames(5)
	var rise := await _measure_rise(2)
	if rise > 1.5 * TILE:
		return "rise %.1f px, expected < 27" % rise
	return ""


func _test_coyote() -> String:
	_ground.free()
	_ground = _make_floor(-20, 2)
	await _frames(3)
	Input.action_press("move_right")
	var frames_in_air := 0
	for i in 120:
		await get_tree().physics_frame
		if not _player.is_on_floor():
			frames_in_air += 1
			if frames_in_air == 4:
				break
	Input.action_press("jump")
	await _frames(2)
	if _player.velocity.y >= 0.0:
		return "no jump 4 frames after leaving the ledge (vy=%.1f)" % _player.velocity.y
	if _player.air_jumps_left != 1:
		return "coyote jump used up the air jump"
	return ""


func _test_buffer() -> String:
	await _frames(3)
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	await _frames(2)
	Input.action_press("jump")  # air jump
	await _frames(2)
	Input.action_release("jump")
	# Wait until falling and close to the floor, then press early.
	var floor_y := FLOOR_ROW * TILE - 8.0
	for i in 200:
		await get_tree().physics_frame
		if _player.velocity.y > 0.0 and floor_y - _player.position.y < 12.0:
			break
	Input.action_press("jump")
	for i in 12:
		await get_tree().physics_frame
		if _player.velocity.y < -100.0:
			return ""
	return "buffered press did not jump after landing"


func _test_gem_refill() -> String:
	var gem := GEM_SCENE.instantiate()
	gem.position = _player.position + Vector2(0, -70)
	add_child(gem)
	await _frames(3)
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	await _frames(1)
	Input.action_press("jump")  # spend the air jump right away
	var refilled := false
	for i in 60:
		await get_tree().physics_frame
		if _player.air_jumps_left == 1 and not _player.is_on_floor():
			refilled = true
			break
	gem.queue_free()
	return "" if refilled else "air jump was not refilled by the gem"


func _test_run_speed() -> String:
	await _frames(3)
	Input.action_press("move_right")
	await _frames(9)
	if _player.velocity.x < Player.RUN_SPEED * 0.95:
		return "speed %.1f after 9 frames" % _player.velocity.x
	return ""
