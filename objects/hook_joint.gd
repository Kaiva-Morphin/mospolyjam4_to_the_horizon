extends Node3D

@export var attention_distance := 25.0
@export var rest_length := 4.0
@export var stiffness := 20.0
@export var damping = 4.0
@export var max_force = 150.0

func _ready() -> void:
	unfocus()

func focus():
	$Focused.show()
	$Idle.hide()

func unfocus():
	$Focused.hide()
	$Idle.show()
