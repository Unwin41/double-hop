class_name Player
extends CharacterBody2D
## Pip, the player. Runs, jumps, and can jump exactly once more in mid-air.
## Feel helpers: coyote time, jump buffering, variable jump height and a
## slightly floaty apex while the jump button is held.

const RUN_SPEED := 110.0
const GROUND_ACCEL := 1100.0
const GROUND_DECEL := 1500.0
const AIR_ACCEL := 800.0
const AIR_DECEL := 450.0

const GRAVITY_UP := 700.0
const GRAVITY_DOWN := 1100.0
const MAX_FALL_SPEED := 320.0
const APEX_SPEED := 40.0
const APEX_GRAVITY_SCALE := 0.6

const JUMP_VELOCITY := -290.0
const AIR_JUMP_VELOCITY := -240.0
const JUMP_CUT_FACTOR := 0.45
const COYOTE_TIME := 0.1
const JUMP_BUFFER_TIME := 0.12
const AIR_JUMPS := 1

const FRAME_IDLE := 4
const FRAME_STEP := 5
const WALK_FRAME_TIME := 0.12
const SQUASH_RECOVERY := 12.0
const LAND_SPEED_FOR_SQUASH := 120.0

## True while the player may steer (false during level-complete celebration).
var input_enabled := true
var air_jumps_left := AIR_JUMPS

var _coyote_timer := 0.0
var _buffer_timer := 0.0
var _was_on_floor := true
var _is_dead := false
var _walk_timer := 0.0
var _last_fall_speed := 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _puff: CPUParticles2D = $Puff
@onready var _dust: CPUParticles2D = $Dust
@onready var _camera: Camera2D = $Camera


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	var direction := Input.get_axis("move_left", "move_right") if input_enabled else 0.0
	_update_timers(delta)
	_apply_horizontal(direction, delta)
	_apply_gravity(delta)
	_handle_jump()
	_last_fall_speed = velocity.y
	move_and_slide()
	_handle_landing()
	_animate(direction, delta)


func set_camera_limits(rect: Rect2i) -> void:
	_camera.limit_left = rect.position.x
	_camera.limit_top = rect.position.y
	_camera.limit_right = rect.end.x
	_camera.limit_bottom = rect.end.y
	_camera.reset_smoothing()


## Called by refill gems. Returns true if the gem was actually used.
func refill_air_jump() -> bool:
	if air_jumps_left >= AIR_JUMPS or is_on_floor():
		return false
	air_jumps_left = AIR_JUMPS
	_sprite.modulate = Color(0.7, 0.9, 1.6)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.3)
	return true


func celebrate() -> void:
	input_enabled = false
	if is_on_floor():
		velocity.y = JUMP_VELOCITY * 0.7


func die() -> void:
	# Once the flag is reached (input disabled) Pip can't be hurt any more.
	if _is_dead or not input_enabled:
		return
	_is_dead = true
	Audio.play("hurt")
	velocity = Vector2.ZERO
	$Hitbox.set_deferred("disabled", true)
	_camera.position_smoothing_enabled = false
	_sprite.frame = FRAME_STEP
	_sprite.modulate = Color(1.0, 0.55, 0.55)
	var tween := create_tween()
	tween.tween_property(_sprite, "position:y", _sprite.position.y - 14.0, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_sprite, "rotation", PI, 0.4)
	tween.tween_property(_sprite, "position:y", _sprite.position.y + 60.0, 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	GameManager.player_died()


func is_dead() -> bool:
	return _is_dead


# --- Movement -----------------------------------------------------------------

func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
		air_jumps_left = AIR_JUMPS
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_buffer_timer = maxf(_buffer_timer - delta, 0.0)
	if input_enabled and Input.is_action_just_pressed("jump"):
		_buffer_timer = JUMP_BUFFER_TIME


func _apply_horizontal(direction: float, delta: float) -> void:
	var on_floor := is_on_floor()
	var target := direction * RUN_SPEED
	var rate: float
	if absf(direction) > 0.01:
		rate = GROUND_ACCEL if on_floor else AIR_ACCEL
	else:
		rate = GROUND_DECEL if on_floor else AIR_DECEL
	velocity.x = move_toward(velocity.x, target, rate * delta)


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		return
	var gravity := GRAVITY_UP if velocity.y < 0.0 else GRAVITY_DOWN
	var holding_jump := input_enabled and Input.is_action_pressed("jump")
	if holding_jump and absf(velocity.y) < APEX_SPEED:
		gravity *= APEX_GRAVITY_SCALE
	velocity.y = minf(velocity.y + gravity * delta, MAX_FALL_SPEED)


func _handle_jump() -> void:
	if _buffer_timer > 0.0:
		if _coyote_timer > 0.0:
			_ground_jump()
		elif air_jumps_left > 0:
			_air_jump()
	# Variable height: letting go early cuts the rise short.
	if input_enabled and Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_FACTOR


func _ground_jump() -> void:
	velocity.y = JUMP_VELOCITY
	_coyote_timer = 0.0
	_buffer_timer = 0.0
	_sprite.scale = Vector2(0.75, 1.3)
	_dust.restart()
	Audio.play("jump", randf_range(0.95, 1.05))


func _air_jump() -> void:
	velocity.y = AIR_JUMP_VELOCITY
	air_jumps_left -= 1
	_buffer_timer = 0.0
	_sprite.scale = Vector2(0.7, 1.35)
	_puff.restart()
	Audio.play("jump", 1.35)


func _handle_landing() -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor and _last_fall_speed > LAND_SPEED_FOR_SQUASH:
		var strength := clampf(_last_fall_speed / MAX_FALL_SPEED, 0.0, 1.0)
		_sprite.scale = Vector2(1.0 + 0.35 * strength, 1.0 - 0.3 * strength)
		_dust.restart()
		Audio.play("land", 1.0, -4.0)
	_was_on_floor = on_floor


# --- Visuals ------------------------------------------------------------------

func _animate(direction: float, delta: float) -> void:
	_sprite.scale = _sprite.scale.lerp(Vector2.ONE, minf(SQUASH_RECOVERY * delta, 1.0))
	if direction != 0.0:
		_sprite.flip_h = direction > 0.0
	if not is_on_floor():
		_sprite.frame = FRAME_STEP
		_walk_timer = 0.0
	elif absf(velocity.x) > 10.0:
		_walk_timer += delta
		var step := int(_walk_timer / WALK_FRAME_TIME) % 2
		_sprite.frame = FRAME_STEP if step == 1 else FRAME_IDLE
	else:
		_sprite.frame = FRAME_IDLE
		_walk_timer = 0.0
