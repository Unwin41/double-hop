extends Node
## Global game state (autoload "GameManager").
## Owns the level order, run statistics, the input map and scene transitions.

signal coins_changed(collected: int, total: int)

const LEVELS: Array[String] = [
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
	"res://scenes/levels/level_03.tscn",
	"res://scenes/levels/level_04.tscn",
	"res://scenes/levels/level_05.tscn",
	"res://scenes/levels/level_06.tscn",
	"res://scenes/levels/level_07.tscn",
]
const TITLE_SCENE := "res://scenes/ui/title.tscn"
const END_SCENE := "res://scenes/ui/end_screen.tscn"

const FADE_TIME := 0.22
const RESPAWN_DELAY := 0.6
const FADE_COLOR := Color(0.18, 0.13, 0.2)

## Keyboard keys (physical, so WASD also works on AZERTY etc.) and gamepad
## buttons for every gameplay action.
const KEY_BINDINGS := {
	"move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D],
	"jump": [KEY_SPACE, KEY_UP, KEY_W, KEY_Z],
	"pause": [KEY_ESCAPE, KEY_P],
	"restart": [KEY_R],
}
const PAD_BINDINGS := {
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"jump": [JOY_BUTTON_A, JOY_BUTTON_B],
	"pause": [JOY_BUTTON_START],
	"restart": [JOY_BUTTON_BACK],
}
const STICK_DEADZONE := 0.35

var level_index := 0
var deaths := 0
var run_time := 0.0
var coins_banked := 0
var coins_possible := 0
var level_coins := 0
var level_coin_total := 0
var level_name := ""
var is_timing := false

var _is_transitioning := false
var _fade_rect: ColorRect
## Bumped on every scene change so a pending respawn can tell it is stale
## (e.g. the player opened the pause menu and went back to the title).
var _scene_serial := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_input_actions()
	_build_fade_layer()


func _process(delta: float) -> void:
	if is_timing and not get_tree().paused:
		run_time += delta


# --- Run flow -----------------------------------------------------------------

func start_new_run() -> void:
	level_index = 0
	deaths = 0
	run_time = 0.0
	coins_banked = 0
	coins_possible = 0
	is_timing = true
	_change_scene(LEVELS[level_index])


func register_level(coin_total: int, display_name: String) -> void:
	level_coins = 0
	level_coin_total = coin_total
	level_name = display_name
	coins_changed.emit(level_coins, level_coin_total)


func collect_coin() -> void:
	level_coins += 1
	coins_changed.emit(level_coins, level_coin_total)


func player_died() -> void:
	deaths += 1
	var serial := _scene_serial
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if serial == _scene_serial:
		restart_level()


func restart_level() -> void:
	_change_scene(LEVELS[level_index])


func complete_level() -> void:
	coins_banked += level_coins
	coins_possible += level_coin_total
	level_index += 1
	if level_index >= LEVELS.size():
		is_timing = false
		_change_scene(END_SCENE)
	else:
		_change_scene(LEVELS[level_index])


func go_to_title() -> void:
	is_timing = false
	_change_scene(TITLE_SCENE)


func level_label() -> String:
	return "%d/%d  %s" % [level_index + 1, LEVELS.size(), level_name]


func is_web() -> bool:
	return OS.has_feature("web")


static func format_time(seconds: float) -> String:
	var total_tenths := int(seconds * 10.0)
	var minutes := total_tenths / 600
	var secs := (total_tenths / 10) % 60
	return "%d:%02d.%d" % [minutes, secs, total_tenths % 10]


# --- Scene transitions --------------------------------------------------------

func _change_scene(path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_scene_serial += 1
	await _fade_to(1.0)
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("GameManager: could not load scene %s (error %d)" % [path, err])
	await _fade_to(0.0)
	_is_transitioning = false


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", alpha, FADE_TIME)
	await tween.finished


func _build_fade_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(FADE_COLOR, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade_rect)


# --- Input map ----------------------------------------------------------------

func _register_input_actions() -> void:
	for action: String in KEY_BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, STICK_DEADZONE)
		for key: Key in KEY_BINDINGS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		for button: JoyButton in PAD_BINDINGS[action]:
			var pad := InputEventJoypadButton.new()
			pad.button_index = button
			InputMap.action_add_event(action, pad)
	_add_stick("move_left", -1.0)
	_add_stick("move_right", 1.0)


func _add_stick(action: String, direction: float) -> void:
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = direction
	InputMap.action_add_event(action, motion)
