class_name Hazard
extends Area2D
## Anything that hurts Pip on touch: spikes, blobs, bats.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.die()
