extends RigidBody2D

@export var bullet_life := 0.5

func _ready() -> void:
	await get_tree().create_timer(bullet_life).timeout
	queue_free()
