extends Node3D

func _ready() -> void:
	$Node3D/AnimationPlayer.play("idle")
