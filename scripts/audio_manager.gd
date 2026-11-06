extends Node
## Sound effects and music (autoload "Audio").
## Sound effects play on a small pool of players so they can overlap.

const SFX := {
	"jump": preload("res://audio/sfx/jump.wav"),
	"land": preload("res://audio/sfx/land.wav"),
	"coin": preload("res://audio/sfx/coin.wav"),
	"hurt": preload("res://audio/sfx/hurt.wav"),
	"gem": preload("res://audio/sfx/gem.wav"),
	"win": preload("res://audio/sfx/win.wav"),
	"menu_move": preload("res://audio/sfx/menu_move.wav"),
	"menu_select": preload("res://audio/sfx/menu_select.wav"),
}
const MUSIC_LEVEL := preload("res://audio/music/level.wav")
const MUSIC_ENDING := preload("res://audio/music/ending.wav")

const POOL_SIZE := 8
const SFX_VOLUME_DB := -6.0
const MUSIC_VOLUME_DB := -14.0

var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.volume_db = SFX_VOLUME_DB
		add_child(player)
		_pool.append(player)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_VOLUME_DB
	_music.finished.connect(_music.play)  # simple, reliable looping
	add_child(_music)


func play(sfx_name: String, pitch := 1.0, volume_offset_db := 0.0) -> void:
	if not SFX.has(sfx_name):
		push_warning("Audio: unknown sound '%s'" % sfx_name)
		return
	var player := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	player.stream = SFX[sfx_name]
	player.pitch_scale = pitch
	player.volume_db = SFX_VOLUME_DB + volume_offset_db
	player.play()


func play_music(stream: AudioStream) -> void:
	if _music.stream == stream and _music.playing:
		return
	_music.stream = stream
	_music.play()
