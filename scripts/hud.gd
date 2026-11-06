extends CanvasLayer
## In-level HUD: coins collected in this level and the level name.

@onready var _coins: Label = %Coins
@onready var _level: Label = %LevelName


func _ready() -> void:
	# The level calls GameManager.register_level() after its children (this HUD
	# included) are ready, which emits coins_changed and fills both labels.
	GameManager.coins_changed.connect(_on_coins_changed)


func _on_coins_changed(collected: int, total: int) -> void:
	_coins.text = "%d/%d" % [collected, total]
	_level.text = GameManager.level_label()
