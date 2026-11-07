extends Node
## Dev tool: opens a scene, optionally plays scripted input, saves screenshots.
## Used for README images and quick visual checks. Not part of the game.
##
##   godot --path . res://tools/capture.tscn -- --scene=res://scenes/levels/level_01.tscn \
##       --out=/tmp/shot --frames=90 --input="0:right+;40:jump+;46:jump-"
##
## --input is "frame:action+|-" steps separated by ';' (+ press, - release).
## --every=N also saves a frame every N frames (for GIF frames).
## --autopilot runs right and jumps over walls and gaps (good enough for demo GIFs).
## --start=X,Y puts Pip on tile X,Y first (to record one part of a level).
## --log prints Pip's tile position twice a second.

var _scene_path := ""
var _out := "user://capture"
var _frames := 60
var _every := 0
var _steps: Array[Dictionary] = []
var _frame := 0
var _autopilot := false
var _log := false
var _jump_frames := 0


func _ready() -> void:
	var args := _parse_args()
	_scene_path = args.get("scene", "res://scenes/ui/title.tscn")
	_out = args.get("out", _out)
	_frames = int(args.get("frames", "60"))
	_every = int(args.get("every", "0"))
	_autopilot = args.has("autopilot")
	_log = args.has("log")
	for step in String(args.get("input", "")).split(";", false):
		var parts := step.split(":")
		var action := parts[1].left(-1)
		_steps.append({"frame": int(parts[0]), "action": action, "pressed": parts[1].ends_with("+")})
	var packed: PackedScene = load(_scene_path)
	var scene := packed.instantiate()
	if args.has("start"):
		var tile := String(args["start"]).split(",")
		var player := scene.get_node_or_null("Player") as Node2D
		if player:
			player.position = Vector2(int(tile[0]) * 18 + 9, (int(tile[1]) + 1) * 18 - 8)
	add_child.call_deferred(scene)


func _physics_process(_delta: float) -> void:
	_frame += 1
	for step in _steps:
		if step["frame"] == _frame:
			if step["pressed"]:
				Input.action_press(step["action"])
			else:
				Input.action_release(step["action"])
	if _autopilot and _frame > 20:
		_drive()
	if _log and _frame % 30 == 0:
		var pip := get_tree().get_first_node_in_group("player") as Node2D
		if pip:
			print("frame %d  tile %.1f, %.1f" % [_frame, pip.position.x / 18.0, pip.position.y / 18.0])
	if _every > 0 and _frame % _every == 0:
		_save("%s_%04d.png" % [_out, _frame / _every])
	if _frame >= _frames:
		_save(_out + ".png")
		get_tree().quit()


func _drive() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.is_dead():
		return
	var ground := player.get_parent().get_node("Ground") as TileMapLayer
	var solid := func(cx: int, cy: int) -> bool: return ground.get_cell_source_id(Vector2i(cx, cy)) != -1
	var fx := floori(player.position.x / 18.0)
	var feet_row := floori((player.position.y + 9.0) / 18.0)
	var top_row := floori((player.position.y - 7.0) / 18.0)
	var low_row := floori((player.position.y + 7.0) / 18.0)
	Input.action_press("move_right")
	if _jump_frames > 0:
		_jump_frames -= 1
		if _jump_frames == 0:
			Input.action_release("jump")
		return
	var wall_ahead: bool = solid.call(fx + 1, top_row) or solid.call(fx + 1, low_row)
	if player.is_on_floor():
		var near_edge := fposmod(player.position.x, 18.0) > 9.0
		var gap_ahead: bool = not solid.call(fx + 1, feet_row)
		if wall_ahead or (gap_ahead and near_edge):
			_press_jump(18)
	elif player.air_jumps_left > 0 and player.velocity.y > -20.0:
		var floor_below := false
		for dy in 4:
			if solid.call(fx + 1, feet_row + dy) or solid.call(fx + 2, feet_row + dy):
				floor_below = true
		if wall_ahead or not floor_below:
			_press_jump(16)


func _press_jump(hold_frames: int) -> void:
	Input.action_press("jump")
	_jump_frames = hold_frames


func _save(path: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(path)


func _parse_args() -> Dictionary:
	var result := {}
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=", true, 1)
		result[kv[0]] = kv[1] if kv.size() > 1 else ""
	return result
